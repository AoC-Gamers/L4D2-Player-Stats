#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3}"
SPCOMP="${SPCOMP:-deps/sourcemod-linux/addons/sourcemod/scripting/spcomp}"

cd "$ROOT_DIR"
make build-smx PYTHON="$PYTHON" SPCOMP="$SPCOMP"
