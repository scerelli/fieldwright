#!/usr/bin/env bash
#
# Exercises infra/scripts/smoke.sh with stubbed `docker` and `curl` so the
# control flow (bring the stack up, poll /readyz, tear it down) and the
# non-zero exits are checked deterministically, without a real Docker daemon.
#
# Run: infra/scripts/smoke.test.sh

set -uo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
smoke="$here/smoke.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

stub_bin="$tmp/bin"
mkdir -p "$stub_bin"

# Stub docker: logs every call, answers `compose ps` with a fixed service list.
cat >"$stub_bin/docker" <<'DOCKER'
#!/usr/bin/env bash
printf 'docker %s\n' "$*" >>"${STUB_LOG:?STUB_LOG unset}"
sub="${4:-}"
if [ "$sub" = "ps" ]; then
  printf 'api running \n'
  printf 'worker running \n'
  printf 'db %s\n' "${STUB_DB_PS:-running healthy}"
  printf 'redis running healthy\n'
fi
exit 0
DOCKER
chmod +x "$stub_bin/docker"

# Stub curl: logs every call and reports STUB_HTTP_STATUS as the HTTP code.
cat >"$stub_bin/curl" <<'CURL'
#!/usr/bin/env bash
printf 'curl %s\n' "$*" >>"${STUB_LOG:?STUB_LOG unset}"
printf '%s' "${STUB_HTTP_STATUS:-200}"
exit 0
CURL
chmod +x "$stub_bin/curl"

pass=0
fail=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   - %s\n' "$1"
    pass=$((pass + 1))
  else
    printf 'FAIL - %s (expected %s, got %s)\n' "$1" "$3" "$2"
    fail=$((fail + 1))
  fi
}

# Run smoke.sh against the stubs; the exit status is printed for the caller.
run_smoke() {
  : >"$tmp/log"
  STUB_LOG="$tmp/log" \
    PATH="$stub_bin:$PATH" \
    API_PORT=4321 \
    SMOKE_TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-2}" \
    SMOKE_POLL_INTERVAL_SECONDS=0 \
    bash "$smoke" >"$tmp/out" 2>&1
}

# C1: an already-healthy stack exits 0 after bringing the stack up and down.
STUB_HTTP_STATUS=200 SMOKE_TIMEOUT_SECONDS=5 run_smoke
check "C1 healthy stack exits 0" "$?" "0"
grep -q 'docker compose .* up -d' "$tmp/log"
check "C1 brings the stack up" "$?" "0"
grep -q 'docker compose .* down' "$tmp/log"
check "C1 tears the stack down" "$?" "0"
grep -q 'localhost:4321/readyz' "$tmp/log"
check "C1 polls the configured API port" "$?" "0"

# C2: a readyz that never turns 200 times out non-zero, after tearing down.
STUB_HTTP_STATUS=503 SMOKE_TIMEOUT_SECONDS=1 run_smoke
check "C2 unhealthy API exits non-zero" "$?" "1"
grep -q 'docker compose .* down' "$tmp/log"
check "C2 tears the stack down on failure" "$?" "0"

# C2: a required service that has exited fails fast, well before the timeout.
start=$SECONDS
STUB_HTTP_STATUS=503 SMOKE_TIMEOUT_SECONDS=30 STUB_DB_PS="exited " run_smoke
status=$?
elapsed=$((SECONDS - start))
check "C2 an exited service exits non-zero" "$status" "1"
[ "$elapsed" -lt 10 ]
check "C2 an exited service fails fast" "$?" "0"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
