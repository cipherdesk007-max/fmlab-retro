#!/bin/bash
# Compila per Linux (PC) lo stesso core e lo stesso commit di core/core.tsv, per provarlo col banco.
#   prove/costruisci-core-linux.sh NOME USCITA   ->  USCITA/NOME_libretro.so
set -euo pipefail
nome=$1; uscita=$(mkdir -p "$2" && cd "$2" && pwd)
riga=$(awk -F'\t' -v n="$nome" '$1==n' "$(dirname "$0")/../core/core.tsv")
IFS=$'\t' read -r _ _ repo commit cartella makefile _ <<< "$riga"
lavoro=$(mktemp -d); cd "$lavoro"
git init -q src && cd src && git remote add origin "https://github.com/libretro/$repo"
git fetch -q --depth 1 origin "$commit" && git checkout -q FETCH_HEAD
git submodule update -q --init --recursive --depth 1 || true
j=$(nproc)
case "$nome" in
  mgba)
    cmake -S . -B fuori -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBRETRO=ON -DBUILD_QT=OFF -DBUILD_SDL=OFF -DBUILD_SHARED=OFF \
      -DBUILD_STATIC=OFF -DSKIP_LIBRARY=ON -DUSE_DISCORD_RPC=OFF -DUSE_EPOXY=OFF -DUSE_SQLITE3=OFF -DUSE_ELF=OFF -DUSE_LZMA=OFF \
      -DUSE_FFMPEG=OFF -DUSE_LIBZIP=OFF -DUSE_PNG=OFF -DUSE_ZLIB=OFF -DUSE_MINIZIP=OFF -DUSE_EDITLINE=OFF -DBUILD_GL=OFF \
      -DBUILD_GLES2=OFF -DBUILD_GLES3=OFF -DUSE_LUA=OFF >/dev/null
    cmake --build fuori -j"$j" --target mgba_libretro >/dev/null; so=fuori/mgba_libretro.so ;;
  bsnes) make -j"$j" target=libretro binary=library >/dev/null 2>&1; so=bsnes_libretro.so ;;
  pcsx_rearmed) make -f Makefile.libretro -j"$j" DYNAREC=0 >/dev/null 2>&1; so=pcsx_rearmed_libretro.so ;;
  *) make -C "$cartella" -f "$makefile" -j"$j" >/dev/null 2>&1; so=$(find "$cartella" -maxdepth 2 -name '*_libretro.so' | head -1) ;;
esac
cp "$so" "$uscita/${nome}_libretro.so"; echo "OK $uscita/${nome}_libretro.so"
