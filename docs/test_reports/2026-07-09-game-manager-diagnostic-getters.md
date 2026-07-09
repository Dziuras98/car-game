# GameManager diagnostic getters

Date: 2026-07-09

## Scope

- Added read-only diagnostic getters to `scripts/game/game_manager.gd` for current car, opponents, configured opponent count, selected mode, selected track, and selected car variant.
- Updated `scripts/tests/game_test_adapter.gd` to read that state through the new public methods instead of `_main.get(...)`.

## Gameplay impact

- No gameplay, physics, tuning, menu, car catalog, AI, track, or smoke test flow changes.
- The new methods only return existing `GameManager` state and have no side effects.

## Validation

- Passed: `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`
  - Result: `[SMOKE] Extended full program smoke test passed: 79 checks`
- Passed: `git diff --check`
