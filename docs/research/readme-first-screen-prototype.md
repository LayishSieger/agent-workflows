# PROTOTYPE — README first screen

**Throwaway.** Answers [README first-screen narrative](https://github.com/LayishSieger/agent-workflows/issues/23).
**Not production copy.** Nothing here ships from this map; it exists to be reacted to.

Voice from [What does friendly mean for this hub](https://github.com/LayishSieger/agent-workflows/issues/19).
Lexicon from [Which terms to soften vs keep precise](https://github.com/LayishSieger/agent-workflows/issues/21).
Friction targets: R1–R6, F1/F2 from [Inventory cold-session friction for newcomers](https://github.com/LayishSieger/agent-workflows/issues/20).

**First screen** = roughly the first 40 lines / one laptop viewport of `README.md`, before any scroll.

---

## What all three variants agree on

- Line 1 is what you get, not what version it is.
- No `v0.1 → v0.2 → v0.3` genealogy, no "Status/design freeze" banner, no breaking-change table above the fold.
- No "Layer" tables, no `outcome:` enum, no spawn resolution order above the fold.
- Chat and shell both appear above the fold, and are visibly the same work run two ways.
- `tick` / `claim` / `publish` get one plain clause at first appearance, then nothing more.

They disagree on **structure** — which is the actual question.

---

## Variant A — Outcome, then the fork

*Bet: the reader's first question is "which of these two things am I?"*

> # agent-workflows
>
> Give a coding agent a repeatable way to take a ready issue all the way to a pull request you can review.
>
> Set a repository up once, then run the work whichever way suits you:
>
> | You want | You run |
> |----------|---------|
> | One issue, in chat, watching it happen | `/loop-workflows` |
> | A few issues, unattended from a terminal | `host.sh -n 3` |
>
> Both do the same pass over one issue — a **tick**: take a ready issue so other agents skip it (**claim**), implement it, open the PR and hand it back to a human (**publish**). Chat runs the tick in your session; the shell host runs it unattended, one fresh agent per issue.
>
> ## Start here
>
> ```bash
> npx skills add LayishSieger/agent-workflows
> ```
>
> Then, in the repository you want agents to work in:
>
> ```text
> /init-workflows      # set the repo up: policy + runtime. Once.
> /loop-workflows      # run your first tick
> ```
>
> Unattended runs need one extra thing — a spawn command telling the host how to start your agent. `/init-workflows` offers to write it.

*(Everything else — three packages, contracts detail, `outcome:`, spawn resolution, version history — moves below the fold or under Internals.)*

---

## Variant B — Show one run first

*Bet: the reader believes a transcript faster than a description, and the fork explains itself once they've seen the work.*

> # agent-workflows
>
> Give a coding agent a repeatable way to take a ready issue all the way to a pull request you can review.
>
> ```text
> /loop-workflows
>
> → picks the oldest issue labelled ready-for-agent      #42 Fix stale cache key
> → claims it, so other agents skip it
> → implements it on feat/42-stale-cache-key, runs your checks
> → opens a PR and labels the issue ready-for-human
>
> done — one tick. 1 issue → 1 PR waiting for you.
> ```
>
> That single pass is a **tick**. You can run it two ways, and they do the same thing:
>
> - **In chat** — `/loop-workflows` runs one tick in your session, or schedules a few.
> - **From a terminal** — the shell host runs ticks unattended, spawning one fresh agent per issue.
>
> ## Start here
>
> ```bash
> npx skills add LayishSieger/agent-workflows
> ```
>
> ```text
> /init-workflows      # set the repo up: policy + runtime. Once.
> /loop-workflows      # the run above
> ```

*(Risk to react to: the transcript is a promise. It has to match what the tick actually prints, or it becomes a lie the first time someone runs it.)*

---

## Variant C — The ladder

*Bet: the reader wants to know where they are in a sequence; chat vs shell is a step you reach, not a fork you choose at the door.*

> # agent-workflows
>
> Give a coding agent a repeatable way to take a ready issue all the way to a pull request you can review.
>
> **1. Install**
>
> ```bash
> npx skills add LayishSieger/agent-workflows
> ```
>
> **2. Set up the repository — once**
>
> ```text
> /init-workflows
> ```
>
> Writes the policy your agents read (tracker, labels, domain) and the runtime they write to. That's it — the repo is now **READY**.
>
> **3. Run one issue**
>
> ```text
> /loop-workflows
> ```
>
> One **tick**: take a ready issue so other agents skip it (**claim**), implement it, open the PR, hand it back (**publish**).
>
> **4. Run several without watching**
>
> ```bash
> bash ~/.agents/skills/host-workflows/scripts/host.sh -n 3
> ```
>
> Same tick, one fresh agent per issue, driven from your terminal instead of chat.

*(Risk to react to: shell lands at step 4 — is "later in the ladder" the same as buried? Also the longest of the three; may push past one viewport.)*

---

## What to react to

1. **Structure** — A (fork), B (transcript), C (ladder), or a hybrid.
2. **Shell above the fold** — a raw `host.sh` path is ugly and needs spawn config that isn't set yet. Show the command anyway, or name the path and link?
3. **Vocabulary budget** — A and C spend the whole `tick`/`claim`/`publish` gloss on screen one. Is that the right spend, or should `claim`/`publish` wait?
4. **Three packages** — no variant names `init-workflows` / `loop-workflows` / `host-workflows` as a set above the fold; they appear as commands. Does the package framing need to survive up top?
5. **What replaces the demoted material** — one "How it works" section below the fold, or a separate Internals/maintainers page?

---

# Converged (grilled 2026-07-25)

Outcome line, then the **ladder** (C) — not the fork table, not the transcript. Package **table** above the fold; the two run paths **merged into one step** so chat and shell sit side by side; **all five** first-touch terms glossed above the fold; **no maintainer material anywhere in the README**. Shape reference: [mattpocock/skills README](https://github.com/mattpocock/skills/blob/main/README.md) — quickstart, why it exists, reference, no internals.

## First screen

> # agent-workflows
>
> Give a coding agent a repeatable way to take a ready issue all the way to a pull request you can review.
>
> | Skill | What it does |
> |-------|--------------|
> | `init-workflows` | Sets a repository up: policy + runtime |
> | `loop-workflows` | Runs one issue in chat |
> | `host-workflows` | Runs several from your terminal, unattended |
>
> ## Quickstart
>
> **1. Install**
>
> ```bash
> npx skills add LayishSieger/agent-workflows
> ```
>
> **2. Set up the repository — once**
>
> ```text
> /init-workflows
> ```
>
> Writes the **contracts** your agents rely on: policy they read (tracker, labels, domain) and runtime they write to. Once those are in place, the repo is **READY**.
>
> **3. Run the work**
>
> ```text
> /loop-workflows                                            # one issue, in chat
> bash ~/.agents/skills/host-workflows/scripts/host.sh -n 3  # several, unattended
> ```
>
> Either way it's the same **tick**: take a ready issue so other agents skip it (**claim**), implement it, open the PR and hand it back to a human (**publish**). The shell path runs one fresh agent per issue and needs a spawn command telling the host how to start your agent; `/init-workflows` offers to write one.

## Section order

```text
<first screen above>
## How it works        the tick in one paragraph; contracts and READY; chat and shell over the same tick
## Why this exists     short — a few paragraphs, named problem → named fix (no unbounded drain,
                       one fresh agent per issue, human review gate). Not several screens.
## The three skills    init (audit, writes, AFK offer) · loop (once vs max N, outcome:) · host (-n N, spawn, {{PROMPT}})
## What lands in your repo   docs/agents/ policy · .agent-workflows/ runtime
## Out of scope · License
```

## Ruled out

- **Variant A / B structures** — fork table reads as a choice before you know what either does; transcript is a promise that has to match real output.
- **Light gloss** — `claim` / `publish` / `READY` deferred below the fold.
- **Four-rung ladder** — separate "run several" step; merged instead, so the same-tick claim is made by adjacency.
- **Internals or maintainers section** — genealogy, design freeze, 0.2→0.3 break and the ops contract stay in `docs/v0.3.md` and `CHANGELOG.md`; the README does not carry them and does not sign-post a maintainer path.
