# Changelog

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
