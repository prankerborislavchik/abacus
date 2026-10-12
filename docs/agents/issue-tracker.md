# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI for tracker operations.

Infer the repository from `git remote -v`; `gh` does this automatically inside a clone. If multiple remotes make the target ambiguous, resolve the intended repository before writing and pass `--repo <owner>/<repo>` explicitly.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body-file <path>`.
- **Read an issue**: `gh issue view <number> --json number,title,body,labels,assignees,comments,state,url`.
- **List issues**: `gh issue list --state open --json number,title,body,labels,assignees,comments`, with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body-file <path>`.
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`.
- **Close**: `gh issue close <number>`. If an explanation is needed, post it first.

For multiline issue bodies, PR descriptions, and comments, write the exact text to a temporary UTF-8 file and pass `--body-file`. Preserve real newlines.

## Pull requests as a triage surface

**PRs as a request surface: no.**

GitHub shares one number space across issues and PRs. Resolve an ambiguous `#number` with `gh pr view <number>`, falling back to `gh issue view <number>`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`; also fetch labels and assignees when needed.

## Wayfinding operations

Used by `/wayfinder`. The map is a single issue with child issues as tickets.

- **Map**: an issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body.
- **Child ticket**: link it to the map as a GitHub sub-issue. If unavailable, add it to a task list in the map body and put `Part of #<map>` at the top of the child body. Labels: `wayfinder:<type>` (`research`, `prototype`, `grilling`, or `task`).
- **Blocking**: use GitHub's native issue dependencies. Add an edge with `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`. Obtain the database ID with `gh api repos/<owner>/<repo>/issues/<blocker> --jq .id`; it is distinct from the issue number and node ID. If dependencies are unavailable, use a `Blocked by: #<n>, #<n>` line at the top of the child body.
- **Frontier**: inspect the map's open children in map order; choose the first unassigned child with no open blocker. For native dependencies, inspect `issue_dependencies_summary.blocked_by`; for the fallback, check each listed issue's state.
- **Claim**: assign the issue to the driving developer with `gh issue edit <number> --add-assignee <login>` before starting work; use `@me` when acting for the authenticated developer.
- **Resolve**: post the answer, close the child issue, then append a concise result and link to the map's Decisions-so-far.
