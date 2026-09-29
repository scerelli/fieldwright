#!/usr/bin/env bash
# shipwright changelog.sh — prepend a release section to CHANGELOG.md.
#
#   changelog.sh <version> [--date YYYY-MM-DD] [--since <ref>]
#
# Groups Conventional Commits since the last tag into Features / Fixes /
# Other, and prepends the section under the file's title (creating the file
# with a `# Changelog` title if absent). Idempotent: re-running for a version
# already present in the file is a no-op.
set -uo pipefail

die() { printf 'changelog.sh: %s\n' "$1" >&2; exit 1; }

version="${1:-}"; shift || true
[[ -n "$version" ]] || die "usage: changelog.sh <version> [--date D] [--since REF]"

date_str=""; since=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --date)  date_str="$2"; shift 2 ;;
    --since) since="$2"; shift 2 ;;
    *) die "unknown flag: $1" ;;
  esac
done
[[ -n "$date_str" ]] || date_str=$(date -u +%F)

# A bare relative path is only correct when invoked from the repo root — the
# same class of bug fixed in skills/preflight/scripts/preflight.sh, where an
# agent's cwd not being the repo root produced a silently wrong result. `git`
# calls below tolerate a subdirectory by walking up to `.git`; the file path
# does not, so anchor it the same way.
repo_root=$(git rev-parse --show-toplevel 2>/dev/null) \
  || die "not a git repository"
file="$repo_root/CHANGELOG.md"
[[ -f "$file" ]] || printf '# Changelog\n' > "$file"

if grep -qF "## [$version]" "$file"; then
  echo "changelog already has $version — no change"; exit 0
fi

section=$(mktemp); out=$(mktemp)
trap 'rm -f "$section" "$out"' EXIT
printf '## [%s] - %s\n' "$version" "$date_str" >> "$section"

# A `git describe` failure is not always "no tags yet" — it is equally what a
# corrupt or shallow checkout looks like, and reading that as "no prior tag"
# silently re-lists every commit in the project's history as if it were this
# release. Only the genuine "no tag reachable" message is safe to continue on.
# Same rule as version.sh's last_tag, for the same reason.
if [[ -z "$since" ]]; then
  if since=$(git describe --tags --abbrev=0 --match 'v*' 2>&1); then
    :
  elif grep -qi 'no names found\|no tags can describe' <<<"$since"; then
    since=""
  else
    die "cannot determine the last release tag: $since"
  fi
fi
# With no tag at all, bound the range to commits since CHANGELOG.md was last
# touched, so a second untagged release doesn't re-list every earlier entry.
# (The previous approach looked for a tag named after the prior entry's
# version — but no tag can exist under that name either, since "no tag at
# all" is exactly the condition that reaches this branch; it never fired.)
if [[ -z "$since" ]]; then
  since=$(git log -1 --format=%H -- "$file" 2>/dev/null || true)
fi
range="HEAD"; [[ -n "$since" ]] && range="$since..HEAD"
commits=$(git log "$range" --pretty=format:'%s' --no-merges) \
  || die "could not read commits for range '$range' — check --since"

emit() { # <heading> <grep-pattern>
  local body
  body=$(grep -E "$2" <<<"$commits" | sed -E 's/^[a-z]+(\(([^)]*)\))?!?: */- /')
  [[ -n "$body" ]] || return 0
  printf '\n### %s\n%s\n' "$1" "$body" >> "$section"
}
emit Features '^feat(\([^)]*\))?!?:'
emit Fixes    '^fix(\([^)]*\))?!?:'
other=$(grep -vE '^(feat|fix)(\([^)]*\))?!?:' <<<"$commits" \
        | grep -E '^[a-z]+(\([^)]*\))?!?:' \
        | sed -E 's/^[a-z]+(\(([^)]*)\))?!?: */- /')
[[ -n "$other" ]] && printf '\n### Other\n%s\n' "$other" >> "$section"

# Prepend under the title line, preserving everything already there.
{
  head -1 "$file"
  printf '\n'
  cat "$section"
  tail -n +2 "$file"
} > "$out"
# Rewrite in place rather than `mv`-ing the temp over it. `mktemp` creates 0600
# in $TMPDIR, and both a cross-device `mv` (copy) and a same-device one
# (rename) leave the DESTINATION carrying the temp's mode — silently turning a
# world-readable CHANGELOG.md into a 0600 file. git records only the exec bit,
# so the change is invisible in a diff and survives into any tarball or `cp -r`
# install. Truncating the existing inode keeps its mode and ownership.
cat "$out" > "$file" || die "could not write $file"
echo "changelog updated for $version"
