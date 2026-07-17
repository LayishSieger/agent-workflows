#!/usr/bin/env python3
"""Structural check for agent-workflows v0.3 ops contract + loop skill.

Fails if:
- GitHub seed is missing any required ## <op> section, or a section lacks
  Input / Steps / Success / Failure field markers
- Local seed is missing any of the same ## <op> headings
- Progress template does not document the required outcome: enum values
- loop-workflows skill is missing required op/role/outcome vocabulary, still
  hard-codes tracker CLI recipes, or omits the 0.2→0.3 multi-N worker break

Usage:
  python3 scripts/check_ops_contract.py
  # or
  bash scripts/check-ops-contract.sh
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILL = ROOT / "skills" / "init-workflows"
GITHUB_SEED = SKILL / "issue-tracker-github.md"
LOCAL_SEED = SKILL / "issue-tracker-local.md"
PROGRESS_TEMPLATE = SKILL / "progress.template.md"
LOOP_SKILL = ROOT / "skills" / "loop-workflows" / "SKILL.md"

REQUIRED_OPS = (
    "preflight",
    "integration-base",
    "list-queue",
    "read-ticket",
    "comment",
    "label-transition",
    "claim",
    "detect-publish-artifact",
    "incomplete-claim",
    "create-publish-artifact",
)

# Each op section must include these field markers (case-insensitive label match).
REQUIRED_FIELDS = ("Input", "Steps", "Success", "Failure")

OUTCOME_ENUM = (
    "SHIPPED",
    "NEEDS_INFO",
    "SKIPPED",
    "COMPLETE",
    "BLOCKED",
    "HARD_STOP",
    "FAILED",
)

HEADING_RE = re.compile(r"^##\s+(\S+)\s*$", re.MULTILINE)
FIELD_RE = re.compile(
    r"^\s*[-*]\s+\*\*(Input|Steps|Success|Failure):\*\*",
    re.MULTILINE | re.IGNORECASE,
)


def section_bodies(text: str) -> dict[str, str]:
    """Map ## heading name (lower) -> body until next ## or EOF."""
    matches = list(HEADING_RE.finditer(text))
    bodies: dict[str, str] = {}
    for i, m in enumerate(matches):
        name = m.group(1).strip().lower()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        bodies[name] = text[start:end]
    return bodies


def check_github(text: str, errors: list[str]) -> None:
    bodies = section_bodies(text)
    for op in REQUIRED_OPS:
        if op not in bodies:
            errors.append(f"GitHub seed: missing required section `## {op}`")
            continue
        body = bodies[op]
        found = {m.group(1).capitalize() for m in FIELD_RE.finditer(body)}
        # Normalize: re already captures as written; use title case of required
        found_lower = {f.lower() for f in found}
        for field in REQUIRED_FIELDS:
            if field.lower() not in found_lower:
                errors.append(
                    f"GitHub seed: section `## {op}` missing **{field}:** field"
                )


def check_local(text: str, errors: list[str]) -> None:
    bodies = section_bodies(text)
    for op in REQUIRED_OPS:
        if op not in bodies:
            errors.append(f"Local seed: missing required section `## {op}`")


def check_progress(text: str, errors: list[str]) -> None:
    if "outcome" not in text.lower():
        errors.append("Progress template: must document `outcome:` field")
    for value in OUTCOME_ENUM:
        # Word-boundary match so SHIPPED does not match SHIPPED_X
        if not re.search(rf"\b{re.escape(value)}\b", text):
            errors.append(
                f"Progress template: missing required outcome enum value `{value}`"
            )


# Tracker CLI recipes must live in product policy, not loop skill prose.
TRACKER_CLI_BANS = (
    r"\bgh\s+issue\b",
    r"\bgh\s+pr\b",
    r"\bgh\s+api\b",
    r"\bgh\s+auth\b",
    r"\bgh\s+repo\b",
    r"\bgh\s+label\b",
)

# Multi-N must be parent-schedules-workers, not same-session multi-implement.
WORKER_BREAK_MARKERS = (
    r"fresh\s+one[- ]tick\s+worker",
    r"\bsubagent",
    r"0\.2",
    r"hard\s+break|breaking\s+change|no longer|not\s+.*same[- ]session",
)


