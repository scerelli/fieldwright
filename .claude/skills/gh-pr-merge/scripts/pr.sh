#!/usr/bin/env bash
# shipwright pr.sh — idempotent, CI-gated, race-tolerant PR create + merge.
#
# Every merge in the pipeline goes through `land`. It is safe to re-run: a
# retried caller never fails on an existing PR, never resurrects a merged
# branch, and never loses a race against a concurrent caller.
#
#   pr.sh land --head H --base B --title T --body BODY [flags]
#   pr.sh land-and-tag --head H --tag V --title T [flags]   # release
#   pr.sh production-branch                # the branch everything lands on
#   pr.sh state --head H --base B          # prints "<number> <state>"
#   pr.sh ci-gate <head-or-pr-number>      # 0 green | 3 failed | 1 no CI
#
# land flags:
#   --push           push --set-upstream the head branch before creating
#   --confirmed      human confirmed this merge; REQUIRED when base is main
#
# land exit codes:
#   0  merged (prints "merged" or "already-merged")
#   1  hard failure — see stderr
#   3  CI ran and failed; route to the caller's own failure handling
#   4  base is main and --confirmed was not passed
#
# There is deliberately no "no CI configured" outcome. CI is the only thing
# gating every merge below production, so whether this repo has any is a
# question preflight answers once, before /build starts — not one an unattended
# merge re-answers on its own authority at the moment it is inconvenient. A
# repo genuinely without CI declares it with SHIPWRIGHT_NO_CI=1; anything else
# reaching a merge with no checks is a hard failure.
set -uo pipefail

die() { printf 'pr.sh: %s\n' "$1" >&2; exit 1; }

