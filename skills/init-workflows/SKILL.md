---
name: init-workflows
description: Get a product repo ready for agent-workflows — audit what's missing, repair it, then optionally configure existing chat and shell runners.
disable-model-invocation: true
---

# Get a product repo ready

Get this product repo to **READY**: the **contracts** are its policy under `docs/agents/` and runtime under `.agent-workflows/`. Audit first, repair gaps, then offer the optional chat and shell runners.

This is a prompt-driven skill, not a deterministic script. Explore silently, keep explanations short, batch questions, and write only per the rules below. Do not trust marker files or prior “initialized” claims.

**Contracts first** → overall READY. Runner skills and spawn are optional and never required for READY.

**Out of scope:** implementing features, draining queues, running `host.sh`, multi-spawn fleets, secrets, full `.agent-workflows/config`, hub-clone as default install path.

Seeds ship **in this skill directory**.

## Process

### 1. Explore silently

Product root (`git rev-parse --show-toplevel` or workspace root). If cwd is only this skill package, ask which product to ensure.

Read:

- `git remote -v`
- `docs/agents/issue-tracker.md`, `triage-labels.md`, `domain.md`
- `.agent-workflows/progress.md`, `logs/`, `spawn` (product) — for **progress.md** use shell `test -f` / `ls` (file is gitignored; do not trust git-only or sandbox file trees that hide ignored paths)
- `.gitignore`, `AGENTS.md` / `CLAUDE.md`, `.scratch/`, `CONTEXT.md` / monorepo signals

Do not narrate this checklist. Mention a finding only when it changes a policy choice or blocks READY. Do not inspect runner installs, agent CLIs, or machine spawn yet; those belong to the optional shell path after READY.

### 2. Audit and present

The first user-facing turn is one purpose sentence followed by the audit table. Print it **before** writes:

> Init gets this product repo to **READY**: its **contracts** are policy under `docs/agents/` plus runtime under `.agent-workflows/`.

| # | Artifact | Status |
|---|----------|--------|
| 1 | `docs/agents/issue-tracker.md` | present / missing |
| 2 | `docs/agents/triage-labels.md` | present / missing |
| 3 | `docs/agents/domain.md` | present / missing |
| 4 | `.agent-workflows/progress.md` | present / missing |
| 5 | `.agent-workflows/logs/` | present / missing |
| 6 | `.gitignore` runtime lines | present / missing |

If policy is missing, end with one short sentence that a single batch of choices comes next, followed by runtime repair. If policy is present, say the runtime gaps will be repaired next.

AGENTS.md / CLAUDE.md not required for READY.

Do not show an ASCII mental model, location table, install command, CLI preset, spawn detail, or autonomy menu in this turn.

**Done when:** purpose + full table shown, with no runner setup mixed in.

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
.agent-workflows/spawn
```

Do **not** write skill-scope gitignore lines here — step 8 adjusts after the user picks global vs product. Do **not** write `spawn` here (step 8 only).

### 6. Optional project pointer

If `AGENTS.md` or `CLAUDE.md` exists without `.agent-workflows/` pointer: offer short section; write only on yes. Prefer existing file; if both, prefer `AGENTS.md`. No slash-command names. Skip if neither exists unless user asks.

Runtime-only when policy already documented elsewhere:

```markdown
## Agent workflows

