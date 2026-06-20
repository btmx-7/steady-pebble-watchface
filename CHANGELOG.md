# Changelog

All notable changes to Steady, newest first.

## [Unreleased]

## [3.0.1] - 2026-06-20
- Restricted official support to Pebble Time 2 (emery) and Pebble Round 2 (gabbro); other Pebble models are "coming soon" instead of declared as supported.
- Reworked the 8 demo QA screenshot scenarios: varied slot layout, color theme, light/dark mode, and time of day.
- Fixed the CGM widget going stale with no recovery on Android (#18).

## [3.0.0] - 2026-06-20
- Added 8 color themes with light, dark, and automatic (sunrise/sunset) mode.

## [2.1.0] - 2026-06-20
- Added per-threshold vibration type setting, with a live vibe test on the settings page.

## [2.0.3] - 2026-06-19
- Fixed Dexcom trend arrow rendering.

## [2.0.2] - 2026-06-19
- Fixed Dexcom authentication and HealthService diagnostics.

## [2.0.1] - 2026-06-19
- Fixed settings page not reachable from the phone app.

## [2.0.0] and [1.0.0]
Initial releases, predating this changelog. See `git log` for detail.

---

## Template

```md
## [X.Y.Z] - YYYY-MM-DD
- 
```

Patch (x.y.Z+1) for fixes, minor (x.Y+1.0) for new features, major (X+1.0.0) for redesigns. Bump `package.json` version in its own commit after the change lands.
