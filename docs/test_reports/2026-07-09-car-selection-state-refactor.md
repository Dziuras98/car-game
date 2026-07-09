# Car Selection State Refactor

Date: 2026-07-09

## Scope

- Added `scripts/game/car_selection_state.gd`.
- Updated `scripts/game/game_manager.gd` to use `CarSelectionState`.
- Left `scripts/game/menu_options_builder.gd` unchanged because its existing API already accepts prepared car scene and variant lists.

## Moved Responsibilities

- `CarSelectionState` now owns the available car variant list and available car scene list.
- `CarSelectionState` configures those lists from `CarCatalog` and falls back to exported scenes when the catalog has no scenes.
- `CarSelectionState` now resolves available car count, valid car indices, variant IDs for menu selections, and fallback variant IDs for spawner indices.
- Missing catalog `variant_id` lookup still emits a warning and falls back to index `0`.

## GameManager Integration

- `GameManager` creates and configures `_car_selection_state` in `_ready()` before menu and spawner setup.
- `GameManager` delegates car selection state and index resolution to `CarSelectionState`.
- `CarSpawner.configure(...)` now receives car scenes and variants from `CarSelectionState`.
- Menu car option setup now reads the prepared car scenes and variants from `CarSelectionState`.

## Visible Behavior

- Menu behavior is unchanged: `Nissan 370Z` still exposes `370Z automat` and `370Z manual`.
- Automatic and manual variant selection still works.
- `switch-car` still works in free drive and remains blocked in race flow.
- Catalog-free fallback behavior remains in `CarSelectionState`.

## Unchanged Areas

- Gameplay, physics, tuning, `CarSpecs`, car resources, car scenes, AI, track generation, race flow, UI scenes, and smoke test code were not changed.

## Validation

- Smoke test command:
  `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`
- Result:
  `[SMOKE] Extended full program smoke test passed: 79 checks`
- `git diff --check`:
  passed with no output.

## Notes

- An initial sandboxed Godot run crashed before producing a smoke-test verdict.
- The successful smoke test was run outside the sandbox with the same command.
- Godot did not create `scripts/game/car_selection_state.gd.uid` during validation.
