# agent-workflows

**Status: v0.3** — policy-driven shared tick, dual schedulers (chat + shell), three packages. GitHub is the only **proven** tracker instance.

Shared workflows and skills for coding agents (Cursor, Claude Code, Grok Build, Codex, …).  
Install the skill pack; agents use what ships **inside each skill** (no extra hub checkout required at runtime).

Design freeze: [docs/v0.3.md](./docs/v0.3.md).

## Mental model

```text
v0.1  /init-workflows     → contracts (docs/agents + .agent-workflows)
v0.2  /loop-workflows     → GitHub-only once | max N in one session
v0.3  policy ops + tick   → shared tick; chat workers for multi-N; thin shell host
later host runner fleet   → park, multi-spawn, rate-limit, stack engines
```

| Layer | Role |
|-------|------|
| **0 — Contracts** | `init-workflows` ensures policy + runtime; seeds encode the tracker **ops contract** |
| **1 — Planning** | Optional upstream (e.g. Matt wayfinder / to-spec / to-tickets). **Not** bundled here |
| **2 — Autonomy** | Worker tick in `loop-workflows`; schedulers only count **N** and stop |

| Layer | Role |
|-------|------|
| This repo | Publishes skill packages (source) |
| Install target (e.g. `~/.agents/skills`) | Full skill directories after install |
| Each product repo | Policy under `docs/agents/` + runtime under `.agent-workflows/` |

## Three packages

| Unit | Role |
|------|------|
| **`init-workflows`** | Contracts first. **Offers** (confirm) `host-workflows` install + spawn interview. Does **not** force-install `loop-workflows` |
| **`loop-workflows`** | Sole home of the **shared tick** and the **chat** entry (`once` / `max N`) |
| **`host-workflows`** | Thin sequential **shell** host (`SKILL.md` + `scripts/host.sh`). Install never executes scripts |

All three live under `skills/` and are discoverable by `npx skills add`.

### Dual schedulers, one tick

Both entry paths run the **same** worker-owned tick:

```text
resume | pick → claim → implement → publish → progress
```

| Entry | Role |
|-------|------|
| **Chat** `/loop-workflows` | **once** = one tick in this session; **max N** = parent schedules N **fresh one-tick workers** (subagents) |
| **Shell** `host-workflows` / `scripts/host.sh` | Sequential 1..N: spawn one-shot agent → read progress `outcome:` → stop rules |

Schedulers only own outer N and stop rules. Workers discover policy under product `docs/agents/*` and pick/resume themselves.

### Breaking change (0.2 → 0.3)

| Mode | 0.2 | 0.3 |
|------|-----|-----|
| **once** | One tick in-session | Same shape |
| **max N** | Up to N implements **in one session context** | Parent **only schedules**; each tick is a **fresh one-tick worker** |

Hard break — no compatibility flag. Pin a **0.2** install if same-session multi-N is required.

## What each skill does

### `/init-workflows`

1. **Audits** a fixed checklist (concrete paths — not an “initialized” stamp)
2. Reports present / missing / drift
3. **Repairs** gaps (confirm before writing policy docs; **never wipe** existing `progress.md`)
4. **Offers** (confirm) `host-workflows` install/wiring and a spawn interview (product file, machine file, or flag-only)
5. **Re-audits** on disk and reports READY | NOT READY

It does **not** implement issues, drain queues, or force-install `loop-workflows`.

### `/loop-workflows` (chat)

1. Preflight via product ops (`preflight`, `integration-base`, …)
2. Resume at most one incomplete claim, else pick oldest claimable ready work
3. Soft-skip open publish artifacts, open blockers, and skill-side **spec/PRD** bodies
4. Implement one ticket (typecheck, focused tests, broader pass when the product has them); create publish artifact; `ready-for-human`
5. Append `.agent-workflows/progress.md` with required **`outcome:`**; stop on COMPLETE / BLOCKED / MAX / HARD_STOP / FAILED

| Mode | Invocation |
|------|------------|
| **once** (default) | `/loop-workflows` |
| **max N** | User states N explicitly (e.g. “max 3”) — **no unbounded drain** |

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

All missing → **HARD STOP** (no silent default binary). Host runs `$SPAWN "<tick prompt>"` with prompt as the final argument; never adds `--continue` / `--resume`.

Workers must have **`loop-workflows`** installed for the agent binary you spawn. Control plane is progress **`outcome:`** only — process exit ≠ tick success.

## Product runtime (`.agent-workflows/`)

| Path | Purpose |
|------|---------|
| `progress.md` | Session log; hosts key off latest **`outcome:`** |
| `logs/` | Optional per-run notes |
| `spawn` | Optional one-line shell command string |

**No** full `.agent-workflows/config` in 0.3. Integration branch (if not the repo default) lives in **`docs/agents/issue-tracker.md`**.

Policy for issues/labels/domain lives in **`docs/agents/`** (reviewable in git), not under `.agent-workflows/`.

### Progress `outcome:` (control plane)

```markdown
### YYYY-MM-DD — #N — <title>
- **outcome:** SHIPPED | NEEDS_INFO | SKIPPED | COMPLETE | BLOCKED | HARD_STOP | FAILED
- **publish:** <url or none>
- **checks:** pass | fail | n/a
- **note:** ≤1 line
```

## Install

```bash
npx skills add LayishSieger/agent-workflows
# or from a local clone:
npx skills add /path/to/agent-workflows
```

That should place `init-workflows`, `loop-workflows`, and `host-workflows` under your skills directory (exact CLI may vary). You can install selectively if your skills CLI supports it.

### Optional planning companions

Ticket/spec generation is **not** shipped here. Example separate install (when you choose Matt or another pack):

```bash
npx skills add <owner/matt-or-other-skills-repo>
```

Then use that pack to produce issues that match `docs/agents` triage labels and are agent-ready (acceptance criteria, blockers).

## Usage

In a **product** repository:

```text
/init-workflows          # ensure contracts; optional host + spawn offer
/loop-workflows          # one ready issue → publish (default once)
/loop-workflows max 3    # up to three ticks via fresh workers (not one stuffed context)
```

Shell AFK (after spawn is configured):

```bash
bash ~/.agents/skills/host-workflows/scripts/host.sh -n 3
```

- **Existing repo** with `docs/agents/*`: init repairs runtime gaps without wiping progress; loop needs a usable tracker policy + clean tree for GitHub.
- **Greenfield**: init interview (tracker → labels → domain), then create issues, then chat loop and/or shell host.
- **Contracts only**: run init and decline the host/spawn offer; do not install loop if you only need policy docs.

Dogfood: real product with GitHub issues, once + multi-N via workers (chat or shell).

## Repository layout

```text
agent-workflows/
  README.md
  CHANGELOG.md
  LICENSE
  docs/
    v0.1.md
    v0.2.md
    v0.3.md
  skills/
    init-workflows/       # contracts ensure skill + seeds
    loop-workflows/       # shared tick + chat scheduler
    host-workflows/       # thin shell host + scripts/host.sh
  scripts/
    check-ops-contract.sh # structural check for tracker ops seeds
  tests/
    host-workflows/       # fake-SPAWN shell tests
```

## Out of scope (still)

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
