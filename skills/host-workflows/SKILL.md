---
name: host-workflows
description: Thin sequential shell host for AFK multi-tick (spawn one-shot workers; stop on progress outcomes).
disable-model-invocation: true
---

# Host workflows

**Shell scheduler** for AFK multi-issue work **without** a chat parent. Spawns sequential one-shot agent sessions; each worker runs **exactly one** shared tick via **`loop-workflows`**.

**Not:** the tick recipe (lives only in `loop-workflows`), a multi-spawn fleet, Sandcastle, or a default agent binary.

**Install never runs the host.** `npx skills add` only copies/symlinks this package. You must **explicitly** invoke the script when you want AFK.

## Prerequisites

| Need | Why |
|------|-----|
| **`loop-workflows` installed** for the agent binary you spawn | Workers are instructed to run one tick of that skill |
| Product contracts (`docs/agents/*`, `.agent-workflows/`) | Usually via `init-workflows` |
| Spawn command configured | Flag, env, product file, or machine file — see below |

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
| `--spawn CMD` | Override spawn command string |
| `--cwd DIR` | Product root (default: current directory) |
| `-h` / `--help` | Usage |

Optional chat use of this skill: print the script path and how to invoke it — **do not** reimplement the loop in prose.

## Spawn resolution

First non-empty wins:

```text
--spawn  >  AGENT_SPAWN  >  product .agent-workflows/spawn  >  machine ~/.config/agent-workflows/spawn
```

| Source | Shape |
|--------|--------|
| `--spawn '…'` | Full command string |
| `AGENT_SPAWN` | Full command string |
| `.agent-workflows/spawn` | One line = command string |
| `~/.config/agent-workflows/spawn` | One line = command string |

**All missing → HARD STOP** with a clear error. There is **no** universal default binary (avoids PATH collisions such as bare `agent`).

Host runs:

```text
$SPAWN "<tick prompt>"
```

- Prompt is the **final** CLI argument.
- Host **never** adds `--continue` / `--resume` (clean one-shot context).
- Unattended/edit flags (`--force`, `--always-approve`, etc.) live **inside** the spawn string.

### Recipes (pin binary names)

Examples only — copy into a spawn file or `--spawn`. Adjust flags for your agent version.

**Cursor Agent CLI** (prefer `cursor-agent` over bare `agent`):

```bash
cursor-agent -p --force --trust --output-format text
```

**Claude Code:**

```bash
claude -p --permission-mode acceptEdits --output-format text
```

**Grok Build** (prefer `grok` over bare `agent` if both exist):

```bash
grok -p --always-approve --output-format plain
```

**Codex CLI:**

```bash
codex exec --sandbox workspace-write --ephemeral
```

Write one line, for example:

```bash
mkdir -p .agent-workflows
echo 'cursor-agent -p --force --trust --output-format text' > .agent-workflows/spawn
```

## What the host does

Sequential `1..N`:

1. Resolve spawn (HARD STOP if missing).
2. If latest progress `outcome:` is already **COMPLETE** / **BLOCKED** / **HARD_STOP** / **FAILED** → stop **before** spawn when known.
3. Spawn one-shot worker with fixed “exactly one tick” prompt (final arg).
4. Re-read `.agent-workflows/progress.md` latest `outcome:`.
5. Apply stop rules; else continue until `N`.

**Control plane is progress only.** The host greps `.agent-workflows/progress.md`; it does **not** call tracker ops (`list-queue`, `incomplete-claim`, etc.). Queue emptiness and incomplete claims are the **worker’s** job when it writes `outcome: COMPLETE` (or other terminals). That keeps the shell host tracker-free and thin.

### Stop rules

| Condition | Overall |
|-----------|---------|
| Latest progress `outcome:` **COMPLETE** (worker reported empty ready-queue + no incomplete claim; prefer before spawn) | **COMPLETE** |
| Latest `outcome:` **BLOCKED** / **HARD_STOP** / **FAILED** | that outcome |
| **SHIPPED** / **NEEDS_INFO** / **SKIPPED** and `i < N` | continue |
| Hit **N** with work still continuing | **MAX** |
| Missing/unusable progress after a spawn that should have written | **FAILED** |

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
