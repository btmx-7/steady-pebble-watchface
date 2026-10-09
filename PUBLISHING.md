# Steady: Pebble App Store Publishing Guide

## Status

Version: 3.2.3 (see `package.json` and `CHANGELOG.md`)
Platforms: Time 2 (emery) and Round 2 (gabbro)
Screenshots: 5 store use cases per platform. Regenerate them with `STORE=1 scripts/screenshot-sweep.sh` after any visual change (the files in the repo predate the 3.2.3 font change).

Before every publish, run the checklist in "Pre-flight checklist" below.

---

## Pre-flight checklist

1. `package.json` `version` matches the top entry of `CHANGELOG.md`.
2. Shell has no `CC`, `CXX`, `LDFLAGS` or `CPPFLAGS` exports. Check with `env | grep -E '^(CC|CXX|LDFLAGS|CPPFLAGS)='`. If any print, run `unset CC CXX LDFLAGS CPPFLAGS`. A set `CC` overrides the ARM cross-compiler and `pebble build` fails with "Could not find gcc/g++ (only Clang)".
3. Screenshots are regenerated for the current UI (see below), then **rebuild a release PBW**: `pebble clean && pebble build`. The screenshot sweep leaves a `DEMO_DATA=1` build in `build/`. Never publish that file, it contains fake glucose data.
4. `pebble login --status` shows you are logged in.

---

## What's Ready

### Build Artifact
- **File**: `build/Steady-watchface.pbw` (rebuild with `pebble clean && pebble build`)
- **Platforms**: emery, gabbro (`targetPlatforms` in `package.json`)

### Screenshots (in `resources/screenshots/`)

The store set is the 5 demo use cases, captured per platform (200×228 for
Time 2 / emery, 260×260 for Round 2 / gabbro):

| File suffix | Use case | Theme / mode |
|-------------|----------|--------------|
| `_in_range`    | nominal, CGM in range        | cyan / dark   |
| `_urgent_low`  | CGM urgent-low + charging    | green / light |
| `_high_alerts` | weather max, low batt, HR hi | yellow / dark |
| `_no_data`     | HR & weather "--", full batt | red / light   |
| `_stale`       | CGM stale (gray)             | purple / dark |

So 10 files: `emery_in_range.png … emery_stale.png` and
`gabbro_in_range.png … gabbro_stale.png`.

**Generate them** (needs the Pebble SDK + emulator; one command per platform):
```bash
STORE=1 ./scripts/screenshot-sweep.sh                 # emery → resources/screenshots/emery_*.png
STORE=1 PLATFORM=gabbro ./scripts/screenshot-sweep.sh # gabbro → resources/screenshots/gabbro_*.png
```

> **Filename prefix matters.** `pebble publish` infers each screenshot's
> platform from the part of the filename **before the first underscore**
> (`emery_…` → Time 2, `gabbro_…` → Round 2). Files must be named
> `<platform>_<anything>.png`. The old `screenshot_T2_…` / `screenshot_R2_…`
> names had the prefix `screenshot`, which matches no platform, so publish
> could not map them and the wrong shot showed for a given watch.

> The files currently committed in `resources/screenshots/` are numbered
> (`emery_0_in_range.png … emery_4_stale.png`, same for gabbro). That is the
> output of the sweep **without** `STORE=1`, and it was captured before the
> 3.2.3 font change (bigger day and month). Do not pass those names to
> `pebble publish`. Regenerate with `STORE=1` (names without the index), check a
> couple of images, then commit them and delete the numbered copies. The
> `states/` folder is an older set that publish does not use.
>
> The sweep builds with `DEMO_DATA=1` and does not restore a release build.
> Run `pebble clean && pebble build` afterwards, before `pebble publish`.

### Metadata
- **Display Name**: Steady
- **Short Description** (package.json): "A clean watchface for Pebble Time 2 and Round 2. Large clock, 4 configurable slots, 9 color themes, light/dark mode, and a built-in CGM widget. Glucose monitoring that fits in."
- **Long Description** (package.json): Clean watchface framing with CGM as a natural widget, not a medical device identity
- **UUID**: 552fd91e-ad93-4d0f-ae44-74bc9d3108d6 (unchanged)
- **Version**: 3.2.3 (from `package.json`)
- **Target Platforms**: Time 2 (emery), Round 2 (gabbro). Pebble Time, Steel and Round are not declared in `targetPlatforms` yet.

