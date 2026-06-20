/**
 * Color theme system — generated from Figma design tokens.
 * Source: resources/tokens/color-semantic-{light,dark}/{hue}.tokens.json
 *
 * Each ColorThemeId picks a hue (Figma "mode"); dark/light picks the
 * light/dark semantic collection. Regenerate by re-reading the token
 * JSON if the Figma file's semantic colors change.
 */

#pragma once

#include <pebble.h>

typedef enum {
  COLOR_THEME_RED = 0,
  COLOR_THEME_ORANGE,
  COLOR_THEME_YELLOW,
  COLOR_THEME_GREEN,
  COLOR_THEME_CYAN,
  COLOR_THEME_BLUE,
  COLOR_THEME_PURPLE,
  COLOR_THEME_PINK,
  COLOR_THEME_COUNT
} ColorThemeId;

typedef struct {
  GColor bg;             // surface/background/core
  GColor bg_inverted;     // surface/background/inverted
  GColor text_default;    // text/default
  GColor text_subtle;     // text/subtle
  GColor text_inverted;   // text/inverted
  GColor icon_default;    // icon/default
  GColor icon_subtle;     // icon/subtle
  GColor border_subtle;   // surface/border/subtle
  GColor state_positive;  // state/positive
  GColor state_warning;   // state/warning
  GColor state_danger;    // state/danger
  GColor state_inactive;  // state/inactive
  GColor state_disabled;  // state/disabled
} ThemeColors;

extern const ThemeColors k_theme_dark[COLOR_THEME_COUNT];
extern const ThemeColors k_theme_light[COLOR_THEME_COUNT];

// Returns the resolved palette for (id, dark/light), falling back to
// the original default (cyan/dark) for an out-of-range id.
static inline const ThemeColors *theme_get(ColorThemeId id, bool dark) {
  if (id < 0 || id >= COLOR_THEME_COUNT) id = COLOR_THEME_CYAN;
  return dark ? &k_theme_dark[id] : &k_theme_light[id];
}
