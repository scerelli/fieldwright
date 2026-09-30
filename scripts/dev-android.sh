#!/usr/bin/env bash
# Mobile process for the dev TUI: launch the emulator detached from this
# process tree if it is not already running, then `flutter run` pointed at the
# host API. Because the emulator is detached, quitting mprocs or this script
# leaves it running and the next run reuses it.
# Override with: EMULATOR_ID=<avd> DEVICE=<serial> API_PORT=<port> scripts/dev-android.sh
set -euo pipefail
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dev-env.sh"

EMULATOR_ID="${EMULATOR_ID:-Medium_Phone_API_36.0}"
DEVICE="${DEVICE:-emulator-5554}"

cd "$DEV_ROOT/app"

# Locate a tool under the Android SDK, honouring an explicit root and falling
# back to the conventional per-user install. A missing tool is not fatal.
sdk_tool() {
  local rel="$1" root
  for root in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk"; do
    [ -n "$root" ] && [ -x "$root/$rel" ] && { printf '%s\n' "$root/$rel"; return 0; }
  done
  return 1
}

adb_bin() {
  command -v adb 2>/dev/null || sdk_tool platform-tools/adb
}

emulator_bin() {
  sdk_tool emulator/emulator || command -v emulator 2>/dev/null
}

# True when the target device is attached and ready.
device_running() {
  local adb
  if adb="$(adb_bin)"; then
    "$adb" devices 2>/dev/null \
      | awk -v d="$DEVICE" '$1 == d && $2 == "device" { found = 1 } END { exit !found }'
  else
    flutter devices 2>/dev/null | grep -q "$DEVICE"
  fi
}

# Start the emulator detached (setsid) so it is not in this script's process
# group: mprocs kills that group on quit, and a child here would die with it.
launch_emulator_detached() {
  local emulator
  if emulator="$(emulator_bin)"; then
    echo "==> launching emulator $EMULATOR_ID detached"
    setsid nohup "$emulator" -avd "$EMULATOR_ID" >/dev/null 2>&1 &
  else
    echo "==> launching emulator $EMULATOR_ID detached (flutter launcher)"
    setsid nohup flutter emulators --launch "$EMULATOR_ID" >/dev/null 2>&1 &
  fi
  disown 2>/dev/null || true
}

if device_running; then
  echo "==> reusing running device $DEVICE"
else
  launch_emulator_detached
  for _ in $(seq 1 60); do
    device_running && break
    sleep 2
  done
fi

# 10.0.2.2 is the host loopback as seen from the Android emulator.
echo "==> flutter run on $DEVICE (API http://10.0.2.2:$DEV_API_PORT)"
exec flutter run -d "$DEVICE" \
  --dart-define="IBIS_API_BASE_URL=http://10.0.2.2:$DEV_API_PORT"
