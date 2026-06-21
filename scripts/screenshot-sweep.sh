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
INSTALL_RETRIES="${INSTALL_RETRIES:-4}"  # emery/gabbro cold boot can outlast pebble-tool's install timeout

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

# Install the freshly-built app for scenario $i (uses $time_str from the loop).
#
# emery/gabbro can take longer to cold-boot than pebble-tool's install
# confirmation timeout, so the first attempt against a not-yet-ready QEMU may
# fail with "Timed out waiting for install confirmation" or a connection
# TimeoutError. The QEMU it spawned keeps booting in the background, so a retry
# a few seconds later lands in a warm, responsive emulator. Returns non-zero
# only if every attempt fails (so the caller can skip the scenario instead of
# aborting the whole sweep).
install_app() {
  local t
  for ((t = 1; t <= INSTALL_RETRIES; t++)); do
    if [[ "$HAVE_FAKETIME" -eq 1 && -n "$time_str" ]]; then
      # faketime only affects a process it spawns, so QEMU has to be (re)booted
      # under it for the fake clock to stick — kill + cold boot per attempt.
      pebble kill >/dev/null 2>&1 || true
      sleep 2  # let the old QEMU process/ports fully release before rebooting
      if faketime "$(date +%Y-%m-%d) $time_str:00" pebble install --emulator "$PLATFORM"; then
        sleep "$BOOT_WAIT"  # let the freshly-booted face settle before the shot
        return 0
      fi
    else
      # No faketime: nothing to pin, so reinstall into the running emulator. The
      # first attempt cold-boots it (and may time out); retries land warm.
      if pebble install --emulator "$PLATFORM"; then
        return 0
      fi
    fi
    echo "  install attempt $t/$INSTALL_RETRIES failed; giving the emulator a few more seconds to boot…" >&2
    sleep 5
  done
  return 1
}

for i in $STATES; do
  name="${NAMES[$i]:-state_$i}"
  time_str="${TIMES[$i]:-}"
  echo ""
  echo "──────────────────────────────────────────"
  echo "  State $i  —  $name  ($PLATFORM)${time_str:+ @ $time_str}"
  echo "──────────────────────────────────────────"
  DEMO_DATA=1 DEMO_STATE="$i" pebble build
  out="$OUT_DIR/${PLATFORM}_${i}_${name}.png"
  if install_app && pebble screenshot --emulator "$PLATFORM" "$out"; then
    echo "  Saved: $out"
  else
    echo "  WARNING: state $i ($name) failed after $INSTALL_RETRIES attempts — skipping" >&2
  fi
done

echo ""
echo "Done. Contact sheet input: $OUT_DIR/"
