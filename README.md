# FMLAB Retro 🎮🐧

🇮🇹 Italiano · [🇬🇧 English](README.en.md)

Distribuzione **FMLAB Retro** per [FMLAB Linux](https://github.com/cipherdesk007-max/fmlab-Linux-io): Debian 13
ARM64 personalizzato per giocare alle console vecchie sull'iPhone, con emulatori già regolati, tema FMLAB e
[RunnerKit](https://github.com/cipherdesk007-max/FMlab---RunnerKit).

> **Nessun gioco incluso.** FMLAB Retro non fornisce e non scarica giochi: li mette l'utente, solo file che
> possiede o liberi (homebrew).

## Installare

**Dall'app** (FMLAB Linux 0.8.8 o dopo): Distribuzioni → Configura Linux… → **FMLAB Retro**. Si installa Debian 13
ufficiale verificato, poi account e desktop, poi *Installa FMLAB Retro*. La trovi in Distribuzioni con l'icona del
controller, accanto a Debian.

**A mano**, in un Debian 13 che hai già:

```sh
B=https://raw.githubusercontent.com/cipherdesk007-max/fmlab-retro/apt
sudo curl -fsSL $B/fmlab-retro.gpg -o /usr/share/keyrings/fmlab-retro.gpg
sudo curl -fsSL $B/fmlab-retro.sources -o /etc/apt/sources.list.d/fmlab-retro.sources
sudo apt update && sudo apt install fmlab-retro
```

Impronta della chiave: `179D FBA1 AE36 3242 B1E6 49D1 66B1 B041 7BE8 A5E2`
(`gpg --show-keys /usr/share/keyrings/fmlab-retro.gpg`).

**Aggiornare**: `sudo apt update && sudo apt upgrade`, Debian e FMLAB insieme. Le impostazioni che cambi in
RetroArch restano (la base FMLAB si copia solo la prima volta; per rimetterla: `fmlab-retro --ripristina`).

## Stato

Prima di costruire la distribuzione si misura quanto regge il telefono, perché in FMLAB Linux i programmi girano
dentro un interprete (o col JIT, con StikDebug) e un emulatore lì dentro fa doppio lavoro.

| Fase | Cosa | Stato |
|---|---|---|
| 1 | **Misura** degli fps su NES, Game Boy, GBA (e SNES/Sega con i tuoi file) | ✅ fatta sul telefono, si continua con JIT e GPU |
| 2 | **Pacchetto** `fmlab-retro` (RetroArch, core, impostazioni FMLAB, `rk-giochi`, misura) in un **archivio apt firmato GPG** (ramo `apt`, costruito e provato su Debian 13 ARM64 da GitHub) | ✅ |
| 3 | **Distribuzione nell'app**: FMLAB Linux → Configura Linux… → FMLAB Retro (Debian 13 verificato + archivio FMLAB) | ✅ FMLAB Linux 0.8.8 |

Non c'è un'immagine da riscaricare: tutto si aggiorna con `apt update && apt upgrade` (Debian ufficiale + archivio
FMLAB), e le modifiche dell'utente restano.

## Fase 1: misura sul telefono

Nel terminale del desktop di FMLAB Linux (pallino >_ di TouchPad), con Debian:

```sh
curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/fmlab-retro/main/misura/misura.sh -o /tmp/misura.sh && bash /tmp/misura.sh
```

- Installa RetroArch e i core più leggeri da Debian (Nestopia, Gambatte, mGBA; SNES e Sega se disponibili).
- Scarica i giochi di prova liberi **240p Test Suite** (Damian Yerrick, GPL) dalla loro pagina GitHub.
- Per ogni console misura due cose: **1x** (finestra piccola: quasi solo il processore) e **intero** (a schermo
  intero, col disegno vero). Metodo: due giri da 120 e 720 fotogrammi, fps = differenza diviso tempo, così l'avvio non conta.
  60 fps = velocità vera.
- Con un tuo file: `bash /tmp/misura.sh mio-gioco.sfc`.
- Il risultato va anche in un file in **Shared** (app File → FMLAB Linux → Shared): mandalo per la tabella qui sotto.

Da provare tre volte: senza JIT, col JIT (StikDebug), e con *Grafica → GPU Metal* accesa e spenta.

### Risultati

Fps a schermo intero (tra parentesi finestra 1x). 60 = velocità vera.

| Data | Dove | JIT | GPU | NES | Game Boy | GBA | SNES |
|---|---|---|---|---|---|---|---|
| 2026-11-04 | riferimento: server ARM64 GitHub, Debian 13, RetroArch 1.20, **senza interprete** | — | software | 260 (932) | 300 (2158) | 253 (5882*) | — |
| 2026-11-04 | **iPhone 15 Pro Max**, FMLAB Linux 0.8.7, Debian 13, misura 0.1.1 | no | software | **7.9** (61) | **9.0** (195) | **7.7** (126) | — |
| | iPhone 15 Pro Max, FMLAB Linux 0.8.7, con JIT | sì | | *da misurare* | | | |

**Cosa dicono i numeri del telefono**: il processore ce la fa (NES 61, Game Boy 195, GBA 126 fps in finestra 1x
anche senza JIT), il collo di bottiglia è **ingrandire l'immagine a tutto schermo** con OpenGL software (~8 fps).
Dalla misura 0.2.0 si provano anche 2x, 3x e lo schermo intero ingrandito da SDL, per trovare il modo più veloce.

\* il menu di prova GBA è quasi fermo e mGBA salta i cicli a vuoto: col gioco vero sarà molto meno.

## I giochi: `rk-giochi`

```sh
rk-giochi importa            # prende i file messi in Shared/Giochi (app File dell'iPhone)
rk-giochi scarica LINK       # scarica da un link che dai tu
rk-giochi elenco             # cosa c'è, per console
rk-giochi togli NOME         # elimina
rk-giochi bios FILE          # BIOS (li metti tu)
```

Riconosce la console dall'estensione (anche dentro gli zip), mette i file in `~/Giochi/<console>/` e crea gli elenchi
di RetroArch (*FMLAB Retro - NES*, …). Accetta solo link http(s). Sarà nel pacchetto `rk-giochi` (fase 2);
intanto: `curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/fmlab-retro/main/strumenti/rk-giochi -o /usr/local/bin/rk-giochi && chmod +x /usr/local/bin/rk-giochi`.

## Come si verifica

- A ogni modifica GitHub prova `rk-giochi` con file finti e rifà la misura su un **server ARM64 vero con Debian 13**
  ([prove](.github/workflows/prove.yml)): è la velocità "nativa" di riferimento. Il rapporto tra quella e la misura sul
  telefono dice quanto costa l'interprete o il JIT.
- Chiunque con lo stesso telefono rifà la misura con lo stesso comando e confronta: differenze sotto il 10% non contano.
- Fase 2: `apt policy fmlab-retro` deve mostrare il repository FMLAB firmato; `apt` deve rifiutare pacchetti non firmati;
  dopo `apt upgrade` le impostazioni cambiate a mano restano (prova automatica).

## Licenza e riconoscimenti

Codice di FMLAB Retro: MIT. RetroArch, i core libretro e Debian hanno le loro licenze (GPL e altre) e arrivano dai
pacchetti ufficiali di Debian. 240p Test Suite: Artemio Urbina e Damian Yerrick (GPL), scaricata dalla loro pagina.
