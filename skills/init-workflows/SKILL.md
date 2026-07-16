---
name: init-workflows
description: Ensure a product repo has agent-workflows contracts (policy docs + runtime). Re-entrant audit and repair.
disable-model-invocation: true
---

# Ensure workflows-ready

**Ensure** this product repo meets agent-workflows contracts. Every run is a full **audit**, then **repair** of gaps only. Do not trust marker files or prior "initialized" claims.

**Out of scope:** implementing features, draining issue queues, runners, secrets.

**Leading words:** *ensure* (goal), *audit* (measure), *repair* (fix gaps).

All seeds and rules ship **in this skill directory**. Read sibling files when a step points at them. Never require a separate hub checkout.

## Steps

### 1. Locate product root

- Resolve git root: `git rev-parse --show-toplevel` (or workspace root if not a git repo).
- Note `git remote -v` when present (informs defaults later).
- Work only on the **product** the user has open. If the cwd is only this skill package itself, stop and ask which product repo to ensure.

**Done when:** product root path is known and stated to the user.

### 2. Audit

Read [checklist.md](checklist.md). For every row, status is **present** | **missing** | **drift** (exists but empty or fails "ready when").

Print the full audit table **before** any writes.

**Done when:** every checklist row has a status and the table was shown.

### 3. Interview missing policy (branch)

If checklist items 1–3 are **all present**, skip to step 4.

If any of 1–3 are **missing**, follow [greenfield-interview.md](greenfield-interview.md) for **only** the missing pieces — one decision at a time. Build drafts in memory; **do not write files yet**.

**Done when:** every missing policy file has a confirmed draft (user said the draft is OK), or user aborted that piece.

### 4. Confirm drafts then write policy

For each **new** policy file from step 3:

1. Show the full draft once more.
2. Write only after explicit confirm.
3. Destination names: `docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md`, `docs/agents/domain.md`.

For an **existing** policy file that is drift (empty): show a proposed fill from the matching seed; write only on confirm. Never overwrite non-empty policy without confirm + clear intent to replace.

Seeds live beside this skill:

- [issue-tracker-github.md](issue-tracker-github.md)
- [issue-tracker-local.md](issue-tracker-local.md)
- [triage-labels.md](triage-labels.md)
- [domain.md](domain.md)

**Done when:** every policy file that was missing or empty is either written (after confirm) or still listed as blocked by the user.

### 5. Repair runtime

Apply [overwrite-policy.md](overwrite-policy.md). Safe auto-repair only:

1. Create `.agent-workflows/logs/` if missing; ensure `.gitkeep` inside.
2. If `.agent-workflows/progress.md` is **missing**, copy [progress.template.md](progress.template.md) to that path. If it exists, leave the body untouched.
3. Ensure `.gitignore` contains every line from [gitignore.snippet](gitignore.snippet) (append missing lines only; create `.gitignore` if absent).

**Done when:** checklist items 4–6 would all be **present** if re-audited now (or user blocked a change).

### 6. Optional project pointer

If `AGENTS.md` or `CLAUDE.md` exists and has no pointer to `docs/agents/` and `.agent-workflows/`:

- Prefer the file that already exists; if both, prefer `AGENTS.md`.
- **Offer** a short section; write only on yes. Not required for READY.

```markdown
## Agent workflows

- Policy: `docs/agents/` (issue tracker, triage labels, domain)
- Runtime: `.agent-workflows/` (`progress.md`, `logs/`)
- Re-verify anytime: `/init-workflows`
```

If neither file exists, skip unless the user asks to create one.

**Done when:** offer handled (accepted, declined, or N/A).

### 7. Re-audit and report

Re-read the product tree. Apply [checklist.md](checklist.md) again for **every** row (exhaustive — not from memory of step 2).

Print:

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

If READY: note that engineering skills can use `docs/agents/*` and humans/agents may append to `.agent-workflows/progress.md`.  
If NOT READY: list exact remaining gaps.

**Done when:** final status printed and every checklist row was re-checked on disk.
