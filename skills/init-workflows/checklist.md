# Ensure checklist

Audit and re-audit against these rows only. No marker files. AGENTS.md / CLAUDE.md is **not** required for READY.

| # | Artifact | Ready when |
|---|----------|------------|
| 1 | `docs/agents/issue-tracker.md` | File exists and is non-empty |
| 2 | `docs/agents/triage-labels.md` | File exists and is non-empty |
| 3 | `docs/agents/domain.md` | File exists and is non-empty |
| 4 | `.agent-workflows/progress.md` | File exists |
| 5 | `.agent-workflows/logs/` | Directory exists (`.gitkeep` optional but preferred) |
| 6 | `.gitignore` | Contains the ignore rules from [gitignore.snippet](gitignore.snippet) |

**Status values:** `present` | `missing` | `drift` (exists but fails "ready when", e.g. empty policy file).
