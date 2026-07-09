# Manual Transmission Input Refactor

Date: 2026-07-09

## Scope

- Added gear-up and gear-down pressed state to `CarInput`.
- Moved direct `Input` reads for manual gear changes out of `ManualTransmissionModel`.
- Passed gear input state from `PlayerCarController` to `ManualTransmissionModel`.

## Unchanged Areas

Gameplay, tuning and physics were not changed.

## Smoke Test

`C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`

Result: `[SMOKE] Extended full program smoke test passed: 79 checks`

## Diff Check

`git diff --check`

Result: passed with no output.
