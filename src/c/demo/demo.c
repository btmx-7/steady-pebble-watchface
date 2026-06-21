/**
 * Steady — Demo scenario fixtures (QA-only)
 *
 * Data table only. The apply/cycle logic lives in main.c where it can
 * touch the watchface's internal state.
 *
 * Trend values match GlucoseTrend in main.c:
 *   0=DOUBLE_UP, 1=SINGLE_UP, 2=45_UP, 3=FLAT,
 *   4=45_DOWN,   5=SINGLE_DOWN, 6=DOUBLE_DOWN, 7=NONE
 * Slot values match SlotType:
 *   0=NONE, 1=BATTERY, 2=WEATHER, 3=HEART_RATE, 4=STEPS, 5=CGM
 * Layout: 0=SIMPLE, 1=DASHBOARD
 * Graph pattern: 0=wave, 1=rising, 2=falling, 3=flat-low, 4=spike
 * Color theme matches ColorThemeId in theme_colors.h:
 *   0=RED, 1=ORANGE, 2=YELLOW, 3=GREEN, 4=CYAN, 5=BLUE, 6=PURPLE, 7=PINK
 *
 * Each scenario also pins a distinct wall-clock time (see TIMES in
 * scripts/screenshot-sweep.sh) so the screenshot sweep produces a
 * heterogeneous panel of hours, not 5 shots of the same minute.
 *
 * 5 scenarios condense the glucose-zone coverage (in_range, urgent_low,
 * high, urgent_high, stale) while spreading all five slot data types
 * (battery, weather, heart rate, steps, CGM) across all four slot
 * positions A-D. 4 of the 5 put CGM in a slot — those show the widget's
 * distinctive styling (zone color, gray/stale treatment); the remaining
 * one (high) covers the watchface configured without the CGM widget.
 * All use the SIMPLE layout because it renders all four slots (DASHBOARD
 * hides slot D), which is what makes the full slot mix visible.
 */
#ifdef DEMO_DATA
#include "demo.h"

const DemoScenario demo_scenarios[DEMO_SCENARIO_COUNT] = {
  /* name           gluc trend delta  age   wT  wMin wMax wI  HR   steps  layout slots         graph theme dark  time  */
  { "in_range",     120, 3,     2,    180,  10, 4,   15,  0,  88,  1234,  0,     {5,1,2,4},    0,    4,    1 },  // 00:07 cyan/dark   — CGM A, battery, weather, steps
  { "urgent_low",   45,  6,    -15,   60,   12, 6,   16,  0,  72,  3201,  0,     {4,3,5,2},    3,    3,    0 },  // 09:21 green/light  — steps, HR, CGM C, weather
  { "high",         195, 1,     10,   120,  22, 16,  28,  0,  128, 6842,  0,     {2,4,1,3},    1,    2,    1 },  // 20:34 yellow/dark — weather, steps, battery, HR (no CGM)
  { "urgent_high",  270, 0,     18,   60,   19, 12,  24,  0,  110, 8500,  0,     {3,5,1,2},    4,    0,    0 },  // 16:59 red/light    — HR, CGM B, battery, weather
  { "stale",        120, 7,     0,    1800, 15, 9,   17,  4,  64,  4200,  0,     {1,5,3,4},    0,    6,    1 },  // 11:38 purple/dark — battery, CGM B (stale), HR, steps
};

#endif /* DEMO_DATA */
