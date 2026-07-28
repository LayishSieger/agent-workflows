#!/usr/bin/env bash
# Automated tests for host-workflows/scripts/host.sh (fake SPAWN seam).
# Exit 0 on pass; non-zero with failure details.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOST="$ROOT/skills/host-workflows/scripts/host.sh"
FAKE="$ROOT/tests/host-workflows/fake-spawn.sh"
PASS=0
FAIL=0

# Case fixture globals (set by setup_case)
product=""
log=""

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name"
    echo "        expected: $(printf %q "$expected")"
    echo "        actual:   $(printf %q "$actual")"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local name="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name (missing $(printf %q "$needle"))"
    echo "        got: $(printf %q "$haystack")"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local name="$1" needle="$2" haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name (unexpected $(printf %q "$needle"))"
    echo "        got: $(printf %q "$haystack")"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  local name="$1" path="$2"
  if [[ -x "$path" || -f "$path" ]]; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name (missing $path)"
    FAIL=$((FAIL + 1))
  fi
}

# --- package shape ---
echo "== package shape =="
assert_file_exists "host.sh present" "$HOST"
assert_file_exists "SKILL.md present" "$ROOT/skills/host-workflows/SKILL.md"
assert_file_exists "fake-spawn present" "$FAKE"
if [[ -x "$HOST" ]]; then
  echo "  PASS: host.sh executable"
  PASS=$((PASS + 1))
else
  echo "  FAIL: host.sh not executable"
  FAIL=$((FAIL + 1))
fi

# --- helpers ---
make_product() {
  local d
  d="$(mktemp -d "${TMPDIR:-/tmp}/host-wf.XXXXXX")"
  mkdir -p "$d/.agent-workflows"
  cat >"$d/.agent-workflows/progress.md" <<'EOF'
# progress

## Entries

EOF
  echo "$d"
}

run_host() {
  # run_host <cwd> [host args...]
  local cwd="$1"
  shift
  (
    cd "$cwd"
    # Isolate machine spawn path per test via HOME
    bash "$HOST" "$@"
  )
}

write_progress_outcome() {
  local progress="$1" outcome="$2"
  cat >"$progress" <<EOF
# Agent workflows — progress log

## Entries

### 2099-01-01 — #0 — prior
- **outcome:** $outcome
- **publish:** none
- **checks:** n/a
- **note:** fixture

EOF
}

# setup_case [outcome]
# Creates product + isolated HOME + spawn log; wires FAKE_SPAWN_* when outcome is set
# (omit outcome to leave FAKE_SPAWN_OUTCOME unset, e.g. skip-progress / no-spawn cases).
setup_case() {
  local outcome="${1-}"
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  log="$(mktemp)"
  unset AGENT_SPAWN FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME \
    FAKE_SPAWN_SKIP_PROGRESS FAKE_SPAWN_EXIT || true
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  if [[ -n "$outcome" ]]; then
    export FAKE_SPAWN_OUTCOME="$outcome"
  fi
}

teardown_case() {
  rm -rf "${product:-}" "${HOME:-}"
  unset AGENT_SPAWN FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME \
    FAKE_SPAWN_SKIP_PROGRESS FAKE_SPAWN_EXIT || true
  product=""
  log=""
}

# Decoy machine + product spawn files (resolution-order tests).
write_decoy_spawns() {
  mkdir -p "$HOME/.config/agent-workflows"
  echo "machine-should-not-run" >"$HOME/.config/agent-workflows/spawn"
  echo "product-should-not-run" >"$product/.agent-workflows/spawn"
}

# assert_spawn_rejected <name> <error-substring> [host-args...]
# Expects exit 1, stderr/stdout contains substring, and spawn log stays empty.
assert_spawn_rejected() {
  local name="$1" needle="$2"
  shift 2
  local out ec
  set +e
  out="$(run_host "$product" -n 1 "$@" 2>&1)"
  ec=$?
  set -e
  assert_eq "${name} rejected" "1" "$ec"
  assert_contains "${name} explains refusal" "$needle" "$out"
  if [[ -n "${log:-}" && -s "$log" ]]; then
    echo "  FAIL: ${name} must not execute"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: ${name} did not execute"
    PASS=$((PASS + 1))
  fi
}

# --- spawn resolution ---
echo "== spawn resolution =="