---

## Prerequisites: Pebble SDK Installation

The `pebble publish` command needs `pebble-tool` and an installed SDK. This
guide was last checked with pebble-tool 5.0.40 and SDK 4.9.169.

### Check if Installed
```bash
pebble --version
pebble sdk list
```

If `pebble` is missing, install the tool, then an SDK:
```bash
uv tool install pebble-tool
pebble sdk install latest
```

Update the tool with `uv tool upgrade pebble-tool`. On macOS this compiles
`gevent`, so it needs the Xcode Command Line Tools (`xcode-select --install`)
and a shell without `CC`/`CXX`/`LDFLAGS`/`CPPFLAGS` exports (see the
pre-flight checklist).

Run `pebble publish --help` to see the options your installed version
supports; they can change between releases.

---

## Publishing Workflow

### Step 1: Authenticate with Pebble Account
```bash
cd /path/to/Steady-watchface
pebble login
```

This opens a browser window for Firebase OAuth. You'll need a Pebble account (or create one).

Verify login status:
```bash
pebble login --status
```

### Step 2: Publish to App Store
Publishing is visible to everyone. Finish the pre-flight checklist first, in
particular the release rebuild, so `build/Steady-watchface.pbw` is not the
demo build.

A bare `pebble publish` works but auto-captures a single screenshot per
platform. Use the full command with `--screenshots` shown below for the store
set. The command will:
1. Read metadata from `package.json`
2. Read the built PBW from `build/Steady-watchface.pbw`
3. Collect screenshots — either auto-captured from the emulator, or passed
   explicitly with `--screenshots`. Each screenshot's platform is inferred
   from its filename prefix (`emery_…`, `gabbro_…`); `--screenshots` files
   whose prefix is not a platform are **rejected with an error**, so always
   pass the prefixed files.

   > ⚠️ **Auto-capture does NOT produce the 5 use cases.** It captures only
   > whatever the watchface is *currently showing* — one shot per platform,
   > from the release PBW (no `DEMO_DATA`). It cannot cycle the demo
   > scenarios. To ship the cyan/green/yellow/red/purple set, generate them
   > first with `STORE=1 ./scripts/screenshot-sweep.sh` (+ `PLATFORM=gabbro`)
   > and pass all 10 explicitly:

   ```bash
   pebble publish --screenshots \
     resources/screenshots/emery_in_range.png \
     resources/screenshots/emery_urgent_low.png \
     resources/screenshots/emery_high_alerts.png \
     resources/screenshots/emery_no_data.png \
     resources/screenshots/emery_stale.png \
     resources/screenshots/gabbro_in_range.png \
     resources/screenshots/gabbro_urgent_low.png \
     resources/screenshots/gabbro_high_alerts.png \
     resources/screenshots/gabbro_no_data.png \
     resources/screenshots/gabbro_stale.png
   ```
   (Each platform takes up to 5 screenshots; the order above sets display order.)
4. Upload PBW + per-platform screenshots + metadata to the App Store

> Screenshots can also be added/curated per platform afterwards via
> **Manage Asset Collections** in the developer portal (one collection per
> supported platform, up to 5 screenshots each).

Expected output:
```
Uploading app...
[... progress ...]
App published successfully!
UUID: 552fd91e-ad93-4d0f-ae44-74bc9d3108d6
View at: https://apps.repebble.com/applications/552fd91e-ad93-4d0f-ae44-74bc9d3108d6
```

