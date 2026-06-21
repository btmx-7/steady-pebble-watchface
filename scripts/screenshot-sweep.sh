#!/usr/bin/env bash
# screenshot-sweep.sh
#
# Build + install + screenshot one PBW per demo scenario.
#
# Each scenario pins a different wall-clock time (see TIMES below) so the
# resulting screenshot set shows a heterogeneous panel of hours rather than
# 8 shots taken at the same minute. This requires `faketime` (libfaketime).
#
# `pebble emu-set-time` looks like the right tool for this but does NOT
# work on emery/gabbro: pebble-tool's own source (pebble_tool/commands/
# screenshot.py) notes that "the QEMU 10 + pebble-emery board ignores
# SetUTC/SetLocaltime: the watch face follows the host RTC" — i.e. the
# firmware itself disregards any live time-set message and just continues
# tracking the host's real wall clock. The only thing that actually works
# is faking what the HOST clock reports, for the QEMU process's entire
# lifetime. `pebble install` reads the host clock once at QEMU boot
# (`-rtc base=localtime`) and the firmware free-runs off the host RTC after
# that, so the fake clock has to be in place before that specific QEMU
# process spawns — meaning a fresh boot (and `faketime`-wrapped install) is
# needed for every scenario; reinstalling into an already-running emulator
# would just inherit whatever time the first scenario booted under. If
# `faketime` isn't installed, the sweep still runs but every shot uses the
# emulator's actual clock instead of the per-scenario TIMES.
#
# Usage:
#   ./scripts/screenshot-sweep.sh                 # emery, all 8 states
#   PLATFORM=gabbro ./scripts/screenshot-sweep.sh # round
#   STATES="0 3 4"  ./scripts/screenshot-sweep.sh # subset

set -euo pipefail

PLATFORM="${PLATFORM:-emery}"
STATES="${STATES:-0 1 2 3 4 5 6 7}"
OUT_DIR="${OUT_DIR:-screenshots/demo}"
BOOT_WAIT="${BOOT_WAIT:-8}"  # cold emulator boot is slower than a warm reinstall

# Keep these arrays aligned (by index) with demo_scenarios[] in src/c/demo/demo.c.
NAMES=(urgent_low low in_range high urgent_high stale post_meal zero_state)
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
    # faketime only affects a process it spawns, so QEMU has to be (re)booted
    # under it for the fake clock to stick — hence kill + cold boot per scenario.
    pebble kill >/dev/null 2>&1 || true
    sleep 2  # let the old QEMU process/ports fully release before booting a new one
    faketime "$(date +%Y-%m-%d) $time_str:00" pebble install --emulator "$PLATFORM"
    sleep "$BOOT_WAIT"
  else
    # No faketime: nothing to pin, so skip the kill + cold boot. A warm reinstall
    # into the already-running emulator is much faster and avoids the cold-boot
    # "Timed out waiting for install confirmation" emery is prone to. Every shot
    # uses the emulator's current wall-clock time. (The first reinstall cold-boots
    # the emulator once if none is running.)
    pebble install --emulator "$PLATFORM"
  fi
  out="$OUT_DIR/${PLATFORM}_${i}_${name}.png"
  pebble screenshot --emulator "$PLATFORM" "$out"
  echo "  Saved: $out"
done

echo ""
echo "Done. Contact sheet input: $OUT_DIR/"
