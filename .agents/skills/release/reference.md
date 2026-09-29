# /release — reference

## Rolling back a bad release

A release that merged into production and turns out to be bad (a regression
only visible in production) is fixed forward, never by `git reset` or a
force-push. Production is history: it only moves forward.

1. **File a Bug issue first.** The revert still needs an issue to attach its
   PR and changelog entry to.
2. Build it like any other Bug — `/decompose` it if it needs sub-tasks, then
   `/build`. The fix itself is a revert of the merge commit rather than a
   hand-edit of the change back out:
   ```bash
   git revert -m 1 <bad-merge-commit-sha>
   ```
   `-m 1` names which parent is mainline. For any release merge into
   production that is always parent 1 — production's own history.
3. A pure revert's criteria carry no `test` type of their own — the behavior
   they restore was already tested — so `/plan` derives `direct` and it routes
   to `/direct` with no special-casing.
4. Tag it with `/release`, using `scripts/version.sh suggest --patch` to
   force a patch bump.

**A revert is not always the whole fix.** If the bad release also applied a
data migration or triggered an external side effect, reverting the code does
not undo those. Flag that to the human explicitly — this pipeline does not
guess at undoing effects outside git history.

## Why `version.sh check` distinguishes three retry states

`land-and-tag` merges, then tags, then deletes the branch — so the pair
(tag on remote, branch still present) pins down exactly where an interrupted
run stopped:

| tag on remote | branch exists | meaning |
|---|---|---|
| yes | no | fully released — stop, not a retry |
| yes | yes | crashed after tagging, before the branch was deleted — resume |
| no | yes | crashed before the production merge — resume |
| no | no | new release |

Checking the **remote** for the tag matters: a prior run may have pushed it
from a working tree that no longer exists, and a local `git tag -l` would
miss that and re-push, which git rejects.

## Why the changelog commits before the merge

Landing it in the same PR as the release keeps production history
self-describing — the tagged merge commit contains its own changelog entry.
A changelog pushed afterward is a second commit on production outside the
gated merge, which is exactly the kind of ungated write the production gate
exists to prevent.
