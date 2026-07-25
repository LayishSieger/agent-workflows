# Clarity plan

Handoff from [Wayfind: make agent-workflows clearer and more approachable](https://github.com/LayishSieger/agent-workflows/issues/18).  
**This file is the ordered clarity plan.** It does not ship the rewrites; it tells an implementer what to change, in what order, and how to know it's done.

## Goal

Make this hub approachable for solo first-time installers, new AI engineers, and junior developers: human-facing docs (especially the README first screen) **and** in-skill agent UX (`init-workflows` first, then `loop-workflows` / `host-workflows`). Chat loop and shell host stay both first-class and clearly related (same tick, different scheduler). Pass bar: a careful-walk cold-session with a junior/newcomer persona.

## Constraints

- **Do not** change v0.3 tick, ops contract, claim/publish, or progress `outcome:` semantics
- **Do not** rename packages or slash-commands
- Presentation / flow / copy only
- Voice: engineer-to-engineer clarity (Matt-Pocock-style), not beginner-targeted — see [What does friendly mean for this hub](https://github.com/LayishSieger/agent-workflows/issues/19)
- Lexicon: canonical terms + first-appearance gloss; no parallel soft vocabulary — see [Which terms to soften vs keep precise](https://github.com/LayishSieger/agent-workflows/issues/21)

## Voice & lexicon (summary)

| Rule | Source |
|------|--------|
| Purpose → action; concrete before abstract | #19 |
| Introduce a term once (plain clause + term), then use it | #19, #21 |
| Same voice for humans and agents | #19 |
| Deny first screen to version history, design-freeze banners, ops-contract density | #19 |
| First-touch must gloss: tick, claim, publish, contracts·READY, chat↔shell | #21 |
| Gate off openings: `outcome:` enum, host/spawn/`{{PROMPT}}`, AFK, S/H/G/P mega-menus, “dual schedulers” / “policy ops” / hard-break essay | #21 |

## Implementation order

Four independently shippable PRs. YAML `description` strings ride with their skill; doc tops are separate from the README rewrite.

### Step 1 — `init-workflows` dialogue (+ its YAML description)

**Files:** `skills/init-workflows/SKILL.md`  
**Decisions:** [Init-workflows first-touch dialogue principles](https://github.com/LayishSieger/agent-workflows/issues/22), [Skill YAML description strings for discoverability](https://github.com/LayishSieger/agent-workflows/issues/26)  
**Asset:** `docs/research/init-first-touch-dialogue-prototype.md` on `prototype/init-first-touch-dialogue`

**Done when:**

- Turn 1 = purpose + audit table only (no ASCII mental model / location tables / CLI presets before audit)
- Explore is silent; AFK offered only after READY; recommend **S**; **S/H** then (if H) **G/P**
- Shell density only after H; Next is short (no genealogy / `outcome:` enum)
- Frontmatter `description:`:
  > Get a product repo ready for agent-workflows — audit what's missing, repair it, then optionally install the chat and shell runners.

### Step 2 — README (+ Tier 1 needle refresh)

**Files:** `README.md`; update stale needles in `tests/dogfood/check-docs.sh` (and related Tier 1 docs checks) that the rewrite invalidates — not a suite redesign  
**Decisions:** [README first-screen narrative](https://github.com/LayishSieger/agent-workflows/issues/23), [Newcomer cross-links to docs/v0.x and CHANGELOG](https://github.com/LayishSieger/agent-workflows/issues/27) (closing pointer only)  
**Asset:** `docs/research/readme-first-screen-prototype.md` on `prototype/readme-first-screen`

**Done when:**

- First screen = outcome line → package table → three-step quickstart; chat + shell side by side in the run step (full host command + spawn caveat)
- All five first-touch terms glossed above the fold
- Section order: first screen → How it works → Why this exists → The three skills → What lands in your repo → Out of scope · License · closing maintainer pointer
- No Internals section; no genealogy / freeze / breaking-change table in the onboarding body
- Closing line (near Out of scope / License):
  > For maintainers and contributors: see the [changelog](./CHANGELOG.md) and [design history](./docs/v0.3.md).
- Dogfood Tier 1 needles that asserted the old README framing are updated to match

### Step 3 — `loop-workflows` + `host-workflows` openings (+ their YAML descriptions)

**Files:** `skills/loop-workflows/SKILL.md`, `skills/host-workflows/SKILL.md`  
**Decisions:** [Loop and host opening clarity principles](https://github.com/LayishSieger/agent-workflows/issues/24), [Skill YAML description strings for discoverability](https://github.com/LayishSieger/agent-workflows/issues/26)  
**Asset:** `docs/research/loop-host-opening-prototype.md` on `prototype/loop-host-openings` (Variant A)

**Done when:**

- Both openings: purpose → “same tick, two doors” → how you run it here
- tick / claim / publish glossed once inline; hard-break one-liner under Modes; full `outcome:` enum and host spawn/`{{PROMPT}}` below the fold
- Affirmative sibling links; short `Not:` after purpose
- Frontmatter `description:` strings:
  - **loop-workflows:** Run one ready issue through to a pull request you can review — in this chat.
  - **host-workflows:** From the terminal, run up to N ready issues one after another, unattended.

### Step 4 — Doc tops (cold-lander notices)

**Files:** `CHANGELOG.md`, `docs/v0.3.md`, `docs/v0.1.md`, `docs/v0.2.md`  
**Decision:** [Newcomer cross-links to docs/v0.x and CHANGELOG](https://github.com/LayishSieger/agent-workflows/issues/27)

**Done when** these one-liners are present under each title:

| File | Line |
|------|------|
| `CHANGELOG.md` | Records project changes for maintainers and upgraders. To install and use agent-workflows, start with the [README](./README.md). |
| `docs/v0.3.md` | Current design reference for agent-workflows. This is not a getting-started guide; to install and use the skills, start with the [README](../README.md). |
| `docs/v0.1.md` / `v0.2.md` | Historical design freeze, superseded by [v0.3](./v0.3.md). Do not implement against this version; start with the [README](../README.md). |

## Acceptance

Careful-walk checklist (same method as the friction inventory). Not “Tier 1 green as-is”; not a live junior-agent run required for handoff.

1. **README first viewport** — outcome → packages → quickstart; five glosses; no genealogy / freeze / Internals; closing maintainer pointer only
2. **Cold `/init-workflows`** — purpose + audit before branching; no ASCII genealogy dump; short Next
3. **Cold loop + host openings** — Variant A job; gloss once; hard-break / full `outcome:` / spawn-`{{PROMPT}}` below the fold
4. **YAML descriptions** — match the three decided strings
5. **Doc tops** — the four cold-lander lines present
6. **Contracts unchanged** — no ops / package-name / `outcome:` meaning edits
7. **Tier 1 needles** refreshed where the README rewrite invalidated them (not a suite redesign)

Friction baseline: [Inventory cold-session friction for newcomers](https://github.com/LayishSieger/agent-workflows/issues/20) / `docs/research/cold-session-newcomer-friction.md` on `research/cold-session-friction`.

## Decision index

| Ticket | Gist |
|--------|------|
| [What does friendly mean for this hub](https://github.com/LayishSieger/agent-workflows/issues/19) | Engineer-to-engineer clarity; voice rules; presentation only |
| [Inventory cold-session friction for newcomers](https://github.com/LayishSieger/agent-workflows/issues/20) | Careful-walk inventory of first-screen / init / loop friction |
| [Which terms to soften vs keep precise](https://github.com/LayishSieger/agent-workflows/issues/21) | Canonical terms + first-appearance gloss; gate control-plane density |
| [Init-workflows first-touch dialogue principles](https://github.com/LayishSieger/agent-workflows/issues/22) | Purpose+audit first; silent explore; AFK after READY; S/H then G/P |
| [README first-screen narrative](https://github.com/LayishSieger/agent-workflows/issues/23) | Outcome → packages → quickstart; README-only onboarding |
| [Loop and host opening clarity principles](https://github.com/LayishSieger/agent-workflows/issues/24) | Variant A shared opening job; demote hard-break / enum / spawn density |
| [Ordered clarity-plan handoff shape](https://github.com/LayishSieger/agent-workflows/issues/25) | This file: sections, four-step order, acceptance |
| [Skill YAML description strings for discoverability](https://github.com/LayishSieger/agent-workflows/issues/26) | Plain install-discovery one-liners; coordinated prepare → chat → shell |
| [Newcomer cross-links to docs/v0.x and CHANGELOG](https://github.com/LayishSieger/agent-workflows/issues/27) | Closing README pointer; cold-lander tops on CHANGELOG / v0.x |

## Assets

| Asset | Branch |
|-------|--------|
| `docs/research/cold-session-newcomer-friction.md` | `research/cold-session-friction` |
| `docs/research/init-first-touch-dialogue-prototype.md` | `prototype/init-first-touch-dialogue` |
| `docs/research/readme-first-screen-prototype.md` | `prototype/readme-first-screen` |
| `docs/research/loop-host-opening-prototype.md` | `prototype/loop-host-openings` |
