# Issue tracker: local markdown

Issues and PRDs for this repo live as markdown files under `.scratch/` (or a path you document below).

This seed keeps the **same v0.3 op headings** as the GitHub reference instance. Bodies are **stubs** — local is not a proven 0.3 runtime; fill Steps when you adopt local-markdown ticks.

## Conventions

- **Create**: write a new markdown file under the issues root with title, body, and labels as used by this team
- **Read / list / comment**: edit those files; no remote API required
- **Labels**: encode in filename, frontmatter, or a labels section — stay consistent

## Issues root

`.scratch/issues/` _(adjust if different)_

---

# Ops contract (v0.3)

Each section: **Input** / **Steps** / **Success** / **Failure**.  
Shared failure words: **HARD_STOP** | **SOFT_SKIP** | **NEEDS_INFO** | **OK**.

## preflight

- **Input:** Product repo root; issues root path from this file.
- **Steps:** _(stub — not proven in 0.3)_ Verify issues root exists and is writable; confirm policy files present.
- **Success:** Local tracker usable → **OK**.
- **Failure:** Missing root or unreadable tree → **HARD_STOP**.

## integration-base

- **Input:** Optional documented default branch for this product.
- **Steps:** _(stub)_ Return configured integration branch or `main` / git default.
- **Success:** Concrete branch name → **OK**.
- **Failure:** Cannot resolve base → **HARD_STOP**.

## list-queue

- **Input:** Ready-queue role string from `triage-labels.md`.
- **Steps:** _(stub)_ List open issues under issues root with ready-for-agent, oldest first. Thin list only.
- **Success:** Ordered list (possibly empty) → **OK**.
- **Failure:** Unreadable issues root → **HARD_STOP**.

## read-ticket

- **Input:** Ticket id / path.
- **Steps:** _(stub)_ Read file: title, body, labels, comments. Read open blockers from body `Blocked by:` (or equivalent frontmatter).
- **Success:** Ticket fields and blocker status known → **OK**.
- **Failure:** Missing file → **HARD_STOP** / skill SOFT_SKIP as appropriate.

## comment

- **Input:** Ticket id; markdown body.
- **Steps:** _(stub)_ Append a comment section or dated note on the issue file.
- **Success:** Note persisted → **OK**.
- **Failure:** Write failure → **HARD_STOP**.

## label-transition

- **Input:** Ticket id; target canonical role.
- **Steps:** _(stub)_ Set exclusive triage role in frontmatter/filename/labels section; remove other four roles; leave non-triage labels.
- **Success:** Exactly one triage role remains → **OK**.
- **Failure:** Cannot update labels → **HARD_STOP**.

## claim

- **Input:** Ticket id; ready-for-agent role string.
- **Steps:** _(stub)_ Claim comment + remove ready-for-agent only (leave-queue). No `claimed` role.
- **Success:** Left queue + comment → **OK**.
- **Failure:** Race / already taken → **SOFT_SKIP**. Infra → **HARD_STOP**.

## detect-publish-artifact

- **Input:** Ticket id.
- **Steps:** _(stub)_ Detect open review handoff for this ticket (e.g. linked PR note, review branch marker). Non-draft “open for review” only.
- **Success:** Present or absent reported → **OK**.
- **Failure:** Cannot inspect → **HARD_STOP**.

## incomplete-claim

- **Input:** Issues root; local branches; role strings.
- **Steps:** _(stub)_ Mid-flight = left ready queue, not ready-for-human, no open publish artifact; and/or `feat/<id>-*` branch. At most one resume; prefer tracker mid-flight over branch-only.
- **Success:** Zero or one resume target → **OK**.
- **Failure:** Unreadable state → **HARD_STOP**.

## create-publish-artifact

- **Input:** Ticket id; change summary; integration base.
- **Steps:** _(stub)_ Create durable review handoff linked to ticket (product-defined: PR link file, review request note, etc.). Do not merge or close-as-done.
- **Success:** Inspectable artifact id/URL → **OK** (then ready-for-human + SHIPPED).
- **Failure:** Cannot create → **NEEDS_INFO** path; tooling broken may be **HARD_STOP**.

---

## When a skill says "publish to the issue tracker"

Create or update a markdown issue file under the issues root.

## When a skill says "fetch the relevant ticket"

Read the corresponding markdown file (**read-ticket**).
