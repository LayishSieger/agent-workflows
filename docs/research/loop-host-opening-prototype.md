# Loop / host opening prototype (throwaway)

**Ticket:** [Loop and host opening clarity principles](https://github.com/LayishSieger/agent-workflows/issues/24)  
**Map:** [Wayfind: make agent-workflows clearer and more approachable](https://github.com/LayishSieger/agent-workflows/issues/18)  
**Branch:** `prototype/loop-host-openings`  
**Purpose:** Cheap first-screen stubs to react to. Presentation only — tick semantics unchanged. Not shipping copy.

---

## How to read this

Each **Variant** is a first ~screenful (title through Modes / Primary entry). Later skill body (Process, Claim/publish, spawn resolution detail) stays; only the *opening* moves.

YAML `description:` strings are out of scope here → [Skill YAML description strings for discoverability](https://github.com/LayishSieger/agent-workflows/issues/26).

---

## A — Shared job (recommended)

Same job on both doors: **purpose → sibling one-liner → how you run it here**. Demote hard-break + full `outcome:` below the fold.

### `loop-workflows` — Variant A

```markdown
# Loop workflows

Run **one ready issue** through to a pull request you can review — in this chat.

That pass is a **tick**: claim the issue so other agents skip it, implement it, then **publish** (open the PR and hand it back to a human). The shell path runs the same tick via `host-workflows`.

Call **op names** and triage **role names** only. Tracker CLIs live in product policy (`docs/agents/issue-tracker.md`). Do **not** invent tracker recipes here.

**Not** a shell host. Does not merge PRs, close issues as done, create tickets, or re-queue work.

## Modes

| Mode | How | Behavior |
|------|-----|----------|
| **once** (default) | `/loop-workflows` | Exactly one tick **in this session** |
| **max N** | e.g. `max 3` | Parent **only schedules**; each tick is a **fresh** one-tick worker |

No unbounded drain — if you want “until empty,” give an **N** or use **once**.

---
(below the fold: hard-break 0.2→0.3 note, glossary, outcome table, Process…)
```

### `host-workflows` — Variant A

```markdown
# Host workflows

Run up to **N** ready issues from your **terminal**, unattended — one fresh agent session per issue.

Each session runs **exactly one tick** of `loop-workflows` (same claim → implement → publish pass as chat). This skill is only the shell scheduler; it is not the tick recipe.

**Install never runs the host** — you invoke the script when you want AFK.

## Prerequisites

| Need | Why |
|------|-----|
| `loop-workflows` installed for the agent you spawn | Workers run one tick of that skill |
| Product contracts (`docs/agents/*`, `.agent-workflows/`) | Usually via `/init-workflows` |
| A **spawn** command | How the host starts your agent — see below |

## Primary entry

```bash
bash ~/.agents/skills/host-workflows/scripts/host.sh -n 3
```

| Flag | Meaning |
|------|---------|
| `-n N` | Max ticks (default **1**). No unbounded drain. |
| `--spawn CMD` | Override spawn command |
| `--cwd DIR` | Product root (default: cwd) |

If spawn is missing, the host **HARD STOP**s — there is no default agent binary.

---
(below the fold: spawn resolution order, {{PROMPT}}, stop-on-outcome rules…)
```

---

## B — Loop denser “tick home”; host thin pointer

Only if you reject A: loop keeps canonical ownership on screen one; host stays shorter.

### `loop-workflows` — Variant B (opening only)

```markdown
# Loop workflows

**Sole home of the shared tick** and the **chat** entry. Schedulers only count N and stop; the **worker** owns resume | pick → claim → implement → publish → progress.

A **tick** is one pass: claim → implement → publish. Shell AFK uses the same tick via `host-workflows`.

… (modes table same as A; hard-break + outcome still below fold) …
```

### `host-workflows` — Variant B

```markdown
# Host workflows

Shell entry for AFK multi-issue work. Spawns one-shot sessions; each runs **one** `loop-workflows` tick. See that skill for the tick recipe.

## Primary entry
… (same bash block as A; prerequisites compressed to one sentence) …
```

---

## Follow-on stubs (react after A vs B)

These assume **Variant A** unless noted. Each is a separate decision.

### Q2 — Where does the hard-break essay live on loop?

| Option | Opening impact |
|--------|----------------|
| **2a (rec)** | One sentence under Modes: “`max N` always uses fresh workers — not multiple implements in one chat context. Details below.” Full 0.2 essay further down. |
| **2b** | Full hard-break section stays in the first screenful (current). |
| **2c** | Remove from skill body entirely; only `docs/v0.3.md` / CHANGELOG. |

**Stub 2a (Modes footer):**

```markdown
## Modes
…table…

`max N` always schedules **fresh** one-tick workers — the parent does not implement N tickets in one context. (0.2 same-session multi-N is gone; see **Breaking change** below.)
```

### Q3 — Where does the full `outcome:` table live?

| Option | Opening impact |
|--------|----------------|
| **3a (rec)** | Opening glosses only what a skimmer needs: progress records an **`outcome:`** the host/scheduler reads. Full enum after Modes / before Process. |
| **3b** | Keep full enum in the first screenful (current). |
| **3c** | Opening names the three a chat user will usually see first (`SHIPPED`, `NEEDS_INFO`, `COMPLETE`); rest below. |

**Stub 3a (one line in opening):**

```markdown
After each tick, append progress with an **`outcome:`** (machine field the host and schedulers read). Full list under **Glossary**.
```

**Stub 3c:**

```markdown
You’ll usually see **`SHIPPED`** (PR opened for review), **`NEEDS_INFO`**, or **`COMPLETE`** (queue empty). Full `outcome:` list under **Glossary**.
```

### Q4 — How much spawn detail on the host first screen?

| Option | Opening impact |
|--------|----------------|
| **4a (rec)** | First screen: “spawn required → HARD STOP if missing” + primary `-n` command. Resolution order + `{{PROMPT}}` below the fold. |
| **4b** | Keep resolution order + `{{PROMPT}}` in the first screenful (near-current). |
| **4c** | First screen only points at `/init-workflows` for spawn; almost no host-side spawn prose until prerequisites fail. |

**Stub 4a** is what Variant A already shows.

### Q5 — Cross-link tone

| Option | Copy |
|--------|------|
| **5a (rec)** | Affirmative sibling line on both (“same tick via …”), keep a short **Not** list. |
| **5b** | Affirmative only; drop defensive **Not:** / “not the tick” from the opening. |
| **5c** | Keep today’s defensive openings (“Sole home…”, “Not: the tick recipe…”). |

---

## Side-by-side: today vs A (loop)

| Today (first screen) | Variant A |
|----------------------|-----------|
| Sole home of shared tick | Run one ready issue → PR in this chat |
| Schedulers vs worker | Gloss tick + claim/publish in one sentence |
| Design freeze link | Demoted |
| Modes + full hard-break essay | Modes + one-line fresh-worker note |
| Full glossary + full outcome enum | Pointer; tables below fold |

## Side-by-side: today vs A (host)

| Today (first screen) | Variant A |
|----------------------|-----------|
| Shell scheduler / AFK / not the tick | Run N issues from terminal, unattended |
| Defensive Not: list first | Purpose first; Not shortened |
| Prerequisites + Primary entry | Same, slightly plainer |
| Spawn resolution often reaches screen two | Explicitly below fold in A |

---

## Reaction checklist

Reply with letters, e.g. `A, 2a, 3a, 4a, 5a` — or mark edits on the stubs.

1. Opening job: **A** shared / **B** loop denser  
2. Hard-break: **2a** / **2b** / **2c**  
3. Outcome table: **3a** / **3b** / **3c**  
4. Host spawn density: **4a** / **4b** / **4c**  
5. Cross-link tone: **5a** / **5b** / **5c**
