# Agent playbook — dogfood tiers 1–5

Run **after** `setup-sandbox.sh`. Work in **`$PRODUCT_DIR`**, not the hub. Skills must load from the hub branch under test (product `.agents/skills` or global install from local path).

```bash
source /path/to/product/.dogfood-env
bash "$HUB_DIR/tests/dogfood/run-automated.sh"   # Tier 0
bash "$HUB_DIR/tests/dogfood/check-docs.sh"      # Tier 1 needles
cp "$HUB_DIR/tests/dogfood/report.template.md" "$PRODUCT_DIR/dogfood-output/report.md"
```

Fill `$PRODUCT_DIR/dogfood-output/report.md` as you go. Full matrix: [scenarios.md](./scenarios.md).

---

## Defaults for this playbook

| Setting | Value |
|---------|--------|
| Skill scope | **P (product)** for isolation |
| Init autonomy | **S** for I1; **H**+**P** for I4 |
| Spawn | `grok -p {{PROMPT}} --always-approve --output-format plain` |
| Loop | once for L1/L2; skip L3–L6 unless full suite |
| Host | H1 + H2 only unless full suite |

Canned user replies (paste when the skill asks):

| Prompt | Reply |
|--------|--------|
| Tracker / labels / domain | `ok` or `all defaults` |
| Autonomy S/H | `S` (I1) or `H` (I4) |
| Scope G/P | `P` |
| Install missing skills | `install` |
| Keep existing skills | `keep` |
| Grok spawn preset | `yes` |
| AGENTS.md pointer | `no` unless useful |

---

## Tier 1 — Docs / AC (hub)

