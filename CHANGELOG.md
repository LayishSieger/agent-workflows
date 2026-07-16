# Changelog

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