# All missing → HARD STOP, non-zero, no spawn
{
  setup_case
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS || true
  set +e
  out="$(run_host "$product" -n 1 2>&1)"
  ec=$?
  set -e
  assert_eq "missing spawn exit non-zero" "1" "$ec"
  assert_contains "missing spawn HARD STOP message" "HARD STOP" "$out"
  assert_contains "missing spawn mentions spawn" "spawn" "$(echo "$out" | tr '[:upper:]' '[:lower:]')"
  teardown_case
}

# --spawn flag wins over product + machine + env
{
  setup_case SHIPPED
  write_decoy_spawns
  export AGENT_SPAWN="env-should-not-run"
  set +e
  out="$(run_host "$product" -n 1 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_eq "flag spawn exit 0 (SHIPPED then max)" "0" "$ec"
  assert_contains "flag spawn used fake" "argc=" "$(cat "$log" 2>/dev/null || true)"
  if grep -q 'machine-should-not-run\|product-should-not-run\|env-should-not-run' "$log" 2>/dev/null; then
    echo "  FAIL: wrong spawn path used"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: flag beats product/machine/env"
    PASS=$((PASS + 1))
  fi
  teardown_case
}

# AGENT_SPAWN wins over product + machine
{
  setup_case COMPLETE
  write_decoy_spawns
  export AGENT_SPAWN="$FAKE"
  set +e
  out="$(run_host "$product" -n 1 2>&1)"
  ec=$?
  set -e
  assert_contains "env spawn used fake" "argc=" "$(cat "$log")"
  assert_contains "env path COMPLETE" "COMPLETE" "$out"
  if grep -q 'machine-should-not-run\|product-should-not-run' "$log" 2>/dev/null; then
    echo "  FAIL: env should beat files"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: AGENT_SPAWN beats product/machine files"
    PASS=$((PASS + 1))
  fi
  teardown_case
}

# product file wins over machine
{
  setup_case COMPLETE
  git -C "$product" init -q
  mkdir -p "$HOME/.config/agent-workflows"
  echo "machine-should-not-run" >"$HOME/.config/agent-workflows/spawn"
  echo "$FAKE" >"$product/.agent-workflows/spawn"
  set +e
  out="$(run_host "$product" -n 1 2>&1)"
  set -e
  assert_contains "product spawn used fake" "argc=" "$(cat "$log")"
  if grep -q 'machine-should-not-run' "$log" 2>/dev/null; then
    echo "  FAIL: product should beat machine"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: product spawn beats machine"
    PASS=$((PASS + 1))
  fi
  teardown_case
}

# Product files require git metadata so unpacked source cannot supply executable config.
{
  setup_case
  echo "$FAKE" >"$product/.agent-workflows/spawn"
  assert_spawn_rejected "non-git product spawn" "without a git worktree"
  teardown_case
}

# machine file used when product missing
{
  setup_case COMPLETE
  mkdir -p "$HOME/.config/agent-workflows"
  echo "$FAKE" >"$HOME/.config/agent-workflows/spawn"
  set +e
  out="$(run_host "$product" -n 1 2>&1)"
  set -e
  assert_contains "machine spawn used fake" "argc=" "$(cat "$log")"
  teardown_case
}

# A tracked product spawn file is repository-controlled and must never execute.
{
  setup_case COMPLETE
  (
    cd "$product"
    git init -q
    git add .agent-workflows/progress.md
    echo "$FAKE" >.agent-workflows/spawn
    git add -f .agent-workflows/spawn
  )
  assert_spawn_rejected "tracked product spawn" "refusing tracked product spawn file"
  teardown_case
}

# A symlinked product spawn must refuse — never fall through to machine config.
{
  setup_case COMPLETE
  mkdir -p "$HOME/.config/agent-workflows"
  echo "$FAKE" >"$HOME/.config/agent-workflows/spawn"
  (
    cd "$product"
    git init -q
    echo "$FAKE" >.agent-workflows/spawn.target
    ln -s spawn.target .agent-workflows/spawn
  )
  assert_spawn_rejected "symlinked product spawn" "refusing symlinked product spawn file"
  teardown_case
}

