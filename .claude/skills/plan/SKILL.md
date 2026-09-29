---
name: plan
description: Use when starting work on a single Sub-task issue inside a /build sub-task subagent, on the checked-out sub-task branch, before any implementation code is written.
---

# /plan — per-sub-task implementation plan

Runs inside a `/build` sub-task subagent on the `subtask/<n>-slug` branch.
Turns the issue's acceptance criteria into an ordered plan, types each
criterion, and derives the build mode from those types. **Writes no code.**

**The criteria are the spec.** The plan is derived from them, constrained by
`ARCHITECTURE.md` and `TECH_STACK.md` — never invented from the title.

## Prerequisites — fail loud

- `TECH_STACK.md`, `ARCHITECTURE.md`, `DOMAIN.md`, `GLOSSARY.md` exist
  (plus `UX.md` and `DESIGN.md` for UI-touching sub-tasks). Missing → refuse,
  name the command that produces it.
- The issue body carries explicit falsifiable acceptance criteria **and** a
  files/modules list. Either missing → the Sub-task wasn't ready; flag back to
  `/build`. Never invent criteria.

Read the issue live: `gh issue view "$N" --json number,title,body,state`.

## Process

1. **Restate each criterion as a falsifiable statement and assign its proof
   type** — `test`/`inspect`/`render`, per `CONVENTIONS.md`. Ambiguous,
   contradictory, impossible, or falsifiable under no type → **design-flaw**:
   stop and report. "Styled per `DESIGN.md`" names no token, so it is that
   case, not a `render` criterion. Never guess.

   **Speak the glossary.** `gh issue view "$N" --json body -q .body |
   ../glossary/scripts/glossary.sh scan -`: a hit, or a criterion naming a
   domain concept `GLOSSARY.md` lacks → design-flaw. Record the `INV-`/`UX-`
   IDs each criterion cites, plus any invariant it plainly touches, as its
   `guards`.
2. **Locate the work in the architecture.** Map each criterion to modules in
   `ARCHITECTURE.md`'s map; constrain choices to `TECH_STACK.md`. A criterion
   with no home in the architecture is also a design-flaw — do not improvise a
   module.

   A pinned choice constrains the **concrete artifact**, not just vocabulary:
   if `TECH_STACK.md` pins an ORM, driver, or library for a layer, every step
   touching it uses *that tool's own* pattern — never a generic example from
   the framework's docs, a starter template, or the project's
   `AGENTS.md`/`CLAUDE.md`, even when the generic one works. On disagreement,
   `TECH_STACK.md` wins. If its Tooling & CLI section pins a command, quote it
   verbatim rather than reconstructing an equivalent.

   *Exception:* a doc opening with `<!-- shipwright:deferred -->` is
   `/init`'s placeholder — plan from the criteria and files list alone
   and note in the output that guidance was unavailable. See `reference.md`.
3. **Derive ordered, bite-sized steps** for an executor with zero context.
   Each step states: which criterion it serves, exact files it touches, and how
   it's proven per that criterion's type. Fold setup into the step that needs
   it.
4. **No placeholders.** "TBD", "handle edge cases", "add appropriate error
   handling", "write tests for the above" without the test, or references to
   functions no step defines — all plan failures.
5. **Scope check.** The union of files across steps must match the issue's
   declared list. Needing more → either the Sub-task was under-specified
   (design-flaw, flag it) or the plan is wrong (revise). Narrowing is fine;
   note it.
6. **Derive the build mode** from the proof types. See below.

## Trivial-plan fast path

If every criterion is `inspect` and the files list names a single declarative
file, skip architecture mapping, ordered steps, and the step-based
self-review rules. Emit only the proof table, build mode, and scope check;
the executor derives the steps inline.

## Build mode

The mode follows from step 1's proof types; it is not a second judgment.

- **Any criterion typed `test`** → `tdd`; `/implement` owns the sub-task.
- **None typed `test`** → `direct`; `/direct` owns it (`reference.md`).

Inside a `tdd` sub-task the Iron Law binds the `test` criteria **only**; the
rest are discharged by their own proof, never by a test asserting that markup
exists.

A render body, a new component, or a themed screen does **not** by itself
force `tdd`; a criterion about *behavior* does. Type the criteria honestly and
the mode is already decided. `/review` re-checks every non-`test` typing
against the diff and routes a mistyped one back.

## Self-review before finishing

1. Every restated criterion is served by ≥1 step.
2. No placeholders (rule 4).
3. Names are consistent — `clearLayers()` in step 2 vs `clearFullLayers()` in
   step 5 is a bug.
4. Every step touching a pinned layer uses that tool's own pattern —
   re-checked against `TECH_STACK.md`'s exact line, not from memory.
5. Re-read each proof type against what its criterion actually claims, not the
   layer it lives in. Any **behavior trigger** (`CONVENTIONS.md`) in its
   satisfaction → `test`. Can't tell what it claims → `test`.

## Output

**Keep the plan in context and output it in your response. Never write
`PLAN.md`, never save it to disk, never commit it.** `/build` expects it in
context.

**Do not stop here.** Continue to `/implement` or `/direct`.

```markdown
# Plan: sub-task #<n> — <title>

## Build mode
tdd | direct — <which criteria are typed `test`, or that none are>

## Criteria restated
- C1 [test | inspect | render] guards: INV-00n, UX-00n | none: <falsifiable statement>

## Steps
1. <step> — serves C1 — touches `path/to/module.ts`
   Proof: <the failing test | the line to read | the render + named token>

## Scope check
Declared: <from the issue>   Planned: <across steps>   Match: yes | no (<why>)
```

## Common mistakes

See `reference.md`. The two most frequent: writing a `PLAN.md` (it stays in
context), and typing a behavioral criterion `render` because the sub-task is
"just UI" (the claim decides the type, never the layer).
