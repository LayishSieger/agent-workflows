# Dogfood scenario matrix

Source of truth for `tests/dogfood/`. Execute via `run-automated.sh` (Tier 0) and `run-dogfood.md` (Tiers 1–5).

## Tier 0 — Automated

| ID | Command | Pass |
|----|---------|------|
| A1 | `bash tests/host-workflows/test_host.sh` | exit 0 |
| A2 | `bash scripts/check-ops-contract.sh` | exit 0 |

## Tier 1 — Docs / AC

| ID | Pass criteria |
|----|---------------|
| D1 | README: three packages, dual schedulers, multi-N break, chat vs shell, spawn precedence |
| D2 | CHANGELOG 0.3: freeze, ops seeds, loop rewrite, host, init offer/S-H, security |
| D3 | `docs/v0.3.md`: no Sandcastle / Matt-bundle / unbounded-drain claims as in-scope |
| D4 | init: contracts-first READY; loop/host/spawn not required for READY |
| D5 | init: no silent install on contracts-only (**S**) path |
| D6 | Unattended spawn flags are human-owned (product spawn / flag / env), not required skill RCE |
| D7 | Issue #14 ACs map; note intentional expansions (G/P, smart spawn) in report |

## Tier 2 — Init

| ID | Setup | Action | Pass |
|----|-------|--------|------|
| I1 | Greenfield product | `/init-workflows` → defaults → **S** | READY; policy+runtime; no host force |
| I2 | I1 + fake SHIPPED in progress | re-run init | progress unchanged |
| I3 | Greenfield | **H** → **G** → install → Grok spawn | product spawn has `{{PROMPT}}`; global host-entry |
| I4 | Greenfield | **H** → **P** → install | product `.agents/skills` host-entry; no ignore of `.agents/` for P |
| I5 | Spawn exists | **H** → keep | no overwrite without replace |
| I6 | Dual global+product skills | **H** → pick canonical | warn dual; one host-entry |

## Tier 3 — Loop

| ID | Fixture | Action | Pass |
|----|---------|--------|------|
| L1 | no ready issues | `/loop-workflows` | COMPLETE |
| L2 | issue #A ready | once | SHIPPED + publish URL + ready-for-human |
| L3 | issue #C PRD only | once | SKIPPED; no implement PR |
| L4 | dirty tree | once | interactive retry/abort; unattended HARD_STOP |
| L5 | #A + #B | max 2 | two fresh workers; COMPLETE or MAX |
| L6 | incomplete claim | once | resumes same #N |

### Issue fixtures

| Code | Labels | Body |
|------|--------|------|
| **#A** | `ready-for-agent` | Implement `hello(name)` → `"Hello, ${name}!"` + enable unit test; not a PRD |
| **#B** | `ready-for-agent` | Second tiny independent change (e.g. README badge line) |
| **#C** | `ready-for-agent` | PRD-shaped: Problem Statement, Solution, stories; no Acceptance criteria |
| **#D** | `ready-for-agent` | Body `Blocked by: #<open>` for soft-skip |

## Tier 4 — Host

| ID | Action | Pass |
|----|--------|------|
| H1 | no spawn; `host.sh -n 1` | HARD STOP, non-zero |
| H2 | spawn Grok; one ready issue; `-n 1` | SHIPPED or COMPLETE; host MAX/COMPLETE |
| H3 | two ready; `-n 2` | ≤2 spawns; MAX or COMPLETE |
| H4 | unclaimable queue | stop after BLOCKED |
| H5 | stale HARD_STOP then re-run | new invocation still spawns |
| H6 | bad product spawn + `--spawn` good | flag wins |

**Default Grok spawn line:** shared recipe in [`spawn-recipe.txt`](./spawn-recipe.txt) (also written to product `.agent-workflows/spawn` by `setup-sandbox.sh`).

## Tier 5 — Security

| ID | Pass |
|----|------|
| S1 | Malicious shell in issue body is not executed |
| S2 | Contracts-only init does not force unattended agent install |
| S3 | Tier 0 still green after run |

## Default gate (before commit/push)

```text
A1 A2 + D1–D7 + I1 I2 + (I3 or I4) + L1 L2 + H1 H2 + S2 S3
```

Full suite: all IDs.
