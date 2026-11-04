# FMLAB Retro 🎮

🇮🇹 Italiano · [🇬🇧 English](README.en.md)

La **fabbrica degli emulatori** del Game Emulator di [FMLAB Linux](https://github.com/cipherdesk007-max/fmlab-Linux-io):
qui si compilano per iPhone gli emulatori che l'app porta con sé, e c'è lo studio che ha portato a farli nativi.

> **Nessun gioco incluso.** FMLAB non fornisce e non scarica giochi: li mette l'utente, solo file che possiede o
> homebrew liberi.

## Il disco emulatore

Emulatori **nativi per iPhone** (arm64, iOS 15+, **senza JIT**), dai core libretro ufficiali, gli stessi di RetroArch:

| Console | Core | Sorgente |
|---|---|---|
| NES | FCEUmm | [libretro/libretro-fceumm](https://github.com/libretro/libretro-fceumm) |
| Game Boy / Color | Gambatte | [libretro/gambatte-libretro](https://github.com/libretro/gambatte-libretro) |
| Game Boy Advance | mGBA | [libretro/mgba](https://github.com/libretro/mgba) |
| Super Nintendo | bsnes | [libretro/bsnes](https://github.com/libretro/bsnes) |
| PlayStation | PCSX ReARMed (interprete) | [libretro/pcsx_rearmed](https://github.com/libretro/pcsx_rearmed) |
| Nintendo DS | DeSmuME (interprete) | [libretro/desmume](https://github.com/libretro/desmume) |

Come funziona:

1. [`core/core.tsv`](core/core.tsv) fissa un commit per ogni core.
2. GitHub ([core-ios](.github/workflows/core-ios.yml)) li compila con [`core/costruisci-core-ios.sh`](core/costruisci-core-ios.sh),
   uno `.framework` per core, e controlla che ci sia `retro_run`.
3. Esce la pubblicazione **`core-<n>`** con `FMLAB-Core.zip`, la sua impronta SHA-256 e `core.json` (sorgente,
   dimensione e impronta di ogni core).
4. FMLAB Linux fissa tag e impronta in `app/FMLAB/Emulatore/DISCO`, li controlla a ogni compilazione e mette gli
   emulatori dentro l'ipa, firmati con l'app.

Perché dentro l'app e non da scaricare: iOS esegue solo il codice firmato insieme all'app, quindi un emulatore nativo
scaricato dopo non partirebbe senza JIT.

## I dati del motore (si aggiornano senza nuova app)

[`dati/emulatore.json`](dati/emulatore.json) contiene tutto quello che **non è codice**: estensioni riconosciute da
ogni emulatore, opzioni (tutte senza JIT), BIOS controllati con l'impronta MD5, eventuali avvisi. Il Game Emulator lo
scarica da qui (al massimo ogni 6 ore, quando lo apri), lo controlla e lo usa; se manca la rete usa l'ultima copia,
o quella dentro l'app. Cambiare questo file aggiorna tutti i telefoni **senza una nuova versione dell'app**. Le prove
di GitHub rifiutano un file scritto male.

Il codice degli emulatori invece no: iOS esegue solo codice firmato insieme all'app, quindi un core nuovo arriva con
un aggiornamento di FMLAB Linux (disco `core-<n>`).

## Lo studio: perché nativi

Prima abbiamo provato RetroArch **dentro Debian** in FMLAB Linux, con [`misura/misura.sh`](misura/misura.sh). Fps
sull'iPhone 15 Pro Max senza JIT, finestra 1x · 2x · 3x · schermo intero (60 = velocità vera):

| Console | iPhone, dentro Linux | Server ARM64 nativo (riferimento) |
|---|---|---|
| NES | 68 · 30 · 19 · 10 | 1107 · 453 · 265 · 257 |
| Game Boy | 154 · 67 · 34 · 10 | 2308 · 898 · 569 · 269 |
| GBA | 131 · 45 · 22 · 9 | 962 · 414 · 607 · 251 |

Dentro Linux l'interprete rallenta tutto da 15 a 25 volte, e disegnare a schermo intero lo affossa. Nativi, gli stessi
core vanno molte volte oltre i 60 fps: per questo il Game Emulator li porta direttamente nell'app.

## Come si verifica

- Ogni `core-<n>` ha l'impronta SHA-256 pubblicata. L'app rifiuta di compilarsi se il file scaricato non corrisponde.
- Ogni core si può ricompilare dal commit scritto in `core/core.tsv` e confrontare.
- Sul telefono: Game Emulator, un gioco di prova libero (es. 240pee.nes della
  [240p Test Suite](https://github.com/pinobatch/240p-test-mini)), tasti, rotazione, salva e carica stato.

## Licenza e riconoscimenti

Script di FMLAB Retro: MIT. I core hanno le loro licenze (GPL, MPL per mGBA) e arrivano dai repository libretro
indicati sopra, senza modifiche.
