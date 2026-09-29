#!/usr/bin/env bash
# shipwright backlog.sh — classify and rank the open backlog. Read-only.
#
#   backlog.sh survey        TSV: bucket, rank, milestone-rank, number,
#                                 type, milestone, title, detail
#   backlog.sh markers <n>   escalation marker comments on one item
#
# Buckets, in rank order:
#   in-progress        branch exists, no escalation marker  (finishing beats starting)
#   ready-to-build     >=1 open Sub-task whose blockers are all closed
#   needs-decomposition open with zero children
#   blocked            has open Sub-tasks, every one blocked by an open sibling
#   cascade-failed     every sub-task closed but the item is still open
#   maybe-stuck        branch idle past SHIPWRIGHT_STALE_DAYS, no marker
#   stuck              branch + escalation marker
#
# `stuck`, `maybe-stuck` and `cascade-failed` rank last and must never be a
# Top pick — they belong in the report's Blocked/stuck section only.
set -uo pipefail

die() { printf 'backlog.sh: %s\n' "$1" >&2; exit 1; }

gh auth status >/dev/null 2>&1 || die "gh is not authenticated (gh auth login)"
command -v jq >/dev/null 2>&1 || die "jq is not installed (required for the survey)"

# `[[ "$x" -eq 0 ]]` has no safe default when $x is not a number, and a gh
# call that exits 0 while printing nothing is not hypothetical. An EMPTY count
# evaluates as 0, which buckets a fully-decomposed item as
# `needs-decomposition` at exit 0 — telling the human to re-run /decompose over
# work that already exists. A literal "null" instead aborts with an
# unbound-variable error naming no cause. Both are the guess CONVENTIONS.md
# forbids, so every count is validated before it is compared. Same guard as
# issue.sh's all-closed, for the same reason.
require_num() { # <value> <what>
  [[ "$1" =~ ^[0-9]+$ ]] \
    || die "unreadable $2 (got: '$1') — refusing to guess the backlog"
}

# Captured, not piped into `grep -q` — see preflight.sh: pipefail plus a
# short-circuiting grep turns a found branch into "no branch", which would
# silently drop a stuck item out of the survey's stuck bucket.
branch_exists() {
  local out; out=$(git ls-remote --heads origin "feature/$1-"'*' 2>/dev/null)
  [[ -n "$out" ]]
}

# Whole days since the item branch's last commit, or empty if unknowable.
# This is an inactivity signal, never a confirmed escalation — there is no
# mechanically correct staleness threshold, which is why the caller must
# label it as unconfirmed.
branch_age_days() {
  local ref last now
  # Read-only: /recommend promises it never touches git, so no fetch here.
  # Use whatever ref this clone already has; if it has none, say nothing
  # rather than mutating the ref store to find out.
  ref=$(git ls-remote --heads origin "feature/$1-"'*' 2>/dev/null \
        | head -1 | sed 's|.*refs/heads/|refs/remotes/origin/|')
  [[ -n "$ref" ]] || return 0
  git rev-parse --verify -q "$ref" >/dev/null 2>&1 || return 0
  last=$(git log -1 --format=%ct "$ref" 2>/dev/null) || return 0
  [[ -n "$last" ]] || return 0
  now=$(date -u +%s)
  echo $(( (now - last) / 86400 ))
}

cmd_markers() {
  gh issue view "$1" --json comments \
    -q '.comments[] | select(.body | startswith("[shipwright:")) | .body' 2>/dev/null
}

