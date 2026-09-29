#!/usr/bin/env bash
# shipwright preflight.sh — fail fast, not mid-pipeline.
#
#   preflight.sh init | decompose | build [--item N] [--fast] [--ui]
#   preflight.sh release-lock [--item N]        # release a lock this run holds
#
# Runs every mechanical environment check for the calling command and stops at
# the first failure with a message naming exactly what to fix. Warn-and-continue
# is never correct here.
#
# Exit 0 = all mechanical checks passed. Exit 1 = a check failed (see stderr).
# Exit 5 = build lock held; the caller must ask a human before proceeding.
#
# NOT checked here (the agent must verify it itself, it is not shell-visible):
#   - a subagent mechanism is available, and whether nested subagents work.
set -uo pipefail

# Resolve this script's directory before we cd to the repo root later.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mode="${1:-}"; shift || true
case "$mode" in init|decompose|build|release-lock) ;; *)
  printf 'usage: preflight.sh {init|decompose|build|release-lock} [--item N] [--fast] [--ui]\n' >&2; exit 1 ;;
esac

item=""; fast=0; ui=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --item) item="$2"; shift 2 ;;
    --fast) fast=1; shift ;;
    --ui)   ui=1; shift ;;
    *) printf 'preflight: unknown flag: %s\n' "$1" >&2; exit 1 ;;
  esac
done

ok()   { printf '  ok    %s\n' "$1"; }
note() { printf '  note  %s\n' "$1"; }
fail() { printf '\nFAIL: %s\n' "$1" >&2; [[ -n "${2:-}" ]] && printf '  fix: %s\n' "$2" >&2; exit 1; }

# This script acquires the build lock, so this script releases it. Leaving the
# release to prose in build/SKILL.md put half a mutex in the hands of a model
# that may not reach that instruction — and a lock nothing reliably clears is
# indistinguishable from crash residue on the next run, so the exit-5 prompt
# stops carrying information. Deliberately runs before the gh checks below: a
# crashed run must be able to clean up without a working network.
if [[ "$mode" == release-lock ]]; then
  git rev-parse --git-dir >/dev/null 2>&1 \
    || fail "not a git repository" "run this from inside the repo"
  cd "$(git rev-parse --show-toplevel)" || fail "could not resolve repository root" ""
  lock=.shipwright/build.lock
  [[ -d "$lock" ]] || { printf 'no build lock held\n'; exit 0; }
  # --item is the caller's claim ticket. A mismatch means this lock belongs to
  # a different /build, and releasing it would hand that run's working
  # directory to whatever asked — the one case the lock exists to prevent.
  if [[ -n "$item" && -f "$lock/info" ]]; then
    held=$(sed -n 's/^item=//p' "$lock/info" | head -1)
    if [[ -n "$held" && "$held" != unknown && "$held" != "$item" ]]; then
      fail "the build lock belongs to item $held, not $item — not releasing it" \
           "ask the human; another /build may be running in this working directory"
    fi
  fi
  rm -rf "$lock"
  printf 'released .shipwright/build.lock\n'
  exit 0
fi

printf 'preflight (%s)\n' "$mode"

# ---------- common checks ----------

gh auth status >/dev/null 2>&1 \
  || fail "gh is not authenticated" "gh auth login"
ok "gh authenticated"

# Every later step — labels, issues, every push — needs a GitHub repo behind
# this directory, and `gh auth status` passing says nothing about that. Without
# this check a greenfield `mkdir && git init` clears preflight, runs the
# interviews, and fails at the first push.
git rev-parse --git-dir >/dev/null 2>&1 \
  || fail "not a git repository" "git init, then: gh repo create --source=. --private"

# Every check below this point uses bare relative paths (docs/shipwright/*,
# .shipwright/, git status --porcelain). Anchor to the repo root now so those
# checks are correct regardless of which directory the caller's shell was in
# when it invoked this script — an agent CLI invoking skill scripts from its
# own working directory should not make "docs/shipwright/PRODUCT.md exists"
# come out false when the file is right there at the project root.
cd "$(git rev-parse --show-toplevel)" \
  || fail "could not resolve repository root" ""

if ! repo_slug=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) \
   || [[ -z "$repo_slug" ]]; then
  fail "no GitHub repository is associated with this directory" \
       "gh repo create --source=. --private --push   (or: git remote add origin <url>)"
fi
ok "GitHub repo $repo_slug"

