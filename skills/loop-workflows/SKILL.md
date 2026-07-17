---
name: loop-workflows
description: Shared tick + chat scheduler (once in-session; max N via fresh one-tick workers). Policy ops only.
disable-model-invocation: true
---

# Loop workflows

**Sole home of the shared tick** and the **chat** entry for agent-workflows v0.3. Schedulers only count N and stop; the **worker** owns resume | pick → claim → implement → publish → progress.

Call **op names** and triage **role names** only. Concrete tracker CLIs live in product policy (`docs/agents/issue-tracker.md` Steps). Role strings map via `docs/agents/triage-labels.md`. Do **not** invent tracker recipes in this skill.

**Not** a shell host (see `host-workflows`). Does not merge publish artifacts, close issues as done, create tickets, or re-queue work.

Design freeze: hub `docs/v0.3.md`.

## Modes

| Mode | Invocation | Behavior |
|------|------------|----------|
| **once** (default) | `/loop-workflows` | Run **exactly one** shared tick **in this session** end-to-end |
| **max N** | User states positive **N** (e.g. `max 3`) | Parent **only schedules**; each tick is a **fresh one-tick worker** (subagent / clean session) |

“Drain until empty” without N → ask for N or use **once**.

### Breaking change (0.2 → 0.3) — hard break

**0.2** ran up to N ticks **in the same session** (one context stuffed with multiple implements).

**0.3 max N** is a **hard break**: the parent agent **does not implement N tickets in one context**. It schedules N independent workers; each worker runs the shared tick once and exits. No compatibility flag — pin a 0.2 install if same-session multi-N is required.

**once** is unchanged in shape: one in-session tick.

## Leading words

| Term | Meaning |
|------|---------|
| **tick** | One shared pass: resume \| pick → claim → implement → publish → progress |
| **claim** | **leave-queue only**: claim **comment** + remove **ready-for-agent**. **No `claimed` role** — mid-flight is inferred via **incomplete-claim** |
| **publish** | **create-publish-artifact** then **label-transition** → **ready-for-human** (no merge / no close-as-done) |
| **outcome:** | Required machine field on progress entries for host/scheduler control |

Terminal / control-plane outcomes (progress `outcome:`):

| `outcome:` | When |
|------------|------|
| **SHIPPED** | Publish artifact created; ready-for-human |
| **NEEDS_INFO** | Fail path; needs-info; no success artifact |
| **SKIPPED** | Soft-skip that settled the ticket (e.g. spec/PRD → ready-for-human) |
| **COMPLETE** | Empty queue + no incomplete claim |
| **BLOCKED** | Queue non-empty; nothing claimable |
| **HARD_STOP** | Preflight / env / infra failure |
| **FAILED** | Control-plane failure (e.g. missing progress after a scheduled worker) |

Scheduler-only labels (status line, not always progress enum): **MAX** when N hit with work left.

## Policy discovery (worker)

From product repo root:

1. Require `docs/agents/issue-tracker.md` and `docs/agents/triage-labels.md` (non-empty).
2. Optional: `docs/agents/domain.md`, CONTEXT — read when implementing.
3. Runtime: `.agent-workflows/progress.md` (auto-create from template header + `## Entries` if missing; **never wipe** existing body). Ensure `.agent-workflows/logs/` exists.
4. Do **not** preload full progress history by default — **append** only.

Resolve role label **strings** from triage-labels (canonical roles → tracker labels). Skills speak roles; ops use the mapped strings.

## Process — **once** (or any one-tick worker)

Product root (`git rev-parse --show-toplevel`). This path runs **exactly one** shared tick in the current session.

### 1. Preflight

Run policy ops:

1. **preflight** — on Failure **HARD_STOP** → progress `outcome: HARD_STOP`, stop.
2. **integration-base** — remember base branch name for feature branches and publish.

**Done when:** env usable; integration base known; progress/logs ready.

### 2. Announce plan (before claim or implement)

1. Run **incomplete-claim** (at most one resume candidate).
2. Run **list-queue** (thin ready list, oldest first — do not pre-filter claimable in the op).
3. Walk soft-skips (below) mentally to name the first claimable pick.
4. Print:

```text
loop-workflows plan
- will resume: #N — <title>   # if incomplete-claim wins
- else will pick: #N — <title>  # first claimable after soft-skips, or "none"
- queue ready-for-agent: <count>
- mode: once | worker-one-tick
```

