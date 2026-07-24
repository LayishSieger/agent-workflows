# Dogfood suite — agent-workflows

End-to-end dogfood for the skill pack: real (throwaway) GitHub product, clean worktree, simple issues, Grok as shell host worker.

This is **not** the browser `dogfood` skill. It is a CLI/skill acceptance suite so we do not rely on ad-hoc manual checks before commit/push.

## Quick start

From the **hub** repo root (this branch / working tree under test):

```bash
# 1) Cheap gate (no network product)
bash tests/dogfood/run-automated.sh
bash tests/dogfood/check-docs.sh

# 2) Isolated product + private GH repo + fixture issues
bash tests/dogfood/setup-sandbox.sh --scope product

# 3) Follow the agent playbook in the product directory
source /tmp/aw-dogfood-*/.dogfood-env   # path printed by setup
# open tests/dogfood/run-dogfood.md and work in $PRODUCT_DIR
```

## Layout

| Path | Role |
|------|------|
| [scenarios.md](./scenarios.md) | Full scenario matrix (source of truth) |
| [run-dogfood.md](./run-dogfood.md) | Agent playbook (Tiers 1–5) |
| [run-automated.sh](./run-automated.sh) | Tier 0: host tests + ops contract |
| [check-docs.sh](./check-docs.sh) | Tier 1 needle greps |
| [setup-sandbox.sh](./setup-sandbox.sh) | Create throwaway GH product |
| [teardown-sandbox.sh](./teardown-sandbox.sh) | Dry-run or delete sandbox |
| [report.template.md](./report.template.md) | Copy into product `dogfood-output/report.md` |
| `../../fixtures/dogfood-product/` | Minimal Node fixture (`hello.js`) |

## Default gate (before commit/push)

```text
Tier 0          A1 A2
Tier 1          D1–D7 (+ check-docs.sh)
Tier 2          I1 I2 + (I3 or I4)
Tier 3          L1 L2
Tier 4          H1 H2
Tier 5          S2 S3
```

Exit criteria: no unexplained HARD_STOP on happy path; L2 or H2 produces `SHIPPED` with publish URL; report filled with links.

## Design rules

1. **Product ≠ hub** — always a throwaway repo under `/tmp/aw-dogfood-*` (or `--dir`).
2. **Skills from local hub** — `npx skills add … $HUB_DIR`, never only remote `main`.
3. **Prefer product skill scope (P)** so dogfood does not clobber machine global skills.
4. **Spawn is human-owned** — setup writes a Grok one-liner with `{{PROMPT}}` for host tests; init dogfood may rewrite with confirm.
5. **Cheap first** — Tier 0 must pass before burning agent tokens.

## Host smoke without full init

After setup with `--scope product` (or hub `host.sh` + product spawn):

```bash
source "$PRODUCT_DIR/.dogfood-env"
# H1
mv "$PRODUCT_DIR/.agent-workflows/spawn" /tmp/spawn.bak
bash "$HOST_SH_HUB" -n 1 --cwd "$PRODUCT_DIR"; echo exit:$?
mv /tmp/spawn.bak "$PRODUCT_DIR/.agent-workflows/spawn"
# H2 (needs READY contracts + ready issue — run init + loop skill first for a fair ship)
bash "$HOST_SH_HUB" -n 1 --cwd "$PRODUCT_DIR"
```

## Teardown

```bash
bash tests/dogfood/teardown-sandbox.sh --repo OWNER/agent-workflows-dogfood-TS --dir /tmp/aw-dogfood-TS
# actually delete:
bash tests/dogfood/teardown-sandbox.sh --repo OWNER/NAME --dir PATH --delete
```

Default setup leaves the private repo for inspection.

## Related

- Design freeze: [docs/v0.3.md](../../docs/v0.3.md)
- Host unit tests: [tests/host-workflows/](../host-workflows/)
- Ops contract: [scripts/check-ops-contract.sh](../../scripts/check-ops-contract.sh)
