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
