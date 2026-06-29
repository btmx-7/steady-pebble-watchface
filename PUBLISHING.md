# Steady: Pebble App Store Publishing Guide

## Status

Build: ✓ Complete (Steady-watchface.pbw, 154KB)
Screenshots: 5 store use cases per platform (regenerate via `STORE=1 scripts/screenshot-sweep.sh`)
Metadata: ✓ Complete (package.json)
SDK: ⚠ Requires installation

---

## What's Ready

### Build Artifact
- **File**: `build/Steady-watchface.pbw` (154 KB)
- **Platforms**: emery, gabbro, basalt, diorite, chalk (all 5 platforms)
- **Last built**: 2026-04-16 19:09

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

> The legacy `emery_simple_dark.png` / `gabbro_simple_dark.png` (a single
> cyan/dark shot) and the stale `states/` set predate this 5-case scheme;
> remove them once the set above is regenerated.

### Metadata
- **Display Name**: Steady
- **Short Description** (package.json): "A clean watchface for Pebble Time 2 and Round 2. Large clock, 4 configurable slots, 9 color themes, light/dark mode, and a built-in CGM widget. Glucose monitoring that fits in."
- **Long Description** (package.json): Clean watchface framing with CGM as a natural widget, not a medical device identity
- **UUID**: 552fd91e-ad93-4d0f-ae44-74bc9d3108d6 (unchanged)
- **Version**: 1.0.0
- **Target Platforms**: Time 2 (emery), Round 2 (gabbro), Time (basalt), Steel (diorite), Round (chalk)

---

## Prerequisites: Pebble SDK Installation

The `pebble publish` command requires the **Pebble SDK** (v4.x or compatible).

### Check if Installed
```bash
pebble --version
```

If this fails, install the SDK:

### macOS (using Homebrew)
```bash
brew install pebble-sdk
```

### Other Platforms
Download from https://github.com/pebble/pebble-sdk-release or use the official installer.

Once installed, verify:
```bash
pebble --version
```

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
```bash
pebble publish
```

The command will:
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
- ✓ Platform list includes: Time 2, Round 2, Time, Steel, Round
- ✓ Author: "btmx-7"

---

## Submission Details for App Store

### Key Details
| Field | Value |
|-------|-------|
| App Name | Steady |
| Version | 1.0.0 |
| UUID | 552fd91e-ad93-4d0f-ae44-74bc9d3108d6 |
| Category | Health / Utilities |
| Author | btmx-7 |

### Supported Platforms
- Pebble Time 2 (emery) — 200×228 color e-paper
- Pebble Round 2 (gabbro) — 260×260 circular color e-paper
- Pebble Time (basalt) — 144×168 color
- Pebble Steel (diorite) — 144×168 rectangular
- Pebble Round (chalk) — 180×180 circular

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
Check that these files exist, are valid PNG, and keep their `<platform>_`
filename prefix (publish maps screenshots to platforms by that prefix):
- `resources/screenshots/emery_simple_dark.png` (Time 2)
- `resources/screenshots/gabbro_simple_dark.png` (Round 2)

---

## Next Steps (Post-Publishing)

1. Share app link in Pebble community forums
2. Update personal Pebble app store listing with release notes
3. Monitor community feedback for bug reports
4. Plan v2.1 with deferred features: light mode, color themes, audio indicator

---

## Reference

- **Pebble SDK Docs**: https://pebble.github.io/
- **rePebble App Store**: https://apps.repebble.com/
- **Package Manifest**: `package.json` (sdkVersion: 3, all metadata)
- **App UUID**: 552fd91e-ad93-4d0f-ae44-74bc9d3108d6
