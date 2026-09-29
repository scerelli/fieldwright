#!/usr/bin/env bash
# shipwright check.sh — validate a Conventional Commits header or full message.
#
#   check.sh "feat(auth): add login"          # a header or PR title
#   check.sh --file .git/COMMIT_EDITMSG       # a full message
#
# Exit 0 = valid. Exit 1 = invalid, with every problem named on stderr.
# You still write the message; this only stops a malformed one from shipping.
set -uo pipefail

TYPES='feat|fix|docs|refactor|test|perf|build|ci|chore|revert'

msg=""
if [[ "${1:-}" == "--file" ]]; then
  [[ -f "${2:-}" ]] || { echo "check.sh: no such file: ${2:-}" >&2; exit 1; }
  msg=$(cat "$2")
else
  msg="${1:-}"
fi
[[ -n "$msg" ]] || { echo 'usage: check.sh "<message>" | --file <path>' >&2; exit 1; }
# A CRLF-authored message (Windows editor, --file on a checked-out-as-CRLF
# repo) puts a trailing \r before every $. `.$` and length checks below would
# then be checking against the \r, not the actual last character.
msg=${msg//$'\r'/}

header=$(head -1 <<<"$msg")
body=$(tail -n +2 <<<"$msg")
bad=0
say() { printf '  ✗ %s\n' "$1" >&2; bad=1; }

if ! grep -qE "^($TYPES)(\([a-z0-9._/-]+\))?!?: .+" <<<"$header"; then
  say "header must be '<type>(<scope>): <description>'"
  grep -qE "^[a-z]+/[a-z]+" <<<"$header" && say "blended type — pick the dominant one"
  grep -qE "^($TYPES)" <<<"$header" || say "type must be one of: ${TYPES//|/, }"
fi

[[ "${#header}" -le 72 ]] || say "header is ${#header} chars; keep it under 72"
grep -qE '\.$' <<<"$header" && say "header must not end with a period"

desc=${header#*: }
grep -qiE '^(added|adds|fixed|fixes|updated|updates|removed|removes|changed|changes) ' <<<"$desc" \
  && say "description must be imperative mood ('add', not 'added'/'adds')"

# Closing belongs to an explicit `gh issue close` step, never a trailer.
grep -qiE '^(closes|fixes|resolves) #[0-9]+' <<<"$body" \
  && say "use 'Refs #<n>' in a trailer, not Closes/Fixes — closing is /ship's explicit step"

if [[ -n "$(tr -d '[:space:]' <<<"$body")" ]]; then
  [[ -z "$(sed -n '1p' <<<"$body" | tr -d '[:space:]')" ]] \
    || say "body must be separated from the header by a blank line"
fi

[[ "$bad" -eq 0 ]] || { printf '\ninvalid: %s\n' "$header" >&2; exit 1; }
echo "ok"
