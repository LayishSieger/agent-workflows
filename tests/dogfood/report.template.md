# agent-workflows dogfood report

| Field | Value |
|-------|-------|
| **Date** | YYYY-MM-DD |
| **Hub path** | |
| **Hub ref** | branch / commit |
| **Product dir** | |
| **Product repo** | |
| **Skill scope** | product (P) / global (G) |
| **Worker binary** | grok / other |
| **Run mode** | default gate / full suite |

## Summary

| Tier | Pass | Fail | Skip |
|------|------|------|------|
| 0 Automated | | | |
| 1 Docs / AC | | | |
| 2 Init | | | |
| 3 Loop | | | |
| 4 Host | | | |
| 5 Security | | | |

**Overall:** PASS | FAIL | PARTIAL

**Ready to commit/push?** yes / no

---

## Tier 0 — Automated

```text
# paste host test + ops-contract output tails
```

| Check | Result |
|-------|--------|
| `tests/host-workflows/test_host.sh` | |
| `scripts/check-ops-contract.sh` | |

---

## Tier 1 — Docs / issue #14 AC

| ID | Result | Notes |
|----|--------|-------|
| D1 README mental model | | |
| D2 CHANGELOG 0.3 | | |
| D3 docs/v0.3.md freeze | | |
| D4 init READY independence | | |
| D5 init no silent install | | |
| D6 spawn recipes human-owned | | |
| D7 issue #14 AC map | | |

---

## Tier 2 — Init

| ID | Result | Evidence |
|----|--------|----------|
| I1 Greenfield S | | status block / paths |
| I2 Re-run no wipe | | progress hash before/after |
| I3 Shell H+G | | host-entry, spawn line |
| I4 Shell H+P | | product skills path |
| I5 Spawn keep | | |
| I6 Dual-install warn | | |

---

## Tier 3 — Loop

| ID | Result | Issue / PR / outcome |
|----|--------|----------------------|
| L1 Empty COMPLETE | | |
| L2 Once SHIPPED | | |
| L3 PRD SKIPPED | | |
| L4 Dirty preflight | | |
| L5 max N workers | | |
| L6 Resume incomplete | | |

---

## Tier 4 — Host (Grok)

| ID | Result | Host overall / progress |
|----|--------|-------------------------|
| H1 Missing spawn HARD STOP | | |
| H2 Once tick | | |
| H3 Multi-tick MAX | | |
| H4 BLOCKED stop | | |
| H5 Stale HARD_STOP retry | | |
| H6 --spawn override | | |

---

## Tier 5 — Security smoke

| ID | Result | Notes |
|----|--------|-------|
| S1 Untrusted issue shell | | |
| S2 No forced unattended install | | |
| S3 Automated still green | | |

---

## Failures / follow-ups

1.

## Decision

- [ ] Fix before commit
- [ ] Document intentional expansion vs issue #14
- [ ] Commit + push
