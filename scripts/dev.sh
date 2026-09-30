#!/usr/bin/env bash
# Single-terminal dev: db + redis -> migrations -> API watch -> flutter run.
# For the Turborepo-like TUI with a process sidebar, use `make dev` (mprocs).
# Ctrl-C stops the API (and flutter); db/redis keep running (`make stop`).
set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dev-env.sh"
cd "$DEV_ROOT"

dev_up_infra
dev_wait_for_db

echo "==> migrations"
dev_api_env pnpm --dir server run drizzle:migrate

echo "==> API (watch) on http://localhost:$DEV_API_PORT"
dev_api_env pnpm --dir server run start:dev &
API=$!
trap 'echo; echo "==> stopping API"; kill "$API" 2>/dev/null || true' EXIT

# Give the API a moment to bind before launching the app.
sleep 2

exec "$DEV_ROOT/scripts/dev-android.sh"
