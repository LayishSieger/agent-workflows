# agent-workflows

Give a coding agent a repeatable way to take a ready issue all the way to a pull request you can review.

| Skill | What it does |
|-------|--------------|
| `init-workflows` | Sets a repository up: policy + runtime |
| `loop-workflows` | Runs one issue in chat |
| `host-workflows` | Runs several from your terminal, unattended |

## Quickstart

**1. Install**

```bash
npx skills add LayishSieger/agent-workflows
```

**2. Set up the repository — once**

```text
/init-workflows
```

Writes the **contracts** your agents rely on: policy they read (tracker, labels, domain) and runtime they write to. Once those are in place, the repo is **READY**.

**3. Run the work**

```text
/loop-workflows                                            # one issue, in chat
bash ~/.agents/skills/host-workflows/scripts/host.sh -n 3  # several, unattended
```

Either way it's the same **tick**: take a ready issue so other agents skip it (**claim**), implement it, open the PR and hand it back to a human (**publish**). The shell path runs one fresh agent per issue and needs a spawn command telling the host how to start your agent; `/init-workflows` offers to write one.

## How it works

One **tick** is always the same pass: resume or pick → claim → implement → publish → progress. **Contracts** (under `docs/agents/`) tell the agent how to talk to your tracker; **READY** means those contracts and the `.agent-workflows/` runtime are in place. Chat (`/loop-workflows`) and shell (`host-workflows`) are two doors over that same tick — chat runs it in your session; the shell host schedules unattended workers, one fresh agent per issue.

## Why this exists

Agents that “keep going” tend to stuff many issues into one context, skip human review, or drain a queue with no bound. This pack refuses that: no unbounded drain without an explicit **N**, one fresh agent per issue on the multi-N path, and a pull request handoff you review (**publish**) instead of a silent merge. Planning (turning ideas into ready tickets) stays optional and separate — this hub owns setup and the implement loop.

## The three skills

### `init-workflows`

1. **Audits** a fixed checklist (concrete paths — not an “initialized” stamp)
2. **Repairs** contracts + runtime (defaults write without a second confirm; never wipe `progress.md`; never overwrite non-empty policy without confirm)
3. **Optional autonomy:** chat only, or shell AFK — with skill scope global (default) or product; install host+loop via CLI; no silent install
4. **Smart spawn** (shell only): detect agent CLIs on PATH; write product `.agent-workflows/spawn` (always product-local)

It does **not** implement issues, drain queues, or run `host.sh`. READY is contracts-only; loop/host/spawn are optional.

**Product vs global skills:** policy + spawn + progress always live in the product. Skill packages may be global (`npx skills add -g …`, run `~/.agents/skills/host-workflows/scripts/host.sh`) or product (`npx skills add …` without `-g`, run `.agents/skills/host-workflows/scripts/host.sh`). Prefer one scope per product.

### `loop-workflows` (chat)

| Mode | Invocation |
|------|------------|
| **once** (default) | `/loop-workflows` — one tick in this session |
| **max N** | User states N explicitly (e.g. “max 3”) — parent schedules N **fresh one-tick workers**; **no unbounded drain** |

On interactive preflight failure: pause and ask **retry** / **abort**. Unattended host workers stop immediately. Soft-skips cover open publish artifacts, open blockers, and skill-side **spec/PRD** bodies. Each tick appends `.agent-workflows/progress.md` with a required **`outcome:`**.

Empty queue → COMPLETE and a short hint to create tickets (planning skills install separately).

### `host-workflows` (shell)

```bash
# After skills install, e.g.:
bash ~/.agents/skills/host-workflows/scripts/host.sh -n 3

# From a hub clone:
bash /path/to/agent-workflows/skills/host-workflows/scripts/host.sh -n 3 --cwd /path/to/product
```

| Flag | Meaning |
|------|---------|
| `-n N` | Max ticks (default **1**). No unbounded drain |
| `--spawn CMD` | Override spawn command string |
| `--cwd DIR` | Product root (default: current directory) |

**Spawn resolution** (first non-empty wins):

```text
--spawn / AGENT_SPAWN  >  product .agent-workflows/spawn  >  machine ~/.config/agent-workflows/spawn
```

All missing → **HARD STOP** (no silent default binary). Host injects the tick prompt into the spawn recipe: if the line contains `{{PROMPT}}`, replace it (quoted); else append as the final argument. Never adds `--continue` / `--resume`.

Spawn is **human-owned** config (flag, env, or one-line file). Skills do not ship unattended/trust flags. Example one-liners (adjust for your agent version):

```bash
# product or machine file — one line only
# Grok: -p requires the prompt as its value → use {{PROMPT}}
grok -p {{PROMPT}} --always-approve --output-format plain
# cursor-agent -p --force --trust --output-format text
# Claude AFK: acceptEdits blocks Bash/gh — use bypassPermissions for shell host
# claude -p {{PROMPT}} --permission-mode bypassPermissions --output-format text
# codex exec --sandbox workspace-write --ephemeral
```

Workers must have **`loop-workflows`** installed for the agent binary you spawn. Control plane is progress **`outcome:`** only — process exit ≠ tick success.

## What lands in your repo

| Path | Purpose |
|------|---------|
| `docs/agents/` | Policy (tracker ops, triage labels, domain) — reviewable in git |
| `.agent-workflows/progress.md` | Session log; hosts key off latest **`outcome:`** |
| `.agent-workflows/logs/` | Optional per-run notes |
| `.agent-workflows/spawn` | Optional one-line shell command string |

**No** full `.agent-workflows/config` in 0.3. Integration branch (if not the repo default) lives in **`docs/agents/issue-tracker.md`**.

### Progress `outcome:` (control plane)

```markdown
### YYYY-MM-DD — #N — <title>
- **outcome:** SHIPPED | NEEDS_INFO | SKIPPED | COMPLETE | BLOCKED | HARD_STOP | FAILED
- **publish:** <url or none>
- **checks:** pass | fail | n/a
- **note:** ≤1 line
```

### Optional planning companions

Ticket/spec generation is **not** shipped here. Example separate install:

```bash
npx skills add <owner/matt-or-other-skills-repo>
```

Then use that pack to produce issues that match `docs/agents` triage labels and are agent-ready (acceptance criteria, blockers).

Dogfood: real product with GitHub issues, once + multi-N via workers (chat or shell). Suite under [`tests/dogfood/`](./tests/dogfood/).

```bash
bash tests/dogfood/run-automated.sh    # host unit tests + ops contract
bash tests/dogfood/setup-sandbox.sh    # private product + labels + issues
# then follow tests/dogfood/run-dogfood.md in the product dir
```

## Out of scope

- Sandcastle (or any sandbox orchestrator) adapter
- Bundling Matt (or other) planning skills into this hub
- Stack/epic base engines and merge bots
- Unbounded drain without explicit N
- Full local-markdown or Linear **runtime** proof (same ops headings + stubs OK)
- Park-branch / multi-spawn / rate-limit fleets beyond thin shell stop rules
- Machine-readable `.agent-workflows/config` beyond one-line spawn files
- Replacing or archiving other skill repos

## License

MIT — see [LICENSE](./LICENSE).

For maintainers and contributors: see the [changelog](./CHANGELOG.md) and [design history](./docs/v0.3.md).
