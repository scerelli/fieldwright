#!/usr/bin/env bash
# shipwright version.sh — suggest and validate release versions.
#
#   version.sh suggest          bump from Conventional Commits since last tag
#   version.sh suggest --patch  force a patch bump (urgent single-fix release)
#   version.sh check <version>  valid semver? already released? a retry?
#
# `suggest` prints "<version>\t<reason>". The human still decides — this only
# removes the blank-page guess.
set -uo pipefail

die() { printf 'version.sh: %s\n' "$1" >&2; exit 1; }

# One definition, used to validate both a human-supplied version and the tag
# `suggest` bumps from — the two must not drift, because `check` rejecting a
# shape `suggest` will happily produce is how a bad version reaches a tag.
# Semver forbids leading zeros in the numeric identifiers (a bare "0" is fine;
# "08" is not) — allowing them let a typo like "1.08.0" through the one gate
# meant to catch it, then break `bump`'s arithmetic (bash reads a leading zero
# as octal).
SEMVER_RE='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?$'

# A `git describe` failure is not always "no tags yet" — it is also what a
# broken cwd (not a git repository at all) or a corrupt/shallow checkout
# looks like, and reading either as "first release" would re-suggest 0.1.0
# for a project already several releases in. Only the genuine "no tag
# reachable from HEAD" message is safe to treat as "no prior tag."
last_tag() {
  local out
  if out=$(git describe --tags --abbrev=0 --match 'v*' 2>&1); then
    printf '%s\n' "$out"
  elif grep -qi 'no names found\|no tags can describe' <<<"$out"; then
    return 0
  else
    die "cannot determine the last release tag: $out"
  fi
}

bump() { # <major.minor.patch[-prerelease]> <major|minor|patch>
  # Strip any prerelease/build suffix first. Without this the patch segment
  # is "3-rc1" and $((pa + 1)) silently evaluates `3 - rc1 + 1` = 4 (bash
  # treats the unset word as 0) — a wrong version with no error, and a hard
  # arithmetic failure for a dotted suffix like "3-rc.1".
  local core="${1%%-*}"; core="${core%%+*}"
  local IFS=. ; read -r ma mi pa <<<"$core"
  # `10#` forces base-10: bash's arithmetic otherwise reads a zero-padded
  # segment (e.g. a hand-tagged "v1.2.08") as invalid octal and aborts.
  case "$2" in
    major) printf '%s.0.0\n' "$((10#$ma + 1))" ;;
    minor) printf '%s.%s.0\n' "$((10#$ma))" "$((10#$mi + 1))" ;;
    patch) printf '%s.%s.%s\n' "$((10#$ma))" "$((10#$mi))" "$((10#$pa + 1))" ;;
  esac
}

cmd_suggest() {
  local force_patch=0
  case "${1:-}" in
    --patch) force_patch=1 ;;
    "")      ;;
    *)       die "unknown flag: $1" ;;   # silently ignoring it bumped wrong
  esac
  # `last_tag`'s own `die` only exits the `$(...)` subshell; without this
  # check its exit status is dropped and a real failure reads as "no tag".
  local tag; tag=$(last_tag) || exit 1

  # `--match 'v*'` matches any tag that STARTS with v — `v1.2`, `v2`, even
  # `vnext` — but `bump` needs three numeric segments. Without this check a
  # two-segment tag makes `$((10#$pa + 1))` abort on an empty operand and
  # `suggest` prints an EMPTY version field at exit 0: /release reads field 1
  # as the version to cut and gets nothing, with no failure to branch on.
  # Refuse instead — a repo whose tags are not semver needs a human decision,
  # not a guessed bump.
  if [[ -n "$tag" ]] && ! grep -qE "$SEMVER_RE" <<<"${tag#v}"; then
    die "last tag '$tag' is not semver — retag it, or pass the version to /release explicitly"
  fi

  if [[ -z "$tag" ]]; then
    if [[ "$force_patch" -eq 1 ]]; then
      printf '0.1.1\tno prior tag — first patch release\n'
    else
      printf '0.1.0\tno prior tag — first release\n'
    fi
    return 0
  fi

  local commits kind reason n
  commits=$(git log "$tag..HEAD" --pretty=format:'%s%n%b')
  if [[ "$force_patch" -eq 1 ]]; then
    kind=patch; reason="forced patch off $tag"
  elif grep -qE '^[a-z]+(\([^)]*\))?!:|^BREAKING[ -]CHANGE:' <<<"$commits"; then
    kind=major; reason="breaking change since $tag"
  elif grep -qE '^feat(\([^)]*\))?:' <<<"$commits"; then
    kind=minor
    n=$(grep -cE '^feat(\([^)]*\))?:' <<<"$commits")
    reason="$n feat commit(s) since $tag"
  else
    kind=patch; reason="no feat or breaking commits since $tag"
  fi
  printf '%s\t%s → %s\n' "$(bump "${tag#v}" "$kind")" "$reason" "$kind"
}

# Distinguishes "already fully released" (stop) from "a retry mid-flight"
# (proceed) — the release branch is deleted only after both merges succeed,
# so its presence alongside the tag is what marks an interrupted run.
cmd_check() {
  local v="${1:-}"
  [[ -n "$v" ]] || die "check takes a version"
  grep -qE "$SEMVER_RE" <<<"$v" || die "not valid semver: $v"

  local tagged=0 branched=0 lsout
  # `ls-remote` cannot distinguish "no such tag" from "couldn't ask". Treating
  # a network/auth failure as "not tagged" fails OPEN — it would report an
  # already-released version as `new`. Check local tags too, and refuse on a
  # genuine query failure.
  if lsout=$(git ls-remote origin "refs/tags/v$v" 2>&1); then
    [[ -n "$lsout" ]] && tagged=1
  elif git rev-parse -q --verify "refs/tags/v$v" >/dev/null 2>&1; then
    tagged=1
  else
    die "cannot reach origin to check tag v$v — refusing to guess whether it is released"
  fi
  git rev-parse -q --verify "refs/tags/v$v" >/dev/null 2>&1 && tagged=1
  { git ls-remote --exit-code --heads origin "release/$v" >/dev/null 2>&1 \
    || git show-ref --verify --quiet "refs/heads/release/$v"; } && branched=1

  if [[ "$tagged" -eq 1 && "$branched" -eq 0 ]]; then
    echo "already-released"; exit 2
  elif [[ "$tagged" -eq 1 ]]; then
    echo "retry-after-tag"
  elif [[ "$branched" -eq 1 ]]; then
    echo "retry-branch-exists"
  else
    echo "new"
  fi
}

case "${1:-}" in
  suggest) shift; cmd_suggest "$@" ;;
  check)   shift; cmd_check "$@" ;;
  *) die "usage: version.sh {suggest [--patch]|check <version>}" ;;
esac