# The production branch is whatever this repo calls it — `master` and `trunk`
# are common — so gating on a literal "main" would mean the gate silently does
# not exist on those repos.
#
# But it is NOT simply the repo's default branch. Plenty of repos carry a
# `develop` branch and set it as the GitHub default; treating that as
# production would be the mirror failure — every item merge gated as if it
# were production, and /release tagging `develop` while `main` never receives
# the release at all. Both directions are dangerous, so resolve by convention
# over a known set, never from the repo default, and never `develop`.
#
# Override with SHIPWRIGHT_MAIN for anything unusual.
prod_branch() {
  local _prod_branch=""
  if [[ -n "${SHIPWRIGHT_MAIN:-}" ]]; then
    _prod_branch="$SHIPWRIGHT_MAIN"; printf '%s\n' "$_prod_branch"; return
  fi

  # Which of the conventional names actually exist here?
  local b found=""
  for b in main master trunk; do
    if git show-ref --verify --quiet "refs/remotes/origin/$b" \
       || git show-ref --verify --quiet "refs/heads/$b" \
       || git ls-remote --exit-code --heads origin "$b" >/dev/null 2>&1; then
      found="$found $b"
    fi
  done
  set -- $found

  local default; default=$(gh repo view --json defaultBranchRef \
    -q .defaultBranchRef.name 2>/dev/null)

  if [[ $# -eq 1 ]]; then
    _prod_branch="$1"
  elif [[ $# -gt 1 ]]; then
    # Ambiguous: e.g. a master-based repo that also kept a `main` branch.
    # Precedence would silently gate the WRONG branch and let a real
    # production merge through at exit 0, so defer to the repo default —
    # and if that doesn't disambiguate, refuse rather than guess.
    if [[ -n "$default" && "$default" != develop ]] && grep -qw "$default" <<<"$found"; then
      _prod_branch="$default"
    else
      printf 'pr.sh: cannot tell which branch is production (found:%s).\n' "$found" >&2
      printf '  Set SHIPWRIGHT_MAIN=<branch> — refusing to guess a production gate.\n' >&2
      exit 1
    fi
  else
    # None of the conventional names exist.
    if [[ -n "$default" && "$default" != develop ]]; then
      _prod_branch="$default"
    else
      printf 'pr.sh: cannot resolve a production branch. Set SHIPWRIGHT_MAIN=<branch>.\n' >&2
      exit 1
    fi
  fi
  printf '%s\n' "$_prod_branch"
}

pr_state() { # <head> <base> -> "<number> <state>" ("" "" if none)
  # A MERGED PR wins over anything else on the same head. `land` is idempotent
  # only if a branch whose work already merged reports MERGED — and a branch
  # name gets reused (a re-cut sub-task, a force-pushed retry), so a newer
  # CLOSED or reopened PR can sit ahead of the merged one in the default
  # newest-first order. Taking a bare `.[0]` there reopens and re-merges work
  # that already landed.
  gh pr list --head "$1" --base "$2" --state all --json number,state \
    --jq '(((map(select(.state=="MERGED")) + .)[0]) // {})
          | "\(.number // "") \(.state // "")"' 2>/dev/null
}

# `gh pr checks --watch` waits for checks that already EXIST to finish; it does
# not wait for them to appear. A PR created seconds ago usually has no check
# runs registered yet, and gh reports that in the same words a repo with no CI
# at all produces. Trusting the first answer therefore reads GitHub's
# registration lag as "this repo has no CI" — which is why the wait exists.
#
# Re-poll for a bounded window before concluding there is nothing coming. A
# repo that has declared it has no CI skips the wait entirely; there is nothing
# to wait for.
ci_wait() {
  [[ "${SHIPWRIGHT_NO_CI:-}" == 1 ]] && { printf 0; return; }
  local w="${SHIPWRIGHT_CI_WAIT:-60}"
  [[ "$w" =~ ^[0-9]+$ ]] || w=60
  printf '%s' "$w"
}

# Returns exactly the codes `land` propagates, so there is no second mapping
# table to keep in sync: 0 green, 3 checks ran and failed, 1 no checks at all
# and no declaration that this repo has none.
ci_gate() { # <ref> -> 0 green | 3 checks failed | 1 no CI configured
  local out budget waited=0 interval=5
  budget=$(ci_wait)
  [[ "$budget" -lt "$interval" ]] && interval="$budget"
  [[ "$interval" -lt 1 ]] && interval=1
  while :; do
    if out=$(gh pr checks "$1" --watch 2>&1); then return 0; fi
    if ! grep -qiE 'no checks reported|no checks were reported|does not have any checks|no commit found' <<<"$out"; then
      printf '%s\n' "$out" >&2
      return 3
    fi
    # Still no checks. Out of budget means there really are none on this PR.
    if [[ "$waited" -ge "$budget" ]]; then
      # A repo without CI is a legitimate choice, but it is the human's to
      # make once — not something an unattended merge concludes for itself at
      # the moment the gate is inconvenient. preflight asks this question
      # before /build starts; reaching it here means it was never answered.
      if [[ "${SHIPWRIGHT_NO_CI:-}" == 1 ]]; then
        printf 'pr.sh: no CI on %s; merging under SHIPWRIGHT_NO_CI=1\n' "$1" >&2
        return 0
      fi
      printf 'pr.sh: %s has no CI checks after %ss.\n' "$1" "$budget" >&2
      printf '  Every merge below production is gated on CI and nothing else.\n' >&2
      printf '  Add a workflow, or declare this repo has none: SHIPWRIGHT_NO_CI=1\n' >&2
      return 1
    fi
    sleep "$interval"
    waited=$((waited + interval))
  done
}

# Where an item branch is cut from and lands back into: production itself.
# There is one integration point and no staging tier.
#
# Exposed as a command, not inlined in /build and /ship, because both need the
# same answer and two prose copies drift. It reuses prod_branch, so it honours
# SHIPWRIGHT_MAIN and refuses an ambiguous production branch rather than
# guessing one.
cmd_production_branch() {
  prod_branch
}

cmd_land() {
  local head= base= title= body= push=0 confirmed=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --head)        head="$2"; shift 2 ;;
      --base)        base="$2"; shift 2 ;;
      --title)       title="$2"; shift 2 ;;
      --body)        body="$2"; shift 2 ;;
      --push)        push=1; shift ;;
      --confirmed)   confirmed=1; shift ;;
      *) die "unknown flag: $1" ;;
    esac
  done
  [[ -n "$head" && -n "$base" ]] || die "land requires --head and --base"

  # The production gate, enforced rather than described. Nothing reaches
  # production without a human having said yes to this exact merge.
  #
  # prod_branch's own failure exits only the $( ) subshell, so an empty result
  # would silently skip the comparison and let the merge through. Fail closed.
  local prod; prod=$(prod_branch) || return 1
  [[ -n "$prod" ]] || { printf 'pr.sh: could not resolve production\n' >&2; return 1; }
  if [[ "$base" == "$prod" && "$confirmed" -ne 1 ]]; then
    printf 'refusing to merge %s into %s (production) without --confirmed\n' \
      "$head" "$base" >&2
    return 4
  fi

  # `pr_state`'s `gh pr list` failing (rate limit, transient 5xx) prints
  # empty stdout — identical to the legitimate "no matching PR" case. A
  # process-substitution `read < <(...)` can't see that failure at all; a
  # real command substitution can, so check it explicitly every time.
  local number state pr_out
  pr_out=$(pr_state "$head" "$base") || die "could not query the PR state for $head -> $base"
  read -r number state <<<"$pr_out"

  if [[ "$state" == "MERGED" ]]; then
    echo "already-merged"; return 0
  fi

  if [[ "$push" -eq 1 ]]; then
    git push -u origin "$head" >/dev/null 2>&1 \
      || git push origin "$head" >/dev/null 2>&1 \
      || die "could not push $head"
  fi

  if [[ -z "$state" ]]; then
    [[ -n "$title" ]] || die "land requires --title when the PR does not exist yet"
    local create_err
    if create_err=$(gh pr create --base "$base" --head "$head" \
        --title "$title" --body "${body:-}" 2>&1); then
      state=OPEN
      # gh prints the new PR's URL. Take the number from it: everything below
      # addresses the PR by number, never by branch name.
      number=$(grep -oE '/pull/[0-9]+' <<<"$create_err" | tail -1 | tr -dc '0-9')
    elif grep -qi 'already exists' <<<"$create_err"; then
      # Lost the create race to a concurrent caller — adopt their PR.
      pr_out=$(pr_state "$head" "$base") || die "could not query the PR state for $head -> $base"
      read -r number state <<<"$pr_out"
    else
      printf '%s\n' "$create_err" >&2; return 1
    fi
  elif [[ "$state" == "CLOSED" ]]; then
    # Closed without merging (CI kept failing, a force-push, a human closed
    # it) — gh pr merge errors outright against a closed PR.
    gh pr reopen "$number" >/dev/null || die "could not reopen PR #$number"
    state=OPEN
  fi

  [[ "$state" == "MERGED" ]] && { echo "already-merged"; return 0; }

  # Address the PR by number wherever one is known. `gh pr checks <branch>` and
  # `gh pr merge <branch>` each re-resolve the branch independently, so a
  # reused branch name can gate one PR and merge another — and the gate is the
  # whole point. Fall back to the branch only when no number could be resolved.
  local ref="${number:-$head}"

  # ci_gate returns the codes land propagates: 3 red, 1 no CI and none
  # declared. Neither is a merge.
  local ci=0
  ci_gate "$ref" || ci=$?
  [[ "$ci" -eq 0 ]] || return "$ci"

  local merge_err
  if ! merge_err=$(gh pr merge "$ref" --merge --delete-branch 2>&1); then
    # A concurrent caller may have won the merge between the check and here.
    pr_out=$(pr_state "$head" "$base") || die "could not query the PR state for $head -> $base"
    read -r _ state <<<"$pr_out"
    if [[ "$state" != "MERGED" ]]; then
      printf '%s\n' "$merge_err" >&2; return 1
    fi
    echo "already-merged"; return 0
  fi
  echo "merged"
}

