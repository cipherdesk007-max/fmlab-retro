#!/bin/bash
# Correzioni per compilare PPSSPP (libretro) per iPhone: la Makefile pensa che arm64 voglia dire Android/Linux.
set -euo pipefail
# libadrenotools serve solo ai driver Adreno di Android
python3 - <<'PY'
import re
p='libretro/Makefile.common'; s=open(p).read()
s=re.sub(r'ifeq \(\$\(TARGET_ARCH\),arm64\)\nSOURCES_CXX \+= \\\n\s*\$\(EXTDIR\)/libadrenotools/src/driver.cpp \\\n[^\n]*\n[^\n]*\nendif\n','',s)
assert 'libadrenotools/src/driver.cpp' not in s
open(p,'w').write(s)
PY
