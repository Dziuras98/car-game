# GameManager test actions API

Date: 2026-07-09

## Scope

- Added public diagnostic/test actions to `scripts/game/game_manager.gd`:
  - `request_return_to_main_menu_for_test()`
  - `simulate_current_player_finish_for_test()`
- Updated `scripts/tests/game_test_adapter.gd` so `return_to_main_menu()` and `simulate_player_finish()` call those public methods instead of private `GameManager` methods.
- Kept the existing private `GameManager` methods in place.

## Gameplay impact

- No gameplay, physics, tuning, menu flow, car catalog, AI, track, or smoke test flow changes.
- The new methods only expose the existing return-to-menu and current-player-finish behavior for tests.

## Validation

- Passed: `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`
  - Result: `[SMOKE] Extended full program smoke test passed: 79 checks`
- Passed: `git diff --check`

Note: the smoke test needed to run outside the filesystem sandbox. Sandboxed Godot scene runs crashed natively before the smoke test log; an unsandboxed run completed successfully.
