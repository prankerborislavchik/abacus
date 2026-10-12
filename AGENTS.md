# Agent instructions

## Development

Read `README.md` for setup and commands. Use `fvm flutter` and `fvm dart` locally so the SDK comes from `.fvmrc`.

Before changing calculator behavior or its UI integration, read `docs/architecture.md`. Implement only the assigned issue's scope.

For branches and review, follow `README.md#работа-в-команде`; for test requirements and ownership, follow `README.md#проверки`.

Before making a commit, follow `README.md#коммиты-mcga`. The optional upstream skill assists with wording; project language and existing user authorization still govern.

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
