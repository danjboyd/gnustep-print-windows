#!/usr/bin/env bash
#
#  run-in-test-runtime.sh
#
#  Runs a program against the private runtime from make-test-runtime.sh
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
#  Usage (in an MSYS2 CLANG64 shell):
#    run-in-test-runtime.sh [--runtime <dir>] <program> [arguments...]
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME="$ROOT/build/runtime"

if [[ "${1:-}" == "--runtime" ]]
then
  RUNTIME="$2"
  shift 2
fi
if [[ $# -lt 1 ]]
then
  echo "usage: $0 [--runtime <dir>] <program> [arguments...]" >&2
  exit 2
fi

PREFIX="${MINGW_PREFIX:-/clang64}"
export PATH="$RUNTIME/bin:$PREFIX/bin:$PATH"
exec "$@"
