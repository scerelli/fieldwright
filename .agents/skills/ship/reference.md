# /ship — reference

Edge cases and rationale. Read only when you are actually in one of these
situations; the main `SKILL.md` covers the normal path.

## `--force-close <item>`

Runs the merge-and-close half of Step 3 by hand, for an item that must close
outside the normal flow. It does **not** run Step 3's `all-closed` check —
that check exists to decide whether the cascade should continue, and its
"sibling still open" answer is precisely the case force-close overrides.

Its own preconditions replace `SKILL.md`'s: no sub-task branch and no passed
`/review` are required, and no argument means show usage rather than proceed.
It reports the milestone like the cascade does, but stops before the Epic.

Returns `shipped` once the item is merged and closed, or `stuck` with the
error — never `design-flaw`.

1. **Validate.** `../gh-sub-issues/scripts/issue.sh type <n>`; refuse unless
   `story`, `task`, or `bug`. Epics and Sub-tasks own no branch, so closing
   one is always a plain `gh issue close`.
2. **Handle open Sub-tasks.** `issue.sh children <n>`, partitioned by state.
   Any open → stop and present them by number and title with the consequence
   named: *"Sub-tasks #N, #M are still open. Closing this item leaves that
   work unmerged. Confirm: close them as descoped, or abort."* Only after an
   affirmative answer, close each with a comment saying it was descoped.
   Never close open work silently.
3. **Merge**, exactly as Step 3 of `SKILL.md` — same `production-branch`
   lookup, same exit-code table. If no PR exists **and no
   `feature/<n>-slug` branch exists at all**, there is nothing to merge: the
   item never started, or its work landed elsewhere. Say so and close it with
   a plain `gh issue close` plus a comment explaining why — do not leave it
   unclosable. If the branch exists but has no mergeable changes, stop and
   report rather than forcing it.
4. **Close only on exit 0.** The nothing-to-merge hatch above is the sole
   exception, and it requires no branch and no PR to exist at all.
5. **Report sibling status — no cascade.** Resolve the Epic with `issue.sh
   parent`, never from the branch name or the issue body. Exit 3 means
   top-tier: report and stop. Exit 1 means the lookup failed: report the item
   as closed and say the Epic could not be resolved; do not guess a number.
   If `all-closed` exits 0, say every sibling is closed and that `gh issue
   close "$E"` will close the Epic — do not close it. Then run the same
   milestone check as Step 5 of `SKILL.md`.

## Why every merge goes through `pr.sh land`

`/ship` and `/release` need the same three things around a merge: a PR in the
right state, checks actually green, and a merge that tolerates being re-run.
Inlined copies would be chances to drift, and a drifted copy is a merge that
isn't gated — so the sequence lives in one script and every caller invokes it.

`gh pr merge --auto` is never a substitute: it returns before the merge
lands, so the `gh issue close` right after it would run against a merge that
hasn't happened.

## Idempotency — why `/ship` can run twice for one sub-task

A `/review` failure sends the sub-task back to `/implement` on the same
branch, and `/ship` runs again when it passes. So every step must tolerate
prior partial completion:

- `pr.sh land` returns `already-merged` (exit 0) if the PR is already
  MERGED — it does not re-push, re-create, or re-merge.
- `gh issue close` on an already-closed issue is a no-op, not an error.
- A branch already deleted by a prior successful merge is expected;
  `gh pr list --head` still finds the PR by its recorded head-branch name.

This is also why the state check happens **before** the push: pushing first
would resurrect a branch that a completed merge had already deleted.

## Filtering PRs by head *and* base

A branch can accumulate PRs against more than one base — an item branch
retargeted after a base rename, or a PR closed against one base and reopened
against another. Matching on head alone picks an arbitrary one of them.

## Why `land` tolerates a PR it didn't create

`/build` runs Sub-tasks strictly one at a time, so nothing races `/ship`.
`pr.sh land` still tolerates finding a PR already there, because the
*sequential* re-entry paths are real: a `/review` failure sends the sub-task
back to `/implement` and `/ship` runs again on the same branch, and a crash
mid-cascade can leave a created-but-unmerged PR behind.

It relies on GitHub itself refusing a second open PR for an identical
head+base, and refusing to merge an already-merged PR:

- `gh pr create` failing with "already exists" → adopt the existing PR and
  continue.
- `gh pr merge` failing → re-query state. `MERGED` means a prior run got
  there first, which is success. Anything else is a genuine failure.

A CI failure (exit 3) is **never** this case. Do not conflate them.

## Crash mid-cascade

`/ship`'s Step 1 deletes the sub-task branch in the same operation that
Step 2 is supposed to close the issue. A crash between them leaves work
merged, the issue open, and no branch anywhere — see `/build`'s crash
recovery, which detects exactly this state and re-runs Step 2 rather than
re-implementing anything.

## Why an unclosed milestone matters

`/recommend` ranks the backlog by milestone due date, and a milestone keeps
its due date after the work inside it ships. A phase that was never closed
therefore holds the earliest due date in the repo permanently, and anything
that later lands in it — a straggler bug, a reopened item — heads the
backlog for good. `backlog.sh` sorts closed milestones after every open one,
so closing the phase is what actually retires it.

The same applies to the GitHub UI, where an open milestone with a past due
date reads as overdue work rather than a finished phase.

## Why the Epic close is manual

Epic is a pure organizational tier with nothing to merge. Closing one is a
statement that a body of work is finished, which is a human judgment — the
automated cascade reports readiness and stops. `--force-close` exists for the
item tier for the same reason, and `close-milestone` for the phase.

## Why the gate lives in Step 3

There is one integration point, so `/ship` Step 3 is the **only** thing
between an item's work and production — which is why `pr.sh` exit 4 fires
there. Everything below it (sub-task → feature) is unattended and CI-gated;
this one hop asks. `/release` is the only other merge into production, and it
carries the same gate.

## Merge conflicts

`pr.sh land` exits 1 when GitHub refuses the merge, and a conflict is the
common cause. It is not a CI failure and not a race — resolve it, don't retry.

**Sub-task → item branch.** Rebase the sub-task branch on the item branch,
resolve, re-run the full suite, then re-run `/ship` Step 1:

```bash
git fetch origin feature/<m>-slug
git rebase origin/feature/<m>-slug          # resolve, git rebase --continue
git push --force-with-lease origin subtask/<n>-slug
```

`--force-with-lease`, never `--force`: it refuses if the remote moved under
you, which is the whole risk of rewriting a branch a reviewer may have read.

**Item → production.** Do **not** rebase the item branch — sub-tasks already
merged into it, and rewriting that history invalidates their merge commits.
Merge production *into* the item branch instead, resolve there, and re-run:

```bash
PROD=$(../gh-pr-merge/scripts/pr.sh production-branch) || exit 1
git checkout feature/<m>-slug && git merge "origin/$PROD"
```

**If the conflict is semantic** — both sides are individually correct and the
combination isn't — that is a `design-flaw`, not a merge problem. Two
sub-tasks were scoped to overlapping work that `/decompose`'s file-overlap
check should have ordered. Report it against the item issue so the
decomposition gets fixed, rather than hand-merging past it.
