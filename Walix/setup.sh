#!/usr/bin/env bash
# Walix one-command setup wrapper.
# Usage: ./setup.sh [--allow-pip]
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$ROOT/install.sh"

if [ ! -f "$INSTALLER" ]; then
  printf '%s\n' '[Walix] install.sh was not found. Run this from the extracted Walix folder.' >&2
  exit 1
fi

chmod +x "$INSTALLER" "$ROOT/walix.py" "$ROOT/walix-launcher.sh" "$ROOT/uninstall.sh"
exec bash "$INSTALLER" "$@"
