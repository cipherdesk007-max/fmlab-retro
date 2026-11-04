#!/bin/bash
# Prova rk-giochi con file finti (nessun gioco vero): importa da Shared/Giochi, zip, doppioni, elenco, togli, playlist.
set -eu
DIR=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export HOME="$T/home" RK_GIOCHI="$T/home/Giochi" RK_PLAYLIST="$T/home/pl"
mkdir -p "$HOME/Shared/Giochi"
printf 'NES\x1a' > "$HOME/Shared/Giochi/prova uno.nes"
printf 'x' > "$HOME/Shared/Giochi/due.gba"
printf 'x' > "$HOME/Shared/Giochi/tre.gbc"
printf 'x' > "$HOME/Shared/Giochi/leggimi.txt"
(cd "$T" && printf 'x' > quattro.sfc && python3 -c "import zipfile; z=zipfile.ZipFile('quattro.zip','w'); z.write('quattro.sfc'); z.close()")
R="$DIR/strumenti/rk-giochi"
out=$(bash "$R" importa 2>&1); echo "$out"
[ -f "$RK_GIOCHI/NES/prova uno.nes" ] && [ -f "$RK_GIOCHI/Game Boy Advance/due.gba" ] && [ -f "$RK_GIOCHI/Game Boy Color/tre.gbc" ]
echo "$out" | grep -q "leggimi.txt: tipo non riconosciuto"
bash "$R" importa "$T/quattro.zip" | grep -q "Super Nintendo"
bash "$R" importa "$T/quattro.zip" | grep -q "c'è già"
python3 -c "import json; d=json.load(open('$RK_PLAYLIST/FMLAB Retro - NES.lpl')); assert d['items'][0]['label']=='prova uno', d"
bash "$R" elenco | grep -q "prova uno.nes"
bash "$R" togli "prova uno" | grep -q "tolto"
[ ! -f "$RK_GIOCHI/NES/prova uno.nes" ]
python3 -c "import json; d=json.load(open('$RK_PLAYLIST/FMLAB Retro - NES.lpl')); assert d['items']==[], d"
bash "$R" scarica "file:///etc/passwd" | grep -q "serve un link"
echo "ok: rk-giochi (importa, zip, doppioni, elenco, togli, playlist, solo link http)"
