# FMLAB Retro 🎮🐧

[🇮🇹 Italiano](README.md) · 🇬🇧 English

The **FMLAB Retro** distribution for [FMLAB Linux](https://github.com/cipherdesk007-max/fmlab-Linux-io): Debian 13
ARM64 customised for playing classic consoles on the iPhone, with tuned emulators, the FMLAB theme and
[RunnerKit](https://github.com/cipherdesk007-max/FMlab---RunnerKit).

> **No games included.** FMLAB Retro neither ships nor downloads games: users add their own, only files they own or
> free homebrew.

## The emulator disc (FMLAB Linux Game Emulator)

Since FMLAB Linux 0.9.0 games no longer go through Linux: the app has a **Game Emulator** with **native iPhone
emulators** (arm64, no JIT) built by this project from libretro cores: FCEUmm (NES), Gambatte (Game Boy/Color), mGBA
(GBA), bsnes (SNES), PCSX ReARMed (PlayStation, interpreter), DeSmuME (DS, interpreter). Fixed commits in
[`core/core.tsv`](core/core.tsv), built by GitHub ([core-ios](.github/workflows/core-ios.yml)); each `core-<n>` release
has `FMLAB-Core.zip`, its SHA-256 and `core.json`. The app pins tag and checksum. No games included.

## FMLAB Retro on Debian (optional)

RetroArch inside Linux is still available as the `fmlab-retro` package (slower: it runs through the interpreter).

## Install

On an existing Debian 13:

```sh
B=https://raw.githubusercontent.com/cipherdesk007-max/fmlab-retro/apt
sudo curl -fsSL $B/fmlab-retro.gpg -o /usr/share/keyrings/fmlab-retro.gpg
sudo curl -fsSL $B/fmlab-retro.sources -o /etc/apt/sources.list.d/fmlab-retro.sources
sudo apt update && sudo apt install fmlab-retro
```

Key fingerprint: `179D FBA1 AE36 3242 B1E6 49D1 66B1 B041 7BE8 A5E2`.
**Updating**: `sudo apt update && sudo apt upgrade` (Debian and FMLAB together); your RetroArch settings are kept.

## Status

Before building the distribution we measure what the phone can handle: in FMLAB Linux programs run inside an
interpreter (or with the JIT, via StikDebug), so an emulator in there does double work.

| Phase | What | Status |
|---|---|---|
| 1 | **Measure** fps on NES, Game Boy, GBA | ✅ done on the phone, continuing with JIT and GPU |
| 2 | **Package** `fmlab-retro` in a **GPG-signed apt archive** (`apt` branch, built and tested on Debian 13 ARM64 by GitHub) | ✅ |
| 3 | **Distribution in the app**: FMLAB Linux → Set Up Linux… → FMLAB Retro | ✅ FMLAB Linux 0.8.8 |

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
| 2026-11-04 | **iPhone 15 Pro Max**, FMLAB Linux 0.8.7, Debian 13, measure 0.1.1 | no | software | **7.9** (61) | **9.0** (195) | **7.7** (126) | — |
| | iPhone 15 Pro Max, FMLAB Linux 0.8.7, with JIT | yes | | *to measure* | | | |

**What the phone numbers say**: the CPU copes (NES 61, Game Boy 195, GBA 126 fps in a 1x window even without JIT);
the bottleneck is **scaling the picture to full screen** with software OpenGL (~8 fps). Measure 0.2.0 also tries 2x,
3x and full screen scaled by SDL, to find the fastest mode.

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
