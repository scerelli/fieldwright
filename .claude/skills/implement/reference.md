# /implement — reference

## Rationalizations — every one means: stop, restart the loop

| Excuse | Reality |
|---|---|
| "We're behind schedule, tests after" | Tests-after pass immediately and prove nothing — they're biased by the code you already wrote. You never watched them fail, so you never proved they can catch the bug. |
| "Too simple to test" | Simple code breaks. The test takes 30 seconds. |
| "I already manually verified it" | Ad-hoc, unrepeatable, unrecorded. "Worked when I tried it" ≠ covered. |
| "Keep the draft as reference" | You'll adapt it. That's tests-after. Delete means delete. |
| "TDD is dogmatic; be pragmatic" | TDD **is** the pragmatic path: bugs caught before commit, regressions prevented. Shortcuts move the debugging to review — or production. |
| "Just the types/interface first, so the test compiles" | That's production code before its test, and it front-loads the design decision the Green step exists to make. An unresolved import *is* your red. |

**Red flags:** code before test · test passes immediately · can't explain why
the test failed · "tests added later" · "spirit not ritual" · "just this
once".

## Why "verify red" is not optional

A test that has never failed is untested test code. It may assert nothing, it
may assert something already true, or it may not run at all — a typo'd
describe block, a filtered suite, a wrong import path. Watching it fail *for
the expected reason* is the only evidence that it is wired to the behavior it
claims to cover. This is the single step that separates TDD from writing tests.

## Why a compile error counts as red

A test against a module that doesn't exist yet cannot reach its assertion —
the compiler or the loader stops first. Requiring assertion-level red would
force a stub of the module, its types, and its signature before every
criterion, which is production code written before its test. The Iron Law
forbids it, and it is where a typed sub-task's wall-clock actually goes.

The distinction is not *assertion vs. compile error*, it is **"the thing
under test doesn't exist yet"** (red) vs. **"the test points at the wrong
thing"** (broken). A wrong import path fails identically to an unwritten
module, and intent can't separate them — under retry pressure you always
"meant" to write it. Mechanical test: the imported path must match a file
your declared list says you are creating.

Per **symbol**, not per file, because sub-tasks add several criteria to one
module — a per-file rule would exempt criterion 1 and stall 2 through N.

**Why step 4 pays for it.** A compile-error red proves the symbol is missing,
not that the assertion is wired to anything. `expect(true).toBe(true)` would
sail through, and `/review` won't catch it — its `test` check asks whether a
test maps to the criterion and passes, not whether it can fail. Breaking the
code and watching the assertion fail restores exactly what the exemption gave
up, for one run instead of the scaffolding detour's several.

## Why one commit per sub-task

`/review` reviews a diff, `/ship` merges a branch, and the Sub-task issue is
the unit of both. One commit keeps that mapping exact: the sub-task branch's
diff against the item branch **is** the sub-task's work, with nothing else
riding along.

Follow-up commits on retry are the exception, and deliberately so — amending a
pushed commit rewrites history the reviewer may already have read, and forces
a force-push onto a branch `/ship` is about to merge.

## Why `git add -A` is banned

The working tree can hold artifacts from a crashed prior run. `git add -A`
sweeps them into the sub-task's commit, silently widening the diff past the
declared scope — which is exactly what the scope guard exists to prevent, defeated by a
staging shortcut.

## Why the local gate exists separately from /review

`/review` runs in a fresh subagent context. Spawning it, having it read the
diff, and having it report back a missing semicolon costs a full round-trip
plus a retry against the cap. Lint and typecheck are deterministic and
instant. Anything a machine can catch mechanically should never consume a
review cycle.

It does not replace `/review`, and passing it is not evidence of correctness —
only that trivial breakage isn't wasting the reviewer's turn.

That cuts both ways: what a machine fixes mechanically shouldn't consume a
*model* turn either. Hand-editing findings `--fix` would clear is the same
waste in a different place.

Scope the **linter** to your own files — `--write` at the repo root is a
formatter run disguised as a gate, leaving the reviewer a diff where the
sub-task's change is a minority of the lines. The **typecheck** is the
opposite: it needs the whole project to mean anything, and a signature change
that breaks callers outside your scope is a break you caused, not noise.

Once per attempt, at the end — but every attempt. Between criteria it pays N
times to format code the refactor step will change; skipped on a retry, the
fix commit reaches the reviewer unlinted.