- Runtime: `.agent-workflows/` (`progress.md`, `logs/`)
```

---

### 7. Re-audit contracts and declare READY

Re-check the six audit rows **on disk**. Print the contract-only status:

```text
agent-workflows status
- issue-tracker: present|missing|drift
- triage-labels: present|missing|drift
- domain: present|missing|drift
- progress.md: present|missing|drift
- logs/: present|missing|drift
- gitignore: present|missing|drift
- overall: READY | NOT READY
```

If NOT READY, list remaining gaps only and stop. Do not offer runner setup.

If READY, finish this turn. Offer the optional runner choice in a separate turn; do not mix it into the repair report.

### 8. Optional runners (not required for READY)

After READY, ask one choice:

> **READY** — the contracts are in place. Optionally set up how work runs:

| Reply | Meaning |
|-------|---------|
| **S** / **skip** / **chat** | Chat only: use `/loop-workflows` when you want. No shell host install. |
| **H** / **shell** | Shell AFK: unattended terminal runs; next choose skill scope, then verify runners and configure spawn. |

Recommend **S** for a first-time or solo setup unless the user wants unattended multi-issue runs now. Do not show G/P, install commands, CLI presets, trust flags, `{{PROMPT}}`, or dual-install details before the user chooses H.

#### 8a. If **S** (chat only)

- Do **not** install host.
- Check for `loop-workflows` in global and product skill paths.
- If loop is missing **everywhere**, report it and ask the user to install it from a source and immutable revision they have reviewed. Do not run or propose an unpinned package-manager/GitHub install.

- Skip spawn. Go to step 9.

#### 8b. If **H** (shell AFK) — skill scope then CLI

Only now inspect:

- loop/host **global** paths: `~/.agents/skills/`, `~/.claude/skills/` (and similar)
- loop/host **product** paths: `<product>/.agents/skills/` and `skills-lock.json`
- existence only (not contents) of product spawn and machine `~/.config/agent-workflows/spawn`
- agent CLIs on PATH (`grok`, `cursor-agent`, `claude`, `codex`; never treat bare `agent` as a hit)

If both global and product copies exist, note both paths here and resolve the canonical scope below.

##### 8b.1 Scope (required)

> Where should **host** + **loop** skills live?

| Reply | Scope | When to recommend |
|-------|--------|-------------------|
| **G** / **global** | User machine (`~/.agents/skills/…`) | **Default** for solo / multi-repo |
| **P** / **product** | This repo (`.agents/skills/…` + `skills-lock.json`) | Team pin / shared clone |

Lead with **G** unless product already has intentional project skills and no global host.

If **both** global and product copies already exist: warn dual install; ask which is **canonical** for this product (G or P). Status/Next must print **only that** `host.sh` path.

Policy and runtime always stay in the product repo. Spawn is always product-local at `.agent-workflows/spawn`. Host and loop skills may be global or product-scoped.

##### 8b.2 Required skills (same scope for host **and** loop)

Do not download or install code from this skill. Inspect only the chosen scope. If either skill is missing, report the missing name and ask the user to install both from a source and immutable revision they have reviewed, then rerun init.

When both are already present, the global primary entry is:

```bash
bash ~/.agents/skills/host-workflows/scripts/host.sh -n N
```

The product-scoped primary entry is:

```bash
bash .agents/skills/host-workflows/scripts/host.sh -n N
```

Both skills must be present in the **same** scope (the worker must load loop from a place the spawned agent sees).

##### 8b.3 Per-skill actions (within chosen scope)

Judge presence only in the **chosen** scope (global roots vs product `.agents/skills/`).

| State | Action |
|-------|--------|
| **Missing** | Report missing; stop optional shell setup until the user installs a reviewed immutable revision |
| **Present** | Report path; keep it. Never overwrite or reinstall from this skill. |

##### 8b.4 Gitignore for skill scope

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

#### 8c. Spawn (only if **H**)

> Spawn = one-line, shell-free argv recipe that starts your coding agent once. Host injects the tick prompt (`{{PROMPT}}` or final arg).
> **Saved to:** product `.agent-workflows/spawn` (one line) — always product, any skill scope.

If product spawn **exists** and non-empty: report only that it is configured — **never read it into chat or show its contents**. Ask **keep** \| **replace**. On keep → step 9. On replace → detection flow below.

Shell-free argv shape presets for the detected CLIs:

| Binary | Preset shape (no trust/unattended flags included) |
|--------|---------------------------------------------------|
| `grok` | `grok -p {{PROMPT}} --output-format plain` |
| `cursor-agent` | `cursor-agent -p --output-format text` |
| `claude` | `claude -p {{PROMPT}} --output-format text` |
| `codex` | `codex exec --ephemeral` |

`{{PROMPT}}` must be a standalone argument; host substitutes the tick prompt. Without it, host appends the prompt as the final argument. Recipes must not contain shell quoting, substitutions, redirects, pipes, command chaining, command interpreters/wrappers, or credentials. Credentials belong in the CLI's environment or credential store.

Shell host needs unattended/trust flags so the worker can run tracker CLIs and write files. Those flags are **human-owned**: copy a full recipe from the hub README or paste a custom line. Do not invent trust flags.

| Detected | UX |
|----------|-----|
| **Exactly one** | Propose that binary’s **shape** preset; remind user to add AFK flags from README before confirming. Ask: **yes** (write shape) \| **edit** (user pastes full AFK line) \| **skip** |
| **Two or more** | Numbered menu of **only** detected shape presets + **custom** + **skip** |
| **Zero** | Ask **custom** paste or **skip** (no fake presets) |

Prefer **edit**/custom when the user wants a working AFK line (README recipes). Before writing custom input, reject shell syntax and likely secrets (tokens, passwords, inline environment assignments, or credential-bearing URLs) without echoing the rejected value. Write **exactly one shell-free argv line** to `.agent-workflows/spawn` on yes/preset/custom. Create `.agent-workflows/` if needed and ensure the file remains gitignored.

Optional one-liner only if user asks: also write machine `~/.config/agent-workflows/spawn`. Do **not** open with product-vs-machine-vs-flag by default.

**Skip** = no file; host HARD STOPs until user sets `--spawn` / `AGENT_SPAWN` / spawn file later.

**Done when:** S or H handled; scope G/P chosen if H; required skills present or reported missing; spawn keep/write/skip resolved; gitignore matched to scope.

---

### 9. Final status and Next

Keep the READY result from step 7 and add only the runner fields resolved in step 8:

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

Then print a short **Next**:

```text
Next
1. Contracts: docs/agents/* (done).
2. Chat: /loop-workflows <or reviewed-install reminder if loop is missing>.
3. Shell AFK: <host-entry, or skipped>.
4. Planning (optional, separate): to-spec/to-tickets → ready-for-agent.
```

Here a **tick** is one issue pass: **claim** leaves the ready queue, then implementation, **publish** hands a pull request to a human, and progress records the result. Gloss these terms once only when useful; omit the sentence if they were already explained.

Do not add version genealogy, migration notes, the full `outcome:` enum, spawn resolution, or scope architecture to Next.

Re-run anytime to re-ensure (repairs gaps; **never** wipes progress).

**Done when:** final status + short Next printed.
