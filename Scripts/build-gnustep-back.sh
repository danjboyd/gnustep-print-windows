#!/usr/bin/env bash
#
#  build-gnustep-back.sh
#
#  Builds gnustep-back with the patches in patches/libs-back
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
#  Builds the gnustep-back release that MSYS2's CLANG64 package is built
#  from (mingw-w64-gnustep-back 0.32.0: the release tarball, configured
#  with the cairo graphics), with this repository's patches applied
#  (Scripts/apply-patches.sh), and
#  copies the backend bundle to an output directory.  It never installs
#  into the toolchain: use Scripts/make-test-runtime.sh to run something
#  with the result.
#
#  Usage (in an MSYS2 CLANG64 shell):
#    build-gnustep-back.sh [--debug] [--work <dir>] [--out <dir>]
#
#  --debug builds with debugging symbols and without optimisation.
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/build/gnustep-back"
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
BACK_VERSION=0.32.0
BACK_URL="https://github.com/gnustep/libs-back/releases/download/back-0_32_0/gnustep-back-$BACK_VERSION.tar.gz"
BACK_SHA256=ce171095012ac5d845f6e1285a5c71e011fd00aa5981ea1d5a5183706478218d
GUI_VERSION=0.32.0

die ()
{
  echo "build-gnustep-back: $*" >&2
  exit 1
}

# The toolchain's gnustep-gui must be the release this backend goes with.
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
  || die "toolchain has gnustep-gui $have_gui, this builds against $GUI_VERSION"

mkdir -p "$WORK/downloads" "$OUT"
tarball="$WORK/downloads/gnustep-back-$BACK_VERSION.tar.gz"
if [[ ! -f "$tarball" ]] \
  || ! echo "$BACK_SHA256  $tarball" | sha256sum -c --status
then
  curl --fail --location --silent --show-error --retry 3 \
    --output "$tarball.part" "$BACK_URL"
  mv "$tarball.part" "$tarball"
fi
echo "$BACK_SHA256  $tarball" | sha256sum -c --status \
  || die "checksum mismatch for $BACK_URL"

src="$WORK/gnustep-back-$BACK_VERSION"
rm -rf "$src"
tar -xzf "$tarball" -C "$WORK"

"$ROOT/Scripts/apply-patches.sh" libs-back "$BACK_VERSION" "$src"

# GNUstep.sh reads variables that may be unset.
set +u
. "$PREFIX/share/GNUstep/Makefiles/GNUstep.sh"
set -u

# As MSYS2's PKGBUILD does for CLANG64.
export LDFLAGS="-lc++"
objcflags="-Wno-int-to-pointer-cast -Wno-pointer-to-int-cast -Wno-format"
make_args=(messages=yes)
if [[ "$DEBUG" == 1 ]]
then
  objcflags="$objcflags -g -O0"
  make_args+=(debug=yes)
fi

(
  cd "$src"
  ./configure \
    --enable-graphics=cairo \
    --prefix="$PREFIX" \
    CC="$PREFIX/bin/clang" \
    CXX="$PREFIX/bin/clang++" > "$WORK/configure.log" 2>&1 \
    || { tail -30 "$WORK/configure.log" >&2; exit 1; }
  make -j"$(nproc 2>/dev/null || echo 2)" "${make_args[@]}" \
    CC="$PREFIX/bin/clang" \
    CXX="$PREFIX/bin/clang++" \
    OBJCFLAGS="$objcflags" > "$WORK/make.log" 2>&1 \
    || { tail -40 "$WORK/make.log" >&2; exit 1; }
)

bundle="$(find "$src/Source" -maxdepth 1 -type d -name 'libgnustep-back*.bundle' \
  | head -1)"
[[ -n "$bundle" ]] || die "no backend bundle was built (see $WORK/make.log)"
rm -rf "$OUT/$(basename "$bundle")"
cp -R "$bundle" "$OUT/"
echo "built $OUT/$(basename "$bundle")"
