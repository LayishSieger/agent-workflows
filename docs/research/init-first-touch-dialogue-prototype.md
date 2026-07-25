# PROTOTYPE — `/init-workflows` first-touch dialogue

**Throwaway.** Answers [Init-workflows first-touch dialogue principles](https://github.com/LayishSieger/agent-workflows/issues/22).  
**Not production copy.** Behavior/contracts unchanged; this is the conversation shape to react to.

Lexicon from [Which terms to soften vs keep precise](https://github.com/LayishSieger/agent-workflows/issues/21).  
Voice from [What does friendly mean for this hub](https://github.com/LayishSieger/agent-workflows/issues/19).  
Friction targets: F3/F4, N1–N5 from cold-session inventory.

---

## Proposed principles (decision draft)

1. **Open with purpose → audit, not architecture.** First agent turn: one purpose sentence (contracts / READY), then the audit table. No ASCII mental-model diagram, location tables, or CLI preset matrix before the table.
2. **Gloss once on first mention.** Opening may introduce **contracts** / **READY** in one plain clause; **tick** / **claim** / **publish** wait until “Next”; **AFK** / **host** / **spawn** only on the shell path.
3. **Explore quietly.** Gather filesystem facts without narrating the Explore checklist to the user. Dump findings only when they change a choice or block READY.
4. **Defer branching until after contracts work.** Policy Batch A (if needed) and runtime repair happen before any **S**/**H** (chat vs shell **AFK**) choice. Letter codes always pair with a plain label the first time in that dialogue.
5. **READY is contracts-only.** Status can show loop/host/spawn as informational. Overall READY does not require autonomy. The optional AFK offer is a *separate* short turn after READY (or after contracts are clearly on track), never interleaved with the audit.
6. **AFK offer is one choice, then deepen.** First: **S** chat only vs **H** shell AFK. Only if **H**: then **G**/**P** scope, then install/spawn. Do not present S/H/G/P as one mega-menu.
7. **Hide shell density until H.** CLI preset table, `{{PROMPT}}`, trust-flag note, dual-install warning — only when the user chose shell AFK (or dual install already exists and must be resolved).
8. **Close with Next, not genealogy.** When READY: short Next (chat `/loop-workflows`, shell host entry if set, planning optional). No version history, hard-break, or full `outcome:` enum.

---

## Stub transcript (cold product, missing policy)

Agent turns only. User replies in `[brackets]`.

### Turn 1 — purpose + audit (always)

> Init gets this product repo to **READY**: **contracts** (policy under `docs/agents/` + runtime under `.agent-workflows/`). Loop/host are optional afterward.
>
> | # | Artifact | Status |
> |---|----------|--------|
> | 1 | `docs/agents/issue-tracker.md` | missing |
> | 2 | `docs/agents/triage-labels.md` | missing |
> | 3 | `docs/agents/domain.md` | missing |
> | 4 | `.agent-workflows/progress.md` | missing |
> | 5 | `.agent-workflows/logs/` | missing |
> | 6 | `.gitignore` runtime lines | missing |
>
> I’ll write the missing policy next (one batch of choices), then repair runtime.

*(No ASCII diagram. No “what lives where”. No spawn/CLI matrix.)*

### Turn 2 — Batch A (only if policy missing)

> Init writes policy under `docs/agents/` and local runtime under `.agent-workflows/`. It does not implement issues or start AFK.
>
> Defaults (reply `ok` to accept all):
> 1. **Tracker** — GitHub (origin looks like GitHub); external PRs as triage: no; integration branch: `main`
> 2. **Labels** — role names as-is (`needs-triage` … `wontfix`)
> 3. **Domain** — single-context (`CONTEXT.md` + `docs/adr/`)
>
> `[ok]`

### Turn 3 — write + repair (quiet)

> Wrote `docs/agents/{issue-tracker,triage-labels,domain}.md`. Created runtime + gitignore runtime lines. Re-audit:

```text
agent-workflows status
- … (rows)
- overall: READY
```

### Turn 4 — optional AFK offer (separate)

> **READY** (contracts in place). Optional: set up **AFK** — unattended shell runs of the same **tick** chat uses.
>
> | Reply | Meaning |
> |-------|---------|
> | **S** / skip / chat | Contracts only. Use `/loop-workflows` in chat when you want. |
> | **H** / shell | Shell AFK: pick where skills live, ensure host + loop, then spawn. |
>
> Recommend **S** unless you want unattended multi-issue from the terminal now.
>
> `[S]`

### Turn 5 — Next

```text
Next
1. Contracts: docs/agents/* (done).
2. Chat: /loop-workflows (needs loop-workflows skill on the agent).
3. Shell AFK: skipped — re-run /init-workflows and choose H when you want it.
4. Planning (optional, separate): e.g. Matt to-spec/to-tickets → ready-for-agent.
```

---

## Stub branch (cold product, already READY, user wants H)

### After status READY → AFK offer → `[H]`

> Where should **host** + **loop** skills live?
>
> | Reply | Scope | When |
> |-------|--------|------|
> | **G** / global | This machine (`~/.agents/skills/…`) | Default for solo / multi-repo |
> | **P** / product | This repo (`.agents/skills/…`) | Team pin |
>
> Recommend **G**.
>
> `[G]`

*(Only now: install cmds, spawn detection, `{{PROMPT}}` / trust-flag reminder, dual-install if present.)*

---

## Anti-stub (do not ship this shape)

> Here’s the mental model:
> ```text
> init-workflows → … [S] … [H] …
> ```
> What lives where: *(table)*. CLI presets: *(matrix)*. AFK note: trust flags…
> Also: are we doing S or H? And G or P? And install/reinstall/skip?
>
> *(Then maybe the audit table.)*

---

## Open for human reaction

- Is Turn 1 the right first screenful (purpose + table only)?
- Is deferring S/H until after READY correct, or should AFK be offered earlier when policy already exists?
- Is recommend-**S** the right default pitch for first-time solo users?
- Anything missing that agents still need on first touch without reintroducing F3/F4?
