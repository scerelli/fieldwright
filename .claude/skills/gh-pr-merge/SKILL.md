---
name: gh-pr-merge
description: Use when a pipeline skill (ship, release) must open or resume a PR and merge it only once CI is actually green.
---

# gh-pr-merge — idempotent, CI-gated PR merge

Every merge in the pipeline runs through one script. Call it; never
transcribe its logic inline.

```bash
scripts/pr.sh land --head <head> --base <base> \
  --title "<conventional-commits title>" --body "Closes #<n>" [flags]
```

`land` is idempotent and race-tolerant: it creates the PR, reopens it if it
was closed unmerged, gates on CI, merges, and deletes the branch. Re-running
it after a partial failure is always safe.

**Flags:** `--push` (push the head branch first), `--confirmed` (a human
approved this merge — required for production).

**Exit codes — branch on these, always:**

| code | meaning | what the caller does |
|---|---|---|
| 0 | merged (or already merged) | continue |
| 1 | hard failure | return `stuck` with stderr |
| 3 | CI failed | the caller's own failure handling (back to `/implement`, or `stuck`) |
| 4 | base is production, no `--confirmed` | get the explicit human yes, then re-run |

**There is no "no CI configured" outcome, and nothing here accepts a local
test run in place of CI.** Whether this repo has CI is settled once by
`preflight`, before `/build` starts; a repo that genuinely has none declares it
with `SHIPWRIGHT_NO_CI=1`. Reaching a merge with no checks and no declaration
is exit 1 — a misconfiguration, not a fallback to improvise around.

Before concluding a PR has no checks, `land` re-polls for
`SHIPWRIGHT_CI_WAIT` seconds (default 60): a freshly created PR has none
registered yet, and gh reports that identically to a repo with no CI at all. A
slow first merge is that wait, not a hang.

Exit 4 is the production gate from `CONVENTIONS.md` enforced in code. This
skill never asks for confirmation itself — the calling skill wraps its own
confirmation around the call and passes `--confirmed`.

Callers branch on these codes and add only their own per-code actions (what
comes next on 0, where a 3 routes) — the generic 2/4 handling above is stated
here once; never re-state it inline at the call site.

## `land-and-tag` — the /release shape

```bash
scripts/pr.sh land-and-tag --head <head> --tag v<version> \
  --title "<title>" --body "<body>" [--confirmed]
```

One call: merges into production, tags that merge commit, deletes the branch.
Same exit codes. The tag is only ever created after the merge lands, so a
failure never leaves a tag pointing at unreleased content.

Production is resolved by convention over `main`/`master`/`trunk`, never from
the repo's default branch; override with `SHIPWRIGHT_MAIN`. Gating on a
hardcoded `main` would mean the gate silently does not exist on such repos.
`pr.sh production-branch` prints the resolved name for callers that need it.

Also available: `pr.sh state --head H --base B` (prints `<number> <state>`)
and `pr.sh ci-gate <ref>` (0 green / 3 failed / 1 none), for callers that need
the pieces.

## Common mistakes

- Setting `SHIPWRIGHT_NO_CI=1` to get past a red or missing gate → it is a
  human's standing statement about the repo, made at `preflight`. An agent
  setting it mid-run has disabled the only gate below production.
- Using `gh pr merge --auto` instead → it returns before the merge lands, so
  anything after it (tagging, closing an issue) acts on a merge that may not
  have happened.
- Re-implementing the create/reopen/merge sequence inline because the call
  site "only needs part of it" → the idempotency and race-tolerance are the
  point; partial copies lose both.
