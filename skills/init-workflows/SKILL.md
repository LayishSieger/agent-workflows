---
name: init-workflows
description: Ensure a product repo has agent-workflows contracts (policy docs + runtime). Re-entrant audit and repair.
disable-model-invocation: true
---

# Ensure workflows-ready

**Ensure** this product repo meets agent-workflows contracts. Every run is a full **audit**, then **repair** of gaps only. Do not trust marker files or prior "initialized" claims.

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write.

**Out of scope:** implementing features, draining issue queues (use `/loop-workflows`), runners, secrets.

All seeds ship **in this skill directory**. Never require a separate hub checkout.

## Process

### 1. Explore

Locate product root (`git rev-parse --show-toplevel` or workspace root). If the cwd is only this skill package, ask which product repo to ensure.

Read whatever exists; don't assume:

- `git remote -v` — GitHub? other?
- `docs/agents/issue-tracker.md`, `triage-labels.md`, `domain.md` — present and non-empty?
- `.agent-workflows/progress.md`, `.agent-workflows/logs/`
- `.gitignore` — has agent-workflows ignore lines? (see step 5)
- `AGENTS.md` / `CLAUDE.md` — optional pointer only
- `.scratch/` — hint of local-markdown issues

### 2. Audit and present

Status each checklist row: **present** | **missing** | **drift** (exists but empty / fails ready-when). Print the table **before** any writes.

| # | Artifact | Ready when |
|---|----------|------------|
| 1 | `docs/agents/issue-tracker.md` | File exists and is non-empty |
| 2 | `docs/agents/triage-labels.md` | File exists and is non-empty |
| 3 | `docs/agents/domain.md` | File exists and is non-empty |
| 4 | `.agent-workflows/progress.md` | File exists |
| 5 | `.agent-workflows/logs/` | Directory exists (prefer `.gitkeep` inside) |
| 6 | `.gitignore` | Contains the four agent-workflows runtime lines (step 5) |

AGENTS.md / CLAUDE.md is **not** required for READY.

**Done when:** full table shown with a status on every row.

### 3. Present findings and ask (missing policy only)

If items 1–3 are **all present**, skip to step 4 (no interview).

If any of 1–3 are **missing**, walk **only those** decisions **one at a time** — explainer → options → user answer → next. Don't dump all three at once. Assume the user may not know the terms. Build drafts; **do not write files yet**.

#### Section A — Issue tracker (if missing)

> Explainer: The issue tracker is where work tickets live. Skills that create or triage issues need to know whether to call `gh`, write markdown under `.scratch/`, or follow another system.

Default: GitHub if `origin` looks like GitHub; otherwise local markdown.

Options:

- **GitHub** — Issues via `gh` CLI
- **Local markdown** — files under `.scratch/` (or a path the user names)
- **Other** — user describes the workflow in one paragraph

If GitHub: ask whether **external PRs** are a triage surface (default **no**). Optionally ask for **integration branch** if PRs do not land on the repo default (default: leave seed as `main` / user override).

Draft from [issue-tracker-github.md](./issue-tracker-github.md) or [issue-tracker-local.md](./issue-tracker-local.md), or freeform for Other.

#### Section B — Triage labels (if missing)

> Explainer: Work moves through roles (needs evaluation, waiting on reporter, ready for agent, ready for human, won't fix). Skills apply labels that must match strings this repo actually uses.

Roles: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`.  
Default: label string equals role name. Ask for overrides.

Draft from [triage-labels.md](./triage-labels.md).

#### Section C — Domain docs (if missing)

> Explainer: Some skills read domain language and ADRs. They need single-context vs multi-context layout.

- **Single-context** (default) — `CONTEXT.md` + `docs/adr/` at root
- **Multi-context** — `CONTEXT-MAP.md` pointing at per-context files

Do not require creating `CONTEXT.md` for READY. Draft from [domain.md](./domain.md).

**Done when:** every missing policy piece has a user-accepted draft (or user aborted that piece).

### 4. Confirm and write policy

Show the user a draft of each **new or empty** policy file. Let them edit before writing.

Write only after confirm:

- `docs/agents/issue-tracker.md`
- `docs/agents/triage-labels.md`
- `docs/agents/domain.md`

**Never** overwrite non-empty policy without explicit confirmation to replace.

**Done when:** policy files that were missing/empty are written or still listed as blocked.

### 5. Repair runtime (safe auto-repair)

No confirm unless something surprising exists:

1. Create `.agent-workflows/logs/` if missing; ensure empty `.gitkeep` inside.
2. If `.agent-workflows/progress.md` is **missing**, copy [progress.template.md](./progress.template.md). If it exists, **never** wipe the body.
3. Ensure `.gitignore` includes these lines (append missing only; create `.gitignore` if absent):

```gitignore
# agent-workflows runtime (local session state)
.agent-workflows/progress.md
.agent-workflows/logs/*
!.agent-workflows/logs/.gitkeep
```

**Done when:** checklist items 4–6 would be present if re-checked now.

### 6. Optional project pointer

If `AGENTS.md` or `CLAUDE.md` exists and has no pointer to `.agent-workflows/`:

- Prefer the file that already exists; if both, prefer `AGENTS.md`.
- **Offer** a short section; write only on yes. Not required for READY.
- Do **not** mention `/init-workflows` or other slash names here — this skill is user-invoked only (`disable-model-invocation: true`); AGENTS should not nudge the model to call it.
- Do **not** duplicate policy already covered under an existing Agent skills / docs/agents section. If policy is already documented, offer **runtime only**.

Runtime-only (when policy is already elsewhere):

```markdown
## Agent workflows

- Runtime: `.agent-workflows/` (`progress.md`, `logs/`)
```

Full pointer (only if policy is not already documented in the same file):

```markdown
## Agent workflows

- Policy: `docs/agents/` (issue tracker, triage labels, domain)
- Runtime: `.agent-workflows/` (`progress.md`, `logs/`)
```

If neither file exists, skip unless the user asks to create one.

**Done when:** offer handled (accepted, declined, or N/A).

### 7. Re-audit and done

Re-check **every** checklist row on disk (exhaustive — not from memory of step 2). Print:

```text
agent-workflows status
- issue-tracker: present|missing|drift
- triage-labels: present|missing|drift
- domain: present|missing|drift
- progress.md: present|missing|drift
- logs/: present|missing|drift
- gitignore: present|missing|drift
- overall: READY | NOT READY
```

If READY: engineering skills can use `docs/agents/*`; append session notes to `.agent-workflows/progress.md` as needed. Re-run this skill anytime to re-ensure.  
If NOT READY: list exact remaining gaps.

**Done when:** final status printed after on-disk re-audit.
