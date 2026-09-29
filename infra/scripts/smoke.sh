#!/usr/bin/env bash
#
# Smoke-tests the docker-compose stack end to end: bring it up, wait for the
# API's GET /readyz to return 200, then tear it down. Exits non-zero when a
# required service never becomes healthy.
#
# Run from anywhere:
#   infra/scripts/smoke.sh
#
# Env:
#   API_PORT                     host port the API is published on (default 3000)
#   SMOKE_TIMEOUT_SECONDS        how long to wait for /readyz      (default 180)
#   SMOKE_POLL_INTERVAL_SECONDS  delay between /readyz polls      (default 2)

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
compose_file="$script_dir/../docker-compose.yml"
env_file="$script_dir/../.env"

# Compose reads infra/.env for credentials and the published API port; load the
# same file here so the readiness URL and the container ports never disagree.
if [ -f "$env_file" ]; then
  set -a
  # shellcheck source=/dev/null
  . "$env_file"
  set +a
fi

api_port="${API_PORT:-3000}"
ready_url="http://localhost:${api_port}/readyz"
timeout_seconds="${SMOKE_TIMEOUT_SECONDS:-180}"
poll_interval="${SMOKE_POLL_INTERVAL_SECONDS:-2}"

compose() {
  docker compose -f "$compose_file" "$@"
}

# Always tear the stack down, whatever the outcome; bash keeps the original
# exit status because the trap does not call `exit`.
trap 'printf "Tearing down the stack...\n"; compose down || true' EXIT

printf 'Bringing the stack up (this may build the images)...\n'
compose up -d --build

printf 'Waiting up to %ss for %s ...\n' "$timeout_seconds" "$ready_url"

deadline=$((SECONDS + timeout_seconds))
last_status=000
while ((SECONDS < deadline)); do
  if ! last_status=$(curl --silent --output /dev/null --write-out '%{http_code}' "$ready_url"); then
    last_status=000
  fi

  if [ "$last_status" = "200" ]; then
    printf 'API is ready.\n'
    exit 0
  fi

  failed=$(compose ps --all --format '{{.Service}} {{.State}} {{.Health}}' |
    awk '$2 == "exited" || $2 == "dead" || $3 == "unhealthy" { print $1 ":" $2 "/" $3 }')
  if [ -n "$failed" ]; then
    printf 'A required service is not healthy:\n%s\n' "$failed" >&2
    exit 1
  fi

  sleep "$poll_interval"
done

printf 'Timed out after %ss waiting for %s (last status: %s).\n' \
  "$timeout_seconds" "$ready_url" "$last_status" >&2
exit 1
