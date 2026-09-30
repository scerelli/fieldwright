#!/usr/bin/env bash
# Shared dev environment. Source this, don't run it:
#   . "$(dirname "$0")/dev-env.sh"
# shellcheck shell=bash
DEV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Work in a non-login shell too: Node 24 (nvm) + pnpm + flutter.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
  nvm use 24 >/dev/null 2>&1 || nvm use default >/dev/null 2>&1 || true
fi
export PATH="$HOME/.local/share/pnpm/bin:$HOME/flutter/bin:$PATH"

DEV_COMPOSE=(
  docker compose
  -f "$DEV_ROOT/infra/docker-compose.yml"
  -f "$DEV_ROOT/infra/docker-compose.dev.yml"
)
# API_PORT is exported by `make dev` (already resolved to a free port).
export DEV_API_PORT="${API_PORT:-3000}"
export DEV_DB_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:55432/ibis}"
export DEV_REDIS_URL="${REDIS_URL:-redis://localhost:56379}"
export DEV_BETTER_AUTH_SECRET="${BETTER_AUTH_SECRET:-dev-insecure-secret-change-me-please-32}"
export DEV_BETTER_AUTH_URL="${BETTER_AUTH_URL:-http://localhost:${DEV_API_PORT}}"

dev_up_infra() {
  echo "==> infra: db + redis"
  "${DEV_COMPOSE[@]}" up -d db redis
}

dev_wait_for_db() {
  printf '==> waiting for postgres'
  until "${DEV_COMPOSE[@]}" exec -T db pg_isready -U postgres -d ibis >/dev/null 2>&1; do
    printf '.'; sleep 1
  done
  echo ' ready'
}

dev_api_env() {
  env \
    DATABASE_URL="$DEV_DB_URL" \
    REDIS_URL="$DEV_REDIS_URL" \
    PORT="$DEV_API_PORT" \
    BETTER_AUTH_SECRET="$DEV_BETTER_AUTH_SECRET" \
    BETTER_AUTH_URL="$DEV_BETTER_AUTH_URL" \
    "$@"
}
