#!/usr/bin/env bash
#
#  make-test-runtime.sh
#
#  Makes a private GNUstep runtime that uses the backend built here
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
#  The toolchain's GNUstep is shared by every GNUstep program on the
#  machine, so the patched backend is never installed there.  Instead
#  this copies gnustep-base and gnustep-gui's DLLs into <runtime>/bin and
#  the toolchain's lib/GNUstep (bundles, themes, resources) into
#  <runtime>/lib/GNUstep, the layout gnustep-base finds relative to its
#  own DLL, and replaces the backend bundle there with the one
#  Scripts/build-gnustep-back.sh built.
#
#  Run a program against it with <runtime>/bin first on PATH, for
#  example with Scripts/run-in-test-runtime.sh.
#
#  Usage (in an MSYS2 CLANG64 shell):
#    make-test-runtime.sh [--backend <bundle>] [--gui <dll>] [--runtime <dir>]
#
#  The gnustep-gui DLL that Scripts/build-gnustep-gui.sh built replaces the
#  toolchain's when there is one (or the one --gui names).
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME="$ROOT/build/runtime"
BACKEND="$ROOT/build/gnustep-back/out/libgnustep-back-032.bundle"
GUI_DLL="$ROOT/build/gnustep-gui/out/gnustep-gui-0.dll"

while [[ $# -gt 0 ]]
do
  case "$1" in
    --backend) BACKEND="$2"; shift ;;
    --gui) GUI_DLL="$2"; shift ;;
    --runtime) RUNTIME="$2"; shift ;;
    *)
      echo "usage: $0 [--backend <bundle>] [--gui <dll>] [--runtime <dir>]" >&2
      exit 2
      ;;
  esac
  shift
done

PREFIX="${MINGW_PREFIX:-/clang64}"

die ()
{
  echo "make-test-runtime: $*" >&2
  exit 1
}

[[ -d "$BACKEND" ]] \
  || die "no backend at $BACKEND (run Scripts/build-gnustep-back.sh)"

rm -rf "$RUNTIME"
mkdir -p "$RUNTIME/bin" "$RUNTIME/lib"
for dll in "$PREFIX"/bin/gnustep-base-*.dll "$PREFIX"/bin/gnustep-gui-*.dll
do
  cp "$dll" "$RUNTIME/bin/"
done
if [[ -f "$GUI_DLL" ]]
then
  cp "$GUI_DLL" "$RUNTIME/bin/"
  echo "gnustep-gui: $GUI_DLL"
fi
cp -R "$PREFIX/lib/GNUstep" "$RUNTIME/lib/"
rm -rf "$RUNTIME/lib/GNUstep/Bundles/$(basename "$BACKEND")"
cp -R "$BACKEND" "$RUNTIME/lib/GNUstep/Bundles/"
echo "runtime in $RUNTIME (backend: $BACKEND)"
