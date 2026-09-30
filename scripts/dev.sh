#!/usr/bin/env bash
# One command to bring up everything for the field app on an Android emulator:
#   db + redis (docker) -> migrations -> API watch -> flutter run.
# Ctrl-C stops the API (and flutter); db/redis keep running (`make stop`).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Make the scripts work in a non-login shell too: Node 24 (nvm) + pnpm + flutter.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
  nvm use 24 >/dev/null 2>&1 || nvm use default >/dev/null 2>&1 || true
fi
export PATH="$HOME/.local/share/pnpm/bin:$HOME/flutter/bin:$PATH"

COMPOSE=(docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml)
API_PORT="${API_PORT:-3000}"
DB_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:55432/ibis}"
REDIS_URL="${REDIS_URL:-redis://localhost:56379}"

echo "==> infra: db + redis"
"${COMPOSE[@]}" up -d db redis
printf '    waiting for postgres'
until "${COMPOSE[@]}" exec -T db pg_isready -U postgres -d ibis >/dev/null 2>&1; do
  printf '.'; sleep 1
done
echo ' ready'

echo "==> migrations"
DATABASE_URL="$DB_URL" pnpm --dir server run drizzle:migrate

REQUESTED_PORT="$API_PORT"
API_PORT="$("$ROOT/scripts/free-port.sh" "$API_PORT")"
if [ "$API_PORT" != "$REQUESTED_PORT" ]; then
  echo "==> port $REQUESTED_PORT is in use; using $API_PORT"
fi
echo "==> API (watch) on port $API_PORT"
DATABASE_URL="$DB_URL" REDIS_URL="$REDIS_URL" PORT="$API_PORT" \
  pnpm --dir server run start:dev &
API=$!
trap 'echo; echo "==> stopping API"; kill "$API" 2>/dev/null || true' EXIT

# Give the API a moment to bind before launching the app.
sleep 2

API_PORT="$API_PORT" "$ROOT/scripts/dev-android.sh"
