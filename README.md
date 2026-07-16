# agent-workflows

**Status: v0.1** — init + contracts only. Not a full autonomous runner yet.

Shared workflows and skills for coding agents (Cursor, Claude Code, Grok Build, Codex, …).  
Install the skill pack; agents use what ships **inside the skill** (no extra hub checkout required at runtime).

## Mental model

```text
v0.1  install skill → /init-workflows → product has standard docs + .agent-workflows/
later CLI / plugins read that layout and run unattended loops
```

**v0.1 is plumbing, not the factory.**

| Layer | Role |
|-------|------|
| This repo | Publishes skill packages (source) |
| Install target (e.g. `~/.agents/skills`) | Full skill directory after install |
| Each product repo | Thin runtime + policy docs after `/init-workflows` |

### What `/init-workflows` does

One skill. **Every time it runs**, it:

1. **Audits** a fixed checklist (concrete paths — not an “initialized” stamp)
2. Reports present / missing / drift
3. **Repairs** gaps (confirm before writing policy docs)
4. **Re-audits** on disk and reports READY | NOT READY

It does **not** implement issues, drain queues, or spawn workers. That is a later release.

Everything the skill needs (checklist, interview, seeds, progress template, gitignore snippet) lives **in the skill folder** and is installed with it.

### Product runtime (`.agent-workflows/`)

| Path | Purpose |
|------|---------|
| `progress.md` | Structured session log (date / what / outcome / learnings) |
| `logs/` | Empty in 0.1; reserved for a future runner |

No config file in 0.1. Knobs for a CLI/backend land when that CLI exists.

Policy for issues/labels/domain lives in **`docs/agents/`** (reviewable in git), not under `.agent-workflows/`.

## Install (v0.1)

While the GitHub remote is private or missing, install from a local clone:

```bash
# after cloning/creating this repo at ~/projects/agent-workflows
npx skills add ~/projects/agent-workflows
# or: npx skills add ./   from inside this repo
```

That should place the full `init-workflows` skill directory under `~/.agents/skills` (exact CLI may vary).

Later (public):

```bash
npx skills add LayishSieger/agent-workflows
```

Harness plugins (Cursor, Claude Code, …) are planned after 0.1 is stable.

## Usage

In any product repository, in your agent chat:

```text
/init-workflows
```

- **Existing repo** with `docs/agents/*` already set up: audit + fill only runtime gaps (progress, logs, gitignore).
- **Greenfield**: interactive questions (issue tracker → labels → domain), confirm drafts, then write.

Dogfood order: a real product first, then a tiny greenfield.

## Repository layout

```text
agent-workflows/
  README.md
  CHANGELOG.md
  LICENSE
  docs/v0.1.md
  skills/
    init-workflows/          # install unit (Matt-shaped: process + seeds)
      SKILL.md               # audit → interview → write → runtime → re-audit
      progress.template.md   # runtime seed
      issue-tracker-github.md
      issue-tracker-local.md
      triage-labels.md
      domain.md
```

## Out of scope for v0.1

- Host runner / global CLI
- Sandcastle (or any sandbox orchestrator) adapter
- Migrating the full engineering skill set into this hub
- Replacing or archiving other skill repos

## License

MIT — see [LICENSE](./LICENSE).
