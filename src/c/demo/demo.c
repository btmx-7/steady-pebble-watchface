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
 * Design of the 5-scenario set:
 *   - Exactly ONE scenario (in_range) is fully nominal: every slot shows a
 *     healthy, mid-range value. It's the calm reference shot.
 *   - The other FOUR each exercise edge/alert states, mixed across slots:
 *     battery charging, battery critically low, battery full, weather at
 *     its daily max, weather/HR unavailable ("--"), HR over the high
 *     threshold, steps at zero, and the CGM stale (gray) treatment.
 *   - Exactly 3 of the 5 put CGM in a slot (in_range / urgent_low / stale),
 *     covering the widget's normal, danger-zone, and stale stylings. The
 *     other two (high_alerts / no_data) configure the watchface without
 *     the CGM widget so the rest of the layout is QA'd on its own.
 *   - All five slot data types (battery, weather, heart rate, steps, CGM)
 *     are spread across all four positions A-D.
 *   - battery_pct / battery_charging drive the battery slot (under
 *     DEMO_DATA the live battery service is bypassed, see main.c).
 *   - All use the SIMPLE layout because it renders all four slots
 *     (DASHBOARD hides slot D), which is what makes the slot mix visible.
 */
#ifdef DEMO_DATA
#include "demo.h"

const DemoScenario demo_scenarios[DEMO_SCENARIO_COUNT] = {
  /* name           gluc trend delta  age   wT    wMin  wMax  wI HR   steps  bat chg layout slots       graph theme dark  time/notes */
  { "in_range",     120, 3,     3,    240,  18,   12,   24,   0, 76,  6842,  70, 0,   0,     {5,1,2,4},  0,    4,    1 },  // 00:07 cyan/dark   — nominal: CGM in-range, all slots healthy
  { "urgent_low",   45,  6,    -18,   60,   14,   8,    19,   0, 70,  3120,  28, 1,   0,     {4,3,5,1},  3,    3,    0 },  // 09:21 green/light  — CGM urgent-low + battery charging
  { "high_alerts",  195, 1,     10,   120,  34,   19,   34,   0, 172, 12480, 7,  0,   0,     {2,4,1,3},  1,    2,    1 },  // 20:34 yellow/dark — no CGM; weather at max, battery low, HR high
  { "no_data",      0,   7,     0,    0,   -128, -128, -128,  7, 0,   0,     100,0,   0,     {3,1,4,2},  3,    0,    0 },  // 16:59 red/light    — no CGM; HR & weather "--", steps 0, battery full
  { "stale",        120, 7,     0,    1800, 16,   9,    17,   4, 64,  5200,  45, 0,   0,     {1,5,3,4},  0,    6,    1 },  // 11:38 purple/dark — CGM stale (gray); battery mid
};

#endif /* DEMO_DATA */
