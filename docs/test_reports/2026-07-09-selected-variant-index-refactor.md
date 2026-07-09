# Selected Variant Index Refactor

Date: 2026-07-09

## Scope

- Updated `GameManager._get_variant_id_for_current_spawner_index()` to derive the selected variant from `CarSpawner.get_current_car_index()`.
- Removed variant lookup based on `CarSpecs` reference comparison.
- Kept the existing `CarSpawner` API unchanged.

## Unchanged Areas

Gameplay, physics and tuning were not changed. Car catalog, menu, AI, track, input and smoke test files were not changed.

## Smoke Test

`C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`

Result: `[SMOKE] Extended full program smoke test passed: 79 checks`

Note: The same command crashed under the sandbox before validation was repeated outside the sandbox successfully.

## Diff Check

`git diff --check`

Result: passed with no output.
