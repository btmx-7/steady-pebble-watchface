#!/usr/bin/env bash
# screenshot-sweep.sh
#
# Build + install + screenshot one PBW per demo scenario.
#
# Default behaviour: boot the emulator ONCE, then reinstall each scenario into
# that already-running emulator and grab a screenshot. This warm-reinstall path
# is the one that actually works on emery/gabbro (QEMU 10): a warm reinstall is
# fast and pebble-tool gets its install confirmation well within the timeout. A
# *cold* boot, by contrast, is slower than pebble-tool's install-confirmation
# timeout, so booting fresh for every scenario reliably fails with "Timed out
# waiting for install confirmation."
#
# TIME PINNING (opt-in, PIN_TIMES=1 — off by default):
#   Each scenario can pin a different wall-clock time (see TIMES below) so the
#   panel shows a heterogeneous set of hours. `pebble emu-set-time` looks like
#   the right tool but does NOT work here: pebble-tool's own source notes the
#   QEMU 10 + pebble-emery board ignores SetUTC/SetLocaltime and the watchface
#   just follows the host RTC. The only lever is faking the HOST clock for the
#   QEMU process's whole lifetime via `faketime`, which means a fresh cold boot
#   per scenario — and that cold boot is slower than pebble-tool's install
#   timeout, so the faketime'd `pebble install` usually reports a timeout.
#   That's fine and expected: the QEMU it spawned keeps running with the faked
#   clock latched into its RTC, so we just ignore that timeout and then do a
#   normal WARM reinstall into the now-booted emulator (which lands quickly and
#   shows the right hour). Time pinning therefore costs one slow cold boot per
#   scenario but does produce varied clocks. Still gated behind PIN_TIMES=1
#   because it's slower and a bit more fragile than the single-clock default.
#
# Usage:
#   ./scripts/screenshot-sweep.sh                  # emery, all 8 states (one clock)
#   PLATFORM=gabbro ./scripts/screenshot-sweep.sh  # round
#   STATES="0 3 4"  ./scripts/screenshot-sweep.sh  # subset
#   PIN_TIMES=1 ./scripts/screenshot-sweep.sh      # opt into per-scenario clocks (flaky)

set -euo pipefail

PLATFORM="${PLATFORM:-emery}"
STATES="${STATES:-0 1 2 3 4 5 6 7}"
OUT_DIR="${OUT_DIR:-screenshots/demo}"
BOOT_WAIT="${BOOT_WAIT:-8}"  # cold emulator boot is slower than a warm reinstall
INSTALL_RETRIES="${INSTALL_RETRIES:-4}"  # emery/gabbro cold boot can outlast pebble-tool's install timeout
PIN_TIMES="${PIN_TIMES:-0}"  # 1 = cold-boot each scenario under faketime to vary the clock (flaky)

# Keep these arrays aligned (by index) with demo_scenarios[] in src/c/demo/demo.c.
NAMES=(urgent_low low in_range high urgent_high stale post_meal zero_state)
TIMES=("06:42" "09:15" "12:08" "14:53" "17:27" "20:36" "22:14" "00:05")

HAVE_FAKETIME=0
if [[ "$PIN_TIMES" == "1" ]]; then
  if command -v faketime >/dev/null 2>&1; then
    HAVE_FAKETIME=1
  else
    echo "Warning: PIN_TIMES=1 but faketime not found — screenshots will use the emulator's actual clock." >&2
  fi
fi

mkdir -p "$OUT_DIR"

# Start from a known-good emulator state. `pebble kill` only stops the QEMU
# process — it does NOT reset the persisted flash image (qemu_spi_flash.bin),
# so a prior run that left that image corrupted (e.g. a `kill -9` mid-write)
# would make every subsequent boot hang on the splash screen forever, no
# matter how many install retries. `pebble wipe` resets that persisted state.
pebble kill >/dev/null 2>&1 || true
pebble wipe >/dev/null 2>&1 || true

# Warm-boot the emulator once, up front, so the per-scenario installs below are
# fast warm reinstalls rather than slow cold boots. We can't boot the emulator
# without an app to install, so build the first requested state and install it
# (with retry, since this first install IS the cold boot). Skipped when pinning
# times, because that mode deliberately cold-boots under faketime per scenario.
first_state="${STATES%% *}"
if [[ "$HAVE_FAKETIME" -ne 1 ]]; then
  echo "Booting $PLATFORM (cold) before the sweep…"
  DEMO_DATA=1 DEMO_STATE="$first_state" pebble build >/dev/null
  for ((t = 1; t <= INSTALL_RETRIES; t++)); do
    if pebble install --emulator "$PLATFORM"; then
      break
    fi
    echo "  cold-boot install attempt $t/$INSTALL_RETRIES failed; waiting for the emulator to come up…" >&2
    sleep "$BOOT_WAIT"
  done
fi

# Warm reinstall into the already-running emulator — the reliable path. No
# kill/wipe: that would tear down the warm emulator we want to reuse and force
# another slow cold boot. Returns non-zero only if every attempt fails, so the
# caller can skip the scenario instead of aborting the whole sweep.
warm_install() {
  local t
  for ((t = 1; t <= INSTALL_RETRIES; t++)); do
    if pebble install --emulator "$PLATFORM"; then
      sleep 2  # brief settle so the face redraws before the shot
      return 0
    fi
    echo "  install attempt $t/$INSTALL_RETRIES failed; giving the emulator more time…" >&2
    sleep 5
  done
  return 1
}

# Install the freshly-built app for scenario $i (uses $time_str when pinning).
install_app() {
  if [[ "$HAVE_FAKETIME" -eq 1 && -n "$time_str" ]]; then
    # Cold-boot a fresh QEMU under faketime so its RTC latches $time_str, then
    # warm-install into it. The faketime'd cold install usually times out on
    # confirmation (cold boot > pebble-tool's timeout), but the QEMU it spawned
    # keeps running with the faked clock, so the warm_install below lands and
    # the screenshot shows the right hour. The script's up-front `pebble wipe`
    # already gave us a clean starting flash; per-scenario we only need to kill
    # the previous QEMU so a fresh one re-reads the (newly faked) host clock.
    pebble kill >/dev/null 2>&1 || true
    sleep 2  # let the old QEMU process/ports fully release before rebooting
    faketime "$(date +%Y-%m-%d) $time_str:00" pebble install --emulator "$PLATFORM" >/dev/null 2>&1 || true
    sleep "$BOOT_WAIT"  # let the cold boot finish before the warm reinstall
  fi
  warm_install
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
