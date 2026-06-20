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

## Scenario table

8 scenarios cover the glucose/data states *and* exercise slot layout, color
theme, light/dark mode, and time-of-day combinations so a single sweep
produces a visually diverse contact sheet rather than 8 near-identical shots.

| # | Name          | Glucose | Trend       | Layout    | Slots (A,B,C,D)              | Theme  | Mode  | Time  |
|---|---------------|---------|-------------|-----------|-------------------------------|--------|-------|-------|
| 0 | `urgent_low`  | 45      | Double Down | Simple    | CGM, Battery, Weather, Steps  | Red    | Dark  | 06:42 |
| 1 | `low`         | 65      | Single Down | Simple    | Battery, Steps, CGM, Weather  | Orange | Light | 09:15 |
| 2 | `in_range`    | 120     | Flat        | Simple    | Steps, Weather, Battery, CGM  | Yellow | Dark  | 12:08 |
| 3 | `high`        | 195     | Single Up   | Simple    | Weather, CGM, Steps, Battery  | Green  | Light | 14:53 |
| 4 | `urgent_high` | 270     | Double Up   | Simple    | Steps, Battery, CGM, Weather  | Cyan   | Dark  | 17:27 |
| 5 | `stale`       | 120     | None        | Simple    | Heart Rate, CGM, Battery, Weather | Blue | Light | 20:36 |
| 6 | `dashboard`   | 142     | Flat        | Dashboard | Weather, Battery, Steps, (unused) | Purple | Dark | 22:14 |
| 7 | `zero_state`  | 0       | None        | Simple    | None, None, None, None       | Pink   | Light | 00:05 |

Notes:
- CGM's slot position rotates across A/B/C/D so the widget grid is exercised
  in every position, not just one fixed spot.
- Steps appears in 6 of the 8 scenarios (it was previously unused by any
  scenario); `stale` and `zero_state` deliberately omit it to also cover
  Heart Rate and the fully-empty grid.
- `dashboard` has a dedicated CGM panel outside the slot grid, so its slots
  showcase Weather/Battery/Steps instead of duplicating CGM as a widget.
- All 8 `ColorThemeId` values are used exactly once, split 4 dark / 4 light.
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
DEMO_DATA=1 DEMO_STATE=4 pebble build   # urgent_high
pebble install --emulator emery
```

`DEMO_STATE` defaults to `2` (in_range).

### Screenshot sweep

```bash
./scripts/screenshot-sweep.sh                   # all 8 states, emery
PLATFORM=gabbro ./scripts/screenshot-sweep.sh   # round
STATES="0 3 4"  ./scripts/screenshot-sweep.sh   # subset
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
