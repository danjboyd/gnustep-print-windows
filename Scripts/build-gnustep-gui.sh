#!/usr/bin/env bash
#
#  build-gnustep-gui.sh
#
#  Builds gnustep-gui with the patches in patches/libs-gui
#
#  Copyright (C) 2026 Daniel Boyd
#
#  Author: Daniel Boyd <danieljboyd@icloud.com>
#  Date: October 2026
#
#  This file is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  Builds the gnustep-gui release that MSYS2's CLANG64 package is built
#  from (mingw-w64-gnustep-gui 0.32.0: the release tarball), against the
#  toolchain's gnustep-base, with this repository's patches applied
#  (Scripts/apply-patches.sh), and copies the DLL to an output directory.
#  Only the library is built.  It never installs into the toolchain: use
#  Scripts/make-test-runtime.sh to run something with the result.
#
#  Usage (in an MSYS2 CLANG64 shell):
#    build-gnustep-gui.sh [--debug] [--work <dir>] [--out <dir>]
#
#  --debug builds with debugging symbols and without optimisation.
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/build/gnustep-gui"
OUT=""
DEBUG=0

while [[ $# -gt 0 ]]
do
  case "$1" in
    --debug) DEBUG=1 ;;
    --work) WORK="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    *)
      echo "usage: $0 [--debug] [--work <dir>] [--out <dir>]" >&2
      exit 2
      ;;
  esac
  shift
done
OUT="${OUT:-$WORK/out}"

PREFIX="${MINGW_PREFIX:-/clang64}"
GUI_VERSION=0.32.0
GUI_URL="https://github.com/gnustep/libs-gui/releases/download/gui-0_32_0/gnustep-gui-$GUI_VERSION.tar.gz"
GUI_SHA256=0c03a1b6313babd592ec58fcb825091f77eb27429a4ce4306ec3a7cfa7f9a1f6
GUI_DLL=gnustep-gui-0.dll

die ()
{
  echo "build-gnustep-gui: $*" >&2
  exit 1
}

# The DLL must match the toolchain's headers and the programs linked
# against them.
gui_version ()
{
  local h="$PREFIX/include/GNUstepGUI/GSVersion.h"

  printf '%s.%s.%s' \
    "$(awk '/GNUSTEP_GUI_MAJOR_VERSION/ {print $NF; exit}' "$h")" \
    "$(awk '/GNUSTEP_GUI_MINOR_VERSION/ {print $NF; exit}' "$h")" \
    "$(awk '/GNUSTEP_GUI_SUBMINOR_VERSION/ {print $NF; exit}' "$h")"
}
have_gui="$(gui_version)"
[[ "$have_gui" == "$GUI_VERSION" ]] \
  || die "toolchain has gnustep-gui $have_gui, this builds $GUI_VERSION"

mkdir -p "$WORK/downloads" "$OUT"
tarball="$WORK/downloads/gnustep-gui-$GUI_VERSION.tar.gz"
if [[ ! -f "$tarball" ]] \
  || ! echo "$GUI_SHA256  $tarball" | sha256sum -c --status
then
  curl --fail --location --silent --show-error --retry 3 \
    --output "$tarball.part" "$GUI_URL"
  mv "$tarball.part" "$tarball"
fi
echo "$GUI_SHA256  $tarball" | sha256sum -c --status \
  || die "checksum mismatch for $GUI_URL"

src="$WORK/gnustep-gui-$GUI_VERSION"
rm -rf "$src"
tar -xzf "$tarball" -C "$WORK"
"$ROOT/Scripts/apply-patches.sh" libs-gui "$GUI_VERSION" "$src"

# GNUstep.sh reads variables that may be unset.
set +u
. "$PREFIX/share/GNUstep/Makefiles/GNUstep.sh"
set -u

# MSYS2 CLANG64's libdispatch header redefines mode_t unless told the
# system has one; libc++ as MSYS2's PKGBUILD links it.
make_args=(messages=yes)
if [[ "$DEBUG" == 1 ]]
then
  make_args+=(debug=yes)
fi

(
  cd "$src"
  CPPFLAGS="-DHAVE_MODE_T=1" LDFLAGS="-lc++" \
    ./configure --prefix="$PREFIX" \
    CC="$PREFIX/bin/clang" CXX="$PREFIX/bin/clang++" \
    > "$WORK/configure.log" 2>&1 \
    || { tail -30 "$WORK/configure.log" >&2; exit 1; }
  make -C Source -j"$(nproc 2>/dev/null || echo 2)" "${make_args[@]}" \
    > "$WORK/make.log" 2>&1 \
    || { grep -iE "error" "$WORK/make.log" | head -40 >&2; exit 1; }
)

dll="$(find "$src/Source" -name "$GUI_DLL" -path '*obj*' | head -1)"
[[ -n "$dll" ]] || die "no $GUI_DLL was built (see $WORK/make.log)"
cp "$dll" "$OUT/$GUI_DLL"
echo "built $OUT/$GUI_DLL"
