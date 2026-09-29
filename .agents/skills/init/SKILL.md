---
name: init
description: Use when bootstrapping a brand-new project that has no PRODUCT.md yet. Defaults to the solo profile; --full adds /ideate and /design, --lean also defers UX.md.
---

# /init — greenfield orchestrator

## Overview

`/init` is the single entry point for a brand-new project. It sequences the
document commands back to back. The default is the **solo profile**, sized
for one person building a domain-heavy product:

```
/validate → PRODUCT.md → /model → DOMAIN.md + GLOSSARY.md → /discover → TECH_STACK.md
          → /architect → ARCHITECTURE.md → /ux → UX.md          (DESIGN.md deferred)
```

- `--full` adds `/ideate` first and runs `/design` last instead of deferring it.
- `--lean` stops after `/architect` and defers both `UX.md` and `DESIGN.md`:
  for a product with no meaningful interface yet.

It owns no interview or document logic of its own — each command keeps its own
skill and stays callable individually. `/init` only guards, sequences, and
stops.

## Guard — run first, fail loud

If `docs/shipwright/PRODUCT.md` already exists, refuse. `/init` is greenfield
only, in either mode. Tell the user:

- To grow an existing backlog: run `/decompose`.
- To revise one document: run `/ideate`, `/validate`, `/model`,
  `/glossary`, `/discover`, `/architect`, `/ux`, or `/design` standalone.
  On an existing doc these are revision interviews (per
  `gated-doc-interview`), not blank-page restarts.

Never overwrite or re-interview over an existing pipeline.

## Preflight

After the guard, before the first interview: run the `init`-mode checks (gh
authenticated, a GitHub repo behind this directory, gh version, type labels
ensured to exist).

**REQUIRED SUB-SKILL:** Use `preflight`. A failed check stops `/init` with the
fix named — better now than partway through the interviews.

## Sequence

Run the steps in order. Each step invokes that command's skill and follows it
exactly; `/init` adds nothing to the interviews.

1. **`--full` only: `/ideate` → `IDEA.md`.** No gate beyond its
   confirm-before-create.
2. **`/validate` → `PRODUCT.md`.** Gated.
3. **`/model` → `DOMAIN.md`, then `GLOSSARY.md`** via `glossary` seed mode.
   Gated once, on the model summary.
4. **`/discover` → `TECH_STACK.md`.** Gated.
5. **`/architect` → `ARCHITECTURE.md`.** Gated.
6. **`/ux` → `UX.md`.** Gated. *(`--lean`: placeholder instead, step 8.)*
7. **`--full` only: `/design` → `DESIGN.md`.** Gated.
8. **Placeholders** for every doc the profile defers: `DESIGN.md` by
   default, `UX.md` and `DESIGN.md` under `--lean`. Not optional: `/plan`
   requires the files to exist, and the marker is what stops it raising a
   design-flaw over a deliberately missing doc.

All docs live in `docs/shipwright/`. Each gate behaves exactly as the
standalone command: summary confirmation per `gated-doc-interview`,
amendments loop back, the document is written only on confirm. A gate that
does not clear stops `/init` — never skip ahead, never auto-confirm on the
user's behalf.

**Material supplied up front.** If the user passes a brief (a file or inline
text), every interview drafts from it first and asks only what it leaves
open, per `gated-doc-interview`'s Skipping the interview. The gates still
run: a brief is input, not a confirmation.

## Deferred docs

A placeholder opens with the literal, greppable marker line
`<!-- shipwright:deferred -->`, followed by one sentence naming the command
that replaces it (`/design` or `/ux`). It must be verbatim: `/plan` treats
that exact marker as license to plan a UI sub-task without that doc's
guidance, noting the gap, rather than raising a design-flaw (see `plan`'s
Process, Step 2). Prose like "Deferred for now" does not count.

**What is never deferred:** `DOMAIN.md`, `GLOSSARY.md`, `TECH_STACK.md`,
`ARCHITECTURE.md`. `/plan` and `domain-review` check every sub-task against
them; deferring one would switch those checks off exactly when the codebase
is forming.

Why `DESIGN.md` is deferred by default and `UX.md` is not: for field
software, how the product must work under its conditions of use decides the
first screens; how it looks can follow once they exist. Use `--full` when
the visual identity matters from day one.

### Graduating off a placeholder

Run `/design` or `/ux` standalone. It is a `gated-doc-interview`, so it sees
the marker rather than content and runs a blank-page interview. Writing the
document removes the marker, and `/plan` resumes checking UI criteria against
it on the very next `/build`. `preflight`'s `build` mode names any doc still
carrying the marker on every run, so it stays visible. Graduating is a human
call about when the interface starts to matter.

## Finish setup

Once the document set exists and every gate has cleared, placeholders
included, hand off to
`repo-bootstrap` for the rest: project-context pointers in `CLAUDE.md`/
`AGENTS.md` and `.shipwright` local state.

**REQUIRED SUB-SKILL:** Use `repo-bootstrap`. `/init` is done once it
completes — including its own completion message suggesting
`/decompose docs/shipwright/PRODUCT.md` as the next step.
