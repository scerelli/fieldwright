#!/usr/bin/env bash
# shipwright issue.sh — issue-hierarchy queries against live GitHub state.
#
#   issue.sh type <n>              print the single type label, or fail loud
#   issue.sh parent <n>            the parent issue number (exit 3 = top tier)
#   issue.sh children <n>          "<num>\t<state>\t<title>" per sub-issue
#   issue.sh all-closed <n>        exit 0 if every sub-issue is closed
#   issue.sh blockers <n>          blocking issue numbers, one per line
#   issue.sh order <n>             runnable execution order for the sub-tasks
#   issue.sh ensure-labels         create/update the type and Spike labels
#
# `order` is the one that matters: it resolves native blocked-by links into a
# real topological order, detects cycles and dangling references, and exits
# nonzero rather than emitting a plausible-but-wrong sequence. Never re-derive
# this ordering by reading the issues yourself.
set -uo pipefail

die() { printf 'issue.sh: %s\n' "$1" >&2; exit 1; }

# `subIssues` and `blockedBy` are GraphQL *connections*: gh returns
# {"nodes":[...],"totalCount":N}, NOT a bare array — so every path through them
# is `.subIssues.nodes[]`, never `.subIssues[]`. `parent`, `labels` and
# `subIssuesSummary` are plain objects and take no `.nodes`. Getting this wrong
# fails loud on a real repo and is invisible to any stub that returns
# already-filtered output.

TYPES='epic story task bug sub-task'

