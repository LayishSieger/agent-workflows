# Research: GitHub sub-issues and issue dependencies

**Ticket:** [#8](https://github.com/LayishSieger/agent-workflows/issues/8)  
**Repo:** [LayishSieger/agent-workflows](https://github.com/LayishSieger/agent-workflows)  
**Date:** 2026-07-17  
**CLI verified:** `gh` 2.96.0 (2026-07-02)  
**Account:** personal user `LayishSieger` (public repo; token has admin on this repo)

## Executive answer

**Yes — on this repo and account, both native features work end-to-end via `gh` and the REST/GraphQL APIs.**

| Feature | Status on this repo | Preferred agent interface |
| --- | --- | --- |
| **Sub-issues** (parent/child) | Live. Map [#1](https://github.com/LayishSieger/agent-workflows/issues/1) has 8 native sub-issues (#2–#9). | `gh issue create --parent`, `gh issue edit --add-sub-issue` / `--parent` |
| **Issue dependencies** (`blocked_by` / `blocking`) | Live. #5←#3, #6←#4, #7←{#2,#3} confirmed via REST + `gh issue view --json`. | `gh issue create --blocked-by`, `gh issue edit --add-blocked-by` |

No paid plan gate was hit. GitHub documents issue dependencies as available on **GitHub Free, Pro, Team, and Enterprise Cloud**. Sub-issues are GA for Issues/Projects.

**Body-line conventions** (`Part of #N`, `Blocked by: #N`, task lists) remain useful as **human-readable mirrors and fallback**, but they are **not** required for native relationships to exist. Prefer native relationships when available; keep body lines for greppable narrative and offline/local-tracker parity.

---

## Live verification (this repo)

Read-only probes on 2026-07-17 (no junk issues created).

### Sub-issues under map #1

```bash
gh api repos/LayishSieger/agent-workflows/issues/1/sub_issues \
  --jq '[.[] | {number, title, id}]'
```

Result: numbers **2–9** listed as sub-issues of #1.

```bash
gh api repos/LayishSieger/agent-workflows/issues/8/parent \
  --jq '{number, title, id}'
# → number 1

gh issue view 8 --json parent
# → parent.number = 1

gh issue view 1 --json subIssues,subIssuesSummary
# → totalCount 8, percentCompleted 0
```

### Native `blocked_by` on grilling tickets

| Issue | `blocked_by` (native) | Body line (mirror) |
| --- | --- | --- |
| #5 Shell packaging and spawn | #3 | `Blocked by: #3` |
| #6 Publish and claim semantics in policy | #4 | `Blocked by: #4` |
| #7 Skill package shape for 0.3 | #2, #3 | `Blocked by: #2, #3` |

```bash
gh api repos/LayishSieger/agent-workflows/issues/5/dependencies/blocked_by \
  --jq '[.[] | {number, title, id}]'
# → [{number:3, ...}]

gh issue view 5 --json blockedBy,blocking,parent
gh issue view 7 --json blockedBy

# Inverse edges
gh api repos/LayishSieger/agent-workflows/issues/3/dependencies/blocking \
  --jq '[.[] | {number, title}]'
# → #5, #7
```

Issue payload also exposes summaries:

```bash
gh api repos/LayishSieger/agent-workflows/issues/7 \
  --jq '{number, issue_dependencies_summary, parent_issue_url, sub_issues_summary}'
# blocked_by: 2, parent_issue_url points at #1
```

### Search operators (queue filtering)

```bash
gh issue list -R LayishSieger/agent-workflows --search "is:blocked" --json number,title
# → #5, #6, #7

gh issue list -R LayishSieger/agent-workflows --search "is:blocking" --json number,title
# → #2, #3, #4

# Also: blocked-by:<number|url>, is:blocking, etc. (changelog)
```

### GraphQL

Parent / sub-issues / blockedBy / blocking resolve **without** special feature headers on current GA (optional headers still accepted):

```bash
gh api graphql -f query='
query {
  repository(owner:"LayishSieger", name:"agent-workflows") {
    issue(number:1) {
      subIssues(first:20) { nodes { number title } totalCount }
      subIssuesSummary { total completed percentCompleted }
    }
  }
}'

gh api graphql -f query='
query {
  repository(owner:"LayishSieger", name:"agent-workflows") {
    issue(number:5) {
      parent { number title }
      blockedBy(first:10) { nodes { number title } totalCount }
      blocking(first:10) { nodes { number title } totalCount }
    }
  }
}'
```

Historical preview note: early sub-issues GraphQL docs required header `GraphQL-Features: sub_issues`. On this account/date, queries work without it; keep the header if targeting older GHES or if a field 404s.

---

## Exact commands that work

### A. GitHub CLI (preferred for agents on this hub)

Requires **write** access on the repo (collaborator with issues write / push-or-triage as applicable). Verified flag surface on `gh` **2.96.0**:

#### Create with parent and/or dependencies

```bash
# New child under map #1
gh issue create \
  --title "TITLE" \
  --body $'Part of #1\n\n## Question\n...' \
  --label wayfinder:grilling \
  --parent 1

# New issue already blocked by #3 and blocking #9
gh issue create \
  --title "TITLE" \
  --body "..." \
  --parent 1 \
  --blocked-by 3 \
  --blocking 9
```

`--parent`, `--blocked-by`, and `--blocking` accept **issue numbers or URLs**. Comma-separated lists are supported for dependency flags.

#### Edit existing relationships

```bash
# Attach existing issues as sub-issues of parent
gh issue edit 1 --add-sub-issue 8,9

# Or set parent from the child
gh issue edit 8 --parent 1

# Remove parent / sub-issue link
gh issue edit 8 --remove-parent
gh issue edit 1 --remove-sub-issue 8

# Dependencies
gh issue edit 5 --add-blocked-by 3
gh issue edit 5 --add-blocking 10
gh issue edit 5 --remove-blocked-by 3
gh issue edit 5 --remove-blocking 10
```

#### Read relationships

```bash
gh issue view 5                          # human: Parent / Blocked by / Blocking rows
gh issue view 5 --json parent,blockedBy,blocking,subIssues,subIssuesSummary
gh issue view 1 --json subIssues,subIssuesSummary
```

JSON field names (camelCase): `parent`, `subIssues`, `subIssuesSummary`, `blockedBy`, `blocking`.

### B. REST API (`gh api` wrappers)

Numeric **issue `id`** (not number) is required for write bodies. Resolve with:

```bash
BLOCKER_ID=$(gh api repos/LayishSieger/agent-workflows/issues/3 --jq .id)
CHILD_ID=$(gh api repos/LayishSieger/agent-workflows/issues/8 --jq .id)
```

#### Sub-issues

| Op | Method / path | Body |
| --- | --- | --- |
| List children | `GET .../issues/{parent}/sub_issues` | — |
| Get parent | `GET .../issues/{child}/parent` | — |
| Add child | `POST .../issues/{parent}/sub_issues` | `{"sub_issue_id": <id>, "replace_parent": true?}` |
| Remove child | `DELETE .../issues/{parent}/sub_issue` | `{"sub_issue_id": <id>}` |
| Reprioritize | `PATCH .../issues/{parent}/sub_issues/priority` | `{"sub_issue_id": <id>, "after_id"|"before_id": <id>}` |

```bash
# Example shapes (do not run casually on production chart)
gh api -X POST repos/LayishSieger/agent-workflows/issues/1/sub_issues \
  -f sub_issue_id="$CHILD_ID"

gh api -X DELETE repos/LayishSieger/agent-workflows/issues/1/sub_issue \
  -f sub_issue_id="$CHILD_ID"
```

Docs: [REST: sub-issues](https://docs.github.com/en/rest/issues/sub-issues).

#### Issue dependencies

| Op | Method / path | Body |
| --- | --- | --- |
| List blocked-by | `GET .../issues/{n}/dependencies/blocked_by` | — |
| List blocking | `GET .../issues/{n}/dependencies/blocking` | — |
| Add blocked-by | `POST .../issues/{n}/dependencies/blocked_by` | `{"issue_id": <blocker id>}` |
| Remove blocked-by | `DELETE .../issues/{n}/dependencies/blocked_by/{issue_id}` | — |

```bash
# Mark issue #5 as blocked by issue #3
gh api -X POST repos/LayishSieger/agent-workflows/issues/5/dependencies/blocked_by \
  -f issue_id="$BLOCKER_ID"

gh api -X DELETE \
  "repos/LayishSieger/agent-workflows/issues/5/dependencies/blocked_by/$BLOCKER_ID"
```

Docs: [REST: issue dependencies](https://docs.github.com/en/rest/issues/issue-dependencies).

### C. GraphQL mutations (automation)

Sub-issue mutations (IDs are GraphQL node ids, e.g. `I_kwDO...` from `gh issue view N --json id`):

```bash
PARENT=$(gh issue view 1 --json id -q .id)
CHILD=$(gh issue view 8 --json id -q .id)

gh api graphql -f query="
mutation {
  addSubIssue(input: { issueId: \"$PARENT\", subIssueId: \"$CHILD\", replaceParent: true }) {
    issue { number }
    subIssue { number }
  }
}"
```

Also available: `removeSubIssue`, `reprioritizeSubIssue`. Dependency GraphQL mutations may lag CLI/REST; prefer REST or `gh issue edit` for `blocked_by` writes unless schema inspection confirms mutations on the target host.

---

## Limits, permissions, plan

### Product limits (platform)

| Limit | Value | Source |
| --- | --- | --- |
| Sub-issues per parent | **100** | [Adding sub-issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues) |
| Nesting depth | **8** levels | same |
| Parents per issue | **1** (unique parent) | GA / community notes |
| Blocked-by / blocking links per issue | **50** each relationship | [Dependencies GA changelog](https://github.blog/changelog/2025-08-21-dependencies-on-issues/), preview notes |
| Cross-repo sub-issues | Allowed (UI supports other repos under same owner constraints for REST `sub_issue_id`) | REST docs note same repository **owner** for add-sub-issue |
| Plan for dependencies | Free / Pro / Team / Enterprise Cloud | [Creating issue dependencies](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-issue-dependencies) (plan availability) |

### Permissions

- **Read** public relationships: no auth required for public repos (REST list endpoints).
- **Write** parent/sub-issue or dependency: authenticated user/app with permission to edit issues (typically **write** or **triage+** on the repo; owner/admin works). `403` if insufficient.
- **Secondary rate limits** apply to rapid create/delete of relationships (documented on POST/DELETE endpoints).
- **Apps / tokens:** classic `repo` or fine-grained **Issues: Read and write**. GraphQL uses the same token as `gh auth`.

### This account / repo

- Owner: personal user `LayishSieger` (not an org).
- Repo: **public**, token has `admin`.
- Features already populated by charting — no opt-in flag required for sub-issues or dependencies as of verification date.
- `gh api user --jq .plan` returned null for this token shape; plan gate was not observed in practice (Free includes dependencies per docs).

### CLI version note

Native flags (`--parent`, `--add-sub-issue`, `--add-blocked-by`, …) are present in **gh 2.96.x**. Older `gh` may only expose REST via `gh api`. Agents should treat **minimum gh with relationship flags** as a preflight, or fall back to REST.

---

## Fallback when native features fail

Use when: GHES without GA features, insufficient permissions, API 404/403, offline local tracker, or body-only policies.

### 1. Body conventions (already used on this chart)

```markdown
Part of #1
Blocked by: #3
```

Multi-blocker:

```markdown
Blocked by: #2, #3
```

Optional reverse narrative (not required if native blocking exists):

```markdown
Blocking: #5, #7
```

### 2. Task list on the map (chart index)

```markdown
## Children (chart index)

- [ ] #2 v0.3 scope boundary
- [ ] #3 Host–worker session contract
...
```

Closing a child and checking the box is a **manual** progress signal; native `subIssuesSummary.percentCompleted` is authoritative when sub-issues exist.

### 3. Labels / search substitutes

If `is:blocked` is unavailable, agents can:

- Parse body for `^Blocked by:` lines.
- Maintain a label such as `status:blocked` (product policy choice — not currently required here).

### 4. Hybrid recommendation for wayfinding ops

| Concern | Prefer | Also keep |
| --- | --- | --- |
| Map ↔ children | Native parent/sub-issue | Task list + `Part of #N` in body |
| Hard prerequisites | Native `blocked_by` | `Blocked by: #N` body line |
| Queue “what is unblocked?” | `gh issue list --search 'is:issue is:open -is:blocked ...'` | Body parse fallback |
| Local markdown tracker | N/A (no GitHub graph) | Same body/task conventions in files |

Dual-write (native + body) is cheap and improves greppability for humans and for trackers that only see markdown.

---

## Implications for wayfinding ops reliability

1. **Do not invent junk issues** to test relationships; re-verify on existing chart edges (#1 children; #5/#6/#7 deps) as done here.
2. **Claim / queue skills** can filter with `is:blocked` so agents skip work that is natively blocked — more reliable than body regex alone.
3. **Map progress** can use `subIssuesSummary` instead of only checkbox counts when all children are linked as sub-issues.
4. **Policy examples** in `docs/agents/issue-tracker.md` should document:
   - native ops: `set-parent`, `add-sub-issue`, `add-blocked-by`, `list-blocked-by`, `search is:blocked`
   - fallback ops: body `Part of` / `Blocked by` lines + task lists
5. **Id types:** REST write bodies need numeric `id`; GraphQL needs `node_id` / `I_…`; CLI flags accept **numbers**. Document the conversion one-liner in policy.
6. **Idempotency:** re-adding an existing sub-issue or dependency may 422; treat as success-if-already-linked in automation.
7. **One parent only:** moving a ticket under a new map requires `replace_parent: true` (REST) or remove-then-add / `gh issue edit --parent`.

---

## Sources

Primary (docs / changelog):

- [Adding sub-issues](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues) — CLI flags, 100 children / depth 8
- [Creating issue dependencies](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-issue-dependencies) — CLI flags, UI Relationships, plan availability
- [REST API: sub-issues](https://docs.github.com/en/rest/issues/sub-issues)
- [REST API: issue dependencies](https://docs.github.com/en/rest/issues/issue-dependencies)
- [Changelog: Dependencies on issues (GA, 2025-08-21)](https://github.blog/changelog/2025-08-21-dependencies-on-issues/) — search (`is:blocked`, `is:blocking`, `blocked-by:`), 50-link limit
- [Changelog: REST API for sub-issues (2024-12-12)](https://github.blog/changelog/2024-12-12-github-issues-projects-close-issue-as-a-duplicate-rest-api-for-sub-issues-and-more/)
- [Community: Sub-issues public preview / GA discussion](https://github.com/orgs/community/discussions/148714)
- [Community: Evolving GitHub Issues GA](https://github.com/orgs/community/discussions/154148)

Live experiments (this research):

- `gh issue view` / `gh issue list --search` / `gh api` / `gh api graphql` against `LayishSieger/agent-workflows` issues **1–9** on 2026-07-17
- Confirmed existing native edges only (no create/delete of relationships beyond claim assignee on #8)

---

## Command cheat-sheet (copy/paste)

```bash
# --- read ---
gh issue view 1 --json subIssues,subIssuesSummary
gh issue view 5 --json parent,blockedBy,blocking
gh issue list --search "is:open is:blocked"
gh api repos/OWNER/REPO/issues/5/dependencies/blocked_by --jq '[.[].number]'
gh api repos/OWNER/REPO/issues/1/sub_issues --jq '[.[].number]'

# --- write (CLI) ---
gh issue create -t "Title" -b "Part of #1" --parent 1 --blocked-by 3
gh issue edit 1 --add-sub-issue 12
gh issue edit 12 --add-blocked-by 3

# --- write (REST) ---
ID=$(gh api repos/OWNER/REPO/issues/3 --jq .id)
gh api -X POST repos/OWNER/REPO/issues/12/dependencies/blocked_by -f issue_id="$ID"
SID=$(gh api repos/OWNER/REPO/issues/12 --jq .id)
gh api -X POST repos/OWNER/REPO/issues/1/sub_issues -f sub_issue_id="$SID"
```
