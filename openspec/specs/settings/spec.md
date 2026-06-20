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

### Requirement: Threshold Alert Vibration

The settings page MUST let the user turn glucose threshold vibration alerts on or off, and independently choose which Pebble OS-native vibration type is used for each of the four thresholds (Low, High, Urgent Low, Urgent High).

#### Scenario: User disables threshold alerts

- **WHEN** the user opens settings
- **THEN** a "Threshold Alerts" toggle is shown, defaulting to on
- **AND** turning it off and saving means the watch no longer vibrates when glucose crosses a low/high or urgent low/high threshold

#### Scenario: User picks a vibration type per threshold

- **WHEN** "Threshold Alerts" is on
- **THEN** a "Vibration Type" section is shown with 4 independent selects — Low, High, Urgent Low, Urgent High
- **AND** each select offers: None; Tap (a brief custom pulse, weaker than Short Pulse, for users who find the OS primitives too strong); Nudge Nudge (two Tap-strength pulses back to back); and the OS-native vibration primitives exposed by the Pebble SDK: Short Pulse, Long Pulse, Double Pulse
- **AND** the saved choice for each threshold determines the haptic pattern fired when glucose crosses that specific threshold, independently of the other thresholds

