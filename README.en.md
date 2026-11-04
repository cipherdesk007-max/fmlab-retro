# FMLAB Retro 🎮

[🇮🇹 Italiano](README.md) · 🇬🇧 English

The **emulator factory** behind the Game Emulator of [FMLAB Linux](https://github.com/cipherdesk007-max/fmlab-Linux-io):
it builds the iPhone emulators the app ships with, plus the study that led to making them native.

> **No games included.** FMLAB neither ships nor downloads games: users add their own, only files they own or free
> homebrew.

## The emulator disc

**Native iPhone** emulators (arm64, iOS 15+, **no JIT**) from the official libretro cores, the same ones RetroArch uses:
FCEUmm (NES), Gambatte (Game Boy/Color), mGBA (GBA), bsnes (SNES), PCSX ReARMed (PlayStation, interpreter), DeSmuME
(DS, interpreter).

1. [`core/core.tsv`](core/core.tsv) pins one commit per core.
2. GitHub ([core-ios](.github/workflows/core-ios.yml)) builds them, one `.framework` per core.
3. A **`core-<n>`** release ships `FMLAB-Core.zip`, its SHA-256 and `core.json` (source, size and checksum of each core).
4. FMLAB Linux pins tag and checksum in `app/FMLAB/Emulatore/DISCO`, verifies them on every build and embeds the
   emulators in the ipa, signed with the app.

They are built in because iOS only runs code signed with the app: a native emulator downloaded later would not start
without JIT.

## The study: why native

We first measured RetroArch **inside Debian** in FMLAB Linux ([`misura/misura.sh`](misura/misura.sh)). iPhone 15 Pro Max
without JIT, fps at 1x · 2x · 3x · full screen: NES 68 · 30 · 19 · 10, Game Boy 154 · 67 · 34 · 10, GBA 131 · 45 · 22 · 9
(60 = full speed). The interpreter costs 15–25×, so the Game Emulator runs the same cores natively.

## How it's checked

Every `core-<n>` has a published SHA-256 and the app refuses to build on a mismatch. Each core can be rebuilt from the
commit in `core/core.tsv`.

## License and credits

FMLAB Retro scripts: MIT. The cores keep their own licenses (GPL, MPL for mGBA) and come unmodified from the libretro
repositories above.
