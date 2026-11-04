# FMLAB Retro 🎮🐧

🇮🇹 Italiano · [🇬🇧 English](README.en.md)

Distribuzione **FMLAB Retro** per [FMLAB Linux](https://github.com/cipherdesk007-max/fmlab-Linux-io): Debian 13
ARM64 personalizzato per giocare alle console vecchie sull'iPhone, con emulatori già regolati, tema FMLAB e
[RunnerKit](https://github.com/cipherdesk007-max/FMlab---RunnerKit).

> **Nessun gioco incluso.** FMLAB Retro non fornisce e non scarica giochi: li mette l'utente, solo file che
> possiede o liberi (homebrew).

## Stato: fase 1, misura

Prima di costruire la distribuzione si misura quanto regge il telefono, perché in FMLAB Linux i programmi girano
dentro un interprete (o col JIT, con StikDebug) e un emulatore lì dentro fa doppio lavoro.

| Fase | Cosa | Stato |
|---|---|---|
| 1 | **Misura** degli fps su NES, Game Boy, GBA (e SNES/Sega con i tuoi file) | ✅ pronta, da fare sul telefono |
| 2 | **Pacchetti FMLAB** (`.deb`): `fmlab-retro` (emulatori + profili per console), `fmlab-tema`, `rk-giochi`, in un repository apt **firmato GPG** su GitHub Pages | in base ai numeri |
| 3 | **Immagine** Debian 13 ARM64 (mmdebstrap su GitHub Actions) da installare con un tocco da FMLAB Linux → Distribuzioni, con impronta SHA-256 | dopo la fase 2 |

Dopo l'installazione **non si riscarica mai l'immagine**: tutto si aggiorna con `apt update && apt upgrade`
(Debian ufficiale + repository FMLAB), e le modifiche dell'utente restano.

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
| | iPhone 15 Pro Max, FMLAB Linux 0.8.6, senza JIT | no | | *da misurare* | | | |
| | iPhone 15 Pro Max, FMLAB Linux 0.8.6, con JIT | sì | | *da misurare* | | | |

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
