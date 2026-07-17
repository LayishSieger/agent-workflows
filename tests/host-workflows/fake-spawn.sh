#!/usr/bin/env bash
# Test double for agent spawn. Records argv; optionally appends progress.
# Controlled by env:
#   FAKE_SPAWN_LOG     — append argv record (required for tests that assert spawn)
#   FAKE_SPAWN_PROGRESS — path to progress.md (if set, append outcome)
#   FAKE_SPAWN_OUTCOME  — outcome to write (default SHIPPED)
#   FAKE_SPAWN_EXIT     — process exit code (default 0); ignored by host for success
#   FAKE_SPAWN_SKIP_PROGRESS — if 1, do not write progress (missing-progress tests)
set -euo pipefail

if [[ -n "${FAKE_SPAWN_LOG:-}" ]]; then
  {
    printf '%s\n' "argc=$#"
    i=1
    for a in "$@"; do
      # Avoid BSD printf treating leading - / --- as options
      printf '%s\n' "arg${i}=${a}"
      i=$((i + 1))
    done
    printf '%s\n' "---"
  } >>"$FAKE_SPAWN_LOG"
fi

if [[ "${FAKE_SPAWN_SKIP_PROGRESS:-0}" != "1" && -n "${FAKE_SPAWN_PROGRESS:-}" ]]; then
  outcome="${FAKE_SPAWN_OUTCOME:-SHIPPED}"
  mkdir -p "$(dirname "$FAKE_SPAWN_PROGRESS")"
  if [[ ! -f "$FAKE_SPAWN_PROGRESS" ]]; then
    cat >"$FAKE_SPAWN_PROGRESS" <<'HDR'
# Agent workflows — progress log

## Entries

HDR
  fi
  # Prepend newest entry after "## Entries"
  tmp="$(mktemp)"
  {
    if grep -q '^## Entries' "$FAKE_SPAWN_PROGRESS" 2>/dev/null; then
      # shellcheck disable=SC2016
      awk -v o="$outcome" '
        BEGIN { done=0 }
        /^## Entries/ && !done {
          print
          print ""
          print "### 2099-01-01 — #1 — fake tick"
          print "- **outcome:** " o
          print "- **publish:** none"
          print "- **checks:** n/a"
          print "- **note:** fake-spawn"
          print ""
          done=1
          next
        }
        { print }
      ' "$FAKE_SPAWN_PROGRESS"
    else
      cat "$FAKE_SPAWN_PROGRESS"
      printf '\n### 2099-01-01 — #1 — fake tick\n- **outcome:** %s\n' "$outcome"
    fi
  } >"$tmp"
  mv "$tmp" "$FAKE_SPAWN_PROGRESS"
fi

exit "${FAKE_SPAWN_EXIT:-0}"
