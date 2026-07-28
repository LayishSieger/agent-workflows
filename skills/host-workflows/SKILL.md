---
name: host-workflows
description: From the terminal, run up to N ready issues one after another, unattended.
disable-model-invocation: true
---

# Host workflows

Run up to **N** ready issues from your **terminal**, unattended — one fresh agent session per issue.

Each session runs **exactly one tick** of `loop-workflows` (same claim → implement → publish pass as chat). This skill is only the shell scheduler.

**Not** the tick recipe (that lives in `loop-workflows`). Does not merge PRs, implement tickets in-process, or default to an agent binary.

**Install never runs the host** — `npx skills add` only copies/symlinks this package; you invoke the script when you want AFK.

## Prerequisites

| Need | Why |
|------|-----|
| `loop-workflows` installed for the agent you spawn | Workers run one tick of that skill |
| Product contracts (`docs/agents/*`, `.agent-workflows/`) | Usually via `/init-workflows` |
| A **spawn** command | How the host starts your agent — see **Spawn resolution** below |

## Primary entry

From a **product** repo (cwd = product root), run the installed script:

```bash
# After skills install, path is under your skills directory, e.g.:
bash ~/.agents/skills/host-workflows/scripts/host.sh -n 3

# From a hub clone:
bash /path/to/agent-workflows/skills/host-workflows/scripts/host.sh -n 3 --cwd /path/to/product
```

| Flag | Meaning |
|------|---------|
| `-n N` | Max ticks (default **1**). No unbounded drain. |
| `--spawn CMD` | Override the shell-free spawn recipe |
| `--cwd DIR` | Product root (default: cwd) |
| `-h` / `--help` | Usage |

If spawn is missing, the host **HARD STOP**s — there is no default agent binary.

Optional chat use of this skill: print the script path and how to invoke it — **do not** reimplement the loop in prose.

## Spawn resolution

First non-empty wins:

```text
--spawn  >  AGENT_SPAWN  >  product .agent-workflows/spawn  >  machine ~/.config/agent-workflows/spawn
```

| Source | Shape |
|--------|--------|
| `--spawn '…'` | Human-supplied shell-free argv recipe |
| `AGENT_SPAWN` | Human-supplied shell-free argv recipe |
| `.agent-workflows/spawn` | One local, untracked line |
| `~/.config/agent-workflows/spawn` | One local machine-config line |

**All missing → HARD STOP** with a clear error. There is **no** universal default binary (avoids PATH collisions such as bare `agent`).

The host parses the recipe into arguments and invokes the executable directly, without `eval`, `bash -c`, or another command shell:

```text
spawn-argv... "<tick prompt>"
```

- Tick prompt injection:
  - If a standalone argument is `{{PROMPT}}`, replace it. Use when the CLI needs the prompt as a **flag value** (e.g. `grok -p {{PROMPT}} …`).
  - Else append the prompt as the **final** CLI argument.
- Recipes are whitespace-separated argv. Shell quoting, substitutions, redirects, pipes, command chaining, embedded/newline commands, command interpreters, and environment wrappers are rejected.
- A product spawn file must be local and gitignored in a valid git worktree. The host refuses a tracked file, symlink, or product file without verifiable git metadata so a cloned or unpacked repository cannot supply executable configuration.
- Never print or reveal a resolved recipe; status reports only that one is configured. Keep credentials in the spawned CLI's environment or credential store, never inline in a recipe.
- Host **never** adds `--continue` / `--resume` (clean one-shot context).
- Any unattended flags belong in the **human-owned** spawn string (flag / env / spawn file), not in this skill.

## What the host does

Sequential `1..N`:

1. Resolve spawn (HARD STOP if missing).
2. If latest progress `outcome:` is **COMPLETE** → stop **before** spawn (no work left).
3. Spawn one-shot worker with fixed “exactly one tick” prompt (`{{PROMPT}}` or final arg).
4. Re-read `.agent-workflows/progress.md` latest `outcome:`.
5. Apply stop rules; else continue until `N`.

**Control plane is progress only.** The host greps `.agent-workflows/progress.md`; it does **not** call tracker ops (`list-queue`, `incomplete-claim`, etc.). Queue emptiness and incomplete claims are the **worker’s** job when it writes `outcome: COMPLETE` (or other terminals). That keeps the shell host tracker-free and thin.

### Stop rules

| Condition | Overall |
|-----------|---------|
| Latest `outcome:` **COMPLETE** before spawn (prefer no spawn) | **COMPLETE** |
| After a spawn: **BLOCKED** / **HARD_STOP** / **FAILED** | that outcome (stops remaining ticks **this process** only) |
| After a spawn: **SHIPPED** / **NEEDS_INFO** / **SKIPPED** and `i < N` | continue |
| Hit **N** with work still continuing | **MAX** |
| Missing/unusable progress after a spawn that should have written | **FAILED** |

A **new** `host.sh` run still spawns once even if progress’s latest line is a stale **HARD_STOP** / **BLOCKED** / **FAILED** (operator fixed env and re-invoked). Only **COMPLETE** skips spawn without trying.

**Process exit of the agent ≠ tick success.** The host may log a non-zero exit but drives the loop from progress only.

### Host does **not** pass

- Issue id  
- Remaining N  
- Host queue blob  
- Stack/git base injection  

Workers discover policy under `docs/agents/*` and pick/resume themselves.

## Status block

```text
host-workflows status
- mode: max N
- ticks: i / N
- last_outcome: …
- overall: COMPLETE | BLOCKED | MAX | HARD_STOP | FAILED
```

Exit code: **0** for COMPLETE or MAX; **non-zero** for BLOCKED / HARD_STOP / FAILED / misconfiguration.

## Dependency on loop-workflows

Workers are prompted to **run `loop-workflows` for exactly one tick**. Install that skill on the agent host you spawn; the shell host does not embed the tick recipe.

Shared tick (worker-owned):

```text
resume | pick → claim → implement → publish → progress
```

Design freeze: [docs/v0.3.md](../../docs/v0.3.md) in this hub (or the installed pack’s docs when published).

## Out of scope (host)

- Multi-spawn fleet, rate limits, park-branch recovery  
- Auto-detect agent matrix  
- Full `.agent-workflows/config` beyond one-line spawn files  
- Implementing tickets inside the host process  
