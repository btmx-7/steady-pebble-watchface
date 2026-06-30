#!/usr/bin/env bash
# screenshot-sweep.sh
#
# Build + install + screenshot one PBW per demo scenario.
#
# Each scenario's clock is BAKED INTO THE DEMO BUILD (demo_hour/demo_min in
# src/c/demo/demo.c, rendered by main.c under DEMO_DATA), so the displayed time
# does not depend on the host clock at all. That replaces the old, flaky
# faketime approach: `pebble emu-set-time` is ignored by the QEMU/emery board,
# and faking the host clock only worked if QEMU latched it at cold boot — which
# was unreliable (the time reset to the host clock before the screenshot).
#
# Because the time is in the build, the emulator is cold-booted exactly ONCE and
# every scenario is a fast WARM reinstall into it. No per-scenario cold boots,
# so there's no ~5-scenario QEMU wedge ceiling anymore.
#
# Usage:
#   ./scripts/screenshot-sweep.sh                  # emery, default states
#   PLATFORM=gabbro ./scripts/screenshot-sweep.sh  # round
#   STATES="0 3 4"  ./scripts/screenshot-sweep.sh  # subset
#   STATES="0 1 2 3 4 5 6" ./scripts/screenshot-sweep.sh  # everything incl. mono
#
# STORE mode — capture the publish-ready App Store screenshots. Writes
# resources/screenshots/<platform>_<name>.png (e.g. emery_in_range.png), which
# `pebble publish` maps to a platform by the <platform>_ filename prefix. Run it
# once per platform; the default STATES (0-4) are exactly the 5 store use cases:
# in_range (cyan/dark), urgent_low (green/light), high_alerts (yellow/dark),
# no_data (red/light), stale (purple/dark).
#   STORE=1 ./scripts/screenshot-sweep.sh                 # emery store set
#   STORE=1 PLATFORM=gabbro ./scripts/screenshot-sweep.sh # round store set

set -euo pipefail

PLATFORM="${PLATFORM:-emery}"
STATES="${STATES:-0 1 2 3 4}"
STORE="${STORE:-0}"  # 1 = write publish-ready resources/screenshots/<platform>_<name>.png
if [[ "$STORE" == "1" ]]; then
  OUT_DIR="${OUT_DIR:-resources/screenshots}"
else
  OUT_DIR="${OUT_DIR:-screenshots/demo}"
fi
BOOT_WAIT="${BOOT_WAIT:-20}"  # cold emulator boot is slower than a warm reinstall
INSTALL_RETRIES="${INSTALL_RETRIES:-4}"  # emery/gabbro cold boot can outlast pebble-tool's install timeout

# Names align (by index) with demo_scenarios[] in src/c/demo/demo.c. The clock
# for each is set there (demo_hour/demo_min), not here.
NAMES=(in_range urgent_low high_alerts no_data stale mono_light mono_dark)

mkdir -p "$OUT_DIR"

# Start from a known-good emulator state. `pebble kill` only stops the QEMU
# process — it does NOT reset the persisted flash image (qemu_spi_flash.bin),
# so a prior run that left that image corrupted (e.g. a `kill -9` mid-write)
# would make every subsequent boot hang on the splash screen forever, no
# matter how many install retries. `pebble wipe` resets that persisted state.
pebble kill >/dev/null 2>&1 || true
pebble wipe >/dev/null 2>&1 || true

# Warm reinstall into the already-running emulator — the reliable path. No
# kill/wipe: that would tear down the warm emulator we want to reuse and force
# another slow cold boot. Retry backoff grows (5s, 10s, 15s, …) so a
# slower-than-usual boot still gets room to finish. Returns non-zero only if
# every attempt fails, so the caller can skip the scenario instead of aborting.
warm_install() {
  local t
  for ((t = 1; t <= INSTALL_RETRIES; t++)); do
    if pebble install --emulator "$PLATFORM"; then
      sleep 2  # brief settle so the face redraws before the shot
      return 0
    fi
    echo "  install attempt $t/$INSTALL_RETRIES failed; giving the emulator more time…" >&2
    sleep $((t * 5))
  done
  return 1
}

# Cold-boot the emulator once, up front, using the first requested state. This
# first install IS the cold boot, so it gets the retry/backoff loop.
first_state="${STATES%% *}"
echo "Booting $PLATFORM (cold) before the sweep…"
DEMO_DATA=1 DEMO_STATE="$first_state" pebble build >/dev/null
for ((t = 1; t <= INSTALL_RETRIES; t++)); do
  if pebble install --emulator "$PLATFORM"; then
    break
  fi
  echo "  cold-boot install attempt $t/$INSTALL_RETRIES failed; waiting for the emulator to come up…" >&2
  sleep "$BOOT_WAIT"
done

for i in $STATES; do
  name="${NAMES[$i]:-state_$i}"
  echo ""
  echo "──────────────────────────────────────────"
  echo "  State $i  —  $name  ($PLATFORM)"
  echo "──────────────────────────────────────────"
  DEMO_DATA=1 DEMO_STATE="$i" pebble build
  # STORE mode drops the numeric index so the filename is a clean, publish-ready
  # <platform>_<name>.png (the <platform>_ prefix is what publish classifies on).
  if [[ "$STORE" == "1" ]]; then
    out="$OUT_DIR/${PLATFORM}_${name}.png"
  else
    out="$OUT_DIR/${PLATFORM}_${i}_${name}.png"
  fi
  if warm_install && pebble screenshot --emulator "$PLATFORM" "$out"; then
    echo "  Saved: $out"
  else
    echo "  WARNING: state $i ($name) failed after $INSTALL_RETRIES attempts — skipping" >&2
  fi
done

echo ""
echo "Done. Contact sheet input: $OUT_DIR/"