# Spawn contents are configuration and may contain sensitive values; never print them.
{
  setup_case COMPLETE
  set +e
  out="$(run_host "$product" -n 1 --spawn "$FAKE --opaque-value" 2>&1)"
  ec=$?
  set -e
  assert_eq "redacted spawn still runs" "0" "$ec"
  assert_not_contains "spawn recipe redacted from output" "--opaque-value" "$out"
  assert_contains "spawn output reports redaction" "contents redacted" "$out"
  teardown_case
}

# Shell operators must be passed as neither syntax nor executable side effects.
{
  setup_case
  marker="$product/should-not-exist"
  assert_spawn_rejected "shell chaining" "unsafe spawn recipe" --spawn "$FAKE; touch $marker"
  if [[ -e "$marker" ]]; then
    echo "  FAIL: rejected shell syntax created marker"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: rejected shell syntax had no side effect"
    PASS=$((PASS + 1))
  fi
  teardown_case
}

# Interpreter wrappers restore shell evaluation even without metacharacters and are rejected.
{
  setup_case
  assert_spawn_rejected "shell interpreter" "command interpreters" --spawn "bash -c id"
  teardown_case
}

# --- prompt as final arg; no resume/continue ---
echo "== prompt placement =="
{
  setup_case COMPLETE
  set +e
  run_host "$product" -n 1 --spawn "$FAKE" >/dev/null 2>&1
  set -e
  last_arg="$(grep '^arg' "$log" | tail -1 | sed 's/^arg[0-9]*=//')"
  assert_contains "prompt is final arg (loop-workflows)" "loop-workflows" "$last_arg"
  assert_contains "prompt mentions exactly one tick" "Exactly one tick" "$last_arg"
  if grep -Eiq -- '--continue|--resume' "$log"; then
    echo "  FAIL: host must not inject --continue/--resume"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: no resume/continue flags from host"
    PASS=$((PASS + 1))
  fi
  argc="$(grep '^argc=' "$log" | head -1 | cut -d= -f2)"
  assert_eq "bare spawn receives one arg (prompt)" "1" "$argc"
  teardown_case
}

# {{PROMPT}} placeholder (Grok-style: prompt is a flag value, not trailing arg only)
{
  setup_case COMPLETE
  set +e
  # Placeholder after a flag so argv is: --flag <prompt>
  run_host "$product" -n 1 --spawn "$FAKE --flag {{PROMPT}}" >/dev/null 2>&1
  set -e
  argc="$(grep '^argc=' "$log" | head -1 | cut -d= -f2)"
  assert_eq "placeholder spawn argc=2 (--flag + prompt)" "2" "$argc"
  assert_eq "placeholder first arg is --flag" "--flag" "$(grep '^arg1=' "$log" | head -1 | sed 's/^arg1=//')"
  assert_contains "placeholder second arg is prompt" "loop-workflows" "$(grep '^arg2=' "$log" | head -1 | sed 's/^arg2=//')"
  teardown_case
}

# --- stop rules ---
echo "== stop rules =="

# COMPLETE before spawn (prefer no spawn)
{
  setup_case
  write_progress_outcome "$product/.agent-workflows/progress.md" "COMPLETE"
  set +e
  out="$(run_host "$product" -n 3 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_eq "COMPLETE-before-spawn exit 0" "0" "$ec"
  assert_contains "COMPLETE-before-spawn status" "COMPLETE" "$out"
  if [[ -s "$log" ]]; then
    echo "  FAIL: should not spawn when already COMPLETE"
    cat "$log"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: no spawn when progress already COMPLETE"
    PASS=$((PASS + 1))
  fi
  teardown_case
}

# Stale HARD_STOP must not brick a new host invocation (retry after env fix)
{
  setup_case COMPLETE
  write_progress_outcome "$product/.agent-workflows/progress.md" "HARD_STOP"
  set +e
  out="$(run_host "$product" -n 1 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_eq "stale-HARD_STOP still spawns exit 0" "0" "$ec"
  assert_contains "stale-HARD_STOP then COMPLETE" "COMPLETE" "$out"
  if [[ ! -s "$log" ]]; then
    echo "  FAIL: should spawn despite stale HARD_STOP"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: spawn despite stale HARD_STOP"
    PASS=$((PASS + 1))
  fi
  teardown_case
}

