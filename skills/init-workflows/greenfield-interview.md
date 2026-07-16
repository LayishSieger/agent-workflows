# Greenfield interview (missing policy only)

Run **only** for checklist items 1–3 that are missing. One section at a time: explainer → options → user answer → next. Assume the user may not know the terms.

Do not write files here — produce drafts for the parent skill’s confirm-then-write step.

---

## A — Issue tracker (if `issue-tracker.md` missing)

**Explainer:** The issue tracker is where work tickets live. Skills that create or triage issues need to know whether to call `gh`, write markdown under `.scratch/`, or follow another system.

**Default:** If `git remote` points at GitHub, propose GitHub. Otherwise propose local markdown.

**Options:**

1. **GitHub** — GitHub Issues via `gh`
2. **Local markdown** — files under `.scratch/` (or a path the user names)
3. **Other** — user describes the workflow in one paragraph (freeform doc)

If **GitHub** (or GitLab-style remote with a CLI): ask whether **external PRs** are a triage surface (default **no**).

**Draft from:**

- GitHub → [issue-tracker-github.md](issue-tracker-github.md) (set PRs line to yes/no from the answer)
- Local → [issue-tracker-local.md](issue-tracker-local.md) (adjust issues root if user named another path)
- Other → freeform markdown capturing create/read/comment/label operations

**Section done when:** user has chosen a tracker (and PR surface if applicable) and accepted the draft text.

---

## B — Triage labels (if `triage-labels.md` missing)

**Explainer:** Incoming work moves through roles: needs evaluation, waiting on reporter, ready for an agent, ready for a human, or won’t fix. Skills apply labels (or equivalents) that must match strings this repo actually uses.

**Canonical roles:**

- `needs-triage` — maintainer needs to evaluate
- `needs-info` — waiting on reporter
- `ready-for-agent` — fully specified; agent may implement
- `ready-for-human` — needs human implementation or review
- `wontfix` — will not be actioned

**Default:** each role’s label string equals its name. Ask for overrides.

**Draft from:** [triage-labels.md](triage-labels.md) with the right-hand column filled from the user’s mapping.

**Section done when:** user accepted the label table draft.

---

## C — Domain docs (if `domain.md` missing)

**Explainer:** Some skills read domain language and past decisions. They need to know whether this repo has one context or several.

**Options:**

- **Single-context** (default) — `CONTEXT.md` + `docs/adr/` at repo root
- **Multi-context** — `CONTEXT-MAP.md` pointing at per-context `CONTEXT.md` files

Do **not** require creating `CONTEXT.md` for READY.

**Draft from:** [domain.md](domain.md); set the “This repo” layout line from the choice.

**Section done when:** user accepted the domain draft.
