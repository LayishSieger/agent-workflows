---
name: init-workflows
description: Ensure a product repo has agent-workflows contracts (policy docs + runtime). Optional CLI install of loop/host (global or product scope) and smart spawn. Re-entrant audit and repair.
disable-model-invocation: true
---

# Ensure workflows-ready

**Ensure** this product repo meets agent-workflows contracts. Audit → repair gaps → optional AFK stack. Do not trust marker files or prior "initialized" claims.

This is a prompt-driven skill, not a deterministic script. Short explainers; batch questions; write only per rules below.

**Contracts first** → overall READY. Autonomy skills/spawn are optional and never required for READY.

**Out of scope:** implementing features, draining queues, running `host.sh`, multi-spawn fleets, secrets, full `.agent-workflows/config`, hub-clone as default install path.

Seeds ship **in this skill directory**.

## Mental model (for you and the final status)

```text
init-workflows → docs/agents/* + .agent-workflows/  (READY)   ← always PRODUCT
       │
  [S] chat only              [H] shell AFK
       │                            │
  loop-workflows             host + loop  (scope: global OR product)
  /loop-workflows            host.sh -n N + product spawn
       │                            │
       └──────── loop tick (claim → implement → publish → progress) ──┘
```

### What lives where

| Location | Contents |
|----------|----------|
| **Product repo** | Always: `docs/agents/*`, `.agent-workflows/` (`progress.md`, `logs/`, **spawn**). Optional: project skills under `.agents/skills/` + `skills-lock.json` if user chose **product** scope |
| **User machine (global)** | Optional: `~/.agents/skills/{init,loop,host}-workflows` (and agent mirrors e.g. `~/.claude/skills/`) when user chose **global** scope |

**Spawn is always product-local** (`.agent-workflows/spawn`). Host package may be global or product; print **one** primary `host.sh` path that matches the chosen scope.

`npx skills add` **defaults to project** when cwd is a git repo. For **global** scope always pass **`-g`**. For **product** scope omit `-g` (and run from product root).

Optional planning (separate install, e.g. Matt Pocock engineering skills): to-spec / to-tickets / triage → `ready-for-agent`. This stack **consumes** that queue; neither installs the other.

## Process

### 1. Explore

Product root (`git rev-parse --show-toplevel` or workspace root). If cwd is only this skill package, ask which product to ensure.

Read:

- `git remote -v`
- `docs/agents/issue-tracker.md`, `triage-labels.md`, `domain.md`
- `.agent-workflows/progress.md`, `logs/`, `spawn` (product) — for **progress.md** use shell `test -f` / `ls` (file is gitignored; do not trust git-only or sandbox file trees that hide ignored paths)
- Machine spawn `~/.config/agent-workflows/spawn` if readable (info only; default write is product)
- `.gitignore`, `AGENTS.md` / `CLAUDE.md`, `.scratch/`, `CONTEXT.md` / monorepo signals
- **Skills (both scopes):**
  - **Global:** `~/.agents/skills/`, `~/.claude/skills/` (and similar) for `loop-workflows`, `host-workflows`
  - **Product:** `<product>/.agents/skills/` + `skills-lock.json` if present
  - If **both** global and product copies exist: note both paths (dual install — pick one scope later)
- **Agent CLIs on PATH** (`command -v` only; do **not** treat bare `agent` as a hit):

| Binary | Preset shape (product spawn — no trust/unattended flags here) |
|--------|--------------------------------------------------------------|
| `grok` | `grok -p {{PROMPT}} --output-format plain` |
| `cursor-agent` | `cursor-agent -p --output-format text` |
| `claude` | `claude -p {{PROMPT}} --output-format text` |
| `codex` | `codex exec --ephemeral` |

`{{PROMPT}}` = host substitutes the tick prompt (required for CLIs where `-p` takes the prompt as a value, e.g. Grok). Without it, host appends the prompt as the final argument.

**AFK note:** shell host needs unattended/trust flags so the worker can run tracker CLIs (`gh`) and write files. Those flags are **human-owned** — copy from hub README spawn examples into the spawn line (or paste a full custom line). Do not invent trust flags from this skill.

### 2. Audit and present

Print table **before** writes:

| # | Artifact | Ready when |
|---|----------|------------|
| 1 | `docs/agents/issue-tracker.md` | non-empty |
| 2 | `docs/agents/triage-labels.md` | non-empty |
| 3 | `docs/agents/domain.md` | non-empty |
| 4 | `.agent-workflows/progress.md` | exists |
| 5 | `.agent-workflows/logs/` | exists (prefer `.gitkeep`) |
| 6 | `.gitignore` | has runtime lines (step 5; scope may add skill lines later) |

Also note (informational): loop/host **global** and **product** paths, agent CLIs, product spawn.

AGENTS.md / CLAUDE.md not required for READY.

**Done when:** full table shown.

---

