---
name: init-workflows
description: >-
  Ensure a product repo is ready for agent-workflows: audit and repair
  docs/agents policy files, .agent-workflows progress/logs, and gitignore.
  Re-entrant — every invoke checks the full checklist; does not trust marker
  files. Use when setting up agent-workflows, running /init-workflows, or
  verifying a repo has workflows contracts. Does not implement features or
  drain issue queues.
disable-model-invocation: true
---

# Init workflows (ensure ready)

**Purpose:** Make (or re-verify) a **product** repository compatible with agent-workflows contracts.

This skill is **re-entrant**. Every invocation **audits** concrete artifacts and **repairs gaps**. Do **not** treat a marker file, `.initialized`, or a one-line README as proof of health.

**Not in scope:** implementing issues, AFK/queue drain, runners, Sandcastle, writing secrets.

Hub reference (templates live next to this skill in the agent-workflows repo):

- `templates/docs/agents/*`
- `templates/agent-workflows/*`
- Design: `docs/v0.1.md` in the hub

If you cannot find the hub checkout, use the embedded checklist and recreate template content from the sections below (or ask the user for the path to `agent-workflows`).

---

## Overwrite policy

| Kind | Action |
|------|--------|
| Missing directory (`logs/`) | Create |
| Missing `progress.md` | Create from template |
| Existing `progress.md` body | **Never** wipe or rewrite entries |
| Missing gitignore lines | Append only the missing lines |
| Missing `docs/agents/*` policy file | Create after interactive decisions (greenfield) or from confirmed defaults |
| Existing policy file content | **Do not** overwrite without explicit user confirmation (show proposed change first) |
| AGENTS.md / CLAUDE.md | **Optional offer only** — not required for ready |

Safe auto-repair = gitignore lines, empty `logs/` + `.gitkeep`, create missing `progress.md` only if absent.

---

## Process

### 1. Locate product root

- Prefer current workspace git root (`git rev-parse --show-toplevel`)
- Note `git remote -v` if present
- Abort if not inside a product project (do not scaffold into the agent-workflows hub unless the user explicitly wants the hub treated as a product)

### 2. Resolve template source

Prefer reading files from the agent-workflows hub:

1. `~/projects/agent-workflows/templates/...` (or `~/Projects/agent-workflows/...`)
2. Path the user provides
3. Fallback: content under [Template fallbacks](#template-fallbacks) in this skill

### 3. Audit (always — full checklist)

Check each item. Record status: **present** | **missing** | **drift** (exists but empty/broken in a defined way).

| # | Artifact | Ready when |
|---|----------|------------|
| 1 | `docs/agents/issue-tracker.md` | File exists and is non-empty |
| 2 | `docs/agents/triage-labels.md` | File exists and is non-empty |
| 3 | `docs/agents/domain.md` | File exists and is non-empty |
| 4 | `.agent-workflows/progress.md` | File exists |
| 5 | `.agent-workflows/logs/` | Directory exists (optional `.gitkeep` inside) |
| 6 | `.gitignore` | Contains ignore rules for progress and logs (see template snippet) |

**Not required:** AGENTS.md / CLAUDE.md section.

Print a short audit table before changing anything.

### 4. Branch: greenfield vs existing policy

**If any of 1–3 are missing:**

Run **interactive setup** for missing pieces only, **one decision at a time** (explain → options → user answer → next). Do not dump all questions at once.

#### 4a. Issue tracker (if `issue-tracker.md` missing)

Explain: skills need to know where issues live.

Options:

1. **GitHub** (default if `origin` is GitHub) — `gh` CLI
2. **Local markdown** — files under `.scratch/` (or user path)
3. **Other** — user describes in one paragraph; write freeform `issue-tracker.md`

If GitHub: ask whether external PRs are a triage surface (default **no**).  
Write `docs/agents/issue-tracker.md` from the matching template; show draft; confirm before write.

#### 4b. Triage labels (if `triage-labels.md` missing)

Explain: five roles — needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix.

Default: label string equals role name. Ask for overrides.  
Write from `triage-labels.md` template; confirm before write.

#### 4c. Domain (if `domain.md` missing)

Explain: where CONTEXT / ADRs live.

Default: **single-context**. Offer multi-context if needed.  
Write from `domain.md` template; confirm before write.  
Do not require creating `CONTEXT.md` for ready (optional mention).

**If 1–3 all present:** skip the interview; never overwrite those files without confirmation.

### 5. Repair runtime (4–6)

Without asking, unless something surprising exists:

1. `mkdir -p .agent-workflows/logs`
2. Ensure `.agent-workflows/logs/.gitkeep` exists (empty file is fine)
3. If `.agent-workflows/progress.md` **missing**, copy the progress template
4. If `progress.md` **exists**, leave body untouched
5. Ensure `.gitignore` includes the snippet lines (append missing lines only; create `.gitignore` if absent)

### 6. Optional AGENTS / CLAUDE offer

If `AGENTS.md` or `CLAUDE.md` exists and has no pointer to agent-workflows / `docs/agents` / `.agent-workflows`:

- Offer a short section (do not add unless user says yes)
- Prefer editing whichever file already exists; if both exist, prefer `AGENTS.md`
- If neither exists, do not create one unless the user asks

Suggested section (only if accepted):

```markdown
## Agent workflows

This repo uses [agent-workflows](https://github.com/LayishSieger/agent-workflows) contracts (when published).

- Policy: `docs/agents/` (issue tracker, triage labels, domain)
- Runtime: `.agent-workflows/` (`progress.md`, `logs/`)
- Setup / audit: `/init-workflows` (re-run anytime to verify)
```

### 7. Final status

Re-run the checklist mentally and report:

```text
agent-workflows status
- issue-tracker: present|missing
- triage-labels: present|missing
- domain: present|missing
- progress.md: present|missing
- logs/: present|missing
- gitignore: ok|missing lines
- overall: READY | NOT READY (list gaps)
```

If READY: tell the user they can use engineering skills that read `docs/agents/*`, and append to `.agent-workflows/progress.md` as they work.  
If NOT READY: list exact remaining actions.

---

## Template fallbacks

Use when hub templates are unavailable.

### progress.md

```markdown
# Agent workflows — progress log

Structured session notes for this product repo. Append new entries at the top (newest first).

---

## Template (copy for each session)

### YYYY-MM-DD — short title

- **What:** …
- **Outcome:** …
- **Learnings:** …

---

## Entries

<!-- Newest first -->
```

### gitignore lines

```gitignore
# agent-workflows runtime (local session state)
.agent-workflows/progress.md
.agent-workflows/logs/*
!.agent-workflows/logs/.gitkeep
```

### Policy seeds

Prefer hub files:

- `templates/docs/agents/issue-tracker-github.md`
- `templates/docs/agents/issue-tracker-local.md`
- `templates/docs/agents/triage-labels.md`
- `templates/docs/agents/domain.md`

If missing, write minimal non-empty stubs covering: how to create/read issues; the five label roles; single-context domain paths (`CONTEXT.md`, `docs/adr/`).

---

## Done criteria

- Audit table shown at least once per invoke
- No blind trust in markers
- No wipe of existing `progress.md` or policy docs without confirm
- Final READY / NOT READY status printed
