# Changelog

All notable changes to Steady, newest first.

## [Unreleased]
- New: configurable CGM refresh interval (1, 2, or 5 minutes) on the settings page. Set it to 1 minute to sync glucose updates with sources like Juggluco.

## [3.0.1] - 2026-06-20
- Improved: restricted official support to Pebble Time 2 (emery) and Pebble Round 2 (gabbro); other Pebble models are "coming soon" instead of declared as supported.
- Improved: reworked the 8 demo QA screenshot scenarios: varied slot layout, color theme, light/dark mode, and time of day.
- Fix: CGM widget going stale with no recovery on Android.

## [3.0.0] - 2026-06-20
- New: 8 color themes with light, dark, and automatic (sunrise/sunset) mode.

## [2.1.0] - 2026-06-20
- New: per-threshold vibration type setting, with a live vibe test on the settings page.

## [2.0.3] - 2026-06-19
- Fix: Dexcom trend arrow rendering.

## [2.0.2] - 2026-06-19
- Fix: Dexcom authentication and HealthService diagnostics.

## [2.0.1] - 2026-06-19
- Fix: settings page not reachable from the phone app.

## [2.0.0] and [1.0.0]
Initial releases, predating this changelog. See `git log` for detail.

---

## Template

```md
## [X.Y.Z] - YYYY-MM-DD
- New: 
- Improved: 
- Fix: 
```

Patch (x.y.Z+1) for fixes, minor (x.Y+1.0) for new features, major (X+1.0.0) for redesigns. Prefix each bullet with `New:`, `Improved:`, or `Fix:`. No PR or issue references. Bump `package.json` version in its own commit after the change lands.
