# settings Specification

## Purpose
TBD - created by archiving change fix-simple-gaps. Update Purpose after archive.
## Requirements
### Requirement: Graph Window Setting

The settings page MUST expose a Graph Window selector so the user can choose how many hours of glucose history the graph displays.

#### Scenario: User selects graph window

- **WHEN** the user opens settings
- **THEN** a "Graph Window" select shows options: 1 hour (13 points), 2 hours (25 points), 3 hours (37 points)
- **AND** the current value is pre-selected

#### Scenario: Graph window saved and applied

- **WHEN** the user saves settings with "2 hours" selected
- **THEN** `settings.graphWindow` is "25"
- **AND** the next Nightscout fetch requests `count=25`

### Requirement: CGM Refresh Interval Setting

The settings page MUST expose a Refresh Interval selector so the user can choose how often the phone fetches new glucose data.

#### Scenario: User selects refresh interval

- **WHEN** the user opens settings
- **THEN** a "Refresh Interval" select shows options: every 1 minute, every 2 minutes, every 5 minutes
- **AND** the current value is pre-selected

#### Scenario: Refresh interval saved and applied

- **WHEN** the user saves settings with "every 1 minute" selected
- **THEN** `settings.refreshInterval` is "1"
- **AND** the CGM polling timer is rescheduled to fetch once per minute without restarting the companion JS

### Requirement: Threshold Alert Vibration

The settings page MUST let the user turn glucose threshold vibration alerts on or off, and independently choose which Pebble OS-native vibration type is used for each of the four thresholds (Low, High, Urgent Low, Urgent High).

#### Scenario: User disables threshold alerts

- **WHEN** the user opens settings
- **THEN** a "Threshold Alerts" toggle is shown, defaulting to on
- **AND** turning it off and saving means the watch no longer vibrates when glucose crosses a low/high or urgent low/high threshold

#### Scenario: User picks a vibration type per threshold

- **WHEN** the user opens settings
- **THEN** the Low, High, Urgent Low, and Urgent High threshold fields each show their numeric mg/dL value followed directly by their own "Vibration" select, within the same field block
- **AND** each select offers: None; Tap (a brief custom pulse, weaker than Short Pulse, for users who find the OS primitives too strong); Nudge Nudge (two Tap-strength pulses back to back); and the OS-native vibration primitives exposed by the Pebble SDK: Short Pulse, Long Pulse, Double Pulse
- **AND** the saved choice for each threshold determines the haptic pattern fired when glucose crosses that specific threshold, independently of the other thresholds

#### Scenario: Vibration pickers hide when alerts are off

- **WHEN** "Threshold Alerts" is off
- **THEN** the 4 vibration selects are hidden while the threshold value inputs remain visible and editable

#### Scenario: User test-fires a vibration type before saving

- **WHEN** the user changes any of the 4 vibration selects
- **THEN** the settings page sends a `KEY_TEST_VIBE` AppMessage (independent of the Save flow) carrying the newly selected vibe type
- **AND** the watch fires that vibe type immediately without persisting it or touching any other setting
- **AND** if the page is opened outside the Pebble app's webview (no `Pebble.sendAppMessage` available), the picker still works for selecting a value to save, it just doesn't test-fire

