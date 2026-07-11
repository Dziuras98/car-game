# Lap Position HUD Scene Refactor

Date: 2026-07-09

## Scope

- Added `scenes/ui/lap_position_hud.tscn` with the static lap/position HUD layout:
  - root `CanvasLayer`, `layer = 12`, default `visible = false`
  - fullscreen `Control`
  - top-left `PanelContainer` with the existing offsets
  - existing margins, vertical separation, label font sizes, and default text
- Updated `scripts/ui/lap_position_hud.gd` to instantiate the scene and keep the existing public methods:
  - `build(owner: Node, lap_count: int)`
  - `show()`
  - `hide()`
  - `update(current_lap, total_laps, position, participant_count)`

## Behavior

- Lap/position HUD behavior was not intended to change.
- `RaceHud` still uses `LapPositionHud` through the same external API.
- Gameplay systems were not changed: `GameManager`, `RaceManager`, countdown overlay, results screen, menus, physics, tuning, AI, track generation, inputs, and car scenes were not modified.

## Validation

- Smoke test command:
  - `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`
- Result:
  - `[SMOKE] Extended full program smoke test passed: 79 checks`
- Note:
  - The first sandboxed run crashed in native Godot startup/shutdown code without project test output.
  - The validation run outside the sandbox completed successfully with exit code 0.

## Diff Check

- Command:
  - `git diff --check`
- Result:
  - Passed with no output.
