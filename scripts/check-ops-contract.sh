#!/usr/bin/env bash
# Structural check: v0.3 ops seeds, progress template, and loop-workflows skill.
# Exit 0 on pass; non-zero with messages on fail.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$ROOT/scripts/check_ops_contract.py" "$@"
