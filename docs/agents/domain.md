# Domain docs

This repository uses a single context: `CONTEXT.md` at the root and architecture decision records (ADRs) in `docs/adr/`.

## Before exploring the codebase

Read the root `CONTEXT.md` and the ADRs relevant to the area you are about to work in.

If these files do not exist, proceed silently. Domain documentation is created lazily through `/domain-modeling` when terminology or decisions are resolved.

## File structure

```text
/
├── CONTEXT.md
└── docs/
    └── adr/
        └── NNNN-short-decision-title.md
```

## Use the glossary's vocabulary

Use the terms defined in `CONTEXT.md` when naming domain concepts in issues, proposals, hypotheses, and tests. If a needed concept is absent, check whether an existing term covers it; otherwise note the gap for `/domain-modeling`.

## Flag ADR conflicts

If a proposal contradicts an existing ADR, identify that ADR and explain why the decision should be reconsidered.
