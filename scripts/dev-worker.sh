#!/usr/bin/env bash
# Worker process for the dev TUI. Runs the built worker (`node dist/worker.js`);
# run `pnpm --dir server build` first if `dist/` is stale.
set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dev-env.sh"
cd "$DEV_ROOT"

dev_up_infra
dev_wait_for_db

echo "==> worker"
DATABASE_URL="$DEV_DB_URL" REDIS_URL="$DEV_REDIS_URL" PORT="$DEV_API_PORT" \
  BETTER_AUTH_SECRET="$DEV_BETTER_AUTH_SECRET" BETTER_AUTH_URL="$DEV_BETTER_AUTH_URL" \
  exec pnpm --dir server run start:worker