cmd_type() {
  local labels found=
  labels=$(gh issue view "$1" --json labels -q '.labels[].name' 2>/dev/null) \
    || die "cannot read issue #$1"
  for t in $TYPES; do
    grep -qxF "$t" <<<"$labels" && found="$found $t"
  done
  set -- $found
  [[ $# -eq 1 ]] || die "issue has ${#} type labels (expected exactly 1):${found:-  none}"
  printf '%s\n' "$1"
}

# The cascade walks UP as often as down — /ship needs the item that owns a
# sub-task, then the Epic that owns that item. Without this the
# only way to answer that is the branch name or memory, and neither is the
# source of truth.
#
#   exit 0 = parent number printed
#   exit 3 = no parent (prints "no-parent") — a top-tier issue, not an error
cmd_parent() {
  local out
  out=$(gh issue view "$1" --json parent -q '.parent.number // ""' 2>&1) || {
    # An older gh has no `parent` field and reports it as an unknown JSON
    # field. Say which it is; "cannot read #N" would send the user hunting
    # for a permissions problem that isn't there.
    grep -qi 'unknown JSON field\|parent' <<<"$out" \
      && die "this gh cannot read an issue's parent — upgrade gh (https://cli.github.com/)"
    die "cannot read the parent of #$1"
  }
  if [[ -z "$out" ]]; then echo "no-parent"; return 3; fi
  printf '%s\n' "$out"
}

cmd_children() {
  gh issue view "$1" --json subIssues \
    -q '.subIssues.nodes[] | "\(.number)\t\(.state)\t\(.title)"' 2>/dev/null \
    || die "cannot read sub-issues of #$1"
}

# Three outcomes, not two — "has no children" and "all children done" are
# different states and only the caller knows which it meant.
#   exit 0 = has children, all closed
#   exit 1 = has children, some open
#   exit 3 = has NO children (prints "no-children")
cmd_all_closed() {
  local summary total completed
  summary=$(gh issue view "$1" --json subIssuesSummary -q \
    '"\(.subIssuesSummary.total) \(.subIssuesSummary.completed)"') \
    || die "cannot read sub-issue summary of #$1"
  read -r total completed <<<"$summary"
  # The API yields "null null" (or empty) when the summary is absent.
  # Evaluating that arithmetically aborts the script under `set -u` — and on
  # bash 3.2 it aborts with status 0, i.e. "all children closed", the most
  # dangerous of the three answers. Validate before comparing.
  if ! [[ "$total" =~ ^[0-9]+$ && "$completed" =~ ^[0-9]+$ ]]; then
    die "unreadable sub-issue summary for #$1 (got: $summary) — refusing to guess"
  fi
  if [[ "$total" -eq 0 ]]; then echo "no-children"; return 3; fi
  [[ "$total" -eq "$completed" ]]
}

cmd_blockers() {
  gh issue view "$1" --json blockedBy -q '.blockedBy.nodes[].number' 2>/dev/null \
    || die "cannot read blockers of #$1"
}

# Emits N/E records for the awk pass below. A blocker outside this parent is
# legitimate (a human can link "story #40 blocks story #52" in the UI), so it
# is emitted as an X record carrying its own state rather than treated as a
# dangling reference — a CLOSED external blocker is satisfied and must not
# stall anything; an OPEN one genuinely blocks and is reported, not fatal.
collect_graph() {
  local parent="$1" num state title kids b bstate rc
  # `die` inside a command substitution only kills the subshell, so a failed
  # query would otherwise surface as an EMPTY graph — indistinguishable from a
  # genuinely childless parent, at exit 0. Check the status explicitly.
  kids=$(cmd_children "$parent") || return 9   # internal: cmd_order turns this into die
  while IFS=$'\t' read -r num state title; do
    [[ -n "$num" ]] || continue
    printf 'N\t%s\t%s\t%s\n' "$num" "$state" "$title"
    # `cmd_blockers`'s internal `die` calls `exit`, which would terminate a
    # `<(cmd_blockers ... || echo MARKER)` process-substitution subshell
    # before the `||` ever ran — silently reading a failed query as "no
    # blockers" instead of tripping the __BLOCKER_QUERY_FAILED__ guard below.
    # Route it through a real command substitution first, exactly like
    # `cmd_children` above, so the failure is visible to `||` in THIS shell.
    blockers=$(cmd_blockers "$num") || blockers="__BLOCKER_QUERY_FAILED__"
    while read -r b; do
      [[ -n "$b" ]] || continue
      printf 'E\t%s\t%s\n' "$num" "$b"
      # Capture, don't pipe into grep -q: under pipefail a SIGPIPE'd producer
      # fails the pipeline even on a match, which here would misread a known
      # child as an external blocker.
      kid_nums=$(cut -f1 <<<"$kids")
      if ! grep -qxF "$b" <<<"$kid_nums"; then
        bstate=$(gh issue view "$b" --json state -q .state 2>/dev/null || echo UNKNOWN)
        printf 'X\t%s\t%s\n' "$b" "$bstate"
      fi
    done <<<"$blockers"
  done <<<"$kids"
}

# Kahn's algorithm. Closed sub-tasks are excluded from execution but still
# satisfy dependencies — a blocker that is done is not a blocker.
cmd_order() {
  local parent="$1"
  local graph rc=0; graph=$(collect_graph "$parent") || rc=$?
  [[ "$rc" -eq 0 ]] || die "cannot read the issue graph for #$parent — refusing to guess an order"
  grep -q '__BLOCKER_QUERY_FAILED__' <<<"$graph" \
    && die "a blocked-by query failed — refusing to emit an order that may drop a dependency"
  [[ -n "$graph" ]] || { printf 'no sub-issues on #%s\n' "$parent" >&2; return 0; }

  local out; out=$(printf '%s\n' "$graph" | awk -F'\t' '
    $1=="N" { state[$2]=$3; title[$2]=$4; known[$2]=1; if ($3!="CLOSED") open[$2]=1 }
    $1=="E" { dep[$2]=dep[$2] " " $3 }
    $1=="X" { known[$2]=1; external[$2]=1; state[$2]=$3 }
    END {
      for (n in dep) {
        split(dep[n], ds, " ")
        for (i in ds) if (ds[i] != "" && !(ds[i] in known)) {
          printf("dangling: #%s is blocked by #%s, which could not be resolved\n", n, ds[i]) > "/dev/stderr"
          bad=1
        }
      }
      if (bad) exit 3
      for (n in state) if (state[n]=="CLOSED") satisfied[n]=1
      # An OPEN external blocker stalls its dependents but is not a broken
      # decomposition — report it and let the cycle check below decide.
      for (n in external) if (state[n]!="CLOSED")
        printf("external blocker: #%s (%s) is open and blocks work under this parent\n", n, state[n]) > "/dev/stderr"
      remaining=0; for (n in open) remaining++
      while (remaining > 0) {
        count=0; batch=""
        for (n in open) {
          if (n in emitted) continue
          ready=1
          split(dep[n], ds, " ")
          for (i in ds) if (ds[i] != "" && !(ds[i] in satisfied)) ready=0
          if (ready) { batch = batch " " n; count++ }
        }
        if (count == 0) {
          # Distinguish a real cycle from work merely waiting on an open
          # external blocker. A remaining node merely TOUCHING an unresolved
          # external is not enough to call the whole stall "external" — if
          # other remaining nodes would still be stuck even after every
          # external blocker closed, that is a genuine cycle, and reporting
          # it as external would tell the caller to wait on an issue whose
          # closing would never actually unstick the decomposition. Simulate:
          # treat every open external as satisfied and see if the rest drains.
          for (n in satisfied) hyp_sat[n]=1
          for (n in external) hyp_sat[n]=1
          hyp_left=0
          for (n in open) if (!(n in emitted) && !(n in hyp_sat)) hyp_left++
          hyp_progress=1
          while (hyp_left > 0 && hyp_progress) {
            hyp_progress=0
            for (n in open) {
              if ((n in emitted) || (n in hyp_sat)) continue
              hready=1
              split(dep[n], ds, " ")
              for (i in ds) if (ds[i] != "" && !(ds[i] in hyp_sat)) hready=0
              if (hready) hyp_new[n]=1
            }
            for (n in hyp_new) { hyp_sat[n]=1; hyp_left--; hyp_progress=1 }
            delete hyp_new
          }
          delete hyp_sat
          if (hyp_left == 0) {
            printf("blocked-externally: nothing runnable until the external blocker(s) above close\n") > "/dev/stderr"
            exit 5
          }
          printf("cycle: no runnable sub-task among:") > "/dev/stderr"
          for (n in open) if (!(n in emitted)) printf(" #%s", n) > "/dev/stderr"
          printf("\n") > "/dev/stderr"
          exit 4
        }
        split(batch, bs, " ")
        # deterministic output: ascending issue number within a wave
        c=0; for (i in bs) if (bs[i] != "") arr[++c]=bs[i]+0
        for (i=1;i<c;i++) for (j=i+1;j<=c;j++) if (arr[j]<arr[i]) {t=arr[i];arr[i]=arr[j];arr[j]=t}
        for (i=1;i<=c;i++) {
          n=arr[i]
          printf("%s\t%s\n", n, title[n])
          emitted[n]=1; satisfied[n]=1; remaining--
        }
        delete arr
      }
    }
  ')
  local rc=$?
  # Emission is buffered on purpose: awk prints per wave, but a cycle is only
  # detected on the NEXT wave. Streaming would put a partial, wrong order on
  # stdout before the failure was known.
  case "$rc" in
    0) printf '%s\n' "$out" ;;
    3) die "decomposition is broken (unresolvable dependency) — re-run /decompose" ;;
    4) die "decomposition is broken (dependency cycle) — re-run /decompose" ;;
    5) printf 'issue.sh: waiting on an open external blocker — not a broken decomposition.\n' >&2
       printf '  Close it, or remove the link with: gh issue edit <n> --remove-blocked-by <blocker>\n' >&2
       exit 5 ;;
    *) die "order failed" ;;
  esac
}

