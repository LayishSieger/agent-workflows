#!/usr/bin/env bash
# Lightweight Tier 1 greps (not a substitute for full D1–D7 reading).
# Exit 0 if all needles found; non-zero otherwise.
set -euo pipefail

HUB_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$HUB_DIR"
FAIL=0

check() {
  local id="$1" file="$2" pattern="$3"
  if grep -qE "$pattern" "$file"; then
    echo "  PASS: $id ($file)"
  else
    echo "  FAIL: $id — missing /$pattern/ in $file"
    FAIL=1
  fi
}

echo "== Tier 1 static needles =="

check D1a README.md "Three packages|three packages"
check D1b README.md "Dual schedulers|dual schedulers|once.*max N|fresh one-tick"
check D1c README.md "host-workflows|host\\.sh"
check D1d README.md "Breaking change|hard break|0\\.2 → 0\\.3"
check D1e README.md "spawn|--spawn|AGENT_SPAWN"

check D2a CHANGELOG.md "0\\.3"
check D2b CHANGELOG.md "host-workflows|ops contract|outcome:"
check D2c CHANGELOG.md "max N|fresh one-tick|breaking"

check D3a docs/v0.3.md "Out of 0.3|Out of scope"
check D3b docs/v0.3.md "host-workflows|shared tick"

check D4a skills/init-workflows/SKILL.md "READY"
check D4b skills/init-workflows/SKILL.md "not required for READY|never required for READY|Contracts first"

check D5a skills/init-workflows/SKILL.md "S.*chat|skip|/chat|shell AFK|\\*\\*S\\*\\*"
check D5b skills/init-workflows/SKILL.md "no silent|Never silent|not force|Do \\*\\*not\\*\\* force|optional"

check D6a skills/host-workflows/SKILL.md "human-owned|spawn string|not in this skill"
check D6b README.md "human-owned|spawn"

echo
if [[ "$FAIL" -ne 0 ]]; then
  echo "check-docs: FAIL ($FAIL)"
  exit 1
fi
echo "check-docs: OK (needles only — still complete D1–D7 in the report)"
exit 0