# BLOCKED from progress after spawn
{
  setup_case BLOCKED
  set +e
  out="$(run_host "$product" -n 3 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_contains "BLOCKED overall" "BLOCKED" "$out"
  spawns="$(grep -c '^argc=' "$log" || true)"
  assert_eq "BLOCKED stops after one spawn" "1" "$spawns"
  if [[ $ec -ne 0 ]]; then
    echo "  PASS: BLOCKED exit non-zero (ec=$ec)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: BLOCKED should be non-zero"
    FAIL=$((FAIL + 1))
  fi
  teardown_case
}

# HARD_STOP from progress
{
  setup_case HARD_STOP
  set +e
  out="$(run_host "$product" -n 3 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_contains "HARD_STOP overall" "HARD_STOP" "$out"
  spawns="$(grep -c '^argc=' "$log" || true)"
  assert_eq "HARD_STOP stops after one spawn" "1" "$spawns"
  if [[ $ec -ne 0 ]]; then
    echo "  PASS: HARD_STOP exit non-zero"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: HARD_STOP should be non-zero"
    FAIL=$((FAIL + 1))
  fi
  teardown_case
}

# FAILED from progress
{
  setup_case FAILED
  set +e
  out="$(run_host "$product" -n 3 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_contains "FAILED overall" "FAILED" "$out"
  spawns="$(grep -c '^argc=' "$log" || true)"
  assert_eq "FAILED stops after one spawn" "1" "$spawns"
  if [[ $ec -ne 0 ]]; then
    echo "  PASS: FAILED exit non-zero"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: FAILED should be non-zero"
    FAIL=$((FAIL + 1))
  fi
  teardown_case
}

# Missing progress after spawn → FAILED
{
  setup_case
  export FAKE_SPAWN_SKIP_PROGRESS=1
  set +e
  out="$(run_host "$product" -n 2 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_contains "missing progress FAILED" "FAILED" "$out"
  spawns="$(grep -c '^argc=' "$log" || true)"
  assert_eq "missing progress no further ticks" "1" "$spawns"
  if [[ $ec -ne 0 ]]; then
    echo "  PASS: missing progress exit non-zero"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: missing progress should be non-zero"
    FAIL=$((FAIL + 1))
  fi
  teardown_case
}

# MAX after N continuing outcomes
{
  setup_case SHIPPED
  set +e
  out="$(run_host "$product" -n 2 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_eq "MAX exit 0" "0" "$ec"
  assert_contains "MAX overall" "MAX" "$out"
  spawns="$(grep -c '^argc=' "$log" || true)"
  assert_eq "MAX runs exactly N spawns" "2" "$spawns"
  teardown_case
}

# Process exit ≠ tick success: non-zero spawn exit with SHIPPED still continues control plane
{
  setup_case SHIPPED
  export FAKE_SPAWN_EXIT=42
  set +e
  out="$(run_host "$product" -n 1 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  # Host overall MAX (hit N with SHIPPED), not FAILED solely due to exit 42
  assert_contains "process exit ignored for success" "MAX" "$out"
  assert_eq "process exit 42 still host exit 0 for MAX" "0" "$ec"
  teardown_case
}

# COMPLETE after spawn stops without further ticks
{
  setup_case COMPLETE
  set +e
  out="$(run_host "$product" -n 5 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_eq "COMPLETE-after-spawn exit 0" "0" "$ec"
  assert_contains "COMPLETE-after-spawn status" "COMPLETE" "$out"
  spawns="$(grep -c '^argc=' "$log" || true)"
  assert_eq "COMPLETE after one spawn no more" "1" "$spawns"
  teardown_case
}

# Template multi-choice outcome line must not be treated as COMPLETE/SHIPPED control plane
{
  setup_case COMPLETE
  cat >"$product/.agent-workflows/progress.md" <<'EOF'
# Agent workflows — progress log

## Template (copy)

### YYYY-MM-DD — #N — <title>
- **outcome:** SHIPPED | NEEDS_INFO | SKIPPED | COMPLETE | BLOCKED | HARD_STOP | FAILED

## Entries

EOF
  set +e
  out="$(run_host "$product" -n 2 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  # Must still spawn once (template is not a real COMPLETE), then stop on worker COMPLETE
  spawns="$(grep -c '^argc=' "$log" || true)"
  assert_eq "template multi-choice does not short-circuit" "1" "$spawns"
  assert_eq "template case exit 0" "0" "$ec"
  assert_contains "template case overall COMPLETE" "COMPLETE" "$out"
  teardown_case
}

# --- summary ---
echo
echo "Results: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