# Phases are milestones, not a hierarchy tier — one issue belongs to exactly
# one, and an Epic can span several because its CHILDREN carry the milestone.
# gh has no `gh milestone` subcommand; these go through the REST API.
#
# all_milestones prints "<number>\t<state>\t<open>\t<closed>\t<title>" per
# milestone, every page.
# Title goes last so a title containing whitespace can't shift a field.
# `--paginate` streams each page through --jq, so this needs no --slurp (which
# only exists in newer gh than preflight requires). Returns nonzero on a
# failed query — every caller checks, because reading a 502 as "no milestones"
# would silently create a duplicate or skip a close.
all_milestones() {
  gh api --paginate "repos/{owner}/{repo}/milestones?state=all&per_page=100" \
    --jq '.[] | "\(.number)\t\(.state)\t\(.open_issues)\t\(.closed_issues)\t\(.title)"' \
    2>/dev/null
}

cmd_milestones() {
  local ms; ms=$(all_milestones) \
    || die "cannot list milestones — refusing to treat a failed query as 'none'"
  awk -F'\t' 'NF{printf "%s\t%s\t%s open, %s closed\n", $5, $2, $3, $4}' <<<"$ms"
}

# A phase that has shipped but whose milestone is still open keeps showing up
# as live work — in the GitHub UI, and ahead of everything else in
# /recommend's milestone ordering, because due-date order does not care that
# the phase is done. Nothing in the pipeline ever closed one; this is that
# missing step. Prints "<title>\t<closed count>" per closable milestone.
cmd_closable_milestones() {
  local ms; ms=$(all_milestones) \
    || die "cannot list milestones — refusing to guess which phases are done"
  awk -F'\t' '$2=="open" && $3==0 && $4>0 {printf "%s\t%s\n", $5, $4}' <<<"$ms"
}

