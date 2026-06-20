#!/usr/bin/env bash
# screenshot-sweep.sh
#
# Build + install + screenshot one PBW per demo scenario.
#
# Each scenario pins a different wall-clock time (see TIMES below) so the
# resulting screenshot set shows a heterogeneous panel of hours rather than
# 8 shots taken at the same minute. This used to rely on `faketime` wrapped
# around `pebble install`, but QEMU only reads the host clock at boot
# (`-rtc base=localtime`), not on every reinstall — so it required killing
# and rebooting the emulator before every single scenario, which was both
# slow and prone to install races. `pebble emu-set-time` instead pushes the
# time directly to the already-running emulator over its live connection, so
# the emulator only needs to boot once for the whole sweep.
#
# Usage:
#   ./scripts/screenshot-sweep.sh                 # emery, all 8 states
#   PLATFORM=gabbro ./scripts/screenshot-sweep.sh # round
#   STATES="0 3 4"  ./scripts/screenshot-sweep.sh # subset

set -euo pipefail

PLATFORM="${PLATFORM:-emery}"
STATES="${STATES:-0 1 2 3 4 5 6 7}"
OUT_DIR="${OUT_DIR:-screenshots/demo}"
SETTLE_WAIT="${SETTLE_WAIT:-2}"  # let the watchface redraw after the time jump

# Keep these arrays aligned (by index) with demo_scenarios[] in src/c/demo/demo.c.
NAMES=(urgent_low low in_range high urgent_high stale post_meal zero_state)
TIMES=("06:42" "09:15" "12:08" "14:53" "17:27" "20:36" "22:14" "00:05")

mkdir -p "$OUT_DIR"

for i in $STATES; do
  name="${NAMES[$i]:-state_$i}"
  time_str="${TIMES[$i]:-}"
  echo ""
  echo "──────────────────────────────────────────"
  echo "  State $i  —  $name  ($PLATFORM)${time_str:+ @ $time_str}"
  echo "──────────────────────────────────────────"
  DEMO_DATA=1 DEMO_STATE="$i" pebble build
  pebble install --emulator "$PLATFORM"
  if [[ -n "$time_str" ]]; then
    pebble emu-set-time "$time_str:00" --emulator "$PLATFORM"
  fi
  sleep "$SETTLE_WAIT"
  out="$OUT_DIR/${PLATFORM}_${i}_${name}.png"
  pebble screenshot --emulator "$PLATFORM" "$out"
  echo "  Saved: $out"
done

echo ""
echo "Done. Contact sheet input: $OUT_DIR/"
