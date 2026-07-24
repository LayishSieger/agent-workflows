#!/usr/bin/env bash
# Tier 0 dogfood gate: host unit tests + ops contract (CI-safe, no network product).
# Exit 0 only if both pass.
set -euo pipefail

HUB_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$HUB_DIR"

FAIL=0

echo "======== Tier 0 / A1: host-workflows tests ========"
if bash "$HUB_DIR/tests/host-workflows/test_host.sh"; then
  echo "A1 PASS"
else
  echo "A1 FAIL"
  FAIL=1
fi

echo
echo "======== Tier 0 / A2: ops contract ========"
if bash "$HUB_DIR/scripts/check-ops-contract.sh"; then
  echo "A2 PASS"
else
  echo "A2 FAIL"
  FAIL=1
fi

echo
if [[ "$FAIL" -ne 0 ]]; then
  echo "Tier 0 FAILED — fix before dogfood E2E or commit/push"
  exit 1
fi
echo "Tier 0 PASSED"
exit 0