### 3. Contracts interview (batch) — missing policy only

If items **1–3 are all present** → skip to step 4 (no policy interview).

If any of 1–3 **missing**, one short blurb + **one batch** (not three separate long turns):

> Init writes policy under `docs/agents/` and local runtime under `.agent-workflows/`. It does not implement issues or start AFK.

**Batch A** (only ask for missing pieces; lead with defaults):

1. **Tracker** — GitHub if origin looks like GitHub, else local. Options: GitHub / local markdown / other. If GitHub: external PRs as triage? **no** (default). Integration branch: seed `main` unless user overrides.
2. **Labels** — defaults = role names (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). Overrides only if user lists them.
3. **Domain** — **single-context** (default: `CONTEXT.md` + `docs/adr/`) unless monorepo signals → offer multi-context.

User may reply **`ok`** / **`all defaults`** / accept recommended line.

Draft from seeds: [issue-tracker-github.md](./issue-tracker-github.md), [issue-tracker-local.md](./issue-tracker-local.md), [triage-labels.md](./triage-labels.md), [domain.md](./domain.md).

**Done when:** drafts ready for each missing policy file.

### 4. Write policy

| Situation | Action |
|-----------|--------|
| All new/missing policy and user accepted **defaults** (`ok` / all defaults / only accepted recommendations) | **Write immediately** — no second draft confirm |
| User gave **custom** tracker/labels/domain answers | Show drafts once; write after confirm |
| Policy file **exists and non-empty** | **Never** overwrite without explicit replace confirm |

Write: `docs/agents/issue-tracker.md`, `triage-labels.md`, `domain.md` as needed.

### 5. Repair runtime (safe auto)

No confirm unless surprising:

1. `.agent-workflows/logs/` + `.gitkeep` if missing
2. **`progress.md` — filesystem check only (critical):**
   - Decide existence with a **shell** check on the product path, e.g.  
     `test -f .agent-workflows/progress.md && echo yes || echo no`  
     or `ls -la .agent-workflows/`.
   - **Do not** use `git status` / git-aware file trees alone — `progress.md` is **gitignored** and Cursor sandboxes often **hide** ignored files, so the IDE may show “missing” when the file still has entries on disk.
   - Create from [progress.template.md](./progress.template.md) **only** when the shell check says the path is absent.
   - If the file exists: **never** write, truncate, or replace it (no “repair” overwrite). Existing HARD_STOP / SHIPPED entries must stay.
3. Ensure `.gitignore` has at least the **runtime** lines (append missing only; create `.gitignore` if absent):

```gitignore
# agent-workflows runtime (local session state)
.agent-workflows/progress.md
.agent-workflows/logs/*
!.agent-workflows/logs/.gitkeep
```

Do **not** write skill-scope gitignore lines here — step 7 adjusts after the user picks global vs product. Do **not** write `spawn` here (step 7 only).

### 6. Optional project pointer

If `AGENTS.md` or `CLAUDE.md` exists without `.agent-workflows/` pointer: offer short section; write only on yes. Prefer existing file; if both, prefer `AGENTS.md`. No slash-command names. Skip if neither exists unless user asks.

Runtime-only when policy already documented elsewhere:

```markdown
## Agent workflows

- Runtime: `.agent-workflows/` (`progress.md`, `logs/`)
```

---

### 7. Optional autonomy (not required for READY)

Detect and print:

- loop/host **global** paths (if any)
- loop/host **product** paths (if any)
- agent CLIs
- product spawn present/missing

Short blurb:

> **Chat path:** `/loop-workflows` needs the **loop-workflows** skill (usually global).  
> **Shell AFK:** `host.sh` + **loop** + product spawn. Skills may be **global** (this machine) or **product** (this repo). Install never runs the host.

**Ask (one choice):**

| Reply | Meaning |
|-------|---------|
| **S** / **skip** / **chat** | Contracts only. No host install. |
| **H** / **shell** | Shell AFK: choose skill scope, ensure host + loop, then spawn. |

#### 7a. If **S** (chat only)

- Do **not** install host.
- If loop missing **everywhere**, print (do not force):

```bash
npx skills add -g -y -s loop-workflows LayishSieger/agent-workflows
```

- Skip spawn. Go to step 8.

#### 7b. If **H** (shell AFK) — skill scope then CLI

##### 7b.1 Scope (required)

> Where should **host** + **loop** skills live?

| Reply | Scope | When to recommend |
|-------|--------|-------------------|
| **G** / **global** | User machine (`~/.agents/skills/…`) | **Default** for solo / multi-repo |
| **P** / **product** | This repo (`.agents/skills/…` + `skills-lock.json`) | Team pin / shared clone |

Lead with **G** unless product already has intentional project skills and no global host.

If **both** global and product copies already exist: warn dual install; ask which is **canonical** for this product (G or P). Status/Next must print **only that** `host.sh` path.