If the user is present and the plan is wrong, stop and ask — do not claim yet.

Print header: mode, integration base, ready-for-agent role label, then run **§3 One tick** once.

### 3. One tick (shared recipe)

```text
resume | pick → claim → implement → publish → progress
```

#### 3a. Resume

If **incomplete-claim** returned a target: stay on / check out that work; **skip new claim**; jump to **3e implement** (or publish if implement already done). Else continue to pick.

#### 3b. Queue empty?

If **list-queue** is empty and no resume → progress `outcome: COMPLETE`; go to **§5 Final status**.

#### 3c. Pick claimable (soft-skip walk)

Walk **list-queue** oldest → newest. For each candidate `#N`:

| Soft-skip | How |
|-----------|-----|
| Open publish artifact | **detect-publish-artifact** present (non-draft open artifact) → SOFT_SKIP |
| Open blockers | **read-ticket** reports open blockers → SOFT_SKIP |
| Spec / PRD (skill-side) | Body looks like Matt **`/to-spec`** / PRD container, not a **`/to-tickets`** slice — see below → settle ticket, do not implement |

No stack/epic base engine: publish base is always **integration-base**.

If queue non-empty but **nothing claimable** → progress `outcome: BLOCKED` (list why per candidate); go to **§5**.

Else pick first claimable `#N`.

**Spec / PRD detection (skill-side, after thin list; re-check after full read):** Treat as non-implementable if **two or more** hold:

- Has `## Problem Statement` and `## Solution` (or `## User Stories`)
- Has `## Implementation Decisions` or `## Testing Decisions`
- Has a long user-story list and **lacks** both `## Acceptance criteria` and `## What to build`
- Title/body clearly marks itself as PRD/spec/epic container only

**On PRD/spec soft-skip (settles the ticket):**

1. **comment** — this is a spec/PRD for splitting (e.g. `/to-tickets`), not an implementable AFK slice.
2. **label-transition** → **ready-for-human** (exclusive triage role; removes ready-for-agent).
3. Progress with `outcome: SKIPPED`; **no** create-publish-artifact.
4. Tick ends (once / worker done).

*(Upstream `/to-spec` may still apply ready-for-agent — this loop refuses to implement those bodies.)*

#### 3d. Claim (leave-queue only)

1. **read-ticket** for `#N` (full body + comments). Re-check spec/PRD; if matched, same settle path as §3c.
2. Run **claim**:
   - claim **comment** (via **comment** / claim Steps)
   - remove **ready-for-agent** only (**leave-queue**)
   - **Do not** add a `claimed` role
   - Race (already left queue) → SOFT_SKIP try next; none left → BLOCKED
   - Infra failure → HARD_STOP

#### 3e. Implement

Branch from integration base (e.g. `feat/<N>-<slug>`). Implement **only** `#N`. Read domain/CONTEXT if present.

Quality bar (unchanged intent from 0.2):

1. Prefer TDD at clear seams when the change warrants tests.
2. Run **typechecking** as you go when the repo has it.
3. Run **focused tests** for touched areas as you go.
4. Run a **broader test pass once at the end** before publish.
5. If the issue lists explicit commands, run those too.
6. Spec pass: every acceptance criterion done or explicitly N/A with reason (**comment**) **before** publish.
7. Optional light self-review; do not block publish when checks are green.

**Implement done when:** AC accounted for **and** typecheck/tests (as above) run with results noted. Do not publish until then.

#### 3f. Publish or fail

| Result | Actions |
|--------|---------|
| Checks pass | **create-publish-artifact** (durable review handoff; linked to ticket; **do not merge**; **do not close** issue as done) → **label-transition** → **ready-for-human** → progress `outcome: SHIPPED` |
| Checks fail / blocked on AC | **comment** → **label-transition** → **needs-info** → **no** success artifact → progress `outcome: NEEDS_INFO`. **Never re-apply ready-for-agent** (human owns re-queue). Do not retry same `#N` this tick |

#### 3g. Progress

Append newest-first under `.agent-workflows/progress.md`. **`outcome:` is required**:

```markdown
### YYYY-MM-DD — #N — <title>
- **outcome:** SHIPPED | NEEDS_INFO | SKIPPED | COMPLETE | BLOCKED | HARD_STOP | FAILED
- **publish:** <url or none>
- **checks:** pass | fail | n/a
- **note:** ≤1 line
```

