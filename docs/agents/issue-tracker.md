# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`
- **List issues**: `gh issue list --state open --json number,title,body,labels` with appropriate filters
- **Comment**: `gh issue comment <number> --body "..."`
- **Labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repo from `git remote -v` — `gh` does this when run inside a clone.

## Integration branch

Git base for agent feature branches and PR `--base` (used by `/loop-workflows`).

**Integration branch:** `main`

_(Change to `dev`, `trunk`, etc. if PRs land somewhere other than the GitHub default branch. If unset, loop-workflows falls back to the repo default branch.)_

## Pull requests as a triage surface

**PRs as a request surface: no.**

_(Set to **yes** if this repo treats external PRs as feature requests.)_

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.