1. Open hub `README.md`, `CHANGELOG.md`, `docs/v0.3.md`, `skills/init-workflows/SKILL.md`, `skills/host-workflows/SKILL.md`.
2. Mark D1–D7 in the report (use `check-docs.sh` for needles; still read for D7 / issue #14).
3. Issue #14 ACs:

   - [ ] Init offers host/spawn with confirm; READY without loop
   - [ ] Init repairs contracts; never wipes progress
   - [ ] README: three packages, dual entry, multi-N break
   - [ ] CHANGELOG consumer-relevant 0.3 detail
   - [ ] Docs align with freeze

   Note intentional expansions (G/P scope, smart spawn, `{{PROMPT}}`) as **PASS with note** if documented in CHANGELOG.

---

## Tier 2 — Init

### I1 — Greenfield contracts only (**S**)

1. `cd $PRODUCT_DIR` with **no** `docs/agents` yet (setup fixture has none).
2. Invoke `/init-workflows`.
3. Reply `ok` for policy defaults; **S** for autonomy.
4. **Pass when:**
   - `docs/agents/{issue-tracker,triage-labels,domain}.md` exist non-empty
   - `.agent-workflows/progress.md` and `logs/` exist
   - `.gitignore` has runtime ignore lines
   - Status `overall: READY`
   - Host was **not** force-installed as a READY requirement
5. Record status block in report.

### I2 — Re-run does not wipe progress

1. Append a fake entry to progress:

```bash
cat >> .agent-workflows/progress.md <<'EOF'

### 2099-01-01 — #0 — dogfood marker
- **outcome:** SHIPPED
- **publish:** none
- **checks:** n/a
- **note:** wipe-guard
EOF
BEFORE=$(shasum -a 256 .agent-workflows/progress.md | awk '{print $1}')
```

2. Re-run `/init-workflows` (S / skip autonomy).
3. **Pass when:** `shasum` unchanged; marker still present; READY.

### I4 — Shell AFK product scope (**default isolation path**)

1. Fresh product **or** after I1 with skills missing in product scope.
2. `/init-workflows` → **H** → **P** → install host+loop if missing → accept Grok spawn.
3. **Pass when:**
   - `.agents/skills/host-workflows` and `loop-workflows` present (or skills-lock documents them)
   - `.agent-workflows/spawn` is one line containing `{{PROMPT}}` and `grok`
   - Status `host-entry` points at **product** `host.sh`
   - READY

*(I3 global: only if testing G; prefer isolated HOME or accept machine skill updates.)*

---

## Tier 3 — Loop

Prereq: product READY, clean tree (`git status --porcelain` empty), `gh` auth, loop skill loaded.

### L1 — Empty queue COMPLETE

1. Remove ready labels from open issues **or** use a product with no ready issues:

```bash
# optional: park fixtures
gh issue edit "$(basename "$ISSUE_A")" --remove-label ready-for-agent 2>/dev/null || true
gh issue edit "$(basename "$ISSUE_B")" --remove-label ready-for-agent 2>/dev/null || true
gh issue edit "$(basename "$ISSUE_C")" --remove-label ready-for-agent 2>/dev/null || true
```

2. `/loop-workflows` (once).
3. **Pass:** progress `outcome: COMPLETE` (or status COMPLETE); no claim.

### L2 — Once SHIPPED

1. Ensure only **#A** is `ready-for-agent` (close or unlabel B/C if needed).
2. Clean tree; `/loop-workflows`.
3. **Pass:**
   - Issue left ready-for-agent; comment claim
   - Feature branch + PR (or publish artifact) linked
   - Label `ready-for-human`
   - progress `outcome: SHIPPED` + publish URL
   - `npm test` would pass on the PR branch

### Optional full suite

| ID | Notes |
|----|--------|
| L3 | Only #C ready → SKIPPED, no implement PR |
| L4 | `echo dirty >> README.md` then once → interactive retry/abort |
| L5 | #A+#B ready → `max 2` → two workers |
| L6 | Claim without publish mid-flight → resume |

---

## Tier 4 — Host (Grok)

Prereq: spawn file set; loop skill visible to `grok`; clean tree; ready work if testing ship.

```bash
source "$PRODUCT_DIR/.dogfood-env"
HOST="${HOST_SH_PRODUCT:-}"
if [[ ! -x "$HOST" ]]; then HOST="$HOST_SH_HUB"; fi
```

### H1 — Missing spawn

```bash
mv .agent-workflows/spawn .agent-workflows/spawn.bak 2>/dev/null || true
unset AGENT_SPAWN
set +e
out=$(bash "$HOST" -n 1 --cwd "$PRODUCT_DIR" 2>&1)
ec=$?
set -e
echo "$out" | tee dogfood-output/h1.txt
# Pass: ec != 0 and output mentions HARD STOP / spawn
mv .agent-workflows/spawn.bak .agent-workflows/spawn 2>/dev/null || true
```

### H2 — One Grok tick

```bash
# ensure one ready issue and clean tree
bash "$HOST" -n 1 --cwd "$PRODUCT_DIR" 2>&1 | tee dogfood-output/h2.txt
# Pass: overall MAX or COMPLETE; progress has new SHIPPED or COMPLETE entry
# Inspect: tail .agent-workflows/progress.md
```

### Optional

| ID | Command idea |
|----|----------------|
| H3 | `-n 2` with two ready issues |
| H5 | write HARD_STOP to progress; re-run host → still spawns |
| H6 | `--spawn 'grok -p {{PROMPT}} --always-approve --output-format plain'` |

---

## Tier 5 — Security smoke

1. **S2:** Re-read I1 — contracts-only path never required unattended spawn install for READY.
2. **S3:** Re-run `run-automated.sh` from hub.
3. **S1 (optional):** open issue with body containing `rm -rf /tmp/not-real` and ready-for-agent; ensure loop does not execute it.

---

## Finish

1. Complete summary counts in `dogfood-output/report.md`.
2. **Commit/push hub only if** default gate passes (see scenarios.md).
3. Keep sandbox for inspection, or:

```bash
bash "$HUB_DIR/tests/dogfood/teardown-sandbox.sh" --repo "$DOGFOOD_REPO" --dir "$PRODUCT_DIR" --delete
```
