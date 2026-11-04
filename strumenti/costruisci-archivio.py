#!/usr/bin/env python3
"""Costruisce l'archivio apt di FMLAB Retro (pacchetti .deb + indici firmati).

    python3 strumenti/costruisci-archivio.py USCITA [--firma IMPRONTA]

USCITA diventa il contenuto del ramo "apt" del repository, servito da
https://raw.githubusercontent.com/cipherdesk007-max/fmlab-retro/apt/
  pool/main/<pacchetto>_<versione>_all.deb
  dists/trixie/{Release,InRelease,Release.gpg}
  dists/trixie/main/binary-arm64/{Packages,Packages.gz}
  fmlab-retro.gpg, fmlab-retro.sources  (per chi aggiunge l'archivio a mano)
Senza --firma gli indici non sono firmati (solo per le prove locali).
"""
import gzip, hashlib, os, shutil, subprocess, sys, tempfile, time

RADICE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SUITE, COMPONENTE, ARCH = "trixie", "main", "arm64"
# file del repository messi dentro il pacchetto: una sola copia, niente differenze
COPIE = {
    "usr/bin/rk-giochi": "strumenti/rk-giochi",
    "usr/bin/fmlab-retro-misura": "misura/misura.sh",
    "usr/share/keyrings/fmlab-retro.gpg": "archivio/fmlab-retro.gpg",
    # la sorgente /etc/apt/sources.list.d/fmlab-retro.sources la crea chi aggiunge l'archivio
    # (l'app o il comando del README): se fosse del pacchetto, dpkg chiederebbe cosa fare
    "usr/share/fmlab-retro/fmlab-retro.sources": "archivio/fmlab-retro.sources",
}


def h(path, algo):
    d = hashlib.new(algo)
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            d.update(b)
    return d.hexdigest()


def costruisci_pacchetto(nome, pool):
    sorgente = os.path.join(RADICE, "pacchetti", nome)
    versione = open(os.path.join(sorgente, "VERSIONE")).read().strip()
    with tempfile.TemporaryDirectory() as t:
        albero = os.path.join(t, nome)
        shutil.copytree(sorgente, albero, ignore=shutil.ignore_patterns("VERSIONE"))
        for dentro, fuori in COPIE.items():
            dest = os.path.join(albero, dentro)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            shutil.copy2(os.path.join(RADICE, fuori), dest)
        for cart, _, files in os.walk(albero):
            for f in files:
                p = os.path.join(cart, f)
                if "/usr/bin/" in p:
                    os.chmod(p, 0o755)
                elif "/DEBIAN/" not in p:
                    os.chmod(p, 0o644)
        ctl = os.path.join(albero, "DEBIAN", "control")
        testo = open(ctl).read().replace("@VERSIONE@", versione)
        kb = sum(os.path.getsize(os.path.join(c, f)) for c, _, fs in os.walk(albero) for f in fs if "/DEBIAN" not in c) // 1024 + 1
        testo = testo.replace("Section:", f"Installed-Size: {kb}\nSection:", 1)
        open(ctl, "w").write(testo)
        deb = os.path.join(pool, f"{nome}_{versione}_all.deb")
        os.environ.setdefault("SOURCE_DATE_EPOCH", "1767225600")
        subprocess.run(["dpkg-deb", "--root-owner-group", "-Zxz", "--build", albero, deb], check=True, stdout=subprocess.DEVNULL)
    return deb, testo


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    uscita = os.path.abspath(sys.argv[1])
    firma = sys.argv[sys.argv.index("--firma") + 1] if "--firma" in sys.argv else None
    shutil.rmtree(uscita, ignore_errors=True)
    pool = os.path.join(uscita, "pool", COMPONENTE)
    binari = os.path.join(uscita, "dists", SUITE, COMPONENTE, f"binary-{ARCH}")
    os.makedirs(pool)
    os.makedirs(binari)

    voci = []
    for nome in sorted(os.listdir(os.path.join(RADICE, "pacchetti"))):
        deb, control = costruisci_pacchetto(nome, pool)
        rel = os.path.relpath(deb, uscita)
        campi = control.strip() + "\n" + "\n".join([
            f"Filename: {rel}", f"Size: {os.path.getsize(deb)}",
            f"MD5sum: {h(deb, 'md5')}", f"SHA256: {h(deb, 'sha256')}"])
        voci.append(campi)
        print("pacchetto:", rel)
    pk = os.path.join(binari, "Packages")
    open(pk, "w").write("\n\n".join(voci) + "\n")
    with open(pk, "rb") as a, gzip.GzipFile(pk + ".gz", "wb", mtime=0) as b:
        b.write(a.read())

    indici = [os.path.join(binari, n) for n in ("Packages", "Packages.gz")]
    base = os.path.join(uscita, "dists", SUITE)
    righe = [
        "Origin: FMLAB", "Label: FMLAB Retro", f"Suite: {SUITE}", f"Codename: {SUITE}",
        "Date: " + time.strftime("%a, %d %b %Y %H:%M:%S UTC", time.gmtime()),
        f"Architectures: {ARCH}", f"Components: {COMPONENTE}",
        "Description: Pacchetti FMLAB Retro per Debian 13 (FMLAB Linux)",
    ]
    for algo, nome in (("md5", "MD5Sum"), ("sha256", "SHA256")):
        righe.append(nome + ":")
        for f in indici:
            righe.append(f" {h(f, algo)} {os.path.getsize(f):>8} {os.path.relpath(f, base)}")
    release = os.path.join(base, "Release")
    open(release, "w").write("\n".join(righe) + "\n")

    if firma:
        g = ["gpg", "--batch", "--yes", "--local-user", firma, "--digest-algo", "SHA512"]
        subprocess.run(g + ["--clearsign", "-o", os.path.join(base, "InRelease"), release], check=True)
        subprocess.run(g + ["--armor", "--detach-sign", "-o", os.path.join(base, "Release.gpg"), release], check=True)
        print("firmato con", firma)
    for f in ("fmlab-retro.gpg", "fmlab-retro.sources", "IMPRONTA"):
        shutil.copy2(os.path.join(RADICE, "archivio", f), uscita)
    open(os.path.join(uscita, "LEGGIMI.md"), "w").write(
        "# Archivio apt di FMLAB Retro\n\nGenerato in automatico da `strumenti/costruisci-archivio.py` "
        "(ramo `main`). Non modificare a mano.\n")


if __name__ == "__main__":
    main()
