#!/bin/bash
# Compila un core libretro per iPhone (arm64, nativo, senza JIT) e lo mette in un .framework
# firmabile da SideStore/LiveContainer insieme all'app.
#   core/costruisci-core-ios.sh NOME USCITA     (NOME da core/core.tsv)
set -euo pipefail
nome=$1; uscita=$(mkdir -p "$2" && cd "$2" && pwd)
riga=$(awk -F'\t' -v n="$nome" '$1==n' "$(dirname "$0")/core.tsv")
[ -n "$riga" ] || { echo "core sconosciuto: $nome"; exit 2; }
IFS=$'\t' read -r _ console repo commit cartella makefile extra <<< "$riga"
lavoro=$(mktemp -d)
git -C "$lavoro" init -q src && cd "$lavoro/src"
case "$repo" in */*) url="https://github.com/$repo" ;; *) url="https://github.com/libretro/$repo" ;; esac
git remote add origin "$url"
git fetch -q --depth 1 origin "$commit" && git checkout -q FETCH_HEAD
git submodule update -q --init --recursive --depth 1 || true
export IOSSDK=$(xcrun --sdk iphoneos --show-sdk-path)
MIN=15.0
if [ "$cartella" = cmake ]; then   # mGBA: CMake
  cmake -S . -B fuori -G Ninja -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=$MIN -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBRETRO=ON \
    -DBUILD_QT=OFF -DBUILD_SDL=OFF -DBUILD_SHARED=OFF -DBUILD_STATIC=OFF -DSKIP_LIBRARY=ON \
    -DUSE_DISCORD_RPC=OFF -DUSE_EPOXY=OFF -DUSE_SQLITE3=OFF -DUSE_ELF=OFF -DUSE_LZMA=OFF \
    -DUSE_FFMPEG=OFF -DUSE_LIBZIP=OFF -DUSE_PNG=OFF -DUSE_ZLIB=OFF -DUSE_MINIZIP=OFF \
    -DUSE_EDITLINE=OFF -DBUILD_GL=OFF -DBUILD_GLES2=OFF -DBUILD_GLES3=OFF -DUSE_LUA=OFF >/dev/null
  cmake --build fuori -j"$(sysctl -n hw.ncpu)" --target mgba_libretro
  dylib=$(find fuori -name 'mgba_libretro*.dylib' | head -1)
else
  args=(); [ "$extra" = - ] || read -ra args <<< "$extra"
  piattaforma=ios-arm64
  if [ "$nome" = ppsspp ]; then
    # nella Makefile di PPSSPP "ios-arm64" finisce nel ramo Linux arm64 (cerca "arm64" prima di "ios"):
    # si usa "ios" e si danno a mano i compilatori arm64 per iPhone
    piattaforma=ios
    args+=("CC=clang -arch arm64 -isysroot $IOSSDK -miphoneos-version-min=$MIN" "CXX=clang++ -arch arm64 -isysroot $IOSSDK -miphoneos-version-min=$MIN" "MINVERSION=-miphoneos-version-min=$MIN")
  fi
  make -C "$cartella" -f "$makefile" platform=$piattaforma -j"$(sysctl -n hw.ncpu)" ${args[@]+"${args[@]}"} \
    IOSSDK="$IOSSDK" >"$lavoro/make.log" 2>&1 || { echo "--- primi comandi:"; grep -m 3 -E '^(clang|cc |c\+\+|xcrun)' "$lavoro/make.log" | cut -c1-2500; echo "---"; tail -60 "$lavoro/make.log"; exit 1; }
  dylib=$(find "$cartella" -maxdepth 3 -name '*_libretro*.dylib' -newer "$lavoro/make.log" -o -maxdepth 3 -name '*_libretro*.dylib' | head -1)
fi
[ -f "$dylib" ] || { echo "dylib non trovata"; exit 1; }
fw="$uscita/FMLAB${nome//_/}.framework"; bin=$(basename "$fw" .framework)
rm -rf "$fw"; mkdir -p "$fw"
cp "$dylib" "$fw/$bin"
install_name_tool -id "@rpath/$bin.framework/$bin" "$fw/$bin"
# versione minima di iOS dichiarata come l'app (le Makefile scrivono 8.0)
vtool -set-build-version ios $MIN 26.0 -replace -output "$fw/$bin.tmp" "$fw/$bin" && mv "$fw/$bin.tmp" "$fw/$bin"
cat > "$fw/Info.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$bin</string>
<key>CFBundleIdentifier</key><string>dev.fmlab.core.$nome</string>
<key>CFBundleName</key><string>$bin</string>
<key>CFBundlePackageType</key><string>FMWK</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleSupportedPlatforms</key><array><string>iPhoneOS</string></array>
<key>MinimumOSVersion</key><string>$MIN</string>
<key>FMLABCoreName</key><string>$nome</string>
<key>FMLABCoreConsole</key><string>$console</string>
<key>FMLABCoreSource</key><string>${url%.git}/tree/$commit</string>
</dict></plist>
PL
# PSP: i file di sistema di PPSSPP (font del firmware, compat.ini...) vanno con il core; l'app li copia in BIOS/PPSSPP
if [ "$nome" = ppsspp ]; then
  mkdir -p "$fw/PPSSPP"
  rsync -a --exclude shaders --exclude ui_images --exclude debugger --exclude '*.ttf' --exclude gamecontrollerdb.txt \
    --exclude lang assets/ "$fw/PPSSPP/"
  mkdir -p "$fw/PPSSPP/lang" && cp assets/lang/en_US.ini assets/lang/it_IT.ini "$fw/PPSSPP/lang/" 2>/dev/null || true
  du -sh "$fw/PPSSPP"
fi
nm -gU "$fw/$bin" > "$lavoro/simboli.txt"
grep -q ' _retro_run$' "$lavoro/simboli.txt" || { echo "manca retro_run"; exit 1; }
lipo -archs "$fw/$bin"
echo "OK $nome → $(basename "$fw") ($(du -h "$fw/$bin" | cut -f1))"
