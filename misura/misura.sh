#!/bin/bash
# FMLAB Retro - Misura: quanto regge il telefono con gli emulatori (fase 1 del progetto).
#   bash misura.sh                 prova NES, Game Boy, GBA (giochi di prova liberi: 240p Test Suite)
#   bash misura.sh mio-gioco.sfc   prova anche un file tuo (riconosce la console dall'estensione)
# Per ogni console: velocità pura dell'emulatore (senza disegnare) e velocità col desktop (video vero).
# Metodo: due giri con un numero diverso di fotogrammi; la differenza toglie il tempo di avvio.
# Risultato a schermo e in un file nella cartella Shared (app File dell'iPhone).
set -u
VERSIONE="0.1.0"
POCHI=${POCHI:-120}      # fotogrammi del giro corto
TANTI=${TANTI:-720}      # fotogrammi del giro lungo (600 in più = 10 s a 60 fps)
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/fmlab-retro"
SUDO=""; [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"
v() { printf '\033[%sm' "$1"; }

echo "$(v '1;31')== FMLAB Retro · Misura $VERSIONE ==$(v 0)"

# ---------- 1) programmi ----------
pacchetti=(retroarch libretro-nestopia libretro-gambatte libretro-mgba unzip curl python3)
manca=()
for p in "${pacchetti[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || manca+=("$p"); done
if [ ${#manca[@]} -gt 0 ]; then
  echo ">> Installo: ${manca[*]} (serve la rete, la prima volta qualche minuto)"
  $SUDO apt-get update -qq >/dev/null 2>&1
  $SUDO apt-get install -y -qq --no-install-recommends "${manca[@]}" >/dev/null 2>&1 ||
    $SUDO apt-get install -y --no-install-recommends "${manca[@]}"
fi
# facoltativo: SNES e Mega Drive (in Debian stanno in "non-free"/"contrib": se non ci sono si saltano)
for p in libretro-snes9x libretro-genesisplusgx; do
  dpkg -s "$p" >/dev/null 2>&1 || $SUDO apt-get install -y -qq --no-install-recommends "$p" >/dev/null 2>&1 || true
done
command -v retroarch >/dev/null || { echo "$(v 31)✘ retroarch non installato: controlla la rete e riprova$(v 0)"; exit 1; }

core() {  # nome del core -> file .so
  local f
  for f in /usr/lib/*/libretro/"$1"_libretro.so /usr/lib/libretro/"$1"_libretro.so; do [ -f "$f" ] && { echo "$f"; return; }; done
}

# ---------- 2) giochi di prova liberi (240p Test Suite di Damian Yerrick, GPL) ----------
mkdir -p "$CACHE/prova"
if ! ls "$CACHE"/prova/*.nes >/dev/null 2>&1; then
  echo ">> Scarico i giochi di prova liberi (240p Test Suite per NES, Game Boy, GBA)"
  # file singoli dell'ultima versione (link fisso di GitHub, senza API)
  ok=0
  for f in 240pee.nes gb240p.gb 240pee_mb.gba; do
    curl -fsSL --max-time 120 "https://github.com/pinobatch/240p-test-mini/releases/latest/download/$f" -o "$CACHE/prova/$f.tmp" &&
      mv "$CACHE/prova/$f.tmp" "$CACHE/prova/$f" && ok=1 || rm -f "$CACHE/prova/$f.tmp"
  done
  if [ $ok = 0 ]; then
    echo "$(v 33)! Giochi di prova non scaricati: provo solo i file che passi tu$(v 0)"
  fi
fi
scegli() {  # $1 estensione: preferisce la suite completa (nome con 240p/144p/160p)
  local f
  f=$(find "$CACHE/prova" -maxdepth 1 -iname "*$1" | grep -iE '240p|144p|160p' | grep -viE 'mdfourier|mmc' | head -1)
  [ -n "$f" ] || f=$(find "$CACHE/prova" -maxdepth 1 -iname "*$1" | head -1)
  echo "$f"
}

# ---------- 3) elenco delle prove: console|core|file ----------
prove=()
[ -n "$(scegli .nes)" ] && prove+=("NES|nestopia|$(scegli .nes)")
[ -n "$(scegli .gb)" ]  && prove+=("Game Boy|gambatte|$(scegli .gb)")
[ -n "$(scegli .gba)" ] && prove+=("Game Boy Advance|mgba|$(scegli .gba)")
for f in "$@"; do
  [ -f "$f" ] || { echo "$(v 33)! $f non esiste, lo salto$(v 0)"; continue; }
  case "${f,,}" in
    *.nes) prove+=("NES (tuo)|nestopia|$f");;
    *.gb|*.gbc) prove+=("Game Boy (tuo)|gambatte|$f");;
    *.gba) prove+=("Game Boy Advance (tuo)|mgba|$f");;
    *.sfc|*.smc) prove+=("Super Nintendo (tuo)|snes9x|$f");;
    *.md|*.gen|*.smd|*.sms|*.gg) prove+=("Sega (tuo)|genesis_plus_gx|$f");;
    *) echo "$(v 33)! $f: estensione non riconosciuta, lo salto$(v 0)";;
  esac
done
[ ${#prove[@]} -gt 0 ] || { echo "$(v 31)✘ Niente da provare$(v 0)"; exit 1; }

# ---------- 4) misura ----------
giro() {  # $1 core $2 file $3 driver video $4 fotogrammi -> secondi
  local cfg t0 t1
  cfg=$(mktemp)
  printf 'video_driver = "%s"\nvideo_vsync = "false"\naudio_driver = "null"\naudio_sync = "false"\nvideo_fullscreen = "false"\nconfig_save_on_exit = "false"\npause_nonactive = "false"\nnotification_show_autoconfig = "false"\n' "$3" > "$cfg"
  t0=$(date +%s.%N)
  timeout 600 retroarch --config "$cfg" -L "$1" "$2" --max-frames="$4" >/dev/null 2>&1
  local e=$?
  t1=$(date +%s.%N); rm -f "$cfg"
  [ $e -eq 0 ] || { echo "ERR"; return; }
  python3 -c "print(f'{$t1-$t0:.3f}')"
}
fps() {  # $1 core $2 file $3 driver -> fps (giro lungo - giro corto)
  local a b
  a=$(giro "$1" "$2" "$3" "$POCHI"); b=$(giro "$1" "$2" "$3" "$TANTI")
  [ "$a" = ERR ] || [ "$b" = ERR ] && { echo "-"; return; }
  python3 -c "d=$b-$a; print(f'{($TANTI-$POCHI)/d:.1f}' if d>0.05 else '-')"
}
giudizio() {
  python3 -c "
f='$1'
if f=='-': print('non parte'); raise SystemExit
f=float(f)
print('giocabile' if f>=60 else 'quasi (con frameskip)' if f>=45 else 'troppo lento')"
}

modi=("null")   # solo calcolo: il massimo che regge il processore
[ -n "${DISPLAY:-}" ] && modi+=("gl")   # col desktop: video vero (GPU Metal se attiva in FMLAB Linux)
app=$(grep -o 'FMLAB-Linux/[^ ]*' /proc/ish/version 2>/dev/null || echo "fuori da FMLAB Linux")
jit=$(grep -m1 -i mode /proc/ish/jit 2>/dev/null | sed 's/.*: //'); jit=${jit:-non disponibile}
quando=$(date '+%Y-%m-%d %H:%M')
rep="FMLAB Retro Misura $VERSIONE — $quando
App: $app · JIT: $jit · GPU: ${LR_GUI_GPU_ACTIVE:-software}
Sistema: $(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-?}") · $(uname -m) · RetroArch $(retroarch --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
Metodo: giri da $POCHI e $TANTI fotogrammi, fps = differenza / tempo (senza l'avvio). 60 fps = velocità vera.
"
printf '%s\n' "$rep"
tab=$(printf '%-24s %-10s %-8s %8s  %s\n' "Console" "Core" "Video" "fps" "Giudizio")
echo "$tab"
for p in "${prove[@]}"; do
  IFS='|' read -r nome nc file <<< "$p"
  so=$(core "$nc")
  if [ -z "$so" ]; then
    r=$(printf '%-24s %-10s %-8s %8s  %s' "$nome" "$nc" "-" "-" "core non installato"); echo "$r"; tab+=$'\n'"$r"; continue
  fi
  for m in "${modi[@]}"; do
    f=$(fps "$so" "$file" "$m")
    r=$(printf '%-24s %-10s %-8s %8s  %s' "$nome" "$nc" "$([ "$m" = null ] && echo calcolo || echo desktop)" "$f" "$(giudizio "$f")")
    echo "$r"; tab+=$'\n'"$r"
  done
done

# ---------- 5) salva il risultato ----------
dest=""
for d in /mnt/LinuxRunnerShared "$HOME/Shared" "$HOME"; do [ -d "$d" ] && [ -w "$d" ] && { dest=$d; break; }; done
nomef="fmlab-retro-misura-$(date +%Y%m%d-%H%M).txt"
printf '%s\n%s\n' "$rep" "$tab" > "$dest/$nomef"
echo
echo "Salvato: $dest/$nomef"
case "$dest" in */LinuxRunnerShared|*/Shared) echo "Nell'app File: In questo iPhone > FMLAB Linux > Shared (mandalo per la tabella del progetto)";; esac
echo "\"calcolo\" = quanto regge il processore; \"desktop\" = con il video vero. Con JIT (StikDebug) di solito va più veloce."
