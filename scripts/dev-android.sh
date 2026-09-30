#!/usr/bin/env bash
# Mobile process for the dev TUI: launch the emulator if needed and `flutter run`
# pointed at the host API.
# Override with: EMULATOR_ID=<avd> DEVICE=<serial> API_PORT=<port> scripts/dev-android.sh
set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dev-env.sh"

EMULATOR_ID="${EMULATOR_ID:-Medium_Phone_API_36.0}"
DEVICE="${DEVICE:-emulator-5554}"

cd "$DEV_ROOT/app"

if ! flutter devices 2>/dev/null | grep -q "$DEVICE"; then
  echo "==> launching emulator $EMULATOR_ID"
  flutter emulators --launch "$EMULATOR_ID" >/dev/null 2>&1 || true
  for _ in $(seq 1 60); do
    flutter devices 2>/dev/null | grep -q "$DEVICE" && break
    sleep 2
  done
fi

# 10.0.2.2 is the host loopback as seen from the Android emulator.
echo "==> flutter run on $DEVICE (API http://10.0.2.2:$DEV_API_PORT)"
exec flutter run -d "$DEVICE" \
  --dart-define="IBIS_API_BASE_URL=http://10.0.2.2:$DEV_API_PORT"
