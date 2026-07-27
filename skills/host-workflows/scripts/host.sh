#!/usr/bin/env bash
# host-workflows — thin sequential shell host for AFK multi-tick.
# Schedulers only count N and stop; workers own the shared tick (loop-workflows).
# Install never executes this script (npx skills add is copy/symlink only).
#
# Usage:
#   host.sh [-n N] [--spawn CMD] [--cwd DIR] [-h|--help]
#
# Spawn resolution (first wins):
#   --spawn | AGENT_SPAWN  >  local product .agent-workflows/spawn  >  machine ~/.config/agent-workflows/spawn
# All missing → HARD STOP (no silent default binary).
# Spawn recipes are parsed as argv and executed directly; shell syntax is rejected.
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
  --spawn CMD    Shell-free command recipe (wins over env and spawn files).
  --cwd DIR      Product root (default: current directory). Host cds here before spawn.
  -h, --help     Show this help.

Environment:
  AGENT_SPAWN    Shell-free command recipe if --spawn is not set.

Spawn resolution (first non-empty wins):
  1. --spawn
  2. AGENT_SPAWN
  3. <product>/.agent-workflows/spawn   (one local, untracked line)
  4. ~/.config/agent-workflows/spawn    (one line)

If all are missing → HARD STOP (clear error; no default agent binary).

The host injects the tick prompt into the spawn recipe:
  - Recipes are whitespace-separated argv, not shell programs. Quotes, substitutions,
    redirects, pipes, and command chaining are rejected.
  - If a standalone argument is {{PROMPT}}, replace it. Example: grok -p {{PROMPT}} --output-format plain
  - Else append prompt as the final CLI argument.
  - Host never adds --continue / --resume (clean one-shot context).
  - Unattended/trust flags belong in the human-owned spawn string only (see hub README examples).

Workers must have loop-workflows installed. Progress path:
  <product>/.agent-workflows/progress.md

Stop rules (progress outcome: + MAX only — host does not inspect the tracker queue):
  COMPLETE   — if latest before any spawn in this run: stop without spawning (queue already done)
  BLOCKED / HARD_STOP / FAILED — stop *after* a spawn that writes them (do not burn more ticks
               in this process). A *new* host.sh invocation still spawns once so the operator
               can retry after fixing env (stale HARD_STOP must not brick AFK forever).
  FAILED     — also if progress missing/unusable after spawn
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
  [[ ! -L "$path" ]] || return 1
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
  if [[ -f "$product_file" ]]; then
    if ! git -C "$product_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      err "host-workflows: refusing product spawn file without a git worktree: $product_file"
      err "  Use --spawn, AGENT_SPAWN, or local machine config instead."
      return 1
    fi
    if git -C "$product_root" ls-files --error-unmatch -- ".agent-workflows/spawn" >/dev/null 2>&1; then
      err "host-workflows: refusing tracked product spawn file: $product_file"
      err "  Spawn configuration must be local and gitignored; use --spawn or AGENT_SPAWN instead."
      return 1
    fi
  fi
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

# Run a shell-free spawn recipe with the tick prompt.
# The recipe is intentionally limited to whitespace-separated argv. This avoids evaluating
# repository-controlled shell syntax while retaining the common agent CLI forms.
run_spawn() {
  local spawn_cmd="$1"
  local prompt="$2"
  local without_prompt="${spawn_cmd//\{\{PROMPT\}\}/}"

  if [[ "$spawn_cmd" == *$'\n'* || "$spawn_cmd" == *$'\r'* ]]; then
    err "host-workflows: unsafe spawn recipe — newlines are not allowed"
    return 1
  fi
  case "$without_prompt" in
    *[\;\&\|\<\>\`\$\\\"\']*)
      err "host-workflows: unsafe spawn recipe — shell syntax and quoting are not allowed"
      return 1
      ;;
  esac

  local argv=()
  read -r -a argv <<<"$spawn_cmd"
  if [[ "${#argv[@]}" -eq 0 ]]; then
    err "host-workflows: unsafe spawn recipe — command is empty"
    return 1
  fi

  local found_prompt=0 i
  for ((i = 0; i < ${#argv[@]}; i++)); do
    if [[ "${argv[$i]}" == "{{PROMPT}}" ]]; then
      argv[$i]="$prompt"
      found_prompt=1
    elif [[ "${argv[$i]}" == *'{{PROMPT}}'* ]]; then
      err "host-workflows: unsafe spawn recipe — {{PROMPT}} must be a standalone argument"
      return 1
    fi
  done
  if [[ "$found_prompt" -eq 0 ]]; then
    argv+=("$prompt")
  fi

  if [[ "${argv[0]}" == */* ]]; then
    [[ -x "${argv[0]}" && ! -d "${argv[0]}" ]] || {
      err "host-workflows: spawn executable is not executable: ${argv[0]}"
      return 1
    }
  elif ! command -v "${argv[0]}" >/dev/null 2>&1; then
    err "host-workflows: spawn executable not found on PATH: ${argv[0]}"
    return 1
  fi

  local executable_name="${argv[0]##*/}"
  case "$executable_name" in
    sh|bash|dash|zsh|ksh|csh|tcsh|fish|env|python|python[0-9]*|node|bun|deno|ruby|perl|php|osascript)
      err "host-workflows: unsafe spawn recipe — command interpreters and wrappers are not allowed"
      return 1
      ;;
  esac

  "${argv[@]}"
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
  log "- spawn: configured (contents redacted)"
  log "- progress: $progress"

  while [[ "$ticks" -lt "$max_n" ]]; do
    # Only COMPLETE skips spawn at the start of a tick: empty queue / work already done.
    # Stale HARD_STOP / BLOCKED / FAILED from a previous host run must not block a new
    # invocation (operator re-ran after fixing env). Those still stop remaining ticks
    # *after* a spawn in this process (see below).
    last_outcome="$(latest_outcome "$progress" || true)"
    if [[ "$last_outcome" == "COMPLETE" ]]; then
      overall="COMPLETE"
      log "stop before spawn: latest outcome=COMPLETE"
      break
    fi

    local before_fp
    before_fp="$(fingerprint_progress "$progress")"

    log "spawn tick $((ticks + 1))/$max_n ..."
    # Inject prompt via {{PROMPT}} or final arg. Never --continue / --resume.
    set +e
    run_spawn "$spawn_cmd" "$TICK_PROMPT"
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