# Milestone order is by due date, not name — "Backlog" must not sort ahead of
# "v1.0" just because B < v. A CLOSED milestone sorts after every open one
# regardless of its due date: a shipped phase has the earliest due date in the
# repo forever, and without this its stragglers head the report for good.
# Undated milestones sort last among their state; no milestone last of all.
#
# Built once per survey, not once per issue — otherwise this is an API round
# trip for every open issue in the backlog.
MILESTONE_RANKS=""
load_milestone_ranks() {
  local raw
  raw=$(gh api --paginate "repos/{owner}/{repo}/milestones?state=all&per_page=100" \
          --jq '.[] | "\(.state)\t\(.due_on // "9999-12-31")\t\(.title)"' 2>/dev/null) \
    || die "cannot list milestones — refusing to rank the backlog on a guess"
  # open before closed, then due date, then title for a stable tie-break.
  MILESTONE_RANKS=$(printf '%s\n' "$raw" \
    | awk -F'\t' 'NF{printf "%s\t%s\t%s\t%s\n", ($1=="closed"?1:0), $2, $3, $3}' \
    | sort -t$'\t' -k1,1n -k2,2 -k3,3 \
    | awk -F'\t' '{printf "%s\t%s\n", NR, $4}')
}

# The survey sorts this column numerically, so the sentinels only need to be
# larger than any real rank — no zero-padding, and no ceiling to collide with.
milestone_rank() {
  local want="$1"
  [[ "$want" == "—" ]] && { echo 999; return; }
  local idx
  idx=$(awk -F'\t' -v w="$want" '$2==w {print $1; exit}' <<<"$MILESTONE_RANKS")
  echo "${idx:-998}"
}

# A phase whose issues are all closed but whose milestone is still open.
# /recommend reports these so a finished phase stops reading as live work.
cmd_closable_milestones() {
  gh api --paginate "repos/{owner}/{repo}/milestones?state=all&per_page=100" \
    --jq '.[] | select(.state == "open" and .open_issues == 0 and .closed_issues > 0)
          | "\(.title)\t\(.closed_issues)"' 2>/dev/null \
    || die "cannot list milestones"
}

