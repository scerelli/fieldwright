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
dev_api_env pnpm --dir server run start:worker
