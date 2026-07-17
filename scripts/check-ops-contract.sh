#!/usr/bin/env bash
# Structural check: init-workflows tracker seeds match the v0.3 ops contract.
# Exit 0 on pass; non-zero with messages on fail.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$ROOT/scripts/check_ops_contract.py" "$@"