# Closing a milestone is the phase-level equivalent of closing an Epic: a
# report-and-confirm step, never automatic, and never over open work.
#   exit 0 = closed        exit 3 = already closed (no-op)
#   exit 4 = still has open issues — the caller must not force it
cmd_close_milestone() {
  local title="${1:-}"
  [[ -n "$title" ]] || die "close-milestone takes a title"
  local ms row num state open_n
  ms=$(all_milestones) || die "cannot list milestones — refusing to guess"
  row=$(awk -F'\t' -v t="$title" '$5==t {print; exit}' <<<"$ms")
  [[ -n "$row" ]] || die "no milestone titled '$title'"
  IFS=$'\t' read -r num state open_n _ <<<"$row"
  if [[ "$state" == "closed" ]]; then echo "already-closed"; return 3; fi
  # Same trap as all-closed: a non-numeric open count in an arithmetic test
  # aborts under `set -u`, and on bash 3.2 it aborts with status 0 — which
  # here would fall through and close a live phase.
  [[ "$open_n" =~ ^[0-9]+$ ]] \
    || die "unreadable open-issue count for milestone '$title' (got: $open_n)"
  if [[ "$open_n" -gt 0 ]]; then
    printf 'issue.sh: milestone "%s" still has %s open issue(s) — not closing a live phase.\n' \
      "$title" "$open_n" >&2
    return 4
  fi
  gh api --method PATCH "repos/{owner}/{repo}/milestones/$num" -f state=closed --jq .state \
    >/dev/null || die "could not close milestone '$title' (needs issue write access)"
  echo "closed"
}

# Re-phasing after a roadmap revision. Moving an item between phases is a
# field change by design (see CONVENTIONS.md) — but only a Story/Task/Bug
# carries a milestone, so this refuses the tiers that must not.
cmd_set_milestone() {
  local title="${1:-}"; shift || true
  [[ -n "$title" && $# -gt 0 ]] || die "usage: set-milestone <title> <issue>..."
  local ms; ms=$(all_milestones) || die "cannot list milestones — refusing to guess"
  awk -F'\t' -v t="$title" '$5==t {found=1} END{exit !found}' <<<"$ms" \
    || die "no milestone titled '$title' — create it with ensure-milestone first"
  local n t
  for n in "$@"; do
    t=$(cmd_type "$n") || exit 1
    case "$t" in
      story|task|bug) ;;
      *) die "#$n is a $t — only Story/Task/Bug carry a milestone (see CONVENTIONS.md)" ;;
    esac
  done
  # Every issue is type-checked above before any edit runs, so a refusal costs
  # nothing. The edits themselves cannot be atomic — on a mid-loop failure the
  # `moved` lines already printed are real and stand; say so rather than
  # leaving the caller to assume the whole batch rolled back.
  for n in "$@"; do
    gh issue edit "$n" --milestone "$title" >/dev/null \
      || die "could not set the milestone on #$n — any 'moved' lines above already applied"
    printf 'moved\t%s\t%s\n' "$n" "$title"
  done
}

