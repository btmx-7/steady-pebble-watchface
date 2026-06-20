#!/usr/bin/env bash
# screenshot-sweep.sh
#
# Build + install + screenshot one PBW per demo scenario.
# Requires a running emulator: `pebble install --emulator emery` once first.
#
# Each scenario pins a different wall-clock time (see TIMES below) so the
# resulting screenshot set shows a heterogeneous panel of hours rather than
# 8 shots taken at the same minute. This requires `faketime` (libfaketime).
# The watch's RTC is synced from the host clock at install/launch time (the
# same way a real watch syncs time from its paired phone), so `faketime`
# wraps `pebble install`, not `pebble screenshot`. If `faketime` isn't
# installed, the sweep still runs but every shot uses the emulator's actual
# clock instead of the per-scenario TIMES.
#
# Usage:
#   ./scripts/screenshot-sweep.sh                 # emery, all 8 states
#   PLATFORM=gabbro ./scripts/screenshot-sweep.sh # round
#   STATES="0 3 4"  ./scripts/screenshot-sweep.sh # subset

set -euo pipefail

PLATFORM="${PLATFORM:-emery}"
STATES="${STATES:-0 1 2 3 4 5 6 7}"
OUT_DIR="${OUT_DIR:-screenshots/demo}"

# Keep these arrays aligned (by index) with demo_scenarios[] in src/c/demo/demo.c.
NAMES=(urgent_low low in_range high urgent_high stale dashboard zero_state)
TIMES=("06:42" "09:15" "12:08" "14:53" "17:27" "20:36" "22:14" "00:05")

if command -v faketime >/dev/null 2>&1; then
  HAVE_FAKETIME=1
else
  HAVE_FAKETIME=0
  echo "Warning: faketime not found — screenshots will use the emulator's actual clock, not the per-scenario TIMES." >&2
fi

mkdir -p "$OUT_DIR"

for i in $STATES; do
  name="${NAMES[$i]:-state_$i}"
  time_str="${TIMES[$i]:-}"
  echo ""
  echo "──────────────────────────────────────────"
  echo "  State $i  —  $name  ($PLATFORM)${time_str:+ @ $time_str}"
  echo "──────────────────────────────────────────"
  DEMO_DATA=1 DEMO_STATE="$i" pebble build
  if [[ "$HAVE_FAKETIME" -eq 1 && -n "$time_str" ]]; then
    faketime "$(date +%Y-%m-%d) $time_str:00" pebble install --emulator "$PLATFORM"
  else
    pebble install --emulator "$PLATFORM"
  fi
  sleep 3
  out="$OUT_DIR/${PLATFORM}_${i}_${name}.png"
  pebble screenshot --emulator "$PLATFORM" "$out"
  echo "  Saved: $out"
done

echo ""
echo "Done. Contact sheet input: $OUT_DIR/"
