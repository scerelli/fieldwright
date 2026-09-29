# gh-sub-issues — reference

## Why type is a label, not GitHub's native issue type

Native issue types are gated on plan and account type, so a pipeline built on
them behaves differently on a personal repo than on an org one. Plain labels
behave identically everywhere, which is why there is no per-repo mode to
resolve anywhere in this pipeline.

The labels are created with `--force` (create-or-update) rather than
checked-then-created. That guarantees the intended color and description
regardless of prior state — including GitHub's auto-created default `bug`
label, and labels left over from an older version of this pipeline.

## The `bug` label collision

GitHub auto-creates a `bug` label on every new repo. On a repo that already
uses it for ordinary bug reports, `ensure-labels` recolors it, and those
existing reports become visually indistinguishable from this pipeline's
Bug-tier items. Worse, if such a report later gets a pipeline type label
added, `issue.sh type` correctly reports it as a data problem — two type
labels.

This pipeline does not namespace or rename `bug` to avoid the collision.
If it matters for a given repo, rename the pre-existing `bug` label before
installing.

## Why ordering uses native links only

`gh issue view <n> --json blockedBy` is queryable, machine-readable, and
enforced by GitHub. `Depends-on: #12` in a body is none of those — it drifts
the moment someone edits the text, and it cannot be validated. `issue.sh
order` reads only the native links, which is what lets it detect cycles and
dangling references at all.

## Why `all-closed` uses `subIssuesSummary`

`gh issue view <n> --json subIssuesSummary` returns `total` and `completed`
in one call, so the cascade test is a single request rather than one per
child. It returns `total: 0` for an issue with no sub-issues — which
`all-closed` treats as **not** closed, deliberately: "has no children" and
"all children are done" are different states, and only the caller knows
which one it meant.
