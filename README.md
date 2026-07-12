# Steady

Your wrist, always in the know.

A clean watchface for Pebble Time 2 and Round 2. Large clock and 4 configurable slots. The CGM widget shows your glucose level naturally, not as the entire identity. People living with diabetes get the data they need in a blended design that looks like any other watchface.

Built for the Pebble Spring 2026 App Contest.

---

## Features

- CGM integration (Nightscout and Dexcom Share supported out of the box)
- 4 configurable widget slots (battery, weather, heart rate, steps, or CGM in any corner)
- 9 color themes, with light, dark, or automatic (sunrise/sunset) mode
- Color-coded glucose zones: urgent low/high (red), low (orange), in range (theme accent color), high (yellow)
- Haptic and visual alerts on urgent glucose zones, with a configurable vibration type per threshold
- Weather via OpenMeteo, no API key required

## Layout

Simple layout. Large 2-row clock in Inter Black with 4 corner widget slots. Clean and glanceable for everyday wear.

## Widget Slots

4 fully configurable corner slots. Each slot can show:

| Slot | Data |
|------|------|
| Battery | Charge percent with arc progress ring |
| Weather | Temperature and condition icon (OpenMeteo) |
| Heart Rate | Live BPM from Pebble Health |
| Steps | Daily step count toward 10k goal |
| CGM | Current glucose with zone color and trend arrow |

## CGM Support

Fetches glucose data from:
- Nightscout (URL and optional access token)
- Dexcom Share (username and password, US and international servers)

Stale data shown in gray. Glucose display in mg/dL or mmol/L.

## Platforms

| Device | Resolution | Shape |
|--------|-----------|-------|
| Pebble Time 2 (emery) | 200x228 | Rectangular |
| Pebble Round 2 (gabbro) | 260x260 | Circular |

Pebble Time (basalt), Pebble 2 (diorite), and Pebble Time Round (chalk) are not
yet designed for. Support is planned for a future release.

## Settings

Configured via the Pebble app settings page:

- 4 widget slot assignments
- CGM data source and credentials
- Glucose display units (mg/dL or mmol/L)
- Graph window (1, 2, or 3 hours)
- Alert thresholds (low, high, urgent low, urgent high), each with its own vibration type
- Color theme (9 options, Cyan is default) and light/dark/auto mode

## Roadmap

### Next release

- Dashboard layout: a glucose-first layout with single-row time, 3 top slots, 3-hour sparkline graph, and a CGM trend/value panel. Designed for active glucose monitoring.

### Future

- Music playback indicator

## License

MIT, see [LICENSE](LICENSE)
