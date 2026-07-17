# Changelog

## 0.3.0 — unreleased

### Added

- Design freeze [docs/v0.3.md](./docs/v0.3.md): policy-driven shared tick, dual schedulers, three packages
- Tracker **ops contract** in product policy seeds (ten named ops with Input / Steps / Success / Failure)
  - GitHub seed fully filled (reference instance)
  - Local seed: same headings; stub bodies OK in 0.3
  - Structural check: `scripts/check-ops-contract.sh`
- Progress control plane: required **`outcome:`** enum on entries (`SHIPPED` | `NEEDS_INFO` | `SKIPPED` | `COMPLETE` | `BLOCKED` | `HARD_STOP` | `FAILED`); template documents host semantics
- Skill package **`host-workflows`**:
  - Thin sequential shell host (`scripts/host.sh`) for AFK multi-tick without a chat parent
  - Spawn resolution: `--spawn` / `AGENT_SPAWN` > product `.agent-workflows/spawn` > machine `~/.config/agent-workflows/spawn`
  - Stop rules driven by progress `outcome:`; process exit ≠ tick success
  - Install never executes the host script
  - Fake-SPAWN shell tests under `tests/host-workflows/`
- `init-workflows`: **offer** (confirm) `host-workflows` install/wiring and spawn interview (product file, machine file, or flag-only); does **not** force-install `loop-workflows`
- README: three packages, dual entry (chat vs shell), multi-N break, install and usage for 0.3

### Changed

- **`loop-workflows` rewrite (breaking for max N):**
  - Shared tick is tracker-agnostic (op names + triage roles only; CLIs live in product policy)
  - **once** = one in-session tick (unchanged shape)
  - **max N** = parent **only schedules** fresh one-tick workers — no more N implements stuffed into one session context
  - Hard break from 0.2 same-session multi-N; pin 0.2 install if old behavior is required
- Claim / publish product meaning: leave-queue claim (no `claimed` role); success = create-publish-artifact → ready-for-human; fail → needs-info without re-queue
- Status: hub is **v0.3** (policy-driven tick + dual schedulers), not v0.2 consumer-only

## 0.2.0 — unreleased

### Added

- Skill package `loop-workflows` (user-invoked):
  - Ralph-shaped **once** / explicit **max N** over GitHub `ready-for-agent`
  - Same-session implement; incomplete-claim resume; oldest pick; blocker soft-skip; skip-if non-draft PR
  - Conservative lifecycle: claim → branch → Matt-style checks → PR (`Closes #N`) → `ready-for-human` (no merge/close)
  - Hard stops: dirty tree, non-GitHub, `gh` auth, missing policy
  - Progress auto-create under `.agent-workflows/`; empty-queue COMPLETE + companion soft hint
- Design freeze [docs/v0.2.md](./docs/v0.2.md)
- README: three-layer model (contracts / optional planning / loop), companion install as separate step

### Changed

- Quality bar: implement-time typecheck/tests (Matt-style), not ticket body sections
- `init-workflows` GitHub seed: optional **Integration branch**
- Greenfield interview: optional integration branch
- `loop-workflows`: preflight plan (will resume/pick), sandbox/`gh` retry note, soft-skip Matt `/to-spec` PRD bodies (do not implement; leave `/to-spec` unchanged)


## 0.1.0 — unreleased

### Added

- Hub scaffold: README, MIT license, design notes
- Skill package `init-workflows` (self-contained install unit):
  - User-invoked; short description; steps with completion criteria
  - Disclosed siblings: checklist, overwrite policy, greenfield interview, seeds
  - No hub checkout required after install

### Changed

- Moved all seeds/templates into `skills/init-workflows/` (removed top-level `templates/`)
- Matt-shaped package: process inlined in `SKILL.md`; siblings are seeds only (dropped checklist / overwrite / interview / gitignore files)
- Optional AGENTS pointer: no slash/`init-workflows` line (user-invoked skill); runtime-only when policy already documented
