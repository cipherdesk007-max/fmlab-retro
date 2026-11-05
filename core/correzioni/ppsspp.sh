#!/bin/bash
# Correzioni per compilare PPSSPP (libretro) per iPhone: la Makefile pensa che arm64 voglia dire Android/Linux.
set -euo pipefail
# libadrenotools serve solo ai driver Adreno di Android
python3 - <<'PY'
import re
p='libretro/Makefile.common'; s=open(p).read()
s=re.sub(r'ifeq \(\$\(TARGET_ARCH\),arm64\)\nSOURCES_CXX \+= \\\n\s*\$\(EXTDIR\)/libadrenotools/src/driver.cpp \\\n[^\n]*\n[^\n]*\nendif\n','',s)
assert 'libadrenotools/src/driver.cpp' not in s
# niente getauxval su Apple (è di Linux); il rilevamento della CPU arm64 di Apple al posto di quello Linux
s=s.replace('else ifneq ($(PLATFORM_EXT), win32)\nCOREFLAGS += -DHAVE_STRONG_GETAUXVAL', 'else ifeq (,$(filter win32 darwin,$(PLATFORM_EXT)))\nCOREFLAGS += -DHAVE_STRONG_GETAUXVAL')
assert 'filter win32 darwin' in s
s=s.replace('$(EXTDIR)/cpu_features/src/impl_aarch64_linux_or_android.c \\', '$(EXTDIR)/cpu_features/src/impl_aarch64_linux_or_android.c \\\n\t$(EXTDIR)/cpu_features/src/impl_aarch64_macos_or_iphone.c \\')
assert 'impl_aarch64_macos_or_iphone' in s
open(p,'w').write(s)
PY
