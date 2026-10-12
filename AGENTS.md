# Agent instructions

## Development

Read `README.md` for setup and commands. Use `fvm flutter` and `fvm dart` locally so the SDK comes from `.fvmrc`.

Before changing code, follow `docs/agents/worktrees.md`. Continue this task in its assigned worktree; preserve unrelated changes.

Before changing calculator behavior or its UI integration, read `docs/architecture.md`. Implement only the assigned issue's scope. The initial application is a visual shell; input, validation, evaluation, and memory are separate team tasks.

For branches, review, commits, and test requirements, follow `docs/contributing.md`. Validation, evaluation, and memory changes require unit tests in the same PR. The first functional PR also enables their execution in CI.

Before making a commit, read the project-local MCGA skill at `.agents/skills/make-commits-great-again/SKILL.md`. Use English commit messages. Inspect staged and unstaged changes as well as new files; an empty unstaged diff does not imply there is nothing to commit. Existing user authorization takes precedence over the skill's confirmation step.

## Verification

- Run the formatter and analyzer commands from `README.md` after Dart changes.
- Run relevant unit tests when the changed behavior has tests.
- For visual changes, inspect the rendered screen, including a narrow window. Keep temporary preview harnesses outside the tracked source.
- Report the commands actually run and any unverified platforms. A successful CI build confirms compilation, not an interactive run on a teammate's machine.

## Agent skills

### Issue tracker

Issues and specs live in GitHub Issues. Before reading or publishing tickets, follow `docs/agents/issue-tracker.md`.

### Triage labels

Use the five canonical triage labels. When triaging issues, read the role mapping in `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: root `CONTEXT.md` and `docs/adr/`. Before exploring the codebase, follow `docs/agents/domain.md`.