command -v jq >/dev/null 2>&1 \
  || fail "jq is not installed" "required by the pipeline's scripts — https://jqlang.github.io/jq/"
ok "jq present"

# Capture first, then match. `producer | grep -q` is a race under `pipefail`:
# grep -q exits on the first match and closes the pipe, the producer takes
# SIGPIPE, and pipefail reports the whole pipeline as failed even though the
# match succeeded. Observed intermittently against a real gh — roughly one run
# in three refused to start, telling the user to upgrade a perfectly good gh.
create_help=$(gh issue create --help 2>/dev/null)
grep -q -- --parent <<<"$create_help" \
  || fail "installed gh has no 'gh issue create --parent'" "upgrade gh: https://cli.github.com/"
edit_help=$(gh issue edit --help 2>/dev/null)
grep -q -- --add-blocked-by <<<"$edit_help" \
  || fail "installed gh has no 'gh issue edit --add-blocked-by'" "upgrade gh: https://cli.github.com/"

# The WRITE flags above are not evidence the READ fields exist. issue.sh
# resolves the hierarchy entirely through these four, and /ship refuses to
# start without `parent` — so a gh missing one clears preflight here and then
# fails on every sub-task, mid-build. gh validates JSON field names locally
# before any network call, which is what makes issue #0 a usable probe.
missing_fields=$(gh issue view 0 --json parent,subIssues,subIssuesSummary,blockedBy 2>&1 \
                 | grep -o 'Unknown JSON field: "[^"]*"' || true)
[[ -z "$missing_fields" ]] \
  || fail "installed gh cannot read the hierarchy ($missing_fields)" \
          "upgrade gh: https://cli.github.com/"
ok "gh supports the hierarchy flags and JSON fields"

if ! "$SCRIPT_DIR/../../gh-sub-issues/scripts/issue.sh" ensure-labels >/dev/null 2>&1; then
  fail "could not create the type and Spike labels" \
       "the token needs issue write access on this repo"
fi
ok "type and Spike labels present"

# ---------- mode-specific ----------

