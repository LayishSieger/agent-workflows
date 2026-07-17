# agent-workflows

**Status: v0.2** — contracts (`init-workflows`) + GitHub ready-work loop (`loop-workflows`). Not a host runner or Sandcastle adapter.

Shared workflows and skills for coding agents (Cursor, Claude Code, Grok Build, Codex, …).  
Install the skill pack; agents use what ships **inside each skill** (no extra hub checkout required at runtime).

## Mental model

```text
v0.1  /init-workflows  → product has docs/agents + .agent-workflows/
v0.2  /loop-workflows  → once | max N over ready-for-agent (GitHub), PR + progress
later host CLI/runner  → park branches, multi-spawn, rate limits, stack policies
```

| Layer | Role |
|-------|------|
| **0 — Contracts** | This hub: `/init-workflows` → policy + runtime layout |
| **1 — Planning** | Optional upstream (e.g. Matt wayfinder / to-spec / to-tickets). Separate install. Tickets need triage labels + enough AC for an agent (Matt bodies are fine) |
| **2 — Autonomy** | This hub: `/loop-workflows` consumes `ready-for-agent`, implements in-session (Matt-style checks), opens PR |

**v0.2 is a consumer of the plumbing, not a full factory daemon.**

| Layer | Role |
|-------|------|
| This repo | Publishes skill packages (source) |
| Install target (e.g. `~/.agents/skills`) | Full skill directories after install |
| Each product repo | Policy under `docs/agents/` + runtime under `.agent-workflows/` |

### What `/init-workflows` does

1. **Audits** a fixed checklist (concrete paths — not an “initialized” stamp)
2. Reports present / missing / drift
3. **Repairs** gaps (confirm before writing policy docs)
4. **Re-audits** on disk and reports READY | NOT READY

It does **not** implement issues or drain queues.

### What `/loop-workflows` does

Ralph-shaped loop skill (user-invoked):

1. Preflight (GitHub + `gh`, clean tree, policy present)
2. Resume at most one incomplete claim, else pick **oldest** claimable `ready-for-agent`
3. Soft-skip open blockers and issues that already have a non-draft PR
4. Implement **in this session** (typecheck, focused tests, broader pass); open PR (`Closes #N`); `ready-for-human`
5. Append `.agent-workflows/progress.md`; stop on COMPLETE / BLOCKED / MAX / HARD STOP

| Mode | Invocation |
|------|------------|
| **once** (default) | `/loop-workflows` |
| **max N** | User states N explicitly (e.g. “max 3”) — no unbounded drain |

Empty queue → COMPLETE and a short hint to create tickets (Matt or manual). This skill never force-installs companions.

Design freeze: [docs/v0.2.md](./docs/v0.2.md).

### Product runtime (`.agent-workflows/`)

| Path | Purpose |
|------|---------|
| `progress.md` | Structured session log (date / what / outcome / learnings) |
| `logs/` | Optional per-run notes; reserved for a future host runner |

No config file in 0.2. Integration branch (if not the repo default) lives in **`docs/agents/issue-tracker.md`**.

Policy for issues/labels/domain lives in **`docs/agents/`** (reviewable in git), not under `.agent-workflows/`.

## Install

```bash
npx skills add LayishSieger/agent-workflows
# or from a local clone:
npx skills add /path/to/agent-workflows
```

That should place `init-workflows` and `loop-workflows` under your skills directory (exact CLI may vary).

### Optional planning companions

Ticket/spec generation is **not** shipped here. Example separate install (when you choose Matt or another pack):

```bash
npx skills add <owner/matt-or-other-skills-repo>
```

Then use that pack to produce GitHub issues that match `docs/agents` triage labels and are agent-ready (acceptance criteria, blockers).

## Usage

In a **product** repository:

```text
/init-workflows          # ensure contracts (any time)
/loop-workflows          # one ready issue → PR (default)
/loop-workflows max 3    # up to three ticks
```

- **Existing repo** with `docs/agents/*`: init repairs runtime gaps; loop needs GitHub + clean tree.
- **Greenfield**: init interview (tracker → labels → domain), then create issues, then loop.

Dogfood: real product with GitHub issues (e.g. MyResumeFlow), then optional multi-N.

## Repository layout

```text
agent-workflows/
  README.md
  CHANGELOG.md
  LICENSE
  docs/
    v0.1.md
    v0.2.md
  skills/
    init-workflows/       # contracts ensure skill + seeds
    loop-workflows/       # ready-work loop skill
```

## Out of scope (still)

- Host runner / global CLI (product-local Ralph shells stay product-local)
- Sandcastle (or any sandbox orchestrator) adapter
- Stack-from-blocker / epic-branch engines
- Bundling Matt (or other) planning skills into this hub
- Replacing or archiving other skill repos

## License

MIT — see [LICENSE](./LICENSE).
