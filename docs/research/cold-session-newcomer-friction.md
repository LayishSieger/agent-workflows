# Cold-session friction inventory (newcomer / junior persona)

**Ticket:** [Inventory cold-session friction for newcomers](https://github.com/LayishSieger/agent-workflows/issues/20)  
**Map:** [Wayfind: make agent-workflows clearer and more approachable](https://github.com/LayishSieger/agent-workflows/issues/18)  
**Date:** 2026-07-24  
**Method:** Careful walk (not a live junior agent run) of hub README → install → `/init-workflows` → `/loop-workflows` → shell-host touchpoints, against fixtures + dogfood playbook shape. Judged against [What does friendly mean for this hub](https://github.com/LayishSieger/agent-workflows/issues/19) (engineer-to-engineer clarity; purpose→action; concrete before abstract; demote version/ops density from first screen).

**Persona:** solo first-time installer / new AI engineer / junior who can run `npx` and open a skill, but has never seen this hub. Goal: get a product repo READY, then run one chat tick (and understand the shell path exists).

**Not this ticket:** rewriting copy; choosing soft terms; locking the handoff plan. This inventory feeds later tickets.

---

## Executive shortlist (fix first)

| # | Surface | Friction | Why it bites first |
|---|---------|----------|--------------------|
| F1 | README first screen | Status/version genealogy + design-freeze + dual layer tables before “what do I run” | Violates purpose→action and demotion rules from friendliness decision |
| F2 | README / skills | Dense glossary dump (`tick`, `claim`, `publish`, `outcome:`, dual schedulers, hard break) before a concrete happy path | Competent engineer can act without the control-plane enum on screen one |
| F3 | `init-workflows` opening | Mental-model ASCII + location tables + CLI preset matrix before audit | Agent (and skimming human) pays jargon tax before the checklist |
| F4 | Init optional autonomy | S/H then G/P then install/reinstall/skip — high branching, letter codes | Easy to mis-choose scope or stall; READY vs AFK boundary is clear in prose but heavy in dialogue |
| F5 | `loop-workflows` opening | “Sole home of the shared tick” + 0.2→0.3 hard-break essay + full `outcome:` table | Chat user asking for one issue→PR gets a control-plane brief first |
| F6 | Skill `description` YAML | Abstract (`Ensure…contracts`, `Shared tick + chat scheduler`) | Install-time discovery does not sell the next action |

---

## Journey walk

### 0. Discover the hub (README first viewport)

**What the persona sees first:** “Status: v0.3”, “policy-driven shared tick”, “dual schedulers”, “three packages”, then a `v0.1 → v0.2 → v0.3 → later` ASCII timeline, then two “Layer” tables (contracts/planning/autonomy *and* repo/install/product), then package table, then dual-scheduler tick recipe, then breaking-change table.

**Friction**

| ID | Observation | Severity | Persona reaction |
|----|-------------|----------|------------------|
| R1 | First lines lead with version status and architecture nouns, not the outcome (“take an issue from ready to review”) | High | “Is this a changelog or a product?” |
| R2 | Genealogy ASCII and freeze link occupy early attention | High | Feels like maintainer notes, not onboarding |
| R3 | Two adjacent “Layer” tables with different meanings (“0/1/2” vs “this repo / install / product”) | Medium | Ambiguous mental model; “layer” overloaded |
| R4 | Install section appears ~line 154 — after long explanation of spawn, progress schema, outcomes | High | Doesn’t know the first command for many screens |
| R5 | Chat vs shell relationship is accurate but buried under scheduler jargon | Medium | May pick one path and never notice the other is the same tick |
| R6 | “Optional planning companions” / Matt install is correct scope but early readers may think planning is required | Low–Med | Confusion about whether tickets must come from another pack |

**What works:** Install one-liner exists; Usage block with `/init-workflows` → `/loop-workflows` is concrete when you reach it; out-of-scope list is honest.

---

### 1. Install skills

**Path:** `npx skills add LayishSieger/agent-workflows` (or local clone).

**Friction**

| ID | Observation | Severity | Persona reaction |
|----|-------------|----------|------------------|
| I1 | README says “exact CLI may vary” — softens confidence | Low | Mild uncertainty; recoverable |
| I2 | Global vs product (`-g`) is explained later in init, not at install | Medium | May install project-scoped into hub clone by accident, or miss `-g` for solo machine use |
| I3 | Three packages land at once; no “start with init only” default story on the install line | Low | Overwhelming but not wrong |

**YAML descriptions (skill discovery)**

| Skill | Current description gist | Friction |
|-------|--------------------------|----------|
| init | Ensure contracts; optional CLI install; re-entrant audit | Sounds like ops, not “get this repo ready to run agents” |
| loop | Shared tick + chat scheduler; policy ops only | Opaque to anyone who doesn’t already know “tick” |
| host | Thin sequential shell host; spawn one-shot workers | Accurate; still opaque without “AFK multi-issue from terminal” |

---

### 2. `/init-workflows` first touch

**Opening density (first ~screenful of skill body):** title “Ensure workflows-ready”, contracts-first READY, out-of-scope list, seeds note, ASCII mental model (S/H paths), what-lives-where table, `npx skills add` `-g` note, planning companions, then Process §1 Explore with a long read list and agent-CLI preset table.

**Friction**

| ID | Observation | Severity | Persona reaction |
|----|-------------|----------|------------------|
| N1 | Purpose sentence is good (“Ensure this product…”) but immediately followed by denser architecture | High | Agent may narrate the ASCII diagram to the user instead of auditing |
| N2 | Explore step asks the agent to gather a lot before the audit table — cold sessions dump findings | Medium | Long first reply; user hasn’t seen READY path yet |
| N3 | CLI preset table + `{{PROMPT}}` + AFK trust-flag note appears before Audit | Medium | Shell concerns leak into contracts-only sessions |
| N4 | Letter codes **S/H** then **G/P** then install verbs — efficient for re-entry, cryptic first time | High | “What am I choosing?”; risk of wrong scope |
| N5 | Dual-install warning is important but adds another branch | Medium | Solo user rarely needs this on day one |
| N6 | Batch A interview (tracker/labels/domain) is well designed when policy missing | — | **Positive:** one batch + defaults is low friction |
| N7 | Runtime repair (`progress.md` shell-check, gitignore) is careful and correct | — | **Positive:** avoids wipe footguns; agent may over-explain gitignore noise |
| N8 | READY vs optional autonomy is stated clearly | — | **Positive:** contracts-only path exists |

**Likely agent misbehavior (cold):** over-explain mental model; ask scope/spawn questions before showing the audit table; use jargon (`contracts`, `spawn`, `AFK`) without one-line plain gloss on first mention.

---

### 3. After READY → `/loop-workflows`

**Opening density:** “Sole home of the shared tick”, schedulers vs worker, design freeze link, modes table, **Breaking change (0.2→0.3)** section, full glossary + full `outcome:` enum, then policy discovery, then Process.

**Friction**

| ID | Observation | Severity | Persona reaction |
|----|-------------|----------|------------------|
| L1 | Hard-break essay is maintainer-critical but wrong for first-touch “run one ticket” | High | Anxiety about version; delays the tick |
| L2 | Full control-plane outcome table before preflight | High | Looks like you must memorize SHIPPED/COMPLETE/… to start |
| L3 | “Claim / publish product meaning” deferred to later sections — good depth, but opening still jargon-heavy | Medium | Terms appear before definitions |
| L4 | Empty-queue COMPLETE + hint to create tickets is correct | Low | Persona may not know planning skills are separate (README says so; skill opening is quieter) |
| L5 | once vs max N is clear when you reach Modes | — | **Positive:** no unbounded drain is easy to grasp |

**Shell-host touchpoints noted from loop:** skill correctly defers to `host-workflows`; cold chat user may never open host skill and thus never see how AFK relates.

---

### 4. Shell host (`host-workflows` / `host.sh`)

**Opening:** Shell scheduler for AFK; not the tick; install never runs host; prerequisites table; primary bash entry; spawn resolution; HARD STOP if missing spawn.

**Friction**

| ID | Observation | Severity | Persona reaction |
|----|-------------|----------|------------------|
| H1 | Strong “not the tick / not a fleet” positioning — accurate, slightly defensive | Low–Med | Fine for engineers; first line could still be purpose (“run N one-shot ticks from the shell”) |
| H2 | Spawn resolution + `{{PROMPT}}` + human-owned trust flags — necessary complexity | Medium | Biggest real AFK cliff; init helps but README spawn examples are deep |
| H3 | Relationship “same tick as `/loop-workflows`” is present | — | **Positive** when read; easy to miss if user only skimmed README genealogy |

---

### 5. Dogfood / fixture path (yardstick notes)

Dogfood assumes hub familiarity (Tier matrix, product≠hub, scope P, Grok spawn). A **junior dogfood runner** hits maintainer gates, not newcomer onboarding — useful as acceptance later, **not** as the first-touch narrative.

Fixture product is minimal and clear — good. Playbook density is for agents verifying the pack, not for teaching the mental model.

---

## Term heat map (for later softening ticket)

Observed on first-touch surfaces without a required plain gloss at first sight:

| Term / phrase | Where it hits early | Keep precise? (inventory guess only) |
|---------------|---------------------|--------------------------------------|
| `tick` | README, all skills | Likely keep; needs first-touch gloss |
| `claim` / `publish` | README tick recipe, loop glossary | Keep; soften first explanation |
| `outcome:` | README control plane, loop table | Keep machine field; demote full enum |
| contracts / READY | init | Keep; plain “policy docs + runtime” first |
| dual schedulers / shared tick | README | Soften to “chat or shell, same workflow” |
| AFK | init offer | Soften to “unattended shell” once |
| spawn / `{{PROMPT}}` | README mid, init, host | Keep for AFK path; hide until H chosen |
| hard break 0.2→0.3 | README + loop opening | Demote off first screen |
| ops / policy ops | skill descriptions | Soften in discovery strings |
| S/H/G/P letter codes | init dialogue | Keep for speed; add one-line plain labels |

---

## Surfaces that already match the friendliness bar

- Init **Batch A** defaults + single batch when policy missing
- Init **never wipe** `progress.md` / no silent policy overwrite
- Explicit **no unbounded drain**
- Host **never** silent-default spawn binary
- Usage one-liners once you scroll to them
- Clear out-of-scope boundaries (planning not bundled; no fleets)

---

## Implications for the map (fog graduation hints)

1. Soft-term work should prioritize **first-screen demotion** of genealogy, freeze banners, and full `outcome:` tables — not inventing a parallel junior dialect.
2. Init dialogue principles should target **audit table before architecture**, and **plain labels beside S/H/G/P**.
3. README first-screen narrative should open with purpose + install/usage, relate chat↔shell in one concrete sentence, link deeper internals.
4. Loop/host openings should teach **one tick / once vs max N / shell = same tick** before control-plane enums and version essays.
5. Dogfood remains the **pass bar**, not the teaching surface.

---

## Method limits

- No live junior-agent transcript this session; friction is inferred from surface order, density, and likely agent narration habits.
- Did not re-run throwaway GH dogfood end-to-end for this ticket (suite is maintainer-oriented; would not change first-touch inventory much).
- Severity is relative to the friendliness decision, not a user study.
