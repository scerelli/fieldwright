#!/usr/bin/env bash
# API process for the dev TUI: infra -> migrations -> `nest start --watch`.
set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dev-env.sh"
cd "$DEV_ROOT"

dev_up_infra
dev_wait_for_db

echo "==> migrations"
dev_api_env pnpm --dir server run drizzle:migrate

echo "==> API (watch) on http://localhost:$DEV_API_PORT"
# exec (not a wrapper call) so Ctrl-C / mprocs signal the pnpm -> nest process
# directly instead of orphaning it.
DATABASE_URL="$DEV_DB_URL" REDIS_URL="$DEV_REDIS_URL" PORT="$DEV_API_PORT" \
  BETTER_AUTH_SECRET="$DEV_BETTER_AUTH_SECRET" BETTER_AUTH_URL="$DEV_BETTER_AUTH_URL" \
  exec pnpm --dir server run start:dev
