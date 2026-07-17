# Agent workflows — progress log

Structured session notes for this product repo. Append new entries at the top (newest first).  
Do not delete older entries unless the team agrees to archive.

**Control plane (v0.3):** hosts and schedulers read the latest entry’s **`outcome:`** field. Workers append; they do not preload full history by default. Process exit codes are **not** tick success.

---

## Outcome enum (required)

Every tick/session entry that participates in the host control plane **must** set:

| `outcome:` | Meaning |
|------------|---------|
| `SHIPPED` | Publish artifact created; ready-for-human |
| `NEEDS_INFO` | Fail path; needs-info; no success artifact |
| `SKIPPED` | Soft-skip that settled the ticket (e.g. spec/PRD) |
| `COMPLETE` | Empty queue + no incomplete claim |
| `BLOCKED` | Queue non-empty; nothing claimable |
| `HARD_STOP` | Preflight / env / infra failure |
| `FAILED` | Missing/unusable progress after spawn, or control-plane failure |

Allowed values only: `SHIPPED` | `NEEDS_INFO` | `SKIPPED` | `COMPLETE` | `BLOCKED` | `HARD_STOP` | `FAILED`.

---

## Template (copy for each tick / session)

```markdown
### YYYY-MM-DD — #N — <title>
- **outcome:** SHIPPED | NEEDS_INFO | SKIPPED | COMPLETE | BLOCKED | HARD_STOP | FAILED
- **publish:** <url or none>
- **checks:** pass | fail | n/a
- **note:** ≤1 line
```

| Field | Required | Notes |
|-------|----------|--------|
| `outcome:` | **yes** | Machine-readable; host/scheduler stop rules key off this |
| `publish:` | optional | Artifact URL when SHIPPED; `none` otherwise |
| `checks:` | optional | Implement quality gate result |
| `note:` | optional | Single short line |

Prose fields (What / Learnings) may be added below the machine fields if useful; they are not required for host control.

---

## Entries

<!-- Newest first -->
