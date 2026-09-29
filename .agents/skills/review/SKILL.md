---
name: review
description: Use when a sub-task implementation inside a /build sub-task subagent is complete and must pass the review gate — after implementation, before domain-review and /ship.
---

# /review — code review gate

The gate between `/implement`/`/direct`/`/spike` and `/ship`. Two questions,
**in order**:

1. **Spec compliance** — does this do what the Sub-task issue said?
2. **Code quality** — is this good code by the project's standards?

Both must pass; never conflate them. `CONVENTIONS.md` holds the retry cap,
return vocabulary, and proof types.

## Prerequisites — fail loud

- `/implement`/`/direct`/`/spike` reported done: committed, suite green, gate
  run.
- The issue carries acceptance criteria and a files/modules list. Missing or
  unusable → **design-flaw**, never improvised around.
- You have `/plan`'s build mode **and its per-criterion proof table** — Check 1
  verifies differently per proof type.

## Fresh context, always

**The reviewer must not be the context that wrote the code** (`reference.md`).
The sub-task subagent spawns a dedicated **reviewer subagent** and hands it
crafted context, never session history:

- the issue number and its acceptance criteria **verbatim**;
- **`/plan`'s build mode and proof table, verbatim** — never on disk, so the
  sub-task subagent is the only source; omitting them ships a mistyped
  criterion unverified;
- the executor's recorded evidence per non-`test` criterion;
- the diff range: `HEAD_SHA=$(git rev-parse subtask/<n>-slug)` and
  **`BASE_SHA=$(git merge-base subtask/<n>-slug feature/<m>-slug)`** — the
  fork point, never the item branch's tip (`reference.md`);
- pointers to `ARCHITECTURE.md` (and `UX.md`, `DESIGN.md` for UI sub-tasks);
- no implementation narrative, no "here's what I tried."

Fallbacks for missing subagents: `reference.md`.

For diffs under 20 lines with only `inspect` criteria, see `reference.md`'s
trivial-change fast path.

**Report format:** strengths first, then findings labelled **Critical**
(blocks), **Important** (fix before ship), or **Minor** (note only) — each with
`file:line`, what, and why. Then a verdict. Concrete only; "could be cleaner"
is not a finding.

## Check 1 — spec compliance

Read the issue via `gh`. Walk the criteria **one by one, in writing**. Per
criterion:

- **`test`** — a test maps to this criterion and passes when run.
- **`inspect`** — read the line it cites and confirm it states the whole claim.
  One whose correctness isn't obvious from that line does **not** pass on
  inspection.
- **`render`** — run it; failing that, compare against the token it names and
  record the weaker proof. Never pass either on the executor's word — their
  evidence is where you start, not what you accept.
- Always: what you observe matches the criterion **as written**, not as
  interpreted.

Compare `git diff --name-only $BASE_SHA..$HEAD_SHA` against the declared
files list — **the range is required**; a bare `git diff` on a committed tree
passes vacuously. Flag divergence.

Verdict per criterion: `pass` / `fail:<concrete reason>`. Never pass on
intent, partial coverage, or "close enough."

A **wrong, contradictory, or unfalsifiable** criterion is a spec problem: stop,
record which and why, return `design-flaw`. Never guess what it "must have
meant."

### Second-guess the typing — every non-`test` criterion

Re-run `/plan`'s own test on each: does its satisfaction, in this diff, hit a
**behavior trigger** (`CONVENTIONS.md`)? Then it was `test` **regardless of how
the code turned out** — fail it `fail:mistyped — needs a test`, one diff
location each, and route back to `/implement`.

**Then check the diff, not just the criteria.** New logic no criterion accounts
for is untested behavior or dead code — **Critical** either way. Criteria bound
what was asked, not what the diff contains.

Runs in both modes, pass or fail. The reverse is never yours: a `test`
criterion whose test only asserts markup exists is a Check 2 finding, not one
you retype.

## Check 2 — code quality

Only after every criterion passes. Review **the sub-task's diff only**:

**Correctness** (edge cases, error handling, dead logic, tests asserting only
that markup exists) · **Readability** (conventions, no speculative
generality) · **UX-fit** (UI diffs: every `UX.md` rule the changed screens
fall under, system states included) · **Architecture-fit**
(boundaries and data flow per `ARCHITECTURE.md`) · **Security** (scan
below, then untrusted input and unsafe calls) · **Performance** (hot-path
waste, N+1, unbounded work).

### Secrets scan — before the security pass

```bash
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source . --log-opts="$BASE_SHA..$HEAD_SHA" -v
elif command -v trufflehog >/dev/null 2>&1; then
  trufflehog git file://. --since-commit "$BASE_SHA" --branch "$HEAD_SHA"
else
  echo "No secrets scanner installed — falling back to manual inspection."
fi
```

A finding here is **Critical** — a leaked secret is never Minor. A
missing scanner is **reported as a gap**, never silently skipped.
Dependency/CVE scanning belongs in CI (`reference.md`).

## Outcomes

- **Both pass** → `domain-review`, then `/ship`.
- **Any failure, including a mistyped criterion** → back on the **same
  branch** with concrete findings: failing criteria verbatim, `file:line` for
  quality issues, what "done" looks like. Mistyping routes to `/implement`;
  other findings on a `direct` diff may stay with `/direct` if the fix adds no
  behavior. You do **not** count attempts — report the verdict; the subagent
  counts.

Critical and Important block; Minor doesn't. If the reviewer is wrong, push
back with the code or test that proves it — never taste, and never accept a
valid finding silently.
