---
name: direct
description: Use when executing a sub-task /plan classified as build mode `direct` — declarative or presentational work with no behavioral criterion, without the strict TDD loop `/implement` uses.
---

# /direct — declarative and presentational sub-task execution

Runs inside a `/build` sub-task subagent on `subtask/<n>-slug`. Drops
`/implement`'s Iron Law for the one case that earns it: a sub-task `/plan`
classified **`direct`** — *no* criterion typed `test`, so nothing here is
about behavior and red-green-refactor adds latency without adding safety.

That covers declarative work (config values, version bumps, renames, docs) and
presentation work (tokens, static layout, themed placeholder screens) alike —
a render body is not behavior.

**Follow the sub-task execution contract in `CONVENTIONS.md`** —
prerequisites, scope guard, local gate, commit format, design-flaw signals,
review-failure handling, and what "done" means. This skill covers only the
direct loop and the mistyping escape hatch.

**REQUIRED SUB-SKILL:** `conventional-commits`.

## One extra prerequisite

The plan's `## Build mode` must say `direct`. If it says `tdd`, this is the
wrong skill — point to `/implement`. **Never override the plan's
classification yourself.** If the issue is labeled `Spike`, this is also the
wrong skill — that routes to `/spike` regardless of the plan's mode.

## The loop

A plan from `/plan`'s trivial fast path carries no steps — work the criteria
in order instead; each is still proven by its own type.

1. **Write.** Implement each step exactly as planned — **no logic beyond what
   the criteria state.** A behavior trigger you find yourself writing is the
   mistyping path below, not something to finish first.
2. **Verify each criterion by its own proof type**, per `CONVENTIONS.md`:
   `inspect` → quote the `file:line` that establishes the fact; `render` → run
   it and compare against the token, `DESIGN.md` section, or `UX.md` rule the criterion names.
   **Record the evidence per criterion** — `/review` re-verifies each one and
   cannot re-derive what you looked at.
3. **Backfill tests where they earn their keep.** Not needed for a renamed
   constant or a token swap — but write one wherever a step turns out to carry
   behavior a regression could silently break.
4. **Refactor** before it goes to review.

## Mistyping — stop, don't push through

Distinct from a design-flaw: the issue and docs are fine, but a criterion the
plan typed `inspect`/`render` turned out to be about behavior — its
satisfaction hits a **behavior trigger** (`CONVENTIONS.md`). That criterion was
`test`, so this sub-task was never `direct`.

**Stop as soon as you notice, before writing more code against it.** Report
to `/build` with which criterion and why. The sub-task reruns via `/implement`
with TDD on the affected criteria, on the same branch, without resetting the
retry counter.

Never push through a criterion you now know needs a test, and never retype one
to justify skipping it. Retyping only ever moves toward `test`.

## Rationalizations — each means the *choice* of `/direct` was wrong

| Excuse | Reality |
|---|---|
| "This criterion needs a branch, but I'm already here" | A criterion whose satisfaction needs real logic was `test` all along — report it. Switching skills is not overhead worth untested logic. |
| "It's only styling, nobody needs to look at it" | `render` is proven by rendering. Conformance asserted from the source is not a proof, it's a claim. |
| "Basically still simple, I'll skip the backfill" | If a step carries behavior a regression could break, backfill it even here. "Simple" and "untested forever" are different claims. |

**Red flags:** a step needed a branch or loop you didn't expect · you can't
state what would make a criterion false · you never actually ran the UI you
just themed.

## Common mistakes

- Running `/direct` on a `tdd` plan → wrong skill; never override the mode.
- Pushing new logic through because the sub-task was labelled `direct` → that's
  the mistyping path.
- Skipping the backfill on a step that carries real behavior.
- Widening the diff with logic no criterion asked for.
- Reporting `shipped` from here → this step ends at `/review`.
