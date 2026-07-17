#!/usr/bin/env python3
"""Structural check for agent-workflows v0.3 tracker ops contract seeds.

Fails if:
- GitHub seed is missing any required ## <op> section, or a section lacks
  Input / Steps / Success / Failure field markers
- Local seed is missing any of the same ## <op> headings
- Progress template does not document the required outcome: enum values

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


def main() -> int:
    errors: list[str] = []

    for path, label in (
        (GITHUB_SEED, "GitHub seed"),
        (LOCAL_SEED, "Local seed"),
        (PROGRESS_TEMPLATE, "Progress template"),
    ):
        if not path.is_file():
            errors.append(f"{label}: file not found at {path}")

    if GITHUB_SEED.is_file():
        check_github(GITHUB_SEED.read_text(encoding="utf-8"), errors)
    if LOCAL_SEED.is_file():
        check_local(LOCAL_SEED.read_text(encoding="utf-8"), errors)
    if PROGRESS_TEMPLATE.is_file():
        check_progress(PROGRESS_TEMPLATE.read_text(encoding="utf-8"), errors)

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
    return 0


if __name__ == "__main__":
    sys.exit(main())