Optional prose (What / Learnings) may follow; hosts key off **`outcome:`**.

**Done when:** tick outcome recorded. For **once** / worker: stop after this single tick (do not loop).

### 4. After one tick (once / worker)

Print **§5 Final status**. Worker sessions end here — they do not schedule further ticks.

### 5. Final status

```text
loop-workflows status
- mode: once | worker-one-tick | max N (parent)
- ticks: <completed> / <N or 1>
- last_issue: #N | none
- last_outcome: SHIPPED | NEEDS_INFO | SKIPPED | COMPLETE | BLOCKED | HARD_STOP | FAILED | …
- queue ready-for-agent: <count>
- overall: COMPLETE | BLOCKED | MAX | HARD_STOP | FAILED | (partial if max N mid-run)
```

Empty queue COMPLETE: say so; suggest creating tickets that match `docs/agents` triage (planning skills install separately). This skill never force-installs companions.

---

## Process — **max N** (chat parent scheduler only)

Parent **only schedules**. Parent **does not** implement N tickets in one context (hard break from 0.2).

### Parent steps

1. Product root; default nothing to implement in parent.
2. Optional cheap preflight: if **list-queue** empty and **incomplete-claim** empty → COMPLETE without spawning (prefer detect **before** spawn).
3. For `i` from 1 to N:
   - If stop rule hits (below), break.
   - Spawn a **fresh one-tick worker** (subagent / clean session) with:
     - product cwd
     - instruction: **run exactly one shared tick** (this skill’s **once** / worker path)
     - policy discovery in-repo (`docs/agents/*`)
   - **Do not** pass: issue id, remaining N, host queue blob, stack base.
   - After worker returns: read **latest** progress `outcome:` (do not require full history).
   - Apply stop rules.
4. Print **§5 Final status** with mode `max N`.

### Worker prompt (conceptual)

```text
In this product repo, run loop-workflows shared tick once:
resume | pick → claim → implement → publish → progress.
Discover policy under docs/agents/*. Call ops and triage roles by name only.
Exactly one tick; then stop.
```

### Scheduler stop rules (chat parent)

| Condition | Action |
|-----------|--------|
| Empty ready-queue + no incomplete claim | **COMPLETE** (prefer before spawn) |
| Latest progress `outcome:` is **BLOCKED**, **HARD_STOP**, or **FAILED** | Stop |
| Tick finished **SHIPPED** / **NEEDS_INFO** / **SKIPPED** and work may remain | Continue if `i < N` |
| Hit N with work left | **MAX** |
| Missing/unusable progress after a worker that should have written it | **FAILED** / stop |

Process exit codes are **not** tick success. Control plane = progress `outcome:` + queue re-check.

Between workers, parent does not accumulate implement context for multiple issues. Each worker is isolated.

---

## Ops reference (names only)

Worker invokes these from product `docs/agents/issue-tracker.md` (each has Input / Steps / Success / Failure):

1. **preflight**
2. **integration-base**
3. **list-queue**
4. **read-ticket**
5. **comment**
6. **label-transition**
7. **claim**
8. **detect-publish-artifact**
9. **incomplete-claim**
10. **create-publish-artifact**

Failure words from policy: **HARD_STOP** | **SOFT_SKIP** | **NEEDS_INFO** | **OK**.

### Triage roles (canonical)

Exclusive set via **label-transition** — exactly one of:

`needs-triage` | `needs-info` | `ready-for-agent` | `ready-for-human` | `wontfix`

Map strings through `triage-labels.md`. Non-triage labels untouched. **No `claimed` role.**

### Claim / publish product meaning (summary)

- **Claim** = leave-queue only (comment + drop ready-for-agent). Race → SOFT_SKIP; infra → HARD_STOP.
- **Success** = create-publish-artifact → ready-for-human → `outcome: SHIPPED`.
- **Fail** = comment → needs-info → no artifact → `outcome: NEEDS_INFO`. **Never re-apply ready-for-agent.**
- **ready-for-human** = agent done for now; artifact optional (absent on SKIPPED spec path).

## Out of scope (this skill)

- Shell host / spawn resolution (`host-workflows`)
- Unbounded drain without explicit N
- Stack/epic/merge bots; park-branch fleet; multi-spawn rate limits
- Dual implement/validate workers
- Hard-coding tracker CLIs (belong in product policy Steps)
