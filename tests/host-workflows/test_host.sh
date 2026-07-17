#!/usr/bin/env bash
# Automated tests for host-workflows/scripts/host.sh (fake SPAWN seam).
# Exit 0 on pass; non-zero with failure details.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOST="$ROOT/skills/host-workflows/scripts/host.sh"
FAKE="$ROOT/tests/host-workflows/fake-spawn.sh"
PASS=0
FAIL=0

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

# --- spawn resolution ---
echo "== spawn resolution =="

# All missing → HARD STOP, non-zero, no spawn
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  unset AGENT_SPAWN || true
  log="$(mktemp)"
  set +e
  out="$(run_host "$product" -n 1 2>&1)"
  ec=$?
  set -e
  assert_eq "missing spawn exit non-zero" "1" "$ec"
  assert_contains "missing spawn HARD STOP message" "HARD STOP" "$out"
  assert_contains "missing spawn mentions spawn" "spawn" "$(echo "$out" | tr '[:upper:]' '[:lower:]')"
  rm -rf "$product" "$HOME"
}

# --spawn flag wins over product + machine + env
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  mkdir -p "$HOME/.config/agent-workflows"
  echo "machine-should-not-run" >"$HOME/.config/agent-workflows/spawn"
  echo "product-should-not-run" >"$product/.agent-workflows/spawn"
  export AGENT_SPAWN="env-should-not-run"
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="SHIPPED"
  set +e
  out="$(run_host "$product" -n 1 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_eq "flag spawn exit 0 (SHIPPED then max)" "0" "$ec"
  assert_contains "flag spawn used fake" "argc=" "$(cat "$log" 2>/dev/null || true)"
  # Ensure wrong binaries not invoked as first token — log should only be from FAKE
  if grep -q 'machine-should-not-run\|product-should-not-run\|env-should-not-run' "$log" 2>/dev/null; then
    echo "  FAIL: wrong spawn path used"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: flag beats product/machine/env"
    PASS=$((PASS + 1))
  fi
  rm -rf "$product" "$HOME"
  unset AGENT_SPAWN FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME
}

# AGENT_SPAWN wins over product + machine
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  mkdir -p "$HOME/.config/agent-workflows"
  echo "machine-should-not-run" >"$HOME/.config/agent-workflows/spawn"
  echo "product-should-not-run" >"$product/.agent-workflows/spawn"
  log="$(mktemp)"
  export AGENT_SPAWN="$FAKE"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="COMPLETE"
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
  rm -rf "$product" "$HOME"
  unset AGENT_SPAWN FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME
}

# product file wins over machine
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  mkdir -p "$HOME/.config/agent-workflows"
  echo "machine-should-not-run" >"$HOME/.config/agent-workflows/spawn"
  echo "$FAKE" >"$product/.agent-workflows/spawn"
  unset AGENT_SPAWN || true
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="COMPLETE"
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
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME
}

# machine file used when product missing
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  mkdir -p "$HOME/.config/agent-workflows"
  echo "$FAKE" >"$HOME/.config/agent-workflows/spawn"
  unset AGENT_SPAWN || true
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="COMPLETE"
  set +e
  out="$(run_host "$product" -n 1 2>&1)"
  set -e
  assert_contains "machine spawn used fake" "argc=" "$(cat "$log")"
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME
}

# --- prompt as final arg; no resume/continue ---
echo "== prompt placement =="
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="COMPLETE"
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
  # single arg total (prompt only) when spawn is bare script
  argc="$(grep '^argc=' "$log" | head -1 | cut -d= -f2)"
  assert_eq "bare spawn receives one arg (prompt)" "1" "$argc"
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME
}

# --- stop rules ---
echo "== stop rules =="

# COMPLETE before spawn (prefer no spawn)
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  write_progress_outcome "$product/.agent-workflows/progress.md" "COMPLETE"
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
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
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS
}

# BLOCKED from progress after spawn
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="BLOCKED"
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
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME
}

# HARD_STOP from progress
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="HARD_STOP"
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
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME
}

# FAILED from progress
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="FAILED"
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
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME
}

# Missing progress after spawn → FAILED
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
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
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_SKIP_PROGRESS
}

# MAX after N continuing outcomes
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="SHIPPED"
  set +e
  out="$(run_host "$product" -n 2 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_eq "MAX exit 0" "0" "$ec"
  assert_contains "MAX overall" "MAX" "$out"
  spawns="$(grep -c '^argc=' "$log" || true)"
  assert_eq "MAX runs exactly N spawns" "2" "$spawns"
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME
}

# Process exit ≠ tick success: non-zero spawn exit with SHIPPED still continues control plane
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="SHIPPED"
  export FAKE_SPAWN_EXIT=42
  set +e
  out="$(run_host "$product" -n 1 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  # Host overall MAX (hit N with SHIPPED), not FAILED solely due to exit 42
  assert_contains "process exit ignored for success" "MAX" "$out"
  assert_eq "process exit 42 still host exit 0 for MAX" "0" "$ec"
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME FAKE_SPAWN_EXIT
}

# COMPLETE after spawn stops without further ticks
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="COMPLETE"
  set +e
  out="$(run_host "$product" -n 5 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  assert_eq "COMPLETE-after-spawn exit 0" "0" "$ec"
  assert_contains "COMPLETE-after-spawn status" "COMPLETE" "$out"
  spawns="$(grep -c '^argc=' "$log" || true)"
  assert_eq "COMPLETE after one spawn no more" "1" "$spawns"
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME
}

# Template multi-choice outcome line must not be treated as COMPLETE/SHIPPED control plane
{
  product="$(make_product)"
  export HOME="$(mktemp -d "${TMPDIR:-/tmp}/host-home.XXXXXX")"
  cat >"$product/.agent-workflows/progress.md" <<'EOF'
# Agent workflows — progress log

## Template (copy)

### YYYY-MM-DD — #N — <title>
- **outcome:** SHIPPED | NEEDS_INFO | SKIPPED | COMPLETE | BLOCKED | HARD_STOP | FAILED

## Entries

EOF
  log="$(mktemp)"
  export FAKE_SPAWN_LOG="$log"
  export FAKE_SPAWN_PROGRESS="$product/.agent-workflows/progress.md"
  export FAKE_SPAWN_OUTCOME="COMPLETE"
  set +e
  out="$(run_host "$product" -n 2 --spawn "$FAKE" 2>&1)"
  ec=$?
  set -e
  # Must still spawn once (template is not a real COMPLETE), then stop on worker COMPLETE
  spawns="$(grep -c '^argc=' "$log" || true)"
  assert_eq "template multi-choice does not short-circuit" "1" "$spawns"
  assert_eq "template case exit 0" "0" "$ec"
  assert_contains "template case overall COMPLETE" "COMPLETE" "$out"
  rm -rf "$product" "$HOME"
  unset FAKE_SPAWN_LOG FAKE_SPAWN_PROGRESS FAKE_SPAWN_OUTCOME
}

# --- summary ---
echo
echo "Results: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
