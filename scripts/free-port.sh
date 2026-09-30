#!/usr/bin/env bash
# Print the first free TCP port at or above $1 (default 3000).
# Used so dev startup falls back past a busy port / leftover dev server.
set -euo pipefail
port="${1:-3000}"
listeners="$({ ss -ltn 2>/dev/null || netstat -ltn 2>/dev/null; } | awk '{print $4}')"
while grep -qE "[:.]${port}\$" <<<"$listeners"; do
  port=$((port + 1))
done
printf '%s\n' "$port"
