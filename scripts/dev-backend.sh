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
dev_api_env pnpm --dir server run start:dev