cmd_survey() {
  local any=0
  load_milestone_ranks
  for type in epic story task bug; do
    local rows
    # A failed query here must not just skip this type: `|| continue` would
    # quietly drop, say, every open story from a rate-limited call and print
    # a backlog that looks complete — exactly what the per-issue queries
    # below refuse to do.
    rows=$(gh issue list --label "$type" --state open --limit 200 \
             --json number,title,milestone 2>/dev/null) \
      || die "gh query failed listing open $type issues — refusing to guess the backlog is complete"
    [[ "$(jq 'length' <<<"$rows")" -gt 0 ]] || continue
    any=1

    local count; count=$(jq 'length' <<<"$rows")
    for ((i=0; i<count; i++)); do
      local n title kids open_kids bucket detail milestone
      n=$(jq -r ".[$i].number" <<<"$rows")
      title=$(jq -r ".[$i].title" <<<"$rows")
      milestone=$(jq -r ".[$i].milestone.title // \"—\"" <<<"$rows")

      # Never swallow a gh failure into a default — a rate-limited query must
      # not read as "no children" (→ needs-decomposition) or "no blockers"
      # (→ ready-to-build). Guessing issue state to fill a gap is exactly
      # what CONVENTIONS.md's "warn-and-continue is never correct" forbids.
      kids=$(gh issue view "$n" --json subIssues -q '.subIssues.totalCount' 2>/dev/null) \
        || die "gh query failed for #$n — refusing to guess its state"
      require_num "$kids" "sub-issue count for #$n"
      open_kids=$(gh issue view "$n" --json subIssues \
                    -q '[.subIssues.nodes[] | select(.state=="OPEN")] | length' 2>/dev/null) \
        || die "gh query failed for #$n — refusing to guess its state"
      require_num "$open_kids" "open sub-issue count for #$n"

      detail=""
      if [[ "$kids" -eq 0 ]]; then
        bucket=needs-decomposition; detail="/decompose #$n"
      elif [[ "$open_kids" -eq 0 ]]; then
        # Every child closed but the item itself still open: the /ship cascade
        # did not complete (CI red at the item merge, a crash, a half-close).
        # Must have its own bucket — folded into any other it reads as normal
        # progress, and it is the one state that most needs a human.
        bucket=cascade-failed; detail="/ship --force-close #$n — all sub-tasks closed, item still open"
      else
        # runnable = an open child with no open blockers
        #
        # A `die` inside a `< <(...)` process-substitution subshell only
        # kills that subshell — the `while read` just sees a closed, empty
        # pipe either way, so a failed query here would silently read as "no
        # open sub-tasks" instead of aborting. Capture through a real command
        # substitution first, like the queries above already do, so a
        # failure is visible to `||` in THIS shell.
        local runnable=0 blockers open_subs
        open_subs=$(gh issue view "$n" --json subIssues \
                      -q '.subIssues.nodes[] | select(.state=="OPEN") | .number' 2>/dev/null) \
          || die "gh query failed for #$n — refusing to guess its state"
        while read -r c; do
          [[ -n "$c" ]] || continue
          blockers=$(gh issue view "$c" --json blockedBy \
                       -q '[.blockedBy.nodes[] | select(.state=="OPEN")] | length' 2>/dev/null) \
            || die "gh query failed for sub-task #$c — refusing to guess"
          require_num "$blockers" "open blocker count for sub-task #$c"
          [[ "$blockers" -eq 0 ]] && { runnable=1; break; }
        done <<<"$open_subs"

        if [[ "$runnable" -eq 1 ]]; then
          bucket=ready-to-build; detail="/build #$n"
        else
          bucket=blocked; detail="all $open_kids open sub-tasks blocked"
        fi
      fi

      # A live branch reclassifies: in-progress, or stuck if an escalation
      # marker is present. Only meaningful at the item tier.
      if [[ "$type" =~ ^(story|task|bug)$ ]] && branch_exists "$n"; then
        local marks; marks=$(cmd_markers "$n") \
          || die "gh query failed reading escalation markers for #$n — refusing to guess it is healthy"
        if [[ -n "$marks" ]]; then
          bucket=stuck
          detail=$(head -1 <<<"$marks" | tr -d '\n')
        else
          # No marker is not proof of health: /build can die before it posts
          # one. Fall back to branch inactivity, and label it as the weaker
          # signal it is — never silently promote it to in-progress.
          local age; age=$(branch_age_days "$n")
          if [[ -n "$age" && "$age" -ge "${SHIPWRIGHT_STALE_DAYS:-7}" ]]; then
            bucket=maybe-stuck
            detail="branch idle ${age}d, no escalation marker — inactivity signal only, unconfirmed"
          else
            bucket=in-progress; detail="resume /build #$n"
          fi
        fi
      fi

      local rank
      case "$bucket" in
        in-progress)         rank=1 ;;
        ready-to-build)      rank=2 ;;
        needs-decomposition) rank=3 ;;
        blocked)             rank=4 ;;
        cascade-failed)      rank=8 ;;
        maybe-stuck)         rank=9 ;;
        stuck)               rank=9 ;;
      esac
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$bucket" "$rank" "$(milestone_rank "$milestone")" "$n" \
        "$type" "$milestone" "$title" "$detail"
    done
  done

  [[ "$any" -eq 1 ]] || die "no open hierarchy issues — run /init or /decompose"
}

case "${1:-}" in
  # bucket rank → milestone (by due date) → issue number
  # Buffered, not streamed: cmd_survey dies mid-scan on a failed gh query, and
  # piping straight into sort would print a partial backlog that looks complete.
  # Same reason issue.sh buffers `order`.
  survey)
    shift
    rows=$(cmd_survey) || exit 1
    printf '%s\n' "$rows" | sort -t$'\t' -k2,2n -k3,3n -k4,4n
    ;;
  markers) shift; [[ $# -eq 1 ]] || die "markers takes one issue number"; cmd_markers "$1" ;;
  closable-milestones) shift; cmd_closable_milestones ;;
  *) die "usage: backlog.sh {survey|markers <n>|closable-milestones}" ;;
esac
