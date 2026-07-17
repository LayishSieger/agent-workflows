#!/usr/bin/env bash
# host-workflows — thin sequential shell host for AFK multi-tick.
# Schedulers only count N and stop; workers own the shared tick (loop-workflows).
# Install never executes this script (npx skills add is copy/symlink only).
#
# Usage:
#   host.sh [-n N] [--spawn CMD] [--cwd DIR] [-h|--help]
#
# Spawn resolution (first wins):
#   --spawn | AGENT_SPAWN  >  product .agent-workflows/spawn  >  machine ~/.config/agent-workflows/spawn
# All missing → HARD STOP (no silent default binary).
#
# Control plane: latest progress `outcome:` + stop rules. Process exit ≠ tick success.
set -euo pipefail

HOST_VERSION="0.3.0"

# Fixed worker prompt: exactly one tick; no issue id / remaining N / queue blob.
TICK_PROMPT='In this product repo, run loop-workflows shared tick once: resume | pick → claim → implement → publish → progress. Discover policy under docs/agents/*. Call ops and triage roles by name only. Exactly one tick; then stop. Append progress with outcome: when done. Do not merge or close issues as done.'

usage() {
  cat <<'EOF'
host-workflows — sequential one-shot AFK host

Usage:
  host.sh [-n N] [--spawn CMD] [--cwd DIR] [-h|--help]

Options:
  -n N           Maximum ticks to schedule (default: 1). No unbounded drain.
  --spawn CMD    Spawn command string (wins over env and spawn files).
  --cwd DIR      Product root (default: current directory). Host cds here before spawn.
  -h, --help     Show this help.

Environment:
  AGENT_SPAWN    Spawn command string if --spawn is not set.

Spawn resolution (first non-empty wins):
  1. --spawn
  2. AGENT_SPAWN
  3. <product>/.agent-workflows/spawn   (one line)
  4. ~/.config/agent-workflows/spawn    (one line)

If all are missing → HARD STOP (clear error; no default agent binary).

The host runs:  $SPAWN "<tick prompt>"
  - Prompt is the final CLI argument.
  - Host never adds --continue / --resume (clean one-shot context).
  - Unattended/edit flags belong inside the spawn string (recipe responsibility).

Workers must have loop-workflows installed. Progress path:
  <product>/.agent-workflows/progress.md

Stop rules (progress outcome: + MAX only — host does not inspect the tracker queue):
  COMPLETE   — latest progress outcome: COMPLETE (worker: empty queue + no incomplete claim)
  BLOCKED    — stop
  HARD_STOP  — stop
  FAILED     — stop (also if progress missing/unusable after spawn)
  MAX        — hit N with work still continuing (SHIPPED | NEEDS_INFO | SKIPPED)
  Process exit codes are not treated as tick success.
EOF
}

log() { printf '%s\n' "$*"; }
err() { printf '%s\n' "$*" >&2; }

# Shared outcome vocabulary (single source for helpers + awk).
# Use [[ =~ ]] — bash 3.2 (macOS) does not treat | from variables as case alternation.
OUTCOME_ALL='SHIPPED|NEEDS_INFO|SKIPPED|COMPLETE|BLOCKED|HARD_STOP|FAILED'
OUTCOME_STOP='COMPLETE|BLOCKED|HARD_STOP|FAILED'
OUTCOME_CONTINUE='SHIPPED|NEEDS_INFO|SKIPPED'

# Read one-line spawn file: first non-empty, non-# line, trim CR/spaces.
read_spawn_file() {
  local path="$1"
  [[ -f "$path" && -r "$path" ]] || return 1
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line//$'\r'/}"
    # trim leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    printf '%s\n' "$line"
    return 0
  done <"$path"
  return 1
}

resolve_spawn() {
  local flag_spawn="$1" product_root="$2"
  if [[ -n "$flag_spawn" ]]; then
    printf '%s\n' "$flag_spawn"
    return 0
  fi
  if [[ -n "${AGENT_SPAWN:-}" ]]; then
    printf '%s\n' "$AGENT_SPAWN"
    return 0
  fi
  local product_file machine_file
  product_file="$product_root/.agent-workflows/spawn"
  machine_file="${HOME:-}/.config/agent-workflows/spawn"
  if out="$(read_spawn_file "$product_file")"; then
    printf '%s\n' "$out"
    return 0
  fi
  if [[ -n "${HOME:-}" ]] && out="$(read_spawn_file "$machine_file")"; then
    printf '%s\n' "$out"
    return 0
  fi
  return 1
}

# Latest progress outcome (newest-first under ## Entries). Prints value or empty.
# Ignores template multi-choice lines (contain |) and docs above ## Entries.
latest_outcome() {
  local progress="$1"
  [[ -f "$progress" ]] || return 0
  awk -v ok="$OUTCOME_ALL" '
    /^## Entries/ { in_entries = 1; next }
    in_entries && /^### / { want = 1; next }
    in_entries && want && /\*\*outcome:\*\*/ {
      line = $0
      if (line ~ /\|/) { want = 0; next }
      sub(/.*\*\*outcome:\*\*[[:space:]]*/, "", line)
      sub(/[[:space:]].*/, "", line)
      sub(/[^A-Z_].*/, "", line)
      if (line ~ ("^(" ok ")$")) {
        print line
        exit
      }
      want = 0
    }
  ' "$progress"
}

valid_outcome() {
  [[ "$1" =~ ^($OUTCOME_ALL)$ ]]
}

