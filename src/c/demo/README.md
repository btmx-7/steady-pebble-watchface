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

5 scenarios condense the glucose/data states *and* exercise slot layout, color
theme, light/dark mode, and time-of-day combinations so a single sweep
produces a visually diverse contact sheet rather than near-identical shots.

| # | Name          | Glucose | Trend       | Layout    | Slots (A,B,C,D)                     | CGM slot? | Theme  | Mode  | Time  |
|---|---------------|---------|-------------|-----------|--------------------------------------|-----------|--------|-------|-------|
| 0 | `in_range`    | 120     | Flat        | Simple    | CGM, Battery, Weather, Steps         | Yes       | Cyan   | Dark  | 00:07 |
| 1 | `urgent_low`  | 45      | Double Down | Simple    | Steps, Heart Rate, CGM, Weather      | Yes       | Green  | Light | 09:21 |
| 2 | `high`        | 195     | Single Up   | Simple    | Weather, Steps, Battery, Heart Rate  | No        | Yellow | Dark  | 20:34 |
| 3 | `urgent_high` | 270     | Double Up   | Simple    | Heart Rate, CGM, Battery, Weather    | Yes       | Red    | Light | 16:59 |
| 4 | `stale`       | 120     | None        | Simple    | Battery, CGM, Heart Rate, Steps      | Yes       | Purple | Dark  | 11:38 |

Notes:
- The set is held at **5** scenarios on purpose: the sweep cold-boots the
  emulator once per scenario to pin its clock, and ~5 cold boots is the
  reliable ceiling — longer 8-state sweeps wedged QEMU on the 6th boot
  (splash-screen loop). 5 condenses the glucose-zone coverage (`in_range`,
  `urgent_low`, `high`, `urgent_high`, `stale`) into that budget.
- **4 of 5** scenarios put CGM in a slot, covering all of the widget's
  distinctive styling (zone color across in-range/low/high, plus the
  gray/stale treatment). `high` is the lone no-CGM scenario, QA'ing the
  rest of the layout (Battery/Weather/Heart Rate/Steps) on its own.
- All **five** slot data types (Battery, Weather, Heart Rate, Steps, CGM)
  are spread across all four positions A–D — e.g. CGM lands in A
  (`in_range`), C (`urgent_low`), and B (`urgent_high`, `stale`); Heart Rate
  hits all four positions across the set.
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
DEMO_DATA=1 DEMO_STATE=3 pebble build   # urgent_high
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