cmd_ensure_milestone() {
  local title="${1:-}"; shift || true
  [[ -n "$title" ]] || die "ensure-milestone takes a title"
  local due="" desc=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --due)  due="$2"; shift 2 ;;
      --desc) desc="$2"; shift 2 ;;
      *) die "unknown flag: $1" ;;
    esac
  done

  local ms; ms=$(all_milestones) \
    || die "cannot list milestones — refusing to create a possible duplicate"
  if awk -F'\t' -v t="$title" '$5==t {found=1} END{exit !found}' <<<"$ms"; then
    echo "exists"; return 0
  fi

  local args=(-f "title=$title")
  [[ -n "$desc" ]] && args+=(-f "description=$desc")
  # GitHub wants an ISO-8601 timestamp, not a bare date.
  [[ -n "$due" ]] && args+=(-f "due_on=${due}T00:00:00Z")
  gh api --method POST "repos/{owner}/{repo}/milestones" "${args[@]}" --jq .title >/dev/null \
    || die "could not create milestone '$title' (needs issue write access)"
  echo "created"
}

# Type tracking is plain labels, so every one of these must exist before any
# issue is created — `gh issue create --label` fails outright against a missing
# one. preflight branches on this command's exit code, which is why a failure
# here may not be swallowed: reporting success after a 403 clears preflight and
# then dies at the first issue /decompose creates, which is exactly the
# mid-run failure preflight exists to prevent. Collect every failure rather
# than stopping at the first, so one run names the whole permissions problem.
_label_failures=""
ensure_label() { # <name> <color> <description>
  gh label create "$1" -c "$2" -d "$3" --force >/dev/null \
    || _label_failures="$_label_failures $1"
}

cmd_ensure_labels() {
  ensure_label epic       1d76db "Epic"
  ensure_label story      2da44e "Story"
  ensure_label task       bfd4f2 "Task"
  ensure_label bug        d93f0b "Bug"
  ensure_label sub-task   c5def5 "Sub-task"
  ensure_label Spike      fbca04 "Exploratory sub-task — skips TDD, see /spike"
  ensure_label foundation 5319e7 "Shared UI foundation — blocks UI items until it ships"
  [[ -z "$_label_failures" ]] || die \
    "could not create label(s):$_label_failures — the token needs issue write access on this repo"
  echo "labels ensured"
}

case "${1:-}" in
  type)          shift; [[ $# -eq 1 ]] || die "type takes one issue number"; cmd_type "$1" ;;
  parent)        shift; [[ $# -eq 1 ]] || die "parent takes one issue number"; cmd_parent "$1" ;;
  children)      shift; [[ $# -eq 1 ]] || die "children takes one issue number"; cmd_children "$1" ;;
  all-closed)    shift; [[ $# -eq 1 ]] || die "all-closed takes one issue number"; cmd_all_closed "$1" ;;
  blockers)      shift; [[ $# -eq 1 ]] || die "blockers takes one issue number"; cmd_blockers "$1" ;;
  order)         shift; [[ $# -eq 1 ]] || die "order takes one issue number"; cmd_order "$1" ;;
  ensure-labels) cmd_ensure_labels ;;
  milestones)    cmd_milestones ;;
  ensure-milestone)    shift; cmd_ensure_milestone "$@" ;;
  closable-milestones) cmd_closable_milestones ;;
  close-milestone)     shift; cmd_close_milestone "$@" ;;
  set-milestone)       shift; cmd_set_milestone "$@" ;;
  *) die "usage: issue.sh {type|parent|children|all-closed|blockers|order|ensure-labels|milestones|ensure-milestone|closable-milestones|close-milestone|set-milestone} ..." ;;
esac
