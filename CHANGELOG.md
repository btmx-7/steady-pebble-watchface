# Changelog

All notable changes to Steady are documented here. Format is loosely based on
[Keep a Changelog](https://keepachangelog.com/), versioned per
[SemVer](https://semver.org/).

History before 3.0.1 is backfilled from git log for reference; entries from
3.0.1 onward are written at release time.

## [Unreleased]

### Added

### Changed

### Fixed

## [3.0.1] - 2026-06-20

### Changed

- Restricted `targetPlatforms` to Pebble Time 2 (emery) and Pebble Round 2
  (gabbro) only. Pebble Time, Pebble 2, and Pebble Time Round are not yet
  designed for and are now called out as "coming soon" in the store
  description and README instead of being declared as supported.
- Reworked the 8 `DEMO_DATA` QA screenshot scenarios: CGM's slot position now
  rotates across the grid, Steps appears in most scenarios (previously
  unused), only 3 of 8 scenarios show the CGM widget (the rest exercise the
  watchface configured without it), and each scenario pins a distinct color
  theme, light/dark mode, and time of day for a heterogeneous screenshot set.

### Fixed

- CGM widget could go stale with no recovery: Android's background execution
  limits could suspend the phone-side poll loop indefinitely. The watch now
  asks the phone to refresh when its data goes stale, and a failed/expired
  Dexcom session now forces a clean re-login instead of getting stuck (#18).

## [3.0.0] - 2026-06-20

### Added

- 8 color themes with light, dark, and automatic (sunrise/sunset) mode.

## [2.1.0] - 2026-06-20

### Added

- Per-threshold vibration type setting (low, high, urgent low, urgent high),
  with a live vibe test on the settings page.

## [2.0.3] - 2026-06-19

### Fixed

- Dexcom trend arrow rendering.

## [2.0.2] - 2026-06-19

### Fixed

- Dexcom authentication and HealthService diagnostics.

## [2.0.1] - 2026-06-19

### Fixed

- Settings page wasn't reachable from the phone app; declared the
  `configurable` capability so it is.

## [2.0.0] and [1.0.0]

Initial releases, predating this changelog. See `git log` for detail.

---

## Template for new entries

When starting work on a release, copy this block under `## [Unreleased]`,
fill it in as changes land, then rename the heading to the version + date
when you bump:

```md
## [X.Y.Z] - YYYY-MM-DD

### Added

-

### Changed

-

### Fixed

-
```

Drop any section with no entries (don't ship an empty `### Added`).

### Version bump convention

- **PATCH** (x.y.Z+1): bug fixes, metadata/description changes, QA-only or
  non-functional changes.
- **MINOR** (x.Y+1.0): a self-contained new feature that doesn't change the
  watchface's core design.
- **MAJOR** (X+1.0.0): a large feature or visual redesign (new layout, new
  theming system, etc.).

Bump the version in `package.json` as its own commit, after the feature/fix
commits land, with a message like `bump version to X.Y.Z for <short summary>`.