### Step 3: Verify Listing
Visit the returned URL (or check https://apps.repebble.com) and confirm:
- ✓ App name: "Steady"
- ✓ Screenshots display correctly **and** match the connected platform (Time 2 shows `emery_*`, Round 2 shows `gabbro_*`)
- ✓ Short description visible
- ✓ Long description complete
- ✓ Platform list includes: Time 2, Round 2 (and no other models)
- ✓ Version shows 3.2.3 and the screenshots show the bigger day and month text
- ✓ Install the published face once on a watch or emulator and confirm it shows no demo data
- ✓ Author: "btmx-7"

---

## Submission Details for App Store

### Key Details
| Field | Value |
|-------|-------|
| App Name | Steady |
| Version | 3.2.3 |
| UUID | 552fd91e-ad93-4d0f-ae44-74bc9d3108d6 |
| Category | Health / Utilities |
| Author | btmx-7 |

### Supported Platforms
- Pebble Time 2 (emery) — 200×228 color e-paper
- Pebble Round 2 (gabbro) — 260×260 circular color e-paper

Pebble Time (basalt), Pebble 2 (diorite) and Pebble Time Round (chalk) are not
declared in `targetPlatforms` and not officially supported yet.

### Feature Summary
- Clean watchface design. Large clock and 4 configurable widget slots.
- Built-in CGM widget. Glucose stays visible alongside other data. It does not dominate the face.
- Each slot is assignable to one of the following:
  - Battery
  - Weather
  - Heart rate
  - Steps
  - Glucose
- Color-coded glucose zones:
  - Urgent low/high: red
  - Low: orange
  - In range: accent color
  - High: yellow
- Haptic and visual alerts on urgent zones
- CGM sources: Nightscout and Dexcom Share
- Weather via OpenMeteo. No API key required.
- Quick View (compact mode) support on all platforms

---

## After Publishing

### Immediate
The app becomes available in the Pebble App Store within minutes. Users can install via their Pebble phone app.

### Visibility
- Listed under Health category
- Searchable by "Steady", "CGM", "glucose", "diabetes", "weather"
- Visible in rePebble app store (https://apps.repebble.com)

### Contest (April 2-19, 2026)
This app qualifies for the Pebble Spring 2026 Contest:
- Team Judging categories: Creativity, Cleverness, New Platform Use, Design
- Both new platforms represented (T2 and R2)
- Quick View support included
- Visual polish demonstrated

---

## Troubleshooting

### "pebble: command not found"
→ Install Pebble SDK (see Prerequisites section)

### "not logged in" error
```bash
pebble login
```

### "PBW file not found" error
Ensure `build/Steady-watchface.pbw` exists:
```bash
ls -lh build/Steady-watchface.pbw
```

If missing, rebuild:
```bash
pebble build
```

### Screenshots not uploading, or wrong screenshot shown for a platform
Check that the 10 files from Step 2 exist (`ls resources/screenshots/`), are
valid PNG, and keep their `<platform>_` filename prefix (publish maps
screenshots to platforms by that prefix). If you only see numbered names like
`emery_0_in_range.png`, you ran the sweep without `STORE=1`; run it again with
`STORE=1`.

### "Could not find gcc/g++ (only Clang)" during `pebble build`
A `CC` (usually `CC=clang`) exported in your shell overrides the ARM
cross-compiler. Run `unset CC CXX LDFLAGS CPPFLAGS` and build again. Remove the
export from your shell config (`~/.zshrc`, `~/.zprofile`, or a mise config) so
it does not come back.

### `uv tool upgrade pebble-tool` fails with "C compiler cannot create executables"
Same cause as above (`CC`/`LDFLAGS` exports), or broken Command Line Tools. Run
`env -u CC -u CXX -u LDFLAGS -u CPPFLAGS uv tool upgrade pebble-tool`. If it
still fails, run `xcode-select --install`.

### `pebble install` says "App install succeeded" after a failed build
`pebble install` reuses the last PBW in `build/`. Make sure `pebble build`
finished successfully before you trust an install.

---

## Next Steps (Post-Publishing)

1. Share app link in Pebble community forums
2. Update personal Pebble app store listing with release notes (copy the newest section of `CHANGELOG.md`)
3. Monitor community feedback for bug reports
4. Commit regenerated screenshots, so the repo matches what the store shows

---

## Reference

- **Pebble SDK Docs**: https://pebble.github.io/
- **rePebble App Store**: https://apps.repebble.com/
- **Package Manifest**: `package.json` (sdkVersion: 3, all metadata)
- **App UUID**: 552fd91e-ad93-4d0f-ae44-74bc9d3108d6
