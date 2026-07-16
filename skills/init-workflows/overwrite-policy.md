# Overwrite policy

| Kind | Action |
|------|--------|
| Missing `logs/` directory | Create; add empty `.gitkeep` |
| Missing `progress.md` | Create from [progress.template.md](progress.template.md) |
| Existing `progress.md` body | **Never** wipe or rewrite entries |
| Missing gitignore lines | Append only missing lines from [gitignore.snippet](gitignore.snippet) |
| Missing policy file | Interview → draft → confirm → write |
| Existing non-empty policy | **Do not** overwrite without explicit user confirmation |
| Empty policy (drift) | Propose seed fill; write only on confirm |
| AGENTS.md / CLAUDE.md | Optional offer only; never required for READY |

**Safe auto-repair** (no confirm): gitignore lines, `logs/` + `.gitkeep`, create missing `progress.md` only if the file is absent.
