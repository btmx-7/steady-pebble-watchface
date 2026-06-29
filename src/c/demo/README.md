# Demo fixtures (QA only)

Visual QA harness for the Steady watchface. Compiled only when `DEMO_DATA=1` is
set in the environment. Release builds (`pebble build` with no env var) do not
include any of this code.

## Files

| File | Role |
|------|------|
| `demo.h` | `DemoScenario` struct + extern table declaration |
| `demo.c` | Scenario table |
| `../main.c` (`#ifdef DEMO_DATA`) | `apply_demo_state()`, button cycler |

Under `DEMO_DATA`, `main.c` also skips restoring persisted settings and
skips subscribing to the real `HealthService` — both would otherwise
clobber the scenario's fixture values (a stale `Dashboard` layout left over
from earlier non-demo testing, or a real step/HR reading of 0 from the
emulator's empty health data) right after `apply_demo_state()` sets them.
A demo build is fully determined by `demo.c` alone; you do not need to
`pebble wipe` before a sweep.

## Scenario table

5 scenarios exercise slot layout, color theme, light/dark mode, time-of-day,
and — crucially — a spread of nominal *and* edge/alert data states, so a
single sweep produces a visually diverse contact sheet rather than
near-identical shots.

| # | Name          | Glucose | Slots (A,B,C,D)                     | CGM slot? | Theme  | Mode  | Time  | Demonstrates |
|---|---------------|---------|--------------------------------------|-----------|--------|-------|-------|--------------|
| 0 | `in_range`    | 120     | CGM, Battery, Weather, Steps         | Yes       | Cyan   | Dark  | 00:07 | **Nominal** — every slot healthy/mid-range |
| 1 | `urgent_low`  | 45      | Steps, Heart Rate, CGM, Battery      | Yes       | Green  | Light | 09:21 | CGM danger zone + **battery charging** |
| 2 | `high_alerts` | 195     | Weather, Steps, Battery, Heart Rate  | No        | Yellow | Dark  | 20:34 | Weather at **max**, battery **low**, HR **high** |
| 3 | `no_data`     | 0       | Heart Rate, Battery, Steps, Weather  | No        | Red    | Light | 16:59 | HR & weather **"--"**, steps 0, battery **full** |
| 4 | `stale`       | 120     | Battery, CGM, Heart Rate, Steps      | Yes       | Purple | Dark  | 11:38 | CGM **stale** (gray) + battery mid |
| 5 | `mono_light`  | 132     | CGM, Battery, Heart Rate, Weather    | Yes       | Mono   | Light | 10:48 | **Mono** light: dark-gray lead hour, white trailing minute, no-data HR slot |
| 6 | `mono_dark`   | 118     | Battery, CGM, Steps, Heart Rate      | Yes       | Mono   | Dark  | 14:25 | **Mono** dark: dark-gray lead hour, light-gray trailing minute, no-data HR slot |

States 5–6 are Mono QA and sit **outside** the default 5-state sweep (the sweep
cold-boots once per state and ~5 boots is the reliable ceiling). Shoot them on
their own with `STATES="5 6" ./scripts/screenshot-sweep.sh`, or just cycle to
them with UP/DOWN in the interactive build.

Notes:
- The set is held at **5** scenarios on purpose: the sweep cold-boots the
  emulator once per scenario to pin its clock, and ~5 cold boots is the
  reliable ceiling — longer 8-state sweeps wedged QEMU on the 6th boot
  (splash-screen loop).
- Exactly **one** scenario (`in_range`) is fully nominal; the other four each
  mix edge/alert states (battery charging / low / full, weather max,
  unavailable `--` readings, HR over threshold, steps 0, CGM stale).
- **3 of 5** put CGM in a slot (`in_range`, `urgent_low`, `stale`), covering
  the widget's normal, danger-zone, and gray/stale stylings. The other two
  (`high_alerts`, `no_data`) configure the watchface without the CGM widget,
  QA'ing the rest of the layout on its own.
- All **five** slot data types (Battery, Weather, Heart Rate, Steps, CGM) are
  spread across all four positions A–D — Heart Rate and Steps each hit all
  four; CGM lands in A (`in_range`), C (`urgent_low`), B (`stale`).
- The battery slot is driven by `battery_pct` / `battery_charging` in the
  scenario (under `DEMO_DATA` the live battery service is bypassed), so the
  charging / low / full states are deterministic in screenshots.
- Themes used: Cyan, Green, Yellow, Red, Purple — 3 dark / 2 light.
- `Time` is the wall-clock time the screenshot sweep pins via `faketime`
  (see `scripts/screenshot-sweep.sh`); spread across the day for a
  heterogeneous panel of hours.

## Usage

### Interactive cycler (recommended)

```bash
DEMO_DATA=1 pebble build
pebble install --emulator emery --logs
```

On the emulator, **UP** cycles forward through states, **DOWN** cycles backward.
The current state name is logged to the `--logs` stream.

### Pin one state at compile time

```bash
DEMO_DATA=1 DEMO_STATE=1 pebble build   # urgent_low
pebble install --emulator emery
```

`DEMO_STATE` defaults to `0` (in_range).

### Screenshot sweep

```bash
./scripts/screenshot-sweep.sh                   # all 5 states, emery (timed)
PLATFORM=gabbro ./scripts/screenshot-sweep.sh   # round
STATES="0 3 4"  ./scripts/screenshot-sweep.sh   # subset
PIN_TIMES=0     ./scripts/screenshot-sweep.sh   # one clock, faster
```

Outputs to `screenshots/demo/<platform>_<i>_<name>.png`.

## Adding a new scenario

1. Bump `DEMO_SCENARIO_COUNT` in `demo.h`.
2. Append a row to `demo_scenarios[]` in `demo.c`, including a `color_theme`
   and `dark_mode` value.
3. Append the short name to `NAMES=(...)` *and* a time to `TIMES=(...)` in
   `scripts/screenshot-sweep.sh`, keeping both arrays aligned by index with
   `demo_scenarios[]`.
4. Update the table above.

Going past ~5 scenarios re-introduces the 6th-cold-boot QEMU wedge in the
default (timed) sweep; if you need more, run them in batches via `STATES=`
(e.g. `STATES="0 1 2 3 4"` then `STATES="5 6 7"`) with a `pebble kill` between
batches, or use `PIN_TIMES=0` (single cold boot for the whole run).

Trend / slot / layout / graph-pattern / color-theme codes are listed in the
header comment of `demo.c`.

## Release checklist

Before `pebble publish`:

```bash
pebble clean
pebble build         # NO DEMO_DATA
```

Verify `build/` has no `-DDEMO_DATA` in any compile command and no `demo/*.o`
objects. Then publish.
