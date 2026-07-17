---
name: loop-workflows
description: Bounded GitHub ready-for-agent implement→PR loop (once or max N).
disable-model-invocation: true
---

# Loop workflows

**Tick** the product’s GitHub `ready-for-agent` queue in this session: resume or pick → **claim** → implement → **publish** PR → progress. Not a host runner. Does not merge, close issues, or create tickets.

**Leading words:** *tick* = one issue pass; *claim* = comment + drop queue label before coding; *publish* = open PR + `ready-for-human` (no merge). Terminals: **COMPLETE** | **BLOCKED** | **MAX** | **HARD STOP**.

Labels: read `docs/agents/triage-labels.md` for exact strings (`ready-for-agent`, `ready-for-human`, `needs-info`). One triage role at a time; never invent labels.

## Modes

| Mode | When | Behavior |
|------|------|----------|
| **once** (default) | `/loop-workflows` | At most one tick |
| **max N** | User states positive **N** | Up to N ticks; no silent unlimited drain |

“Drain until empty” without N → ask for N or use **once**.

| Outcome | When |
|---------|------|
| **COMPLETE** | No queue work and no incomplete claim |
| **BLOCKED** | Queue non-empty but nothing claimable |
| **MAX** | Hit N with work left |
| **HARD STOP** | Preflight failed |

## Process

### 1. Root and mode

Product root (`git rev-parse --show-toplevel`). Default `max_items=1`; else user N. `i=0`.

**Done when:** root and `max_items` known.

### 2. Preflight → HARD STOP on fail

| Check | Fail when |
|-------|-----------|
| Git | No repo root |
| Clean tree | `git status --porcelain` non-empty |
| GitHub + `gh` | Remote/policy not GitHub/`gh`, or `gh auth status` fails |
| Policy | `docs/agents/issue-tracker.md` or `triage-labels.md` missing/empty |

**`gh` / sandbox:** If `gh auth status` fails with keyring/OS keychain errors inside a restricted sandbox, **retry the same checks with full host permissions** (Cursor “all” / outside sandbox). Do not invent a different tracker. HARD STOP only after host retry still fails.

Not gates: `domain.md`, AGENTS.md. Ensure `.agent-workflows/logs/` exists. If `progress.md` missing, create a short header + `## Entries` (do not wipe existing). Integration branch: from issue-tracker **Integration branch** if set, else repo default (`gh repo view`). `git fetch origin`.

**Done when:** checks pass; progress/logs exist; integration name known.

**Announce intent (required before any claim or implement):**

1. Scan incomplete claims (same rules as §3a).  
2. List open `ready-for-agent` (numbers + titles, oldest first).  
3. Print one of:

```text
loop-workflows plan
- will resume: #N — <title>   # if incomplete claim wins
- else will pick: #N — <title>  # first claimable after soft-skips, or "none"
- queue ready-for-agent: <count>
- mode: once | max N
```

If the user is present and the plan is wrong, stop and ask — do not claim yet.

Print header: mode, integration, ready-for-agent label, tick `0/N`. Then while `i < max_items`:

### 3. One tick

**3a. Resume** — Before a new pick, finish **at most one** incomplete claim: local `feat/<N>-*` with no non-draft PR for `#N`, or claimed open issue lacking both queue and `ready-for-human` with no non-draft open PR. If found, stay on that branch; jump to **3e** (skip new claim). Else continue.

**3b. Queue** — List open issues with ready-for-agent label; **oldest first**. Empty and no resume → **COMPLETE**.

**3c. Claimable** — Walk oldest → newest. Skip when:

| Skip | Condition |
|------|-----------|
| Open PR | Non-draft open PR targets `#N` (draft does not block pick) |
| Blockers | Body has open **Blocked by** issues |
| **Spec / PRD (not a ticket)** | Body looks like a Matt **`/to-spec`** publish, not a **`/to-tickets`** slice — see below |

No stack/epic: base is always integration. None claimable → **BLOCKED** (list why). Else pick first claimable `#N`.

**Spec / PRD detection (do not implement):** Treat as non-implementable if **two or more** hold:

- Has `## Problem Statement` and `## Solution` (or `## User Stories`)
- Has `## Implementation Decisions` or `## Testing Decisions`
- Has a long user-story list and **lacks** both `## Acceptance criteria` and `## What to build`
- Title/body clearly marks itself as PRD/spec/epic container only

**On skip:** comment that this is a spec/PRD for splitting via `/to-tickets` (or equivalent), not an implementable AFK slice; remove `ready-for-agent`; add `ready-for-human` (human decides next: split tickets or re-queue a child). Progress line; consume tick; go to §4. Do **not** open a PR for the PRD itself.

*(Matt `/to-spec` applies `ready-for-agent` by design — do not change that skill; this loop refuses to implement those issues.)*

**3d. Claim** — `gh issue view N --comments`. Re-check spec/PRD after full body read; if matched, same skip path as §3c. Else comment claim (integration, UTC); **immediately** remove ready-for-agent; do not add ready-for-human yet.

**3e. Branch + implement** — `git checkout -B feat/<N>-<slug> origin/<integration>` (resume: keep branch). Implement **only** `#N` in this session. Read `domain.md` / CONTEXT if present.

Implement discipline (same session):

1. Prefer TDD at clear seams when the change warrants tests (pick seams from the issue/AC; do not block on a human seam meeting).
2. Run **typechecking** as you go when the repo has it.
3. Run **focused tests** for touched areas as you go.
4. Run a **broader test pass once at the end** before publish (full suite if reasonable; otherwise the product’s usual package/app checks for the touch set).
5. If the issue lists explicit commands to run, run those too.
6. Spec pass: every acceptance criterion done or explicitly N/A with reason (issue comment) **before** publish.
7. Optional: light self-review against the issue (`/code-review` if available); do not block publish when checks are green.

**Implement done when:** AC comment written **and** typecheck/tests (as above) have been run with results noted in the issue comment or progress entry. Do not open a PR until then.

**3f. Publish or bail**

| Result | Action |
|--------|--------|
| Checks pass | Commit (`#N`), push, open PR base=integration, body `Closes #N`, **no merge/close**; add `ready-for-human`; comment PR URL |
| Checks fail or blocked on AC | Comment; `needs-info` (or leave for human with clear note); progress; no success PR; `i++`; §4 — **do not** retry same `#N` this run |

**3g. Progress** — Append newest-first under `.agent-workflows/progress.md`:

```markdown
### YYYY-MM-DD — #N — <title>
- **Base:** … | **PR:** … | **Outcome:** shipped-PR | needs-info | blocked | skipped-spec | failed
- **What:** … | **Checks:** … | **Learnings:** …
```

**Done when:** tick outcome recorded; `i` incremented.

### 4. After tick

If another tick: checkout integration cleanly (`git checkout` + ff-only pull if safe). Cannot get clean tree → **HARD STOP** (do not mix issues).  
If `i >= max_items` and work remains → **MAX**. Else if more ticks allowed and not COMPLETE/BLOCKED/HARD STOP → §3. Do not ask “continue?” when N was explicit.

### 5. Final status

```text
loop-workflows status
- mode: once | max N
- ticks: i / N
- last_issue: #N | none
- last_outcome: …
- queue_ready_for_agent: <count>
- overall: COMPLETE | BLOCKED | MAX | HARD STOP
```

Empty queue COMPLETE: say so; create tickets that match `docs/agents` triage (Matt `/to-tickets` slices or manual). Planning skills install separately.

**Done when:** status printed.
