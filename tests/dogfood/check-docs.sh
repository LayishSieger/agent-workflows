#!/usr/bin/env bash
# Lightweight Tier 1 greps (not a substitute for full D1–D7 reading).
# Exit 0 if all needles found; non-zero otherwise.
set -euo pipefail

HUB_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$HUB_DIR"
FAIL=0

check() {
  local id="$1" label="$2" file="$3" pattern="$4"
  if grep -qE "$pattern" "$file"; then
    echo "  PASS: $id — $label ($file)"
  else
    echo "  FAIL: $id — $label — missing /$pattern/ in $file"
    FAIL=1
  fi
}

echo "== Tier 1 static needles =="

check D1a "README names three skills / packages" README.md "The three skills|init-workflows|loop-workflows|host-workflows"
check D1b "README describes once / max N fresh workers" README.md "once.*max N|fresh one-tick|max N"
check D1c "README mentions host-workflows / host.sh" README.md "host-workflows|host\\.sh"
check D1d "README first screen is outcome → quickstart (no genealogy banner)" README.md "Give a coding agent a repeatable way|## Quickstart"
check D1e "README covers spawn resolution" README.md "spawn|--spawn|AGENT_SPAWN"

check D2a "CHANGELOG has 0.3 entries" CHANGELOG.md "0\\.3"
check D2b "CHANGELOG mentions host / ops / outcome" CHANGELOG.md "host-workflows|ops contract|outcome:"
check D2c "CHANGELOG notes max-N / breaking rewrite" CHANGELOG.md "max N|fresh one-tick|breaking"

check D3a "Freeze lists out-of-scope items" docs/v0.3.md "Out of 0.3|Out of scope"
check D3b "Freeze covers host + shared tick" docs/v0.3.md "host-workflows|shared tick"

check D4a "Init skill defines READY" skills/init-workflows/SKILL.md "READY"
check D4b "Init READY is contracts-first (skills optional)" skills/init-workflows/SKILL.md "not required for READY|never required for READY|Contracts first"

check D5a "Init offers S chat / H shell AFK" skills/init-workflows/SKILL.md "S.*chat|skip|/chat|shell AFK|\\*\\*S\\*\\*"
check D5b "Init does not force / silent-install skills" skills/init-workflows/SKILL.md "no silent|Never silent|not force|Do \\*\\*not\\*\\* force|optional"

check D6a "Host skill: spawn is human-owned" skills/host-workflows/SKILL.md "human-owned|spawn string|not in this skill"
check D6b "README: spawn is human-owned" README.md "human-owned|spawn"

# D6c: dogfood shared spawn recipe must not drift from the README AFK example.
RECIPE="$(tr -d '\r' <tests/dogfood/spawn-recipe.txt | head -1)"
if [[ -n "$RECIPE" ]] && grep -qF -- "$RECIPE" README.md; then
  echo "  PASS: D6c — dogfood spawn-recipe matches a README AFK example (README.md)"
else
  echo "  FAIL: D6c — dogfood spawn-recipe matches a README AFK example — tests/dogfood/spawn-recipe.txt not found verbatim in README.md"
  FAIL=1
fi

echo
if [[ "$FAIL" -ne 0 ]]; then
  echo "check-docs: FAIL ($FAIL)"
  exit 1
fi
echo "check-docs: OK (needles only — still complete D1–D7 in the report)"
exit 0
