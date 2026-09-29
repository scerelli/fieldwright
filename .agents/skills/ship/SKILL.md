---
name: ship
description: Use when a sub-task has passed /review and domain-review inside a /build sub-task subagent and its sub-task branch must be merged, its issue closed, and the item/epic cascade evaluated. Also --force-close <item> to close an item whose remaining sub-tasks are descoped.
---

# /ship — merge + cascade-close

Runs inside a `/build` sub-task subagent after a successful `/review` and
`domain-review`.
Merges the sub-task branch, closes its issue, then walks the cascade upward
as far as it can go.

**REQUIRED SUB-SKILLS:** `gh-pr-merge` for every merge, `gh-sub-issues` for every
issue query, `conventional-commits` for every PR title. See
`CONVENTIONS.md` for the branch model, the production gate, and the return
vocabulary.

**`--force-close <item>`** merges and closes that item alone — for
deliberately descoped Sub-tasks, or a cascade that needs re-running. The
Prerequisites below do **not** apply to it. It requires an explicit human yes
on every open Sub-task it would abandon. Its procedure, preconditions, and
return live in `reference.md`.

## Prerequisites — fail loud

Current branch is `subtask/<n>-slug` and `/review` and `domain-review` have passed. Resolve the
parent item live — `../gh-sub-issues/scripts/issue.sh parent "$N"` — never
from the branch name or remembered state. Anything but exit 0 (including
exit 3, `no-parent`, which a Sub-task must never be) → return `stuck`. Never
guess the hierarchy.

## Step 1 — Merge the sub-task into the item branch

```bash
../gh-pr-merge/scripts/pr.sh land --push \
  --head subtask/<n>-slug --base feature/<m>-slug \
  --title "<type>(<scope>): <sub-task title>" --body "Closes #<n>"
```

Branch on the exit code per `gh-pr-merge`'s table — **`land` returning
non-zero means nothing merged**, so Step 2 must not run:

- **0** → merged; continue to Step 2.
- **3** (CI failed) → back to `/implement` on the **same branch** with the
  failing output; counts toward the attempt cap.
- **1** → `stuck`; the branch stays.

## Step 2 — Close the sub-task issue

Comment the PR link, then `gh issue close "$N"`. The close is mandatory.

## Step 3 — Item ship check

Query the parent item with `../gh-sub-issues/scripts/issue.sh all-closed
"$M"` and branch on its exit code:

- **exit 1 — any sibling open** → return `shipped`. The orchestrator advances.
- **exit 3 — no sub-issues at all** → this is the direct-build path (`/build`
  built the item itself, standing in for its own sole sub-task). Treat it
  exactly like "all closed" and ship the item below. Do **not** read
  "no children" as "nothing to ship."
- **exit 0 — all siblings closed** → ship the item below.
- **All closed** → the item ships into production. **Merge first, and only
  close the item issue if the merge actually landed** — run these as two
  separate steps, never as one block:

```bash
TARGET=$(../gh-pr-merge/scripts/pr.sh production-branch) || exit 1
../gh-pr-merge/scripts/pr.sh land \
  --head feature/<m>-slug --base "$TARGET" \
  --title "<type>(<scope>): <item title>" --body "Closes #<m>"
```

Branch on the exit code before doing anything else:

| exit | meaning | do |
|---|---|---|
| 0 | merged | `gh issue close "$M"`, then Step 4 |
| 3 | CI failed | sub-tasks passed individually but broke together — return `stuck` with the failing checks. **Never merge red, never close the issue.** |
| 4 | production merge | the human gate per `gh-pr-merge` — the pipeline's one such gate below `/release` |
| 1 | hard failure | return `stuck` with stderr |

**Closing `#<m>` on any non-zero exit is the worst failure this skill can
produce** — the issue reads as done, the work is unmerged, and `/recommend`
will never surface it again.

## Step 4 — Epic (report only)

Epic never owns a branch. Resolve it with `issue.sh parent "$M"` (exit 3 →
the item is top-tier; the cascade ends here). If all of an Epic's sibling
items are closed, say so and note that `gh issue close "$E"` will close it —
do not close it automatically. Otherwise the cascade ends here.

## Step 5 — Phase (report only)

A shipped item may have been the last open issue in its milestone. Run
`../gh-sub-issues/scripts/issue.sh closable-milestones`; if this phase
appears, report it complete and that `issue.sh close-milestone "<title>"`
will close it. **Never close it here** — same rule as the Epic. Why an
unclosed phase is not cosmetic: `reference.md`.

## Return

`shipped`, or `stuck` with the error. `/ship` never originates
`design-flaw`.

## Escape hatch

If the cascade is blocked by an abandoned Sub-task, point the user at
`/ship --force-close <item>` rather than working around it here.

For `--force-close`, crash mid-cascade, and reopened-PR edge cases, see
`reference.md`.

## Common mistakes

- Checking sibling status from local branches or remembered state → query
  `gh` live.
- Retrying on a fresh branch → retries stay on the same sub-task branch.
- Copying the issue title verbatim into `--title` → PR titles are
  `conventional-commits` headers.
- Creating a branch for an Epic → that tier never owns one.