case "$mode" in
  init)
    note "greenfield — no docs required, dirty tree expected"
    ;;

  decompose)
    if [[ "$fast" -eq 1 ]]; then
      note "--fast: skipping the target-doc gate check (human accepted the risk)"
    elif [[ -f docs/shipwright/PRODUCT.md ]]; then
      ok "docs/shipwright/PRODUCT.md exists"
    else
      fail "docs/shipwright/PRODUCT.md is missing" "run /validate first (or pass --fast)"
    fi
    ;;

  build)
    # `.shipwright/` is local-only state. It goes in .git/info/exclude, NOT
    # .gitignore — .gitignore is tracked, so writing it would dirty the tree
    # and then fail the clean-tree check below on a mess we made ourselves.
    mkdir -p .shipwright
    # `.git` is a FILE in a worktree or submodule, not a directory, so
    # `-d .git` silently skips the exclude write there. Ask git where the
    # real git dir is rather than assuming its shape.
    gitdir=$(git rev-parse --git-dir 2>/dev/null || true)
    if [[ -n "$gitdir" ]]; then
      exclude="$gitdir/info/exclude"
      if ! grep -qxF '.shipwright/' "$exclude" 2>/dev/null \
         && ! grep -qxF '.shipwright/' .gitignore 2>/dev/null; then
        mkdir -p "$gitdir/info" && echo '.shipwright/' >> "$exclude"
      fi
    fi

    # The lock is checked BEFORE the clean-tree check on purpose: a genuinely
    # running /build has an in-flight subagent, which necessarily makes the
    # tree dirty. Check the tree first and you misdiagnose that as an ordinary
    # dirty tree and tell the human to stash — clobbering the other run's work.
    # It is only ACQUIRED at the very end, once every other check has passed,
    # so no failure below can leak it.
    if [[ -d .shipwright/build.lock ]]; then
      printf '\nBUILD LOCK HELD — another /build may be running in this working directory.\n' >&2
      cat .shipwright/build.lock/info >&2 2>/dev/null || true
      printf '\nAsk the human before proceeding. Either another /build is genuinely\n' >&2
      printf 'running (do not touch it, or the tree), or a prior run crashed\n' >&2
      printf '(safe to: rm -rf .shipwright/build.lock, then retry).\n' >&2
      exit 5
    fi
    ok "no concurrent /build holds this working directory"

    if [[ -n "$(git status --porcelain)" ]]; then
      git status --short >&2
      fail "working tree is not clean" "commit or stash before /build"
    fi
    ok "working tree clean"

    missing=()
    for d in PRODUCT DOMAIN GLOSSARY TECH_STACK ARCHITECTURE; do
      [[ -f "docs/shipwright/$d.md" ]] || missing+=("docs/shipwright/$d.md")
    done
    if [[ "$ui" -eq 1 ]]; then
      for d in UX DESIGN; do
        [[ -f "docs/shipwright/$d.md" ]] || missing+=("docs/shipwright/$d.md")
      done
    fi
    if [[ ${#missing[@]} -gt 0 ]]; then
      fail "missing required docs: ${missing[*]}" \
           "run /validate, /model, /discover, /architect (or /ux and /design for UI items)"
    fi
    ok "required docs present"

    # The glossary is read by a script at every /plan and domain-review. A
    # malformed one would fail there, mid-build, once per sub-task; fail here.
    if ! lint_out=$("$SCRIPT_DIR/../../glossary/scripts/glossary.sh" lint 2>&1); then
      printf '%s\n' "$lint_out" >&2
      fail "docs/shipwright/GLOSSARY.md does not lint" "fix the entries above via /glossary"
    fi
    ok "glossary lints clean"

    # `/init` writes these as deliberate placeholders, and /plan honours
    # the marker by skipping the module-map check rather than raising a
    # design-flaw. That is correct for a lean start and quietly wrong once it
    # isn't one — so name them on every build instead of letting them fade into
    # the background.
    deferred=()
    for d in TECH_STACK ARCHITECTURE UX DESIGN; do
      f="docs/shipwright/$d.md"
      [[ -f "$f" ]] && grep -qF '<!-- shipwright:deferred -->' "$f" && deferred+=("$d")
    done
    if [[ ${#deferred[@]} -gt 0 ]]; then
      note "still carrying the deferred marker: ${deferred[*]} — /plan will skip their checks"
      note "graduate when the design starts mattering: run /discover, /architect, /ux or /design standalone"
    fi

    # CI is the ONLY thing gating every merge below production, so a repo with
    # none turns the whole cascade into an unattended merge train. That is a
    # legitimate choice for a throwaway project — but it has to be a human's,
    # made once, here. The alternative the pipeline used to have was each
    # merge discovering it at the gate and waving itself through on its own
    # authority, which is not a gate at all. `pr.sh` refuses to merge without
    # checks unless SHIPWRIGHT_NO_CI=1, and this is where that gets answered.
    if [[ "${SHIPWRIGHT_NO_CI:-}" == 1 ]]; then
      note "SHIPWRIGHT_NO_CI=1 — merges below production will NOT be CI-gated"
    else
      ci_found=""
      for f in .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml \
               .circleci/config.yml Jenkinsfile .travis.yml azure-pipelines.yml \
               .drone.yml bitbucket-pipelines.yml; do
        [[ -e "$f" ]] && { ci_found="$f"; break; }
      done
      # An in-repo config is the common case but not the only one — CI can come
      # from a GitHub App that leaves no file behind. Ask GitHub before failing.
      if [[ -z "$ci_found" ]]; then
        wf=$(gh api "repos/{owner}/{repo}/actions/workflows" --jq .total_count 2>/dev/null || true)
        [[ "$wf" =~ ^[0-9]+$ && "$wf" -gt 0 ]] && ci_found="$wf GitHub Actions workflow(s)"
      fi
      [[ -n "$ci_found" ]] || fail "no CI is configured on this repo" \
        "every merge below production is gated on CI and nothing else. Add a workflow, or declare this repo has none: SHIPWRIGHT_NO_CI=1"
      ok "CI configured ($ci_found)"
    fi

    # Last thing we do: everything above has passed, so nothing can fail while
    # holding it. `mkdir` is the atomic primitive — exactly one racing caller
    # wins. Re-checking here is not redundant: a concurrent /build may have
    # acquired it during the checks above.
    if mkdir .shipwright/build.lock 2>/dev/null; then
      printf 'item=%s\nstarted=%s\n' "${item:-unknown}" "$(date -u +%FT%TZ)" \
        > .shipwright/build.lock/info
      ok "acquired .shipwright/build.lock"
    else
      printf '\nBUILD LOCK was taken by a concurrent /build during preflight.\n' >&2
      exit 5
    fi
    ;;
esac

printf '\npreflight passed — still verify a subagent mechanism yourself.\n'
