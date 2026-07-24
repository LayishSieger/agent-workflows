#!/usr/bin/env bash
# Delete or archive a dogfood sandbox created by setup-sandbox.sh.
# Default is dry-run; pass --delete to actually remove the GitHub repo.
#
# Usage:
#   bash tests/dogfood/teardown-sandbox.sh --repo OWNER/NAME [--dir PATH] [--delete]
set -euo pipefail

REPO=""
DIR=""
DELETE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --dir) DIR="${2:-}"; shift 2 ;;
    --delete) DELETE=1; shift ;;
    -h|--help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$REPO" ]]; then
  echo "error: --repo OWNER/NAME required" >&2
  exit 2
fi

echo "repo: $REPO"
if [[ -n "$DIR" ]]; then
  echo "dir:  $DIR"
fi

if [[ "$DELETE" -eq 0 ]]; then
  echo "dry-run only. Re-run with --delete to:"
  echo "  gh repo delete $REPO --yes"
  if [[ -n "$DIR" && -d "$DIR" ]]; then
    echo "  rm -rf $(printf %q "$DIR")"
  fi
  exit 0
fi

gh repo delete "$REPO" --yes
echo "deleted remote $REPO"

if [[ -n "$DIR" && -d "$DIR" ]]; then
  rm -rf "$DIR"
  echo "removed local $DIR"
fi
