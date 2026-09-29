---
name: implement
description: Use when executing a single Sub-task issue inside a /build sub-task subagent, on its subtask/<n>-slug branch, after /plan has produced the sub-task's plan.
---

# /implement — TDD sub-task execution

Runs inside a `/build` sub-task subagent on `subtask/<n>-slug`, after
`/plan`. Writes the code for exactly one Sub-task.

**Follow the sub-task execution contract in `CONVENTIONS.md`** —
prerequisites, scope guard, local gate, commit format, design-flaw signals,
review-failure handling, and what "done" means. This skill covers only the
TDD loop, which is what makes it different from `/direct` and `/spike`.

**REQUIRED SUB-SKILL:** `conventional-commits`.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Wrote code before the test? **Delete it and start over.** Not "keep it as
reference", not "adapt it while writing tests". Delete means delete. If you
didn't watch the test fail, you don't know it tests the right thing.

**It binds every criterion the plan typed `test`** — those, and only those,
are what the loop runs over. `inspect` and `render` criteria are discharged
below instead, per `CONVENTIONS.md`'s Proof types.

**Mistyping moves one way only.** A non-`test` criterion that turns out to hit
a **behavior trigger** (`CONVENTIONS.md`) is mistyped: write the test, note it
in the handoff. Never the reverse. Downgrading a `test`
criterion mid-loop to skip a red is the rationalization the Law exists to stop.

## The loop — once per `test` criterion, in order

1. **Red.** Write ≥1 test that fails if and only if that criterion is unmet:
   one behavior, a clear name, real code (mocks only when unavoidable).
2. **Verify red — mandatory, never skip.** Run it. It must fail because the
   behavior is missing, not because the test is broken.

   Missing code can't reach its assertion: `Cannot find module`, `Property 'x'
   does not exist`, `undefined is not a function` are **valid reds** — step 3
   fixes them, never a stub written to force an assertion failure. Judge per
   **symbol**: a new method on an existing module still counts. Once the symbol
   exists with the tested signature, red must be an assertion failure.
   Exemption taken → step 4 pays it off.

   Passes immediately → testing existing behavior. Typo, filtered suite, or an
   import path matching no file in your declared list → broken test. Fix it.
3. **Green.** The simplest code that passes. No extra features, no
   improvements beyond it (YAGNI).
4. **Verify green — mandatory.** Test passes, suite still passes, output clean
   per `CONVENTIONS.md`. Something else broke? Fix it now. **Took step 2's
   exemption?** Break the new code, watch it fail *on the assertion*, restore
   — untested until you have. No lint or typecheck here; that's the gate.
5. **Refactor** only with everything green: remove duplication, improve
   names, extract helpers. No behavior changes.
6. Repeat until every `test` criterion has a passing red-first test. Then run
   the **full** suite, not just the new tests.

## Then discharge the rest — don't test them

With the loop green, close out the remaining criteria by their own proof:

- **`inspect`** — quote the `file:line` that establishes the fact.
- **`render`** — run it and compare against the token, `DESIGN.md` section, or `UX.md` rule
  the criterion names. Can't render here? Take `CONVENTIONS.md`'s fallback and
  report it as a gap — never pass a conformance claim read off the source as a
  render proof.

Record the evidence per criterion in the handoff — `/review` re-verifies each
independently, so this is its starting point, not its conclusion. Only now the
local gate.

## Common mistakes

- Writing the test after the code, in any form → that's the Iron Law.
- Skipping "verify red" because the test looks obviously correct → a test
  that has never failed is untested test code.
- Stubbing types or empty modules to make a red compile → a compile error
  against code that doesn't exist yet is already red.
- Taking step 2's exemption and skipping step 4's proof → the assertion has
  then never failed, which is all verify-red establishes.
- Linting or typechecking between criteria → that's the gate, once, at the end.
- Marking a criterion done on a test that passed the moment it was written.
- A test whose only assertion is that a component rendered or an element
  exists → that exercises the framework, not the criterion. A criterion with
  no assertion worth watching fail was never `test`.
- Claiming a `render` proof without rendering anything.
- Expanding beyond the declared files without flagging it.
- Reporting `shipped` from here → this step ends at `/review`.

See `reference.md` for the rationalization table — read it the moment you
catch yourself reaching for one.