# Tag the production merge commit.
#
# Checks the REMOTE, not just local tags: a prior run may have pushed this tag
# from a working tree that no longer exists, and re-pushing is an error. Called
# only AFTER production is merged, so a failure here is never "retry the
# release" — the content is already live and the tag is what is missing.
tag_production() { # <tag> <title> <prod-branch>
  local tag="$1" title="$2" prod="$3"
  git ls-remote --exit-code origin "refs/tags/$tag" >/dev/null 2>&1 \
    && { printf 'tagged %s (already)\n' "$tag"; return 0; }
  local was; was=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  # Both of these must fail loud: `gh pr merge` merged on GitHub, not in this
  # clone, so tagging depends entirely on fetch + ff-only actually bringing
  # local $prod up to the real merge commit. Swallowing either failure risks
  # tagging a stale local $prod and reporting the release as tagged anyway.
  git fetch origin "$prod" >/dev/null 2>&1 \
    || die "$prod is MERGED but could not fetch it to tag — fetch and re-run, do not re-cut"
  git checkout "$prod" >/dev/null 2>&1 || die "could not check out $prod to tag"
  # Explicit ref: a bare `git pull --ff-only` dies when $prod has no
  # upstream, and by this point production is already merged.
  git merge --ff-only FETCH_HEAD >/dev/null 2>&1 \
    || die "$prod is MERGED but local $prod would not fast-forward to it — resolve and re-run, do not re-cut"
  # Captured, not piped: a SIGPIPE'd `git tag -l` under pipefail would read as
  # "tag absent" and re-create one that already exists.
  local existing; existing=$(git tag -l "$tag")
  [[ -n "$existing" ]] || git tag -a "$tag" -m "$title"
  git push origin "$tag" >/dev/null 2>&1 || die \
    "$prod is MERGED but tag $tag could not be pushed — push it before anything else; do not re-cut"
  [[ -n "$was" ]] && git checkout "$was" >/dev/null 2>&1 || true
  printf 'tagged %s\n' "$tag"
  return 0
}

