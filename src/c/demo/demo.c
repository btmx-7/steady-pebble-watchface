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
 * heterogeneous panel of hours, not 8 shots of the same minute.
 */
#ifdef DEMO_DATA
#include "demo.h"

const DemoScenario demo_scenarios[DEMO_SCENARIO_COUNT] = {
  /* name           gluc trend delta  age   wT  wMin wMax wI  HR   steps  layout slots         graph theme dark  time  */
  { "urgent_low",   45,  6,    -15,   60,   10, 4,   15,  0,  88,  1234,  0,     {5,1,2,4},    2,    0,    1 },  // 06:42 red/dark
  { "low",          65,  5,    -8,    120,  10, 4,   15,  0,  72,  3201,  0,     {1,4,5,2},    2,    1,    0 },  // 09:15 orange/light
  { "in_range",     120, 3,     2,    180,  10, 4,   15,  0,  128, 6842,  0,     {4,2,1,5},    0,    2,    1 },  // 12:08 yellow/dark
  { "high",         195, 1,     10,   120,  22, 16,  28,  0,  95,  8500,  0,     {2,5,4,1},    1,    3,    0 },  // 14:53 green/light
  { "urgent_high",  270, 0,     18,   60,   22, 16,  28,  0,  110, 12034, 0,     {4,1,5,2},    1,    4,    1 },  // 17:27 cyan/dark
  { "stale",        120, 7,     0,    1800, 10, 4,   15,  0,  0,   0,     0,     {3,5,1,2},    3,    5,    0 },  // 20:36 blue/light
  { "dashboard",    142, 3,     3,    180,  12, 6,   18,  0,  78,  6842,  1,     {2,1,4,0},    0,    6,    1 },  // 22:14 purple/dark
  { "zero_state",   0,   7,     0,    0,    -128,-128,-128,7, 0,   0,     0,     {0,0,0,0},    3,    7,    0 },  // 00:05 pink/light
};

#endif /* DEMO_DATA */