##### 7b.2 Install commands (same scope for host **and** loop)

**Global (G):**

```bash
npx skills add -g -y -s loop-workflows LayishSieger/agent-workflows
npx skills add -g -y -s host-workflows LayishSieger/agent-workflows
```

Primary entry:

```bash
bash ~/.agents/skills/host-workflows/scripts/host.sh -n N
```

**Product (P)** — run from product root; omit `-g`:

```bash
npx skills add -y -s loop-workflows LayishSieger/agent-workflows
npx skills add -y -s host-workflows LayishSieger/agent-workflows
```

Primary entry:

```bash
bash .agents/skills/host-workflows/scripts/host.sh -n N
```

Install **both** skills in the **same** scope (worker must load loop from a place the spawned agent sees; product scope pins both for the repo).

##### 7b.3 Per-skill actions (within chosen scope)

Judge presence only in the **chosen** scope (global roots vs product `.agents/skills/`).

| State | Action |
|-------|--------|
| **Missing** | **install** (run CLI) \| **I'll install** (print cmd) \| **skip** (warn incomplete) |
| **Present** | Report path. **keep** \| **reinstall** \| **skip**. Never silent overwrite. |

On **install** / **reinstall**: run the matching commands for that scope. On **I'll install**: print only.

##### 7b.4 Gitignore for skill scope

After scope is known, ensure `.gitignore` matches (append only; do not remove user lines without ask):

**If G (global):** ignore accidental project skill noise:

```gitignore
# skills CLI project noise when using global skills
.agents/
skills-lock.json
```

**If P (product):** do **not** add those ignores (team may commit `skills-lock.json` and/or `.agents/`). Remind user: commit lock (and skills if that is the team policy) so preflight is clean; never leave intentional product skills untracked long-term.

**Always keep** runtime ignores for progress/logs (step 5).

**Never** run `host.sh` from this skill.

#### 7c. Spawn (only if **H**)

> Spawn = one-line command that starts your coding agent once. Host injects the tick prompt (`{{PROMPT}}` or final arg).  
> **Saved to:** product `.agent-workflows/spawn` (one line) — always product, any skill scope.

If product spawn **exists** and non-empty: show contents → **keep** \| **replace**. On keep → step 8. On replace → detection flow below.

**Detect** CLIs from step 1 (`grok`, `cursor-agent`, `claude`, `codex` only).

| Detected | UX |
|----------|-----|
| **Exactly one** | Propose that binary’s **shape** preset; remind user to add AFK flags from README before confirming. Ask: **yes** (write shape) \| **edit** (user pastes full AFK line) \| **skip** |
| **Two or more** | Numbered menu of **only** detected shape presets + **custom** + **skip** |
| **Zero** | Ask **custom** paste or **skip** (no fake presets) |

Prefer **edit**/custom when the user wants a working AFK line (README recipes). Write **exactly one line** to `.agent-workflows/spawn` on yes/preset/custom. Create `.agent-workflows/` if needed.

Optional one-liner only if user asks: also write machine `~/.config/agent-workflows/spawn`. Do **not** open with product-vs-machine-vs-flag by default.

**Skip** = no file; host HARD STOPs until user sets `--spawn` / `AGENT_SPAWN` / spawn file later.

**Done when:** S or H handled; scope G/P chosen if H; installs keep/reinstall/skip resolved; spawn keep/write/skip resolved; gitignore matched to scope.

---

### 8. Re-audit, status, what next

Re-check checklist rows **on disk**. Print:

```text
agent-workflows status
- issue-tracker: present|missing|drift
- triage-labels: present|missing|drift
- domain: present|missing|drift
- progress.md: present|missing|drift
- logs/: present|missing|drift
- gitignore: present|missing|drift
- skill-scope: global|product|n/a
- loop-workflows: present|missing|… (path)
- host-workflows: present|missing|… (path)
- host-entry: <canonical bash …/host.sh -n N or n/a>
- spawn: product|skipped|kept|n/a
- overall: READY | NOT READY
```

`skill-scope`, skills, and `spawn` are **informational** — they do **not** flip overall to NOT READY when skipped.

Then **How it works next** (always when READY, short):

```text
Next
1. Contracts (this repo): docs/agents/* .
2. Chat: /loop-workflows  (loop skill on the agent)
3. Shell: <host-entry from status>
   → reads product .agent-workflows/spawn + progress
   → worker runs one loop tick; host stops on progress outcome:
     COMPLETE | BLOCKED | MAX | HARD_STOP | FAILED | …
4. Scope: global skills on the machine, or product .agents/ for team pin;
   spawn/progress/policy always product-local.
5. Planning (optional, separate): e.g. Matt to-spec/to-tickets → ready-for-agent.
```

If NOT READY: list remaining gaps only.

Re-run anytime to re-ensure (repairs gaps; **never** wipes progress).

**Done when:** status + next steps printed after on-disk re-audit.
