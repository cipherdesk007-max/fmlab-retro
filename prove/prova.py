#!/usr/bin/env python3
"""Prova un core libretro come lo usa il Game Emulator di FMLAB Linux.

    python3 prove/prova.py CORE.so NOME_CORE [GIOCO]

- passa al core le opzioni di dati/emulatore.json (come l'app)
- controlla che ognuna esista nel core e che il valore sia tra quelli che il core accetta
- se c'è un gioco: lo fa girare 600 fotogrammi con tasti simulati, salva e ricarica lo stato
"""
import json, os, subprocess, sys

QUI = os.path.dirname(os.path.abspath(__file__))
so, nome = sys.argv[1], sys.argv[2]
gioco = sys.argv[3] if len(sys.argv) > 3 else None
dati = json.load(open(os.path.join(QUI, "..", "dati", "emulatore.json")))
opzioni = dati["core"][nome]["opzioni"]
banco = os.path.join("/tmp", "banco-fmlab")
subprocess.run(["cc", "-O2", "-o", banco, os.path.join(QUI, "banco.c"), "-ldl"], check=True)

vuoto = "/tmp/banco-vuoto.bin"
open(vuoto, "wb").write(b"\0" * 1024)
amb = dict(os.environ, BANCO_OPZ="1", BANCO_FISSE=";".join(f"{k}={v}" for k, v in opzioni.items()))
r = subprocess.run([banco, so, gioco or vuoto, "600"], capture_output=True, text=True, env=amb, errors="replace")
dichiarate = {}
for riga in r.stdout.splitlines():
    if riga.startswith("OPZ\t"):
        _, k, valori = riga.split("\t", 2)
        dichiarate[k] = valori.split("|")
ok = True
for k, v in opzioni.items():
    # DeSmuME e altri usano le opzioni v2 (SET_VARIABLES solo come ripiego): se non le dichiara, si salta
    if not dichiarate:
        print(f"  ? {k} = {v} (il core non elenca le opzioni)")
    elif k not in dichiarate:
        print(f"  ✘ {k}: il core non ha questa opzione"); ok = False
    elif v not in dichiarate[k]:
        print(f"  ✘ {k} = {v}: valori possibili {dichiarate[k][:8]}"); ok = False
    else:
        print(f"  ✔ {k} = {v}")
print(f"{nome}: {len(dichiarate)} opzioni dichiarate dal core, {len(opzioni)} nei dati")
if gioco:
    righe = [l for l in r.stdout.splitlines() if not l.startswith("OPZ")]
    print("\n".join(righe[-2:]))
    if "OK" not in righe[-1:]:
        ok = False
sys.exit(0 if ok else 1)
