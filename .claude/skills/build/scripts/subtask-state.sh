#!/usr/bin/env bash
# shipwright subtask-state.sh — what actually happened to an open Sub-task.
#
#   subtask-state.sh <subtask-issue> <item-branch>
#
# Answers the one question /build's crash recovery needs, from live state
# rather than from memory. Prints exactly one word:
#
#   never-started     no branch, no PR — spawn a fresh subagent
#   in-flight         branch exists, not merged — INSPECT before acting
#   merged-not-closed work already merged, issue still open — run /ship Step 2
#   done              issue is closed — nothing to do
#
# The merged-not-closed case is the one that is easy to get wrong: /ship's
# Step 1 deletes the sub-task branch in the same operation Step 2 is supposed
# to close the issue in. A crash between them leaves the work merged, the
# issue open, and no branch anywhere to hint at it. Re-implementing from a
# branch tip that already contains the work is the failure this prevents.
set -uo pipefail

die() { printf 'subtask-state.sh: %s\n' "$1" >&2; exit 1; }

n="${1:-}"; item="${2:-}"
[[ -n "$n" && -n "$item" ]] || die "usage: subtask-state.sh <subtask-issue> <item-branch>"

state=$(gh issue view "$n" --json state -q .state 2>/dev/null) \
  || die "cannot read issue #$n"
[[ "$state" == "CLOSED" ]] && { echo done; exit 0; }

branch="subtask/$n-"
# Under `pipefail` this pipeline's exit status is `sed`'s, which always
# succeeds — a failing `git ls-remote` (no origin, network error) would
# silently read as "no matching branch" instead of "unknown", so check its
# status directly rather than through the pipe.
ls_remote_out=$(git ls-remote --heads origin 2>/dev/null) \
  || die "cannot list remote branches (needed to tell never-started from in-flight)"
head=$(grep -oE "refs/heads/${branch}[^ ]*" <<<"$ls_remote_out" | head -1 | sed 's|refs/heads/||')
[[ -z "$head" ]] && head=$(git for-each-ref --format='%(refname:short)' "refs/heads/${branch}*" | head -1)

# The merged PR is still findable by its recorded head-branch name even after
# the branch itself is gone.
pr_state=""
if [[ -n "$head" ]]; then
  pr_state=$(gh pr list --head "$head" --base "$item" --state all \
    --json state -q '.[0].state // ""' 2>/dev/null) \
    || die "cannot query the PR for branch $head (needed to tell in-flight from merged-not-closed)"
else
  # --limit is essential: gh defaults to 30, and past that the sub-task's
  # merged PR falls off the page and this returns never-started — i.e. "go
  # re-implement work that already merged", the exact failure this file exists
  # to prevent. A failed query must fail the same way a truncated one would
  # silently not: this is the one query whose default answer (never-started)
  # is the most dangerous of the four, so it may never read a failure as empty.
  pr_state=$(gh pr list --base "$item" --state merged --limit 500 \
    --json headRefName,state \
    -q "[.[] | select(.headRefName | startswith(\"$branch\"))][0].state // \"\"" 2>/dev/null) \
    || die "cannot query merged PRs for #$n (needed to tell never-started from merged-not-closed)"
fi

if [[ "$pr_state" == "MERGED" ]]; then
  echo merged-not-closed
elif [[ -n "$head" ]]; then
  echo in-flight
else
  echo never-started
fi