is_stop_outcome() {
  [[ "$1" =~ ^($OUTCOME_STOP)$ ]]
}

is_continue_outcome() {
  [[ "$1" =~ ^($OUTCOME_CONTINUE)$ ]]
}

fingerprint_progress() {
  local progress="$1"
  if [[ -f "$progress" ]]; then
    # content + size; portable-ish
    if command -v cksum >/dev/null 2>&1; then
      cksum "$progress" | awk '{print $1"-"$2}'
    else
      wc -c <"$progress" | tr -d ' '
    fi
  else
    printf 'missing\n'
  fi
}

exit_for_overall() {
  case "$1" in
    COMPLETE|MAX) exit 0 ;;
    *) exit 1 ;;
  esac
}

print_status() {
  local mode_n="$1" ticks="$2" last_outcome="$3" overall="$4"
  cat <<EOF
host-workflows status
- mode: max $mode_n
- ticks: $ticks / $mode_n
- last_outcome: ${last_outcome:-none}
- overall: $overall
EOF
}

main() {
  local max_n=1 flag_spawn="" cwd=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -n)
        shift
        [[ $# -gt 0 ]] || { err "host-workflows: -n requires a positive integer"; exit 1; }
        max_n="$1"
        shift
        ;;
      --spawn)
        shift
        [[ $# -gt 0 ]] || { err "host-workflows: --spawn requires a command string"; exit 1; }
        flag_spawn="$1"
        shift
        ;;
      --cwd)
        shift
        [[ $# -gt 0 ]] || { err "host-workflows: --cwd requires a directory"; exit 1; }
        cwd="$1"
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        err "host-workflows: unknown option: $1"
        usage >&2
        exit 1
        ;;
      *)
        err "host-workflows: unexpected argument: $1"
        usage >&2
        exit 1
        ;;
    esac
  done

  if ! [[ "$max_n" =~ ^[1-9][0-9]*$ ]]; then
    err "host-workflows: -n must be a positive integer (got: $max_n)"
    exit 1
  fi

  if [[ -n "$cwd" ]]; then
    cd "$cwd" || { err "host-workflows: cannot cd to --cwd $cwd"; exit 1; }
  fi
  local product_root
  product_root="$(pwd -P 2>/dev/null || pwd)"

  local spawn_cmd
  if ! spawn_cmd="$(resolve_spawn "$flag_spawn" "$product_root")"; then
    err "host-workflows: HARD STOP — no spawn command configured."
    err "  Set --spawn, AGENT_SPAWN, or a one-line spawn file at:"
    err "    $product_root/.agent-workflows/spawn"
    err "    ${HOME:-~}/.config/agent-workflows/spawn"
    err "  There is no default agent binary; pin the name in your recipe (e.g. cursor-agent)."
    print_status "$max_n" 0 "none" "HARD_STOP"
    exit 1
  fi

  local progress="$product_root/.agent-workflows/progress.md"
  local ticks=0
  local last_outcome=""
  local overall=""

  log "host-workflows $HOST_VERSION"
  log "- product: $product_root"
  log "- max: $max_n"
  log "- spawn: $spawn_cmd"
  log "- progress: $progress"

  while [[ "$ticks" -lt "$max_n" ]]; do
    # Prefer COMPLETE / terminal outcomes before spending a spawn.
    last_outcome="$(latest_outcome "$progress" || true)"
    if [[ -n "$last_outcome" ]] && is_stop_outcome "$last_outcome"; then
      overall="$last_outcome"
      log "stop before spawn: latest outcome=$last_outcome"
      break
    fi

    local before_fp
    before_fp="$(fingerprint_progress "$progress")"

    log "spawn tick $((ticks + 1))/$max_n ..."
    # Prompt is final argument. Never inject --continue / --resume.
    # Word-split the spawn command string (one-line recipes; no universal default).
    set +e
    # shellcheck disable=SC2086
    bash -c "$spawn_cmd \"\$1\"" _ "$TICK_PROMPT"
    local spawn_ec=$?
    set -e
    ticks=$((ticks + 1))
    if [[ "$spawn_ec" -ne 0 ]]; then
      log "note: spawn process exit=$spawn_ec (not used as tick success)"
    fi

    local after_fp
    after_fp="$(fingerprint_progress "$progress")"
    last_outcome="$(latest_outcome "$progress" || true)"

    if [[ "$before_fp" == "$after_fp" ]] || [[ -z "$last_outcome" ]] || ! valid_outcome "$last_outcome"; then
      err "host-workflows: FAILED — missing or unusable progress after spawn (expected outcome: append)."
      last_outcome="FAILED"
      overall="FAILED"
      break
    fi

    if is_stop_outcome "$last_outcome"; then
      overall="$last_outcome"
      log "stop after spawn: outcome=$last_outcome"
      break
    fi

    if is_continue_outcome "$last_outcome"; then
      log "continue: outcome=$last_outcome ($ticks/$max_n)"
      continue
    fi

    # Unknown but non-empty token that passed valid_outcome — should not happen.
    err "host-workflows: FAILED — unexpected outcome token: $last_outcome"
    last_outcome="FAILED"
    overall="FAILED"
    break
  done

  # Loop only ends without overall when every tick continued through N.
  if [[ -z "$overall" ]]; then
    overall="MAX"
  fi

  print_status "$max_n" "$ticks" "${last_outcome:-none}" "$overall"
  exit_for_overall "$overall"
}

main "$@"