# The release shape: merge into production, tag it, done. One merge, one tag,
# no back-merge and no branch to keep — production is the only integration
# point, so there is nowhere else for the release to land.
cmd_land_tag() {
  local head= tag= title= body= confirmed=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --head)        head="$2"; shift 2 ;;
      --tag)         tag="$2"; shift 2 ;;
      --title)       title="$2"; shift 2 ;;
      --body)        body="$2"; shift 2 ;;
      --confirmed)   confirmed=(--confirmed); shift ;;
      *) die "unknown flag: $1" ;;
    esac
  done
  [[ -n "$head" && -n "$tag" && -n "$title" ]] \
    || die "land-and-tag requires --head, --tag and --title"

  local rc=0 prod; prod=$(prod_branch) || return 1
  [[ -n "$prod" ]] || { printf 'pr.sh: could not resolve production\n' >&2; return 1; }
  # ${arr[@]+"${arr[@]}"} — expanding an EMPTY array under `set -u` is an
  # unbound-variable error in bash < 4.4, and macOS ships 3.2. Without this
  # guard land-and-tag dies before doing anything, taking /release with it on
  # a default macOS install.
  cmd_land --head "$head" --base "$prod" --title "$title" --body "${body:-}" \
    ${confirmed[@]+"${confirmed[@]}"} || rc=$?
  [[ "$rc" -eq 0 ]] || return "$rc"
  tag_production "$tag" "$title" "$prod"
}

case "${1:-}" in
  land)          shift; cmd_land "$@" ;;
  production-branch) shift; [[ $# -eq 0 ]] || die "production-branch takes no arguments"
                     cmd_production_branch ;;
  land-and-tag)  shift; cmd_land_tag "$@" ;;
  state)   shift
           head=; base=
           while [[ $# -gt 0 ]]; do
             case "$1" in
               --head) head="$2"; shift 2 ;;
               --base) base="$2"; shift 2 ;;
               *) die "unknown flag: $1" ;;
             esac
           done
           [[ -n "$head" && -n "$base" ]] || die "state requires --head and --base"
           pr_state "$head" "$base" ;;
  ci-gate) shift; [[ $# -eq 1 ]] || die "ci-gate takes one ref"; ci_gate "$1" ;;
  *) die "usage: pr.sh {land|land-and-tag|production-branch|state|ci-gate} ..." ;;
esac
