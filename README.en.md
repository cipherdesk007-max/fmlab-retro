# FMLAB Retro 🎮🐧

[🇮🇹 Italiano](README.md) · 🇬🇧 English

The **FMLAB Retro** distribution for [FMLAB Linux](https://github.com/cipherdesk007-max/fmlab-Linux-io): Debian 13
ARM64 customised for playing classic consoles on the iPhone, with tuned emulators, the FMLAB theme and
[RunnerKit](https://github.com/cipherdesk007-max/FMlab---RunnerKit).

> **No games included.** FMLAB Retro neither ships nor downloads games: users add their own, only files they own or
> free homebrew.

## Status: phase 1, measurement

Before building the distribution we measure what the phone can handle: in FMLAB Linux programs run inside an
interpreter (or with the JIT, via StikDebug), so an emulator in there does double work.

| Phase | What | Status |
|---|---|---|
| 1 | **Measure** fps on NES, Game Boy, GBA (and SNES/Sega with your own files) | ✅ ready, to run on the phone |
| 2 | **FMLAB packages** (`.deb`): `fmlab-retro` (emulators + per-console profiles), `fmlab-tema`, `rk-giochi`, in a **GPG-signed** apt repository on GitHub Pages | depends on the numbers |
| 3 | **Image**: Debian 13 ARM64 (mmdebstrap on GitHub Actions), installed with one tap from FMLAB Linux → Distributions, with a SHA-256 checksum | after phase 2 |

After installation **the image is never downloaded again**: everything updates with `apt update && apt upgrade`
(official Debian + FMLAB repository), and user changes are kept.

## Phase 1: measure on the phone

In the FMLAB Linux desktop terminal (TouchPad's >_ bubble), on Debian:

```sh
curl -fsSL https://raw.githubusercontent.com/cipherdesk007-max/fmlab-retro/main/misura/misura.sh -o /tmp/misura.sh && bash /tmp/misura.sh
```

- Installs RetroArch and the lightest cores from Debian (Nestopia, Gambatte, mGBA; SNES and Sega if available).
- Downloads the free **240p Test Suite** test ROMs (Damian Yerrick, GPL) from their GitHub page.
- For each console it measures **1x** (small window: mostly the CPU) and **full** (full screen, with real
  drawing).
  Method: two runs of 120 and 720 frames, fps = difference over time, so start-up doesn't count. 60 fps = full speed.
- With your own file: `bash /tmp/misura.sh my-game.sfc`.
- The result is also saved in **Shared** (Files app → FMLAB Linux → Shared).

Run it three ways: without JIT, with JIT (StikDebug), and with *Graphics → Metal GPU* on and off.

### Results

Full-screen fps (1x window in brackets). 60 = full speed.

| Date | Where | JIT | GPU | NES | Game Boy | GBA | SNES |
|---|---|---|---|---|---|---|---|
| 2026-11-04 | reference: GitHub ARM64 server, Debian 13, RetroArch 1.20, **no interpreter** | — | software | 260 (932) | 300 (2158) | 253 (5882*) | — |
| | iPhone 15 Pro Max, FMLAB Linux 0.8.6, no JIT | no | | *to measure* | | | |
| | iPhone 15 Pro Max, FMLAB Linux 0.8.6, with JIT | yes | | *to measure* | | | |

\* the GBA test menu is nearly static and mGBA skips idle loops: a real game will be much lower.

## Games: `rk-giochi`

```sh
rk-giochi importa            # takes the files you put in Shared/Giochi (iPhone Files app)
rk-giochi scarica LINK       # downloads from a link you give
rk-giochi elenco             # what's there, by console
rk-giochi togli NAME         # removes a game
rk-giochi bios FILE          # BIOS files (you provide them)
```

It detects the console from the extension (also inside zips), puts files in `~/Giochi/<console>/` and creates
RetroArch playlists (*FMLAB Retro - NES*, …). Only http(s) links are accepted.

## How it's checked

- On every change GitHub tests `rk-giochi` with dummy files and re-runs the measurement on a **real ARM64 server with
  Debian 13** ([prove](.github/workflows/prove.yml)): the "native" reference. The ratio between that and the phone
  measurement shows what the interpreter or the JIT costs.
- Anyone with the same phone can repeat the measurement with the same command; differences under 10% don't count.

## License and credits

FMLAB Retro code: MIT. RetroArch, the libretro cores and Debian have their own licenses (GPL and others) and come from
official Debian packages. 240p Test Suite: Artemio Urbina and Damian Yerrick (GPL), downloaded from their page.
