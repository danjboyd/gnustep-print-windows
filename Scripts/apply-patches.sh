#!/usr/bin/env bash
#
#  apply-patches.sh
#
#  Applies this repository's patches for one GNUstep library to a release
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
#  patches/<library>/ holds the patches as they would go to GNUstep:
#  made against master, each with its ChangeLog entry.  When one does not
#  apply to the release the packages build, backports/<version>/<library>/
#  holds a patch of the same name made for that release.  Either way the
#  ChangeLog part is left out: a release's ChangeLog differs from master's.
#  Patches are applied without fuzz, so a patch that has drifted fails
#  here rather than landing in the wrong place.
#
#  Usage:
#    apply-patches.sh <library> <version> <source directory>
#  for example
#    apply-patches.sh libs-gui 0.32.0 build/gnustep-gui/gnustep-gui-0.32.0
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ne 3 ]]
then
  echo "usage: $0 <library> <version> <source directory>" >&2
  exit 2
fi
library="$1"
version="$2"
src="$3"

# Prints a patch without its ChangeLog section.
without_changelog ()
{
  awk '
    /^diff --git / { skip = ($3 == "a/ChangeLog") }
    !skip { print }
  ' "$1"
}

shopt -s nullglob
for p in "$ROOT/patches/$library"/*.patch
do
  name="$(basename "$p")"
  backport="$ROOT/backports/$version/$library/$name"
  if [[ -f "$backport" ]]
  then
    p="$backport"
    echo "applying $name (backport for $version)"
  else
    echo "applying $name"
  fi
  if ! without_changelog "$p" \
    | patch -d "$src" -p1 --forward --fuzz=0 --no-backup-if-mismatch --quiet
  then
    echo "apply-patches: $name does not apply to $library $version;" \
      "add backports/$version/$library/$name" >&2
    exit 1
  fi
done
