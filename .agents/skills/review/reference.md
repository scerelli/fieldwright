# /review — reference

## Why `merge-base`, not the item branch's current tip

`BASE_SHA` must be `git merge-base subtask/<n>-slug feature/<m>-slug`, never
a live `git rev-parse feature/<m>-slug`.

The item branch can move forward — a sibling sub-task merges — after this
sub-task's branch was cut but before its review runs. A
two-dot diff against the item branch's *current* tip then diffs against a
commit that isn't even an ancestor of this sub-task's `HEAD`, which surfaces
unrelated files from the sibling's work and can mask real changes in this one.

`merge-base` always resolves to where this branch actually forked, regardless
of how far the base has moved since. It is correct in serial mode too; it is
simply not *load-bearing* there.

## Reviewer fallbacks

**No nested subagents.** The sub-task subagent stops after
`/implement`/`/direct`/`/spike` and returns `implemented` **plus the build mode and the
proof table** — `/build`'s Step 3 return contract carries both for exactly
this reason. `/build` spawns the reviewer itself, hands it both alongside the
rest of the context, then resumes the sub-task subagent with the verdict. `/build` counts attempts in this mode.

**No subagent mechanism at all.** Review inline, and **flag in the report
that the review was not independently contextualized.** This is a degraded
review, and saying so is what keeps it honest — a reader must be able to tell
which reviews had the sunk-cost bias the fresh-context rule exists to remove.

## Trivial-change fast path

If `git diff --stat $BASE_SHA..$HEAD_SHA` shows fewer than 20 changed lines
**and** every criterion is typed `inspect`, the reviewer may run inline in the
executor's context — **only after** the executor has written a checklist
proving each criterion verbatim against the diff. The checklist replaces the
fresh-context review for this change. The second-guess pass and Check 2 still
run; only the context switch is skipped.

## Why dependency/CVE scanning is not done here

Secrets and dependency vulnerabilities look similar but behave differently.

A secret must be caught **before a specific diff merges** — once it lands in
history, rotating it is the only remedy. That is inherently per-diff work, so
it belongs in review.

A dependency CVE is a **whole-manifest, point-in-time** concern. A new CVE in
an already-merged dependency doesn't wait for the next sub-task's review to
matter, and re-auditing the full manifest inside every sub-task's review
would cost real time and tokens per sub-task for no earlier detection.

That belongs in CI — a scheduled or on-push job (Dependabot, `npm audit`,
`pip-audit`, `govulncheck`, `osv-scanner`), set up once via `/discover`'s
Testing & tooling question. `/ship`'s CI gate already blocks every merge in
the cascade on it once it's red.

## Why the two checks are ordered, not merged

Check 2 on code that fails Check 1 is wasted work — the code is going back to
`/implement` regardless, and quality findings against a diff that's about to
be rewritten are noise. Running spec compliance first also stops the common
failure where green tests and tidy code create enough confidence that nobody
re-reads what the issue actually asked for.

## Why the reviewer gets criteria verbatim

Paraphrasing an acceptance criterion into the reviewer's prompt is the same
failure the review exists to catch — the implementer's interpretation
standing in for what was written. The reviewer must compare the diff against
the issue's own words, which means it needs those words, not a summary of
them.

## Common mistakes

- Reviewing the diff yourself when a subagent mechanism exists.
- Skipping Check 1 because tests are green → tests existing ≠ criteria
  satisfied.
- Taking the executor's word on a non-`test` criterion, or skipping the
  second-guess pass because the mode is `tdd`.
- Rubber-stamping Check 2 → findings need `file:line`, what, and why.
- Fixing issues inline instead of sending them back.
- Rewriting a bad criterion yourself → that's a `design-flaw` return.
