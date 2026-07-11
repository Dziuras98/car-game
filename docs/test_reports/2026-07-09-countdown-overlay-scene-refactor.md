# Countdown Overlay Scene Refactor

Date: 2026-07-09

## Scope

- Added `scenes/ui/countdown_overlay.tscn` with the static countdown overlay layout:
  - root `CanvasLayer`, `layer = 20`, default `visible = false`
  - fullscreen `Control`
  - fullscreen `CenterContainer`
  - centered `Label`
- Updated `scripts/ui/countdown_overlay.gd` to instantiate the scene and keep the existing public methods:
  - `build(owner: Node)`
  - `show(text: String)`
  - `hide()`

## Behavior

- Countdown behavior was not intended to change.
- `RaceHud` still uses `CountdownOverlay` through the same external API.
- Physics, tuning, AI, track generation, menu behavior, input map, car scenes, lap HUD, results screen, `GameManager`, and `RaceManager` were not changed.

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