def check_loop_skill(text: str, errors: list[str]) -> None:
    """loop-workflows must be policy-driven (ops/roles by name) and document multi-N workers."""
    # Ops invoked by name (tracker-agnostic)
    for op in REQUIRED_OPS:
        if not re.search(rf"\b{re.escape(op)}\b", text):
            errors.append(f"loop-workflows: must invoke op by name `{op}`")

    # Triage roles by name (canonical)
    for role in (
        "ready-for-agent",
        "ready-for-human",
        "needs-info",
    ):
        if role not in text:
            errors.append(f"loop-workflows: must mention triage role `{role}`")

    # Progress control plane (`outcome:` — no trailing \b; colon is non-word)
    if not re.search(r"\boutcome:", text):
        errors.append("loop-workflows: progress entries must require `outcome:` field")
    for value in ("SHIPPED", "NEEDS_INFO", "SKIPPED", "BLOCKED", "HARD_STOP"):
        if not re.search(rf"\b{re.escape(value)}\b", text):
            errors.append(
                f"loop-workflows: missing required progress outcome value `{value}`"
            )

    # Claim / publish product meaning
    if not re.search(r"leave[- ]queue", text, re.IGNORECASE):
        errors.append("loop-workflows: claim must be documented as leave-queue only")
    if not re.search(
        r"(no|never|without)\s+(a\s+)?[`'\"*]*(claimed)[`'\"*]*\s+role"
        r"|no\s+[`'\"*]*(claimed)[`'\"*]*\s+role"
        r"|do\s+not\s+add\s+.*claimed",
        text,
        re.IGNORECASE,
    ):
        errors.append("loop-workflows: must state there is no claimed triage role")
    if "create-publish-artifact" not in text:
        errors.append(
            "loop-workflows: success path must call create-publish-artifact by name"
        )
    if not re.search(r"never\s+re-?appl|do not\s+re-?appl|no re-?queue", text, re.I):
        errors.append(
            "loop-workflows: fail path must never re-apply ready-for-agent / re-queue"
        )

    # Soft-skips
    if "detect-publish-artifact" not in text:
        errors.append("loop-workflows: soft-skip must use detect-publish-artifact")
    if not re.search(r"blocker|blocked by", text, re.I):
        errors.append("loop-workflows: must soft-skip open blockers")
    if not re.search(r"spec|PRD|/to-spec", text, re.I):
        errors.append("loop-workflows: must skill-side soft-skip PRD/spec bodies")
    if not re.search(r"\bSKIPPED\b", text):
        errors.append("loop-workflows: PRD/spec path must record outcome SKIPPED")

    # Modes: once in-session; max N = workers only
    if not re.search(r"\bonce\b", text, re.I):
        errors.append("loop-workflows: must document once (default) mode")
    if not re.search(r"max\s+N|max_items", text, re.I):
        errors.append("loop-workflows: must document max N mode")
    worker_hits = sum(
        1 for p in WORKER_BREAK_MARKERS if re.search(p, text, re.IGNORECASE)
    )
    if worker_hits < 3:
        errors.append(
            "loop-workflows: must document max N as fresh one-tick workers "
            "and hard break from 0.2 same-session multi-N"
        )
    if not re.search(
        r"parent\s+(only\s+)?schedul|schedules?\s+only|does not implement",
        text,
        re.I,
    ):
        errors.append(
            "loop-workflows: max N parent must only schedule (not implement N in one context)"
        )

    # No hard-coded tracker CLI recipes in skill body
    for pattern in TRACKER_CLI_BANS:
        m = re.search(pattern, text, re.IGNORECASE)
        if m:
            errors.append(
                f"loop-workflows: must not hard-code tracker CLI recipe "
                f"(found `{m.group(0).strip()}`); use policy op Steps instead"
            )


def main() -> int:
    errors: list[str] = []

    for path, label in (
        (GITHUB_SEED, "GitHub seed"),
        (LOCAL_SEED, "Local seed"),
        (PROGRESS_TEMPLATE, "Progress template"),
        (LOOP_SKILL, "loop-workflows skill"),
    ):
        if not path.is_file():
            errors.append(f"{label}: file not found at {path}")

    if GITHUB_SEED.is_file():
        check_github(GITHUB_SEED.read_text(encoding="utf-8"), errors)
    if LOCAL_SEED.is_file():
        check_local(LOCAL_SEED.read_text(encoding="utf-8"), errors)
    if PROGRESS_TEMPLATE.is_file():
        check_progress(PROGRESS_TEMPLATE.read_text(encoding="utf-8"), errors)
    if LOOP_SKILL.is_file():
        check_loop_skill(LOOP_SKILL.read_text(encoding="utf-8"), errors)

    if errors:
        print("check-ops-contract: FAIL", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        print(f"\n{len(errors)} problem(s).", file=sys.stderr)
        return 1

    print("check-ops-contract: OK")
    print(f"  GitHub seed: {len(REQUIRED_OPS)} ops with Input/Steps/Success/Failure")
    print(f"  Local seed:  {len(REQUIRED_OPS)} op headings present")
    print(f"  Progress:    outcome enum ({', '.join(OUTCOME_ENUM)})")
    print(f"  loop-workflows: ops-by-name, no tracker CLI, multi-N workers")
    return 0


if __name__ == "__main__":
    sys.exit(main())
