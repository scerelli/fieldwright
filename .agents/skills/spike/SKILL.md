---
name: spike
description: Use when executing a Spike-labeled issue — exploring an uncertain approach code-first, without the strict TDD loop `/implement` uses.
---

# /spike — exploratory sub-task execution

Runs inside a `/build` sub-task subagent on `subtask/<n>-slug`, for an
explicit **Spike issue** — exploring an uncertain approach code-first,
because the point is to learn something before committing to a design.

**Follow the sub-task execution contract in `CONVENTIONS.md`** —
prerequisites, scope guard, local gate, commit format, design-flaw signals,
review-failure handling, and what "done" means. This skill covers only the
exploration loop.

**REQUIRED SUB-SKILL:** `conventional-commits`.

## One extra prerequisite

The issue must be labeled `Spike` — `/build` routes those here regardless of
the plan's `## Build mode`. Without the label, a `/plan`-classified `direct`
sub-task belongs to `/direct` and anything else to `/implement`.

It must also carry **`## Question`** and **`## Timebox`**. No Question means
nobody stated what this Spike is for — a **design-flaw**, not something to
infer from the title. The Timebox is a real stop condition: when it's spent,
report what you learned, including "still unknown".

## The loop

1. **Write.** Explore code-first, per the plan's steps.
2. **Answer the Question in writing, on the issue** — which approach, and why.
   That is the Spike's first criterion and its deliverable; code that ships
   without it leaves the learning in a diff nobody rereads.
3. **Verify** each remaining criterion by its proof type (`CONVENTIONS.md`) —
   manual verification or a simple test script. Record the evidence for
   `/review`.
4. **Backfill tests before commit.** A Spike skips tests-*before*-code, not
   tests entirely — wherever the explored approach carries behavior a
   regression could silently break, lock it in with a test so the learning
   survives the commit.
5. **Refactor** before it goes to review.

## Rationalizations — each means the Spike is drifting off-purpose

| Excuse | Reality |
|---|---|
| "It's a Spike issue, so nothing needs a test ever" | A Spike skips tests-*before*-code, not tests entirely. Backfill before commit. |
| "Keep the draft as reference" | If a step needs rework, rewrite it. Half-verified exploration code does not belong in the commit. |

**Red flags:** you're polishing the exploration instead of landing the
learning · you're past the Timebox and still going · you're inferring the
Question because the issue doesn't state one.

## Common mistakes

- Running `/spike` without the `Spike` label → the label is the routing.
- Treating the Spike as a license to skip the backfill before commit.
- Reporting `shipped` from here → this step ends at `/review`.
