# Menu Options Builder Refactor

Date: 2026-07-09

## Scope

- Added `scripts/game/menu_options_builder.gd`.
- Added `MenuOptionsBuilder extends RefCounted`.
- Moved menu option construction out of `GameManager`:
  - track options,
  - car model options,
  - fallback car names for the older menu API.
- Removed `GameManager._get_menu_car_models()`.
- Kept `GameManager` responsible for menu wiring and race/gameplay flow.

## Moved Responsibilities

- `MenuOptionsBuilder.build_track_options()` now returns the single track option:
  - `label = "Prosty owal"`
  - `track_id = "simple_oval"`
- `MenuOptionsBuilder.build_car_models(...)` now builds catalog-backed model/variant menu data and falls back to `"Samochody"` / `"Samochod %d"` variants from available scenes.
- `MenuOptionsBuilder.build_fallback_car_names(...)` now builds legacy `set_car_names` values from catalog variants or scene fallback names.

## Behavior

- Visible menu behavior was not changed.
- The menu still shows `"Prosty owal"` for the track.
- The selected track ID remains `"simple_oval"`.
- The car menu still shows `Nissan 370Z -> 370Z automat / 370Z manual`.
- Fallback car names still use `"Samochod %d"`.

## Unchanged Areas

- Gameplay was not changed.
- Physics was not changed.
- Tuning was not changed.
- `CarSpecs` was not changed.
- Car resources and car scenes were not changed.
- AI was not changed.
- Track implementation was not changed.
- Race flow was not changed.
- UI scenes were not changed.
- Smoke test flow was not changed.

## Validation

- `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`
  - Final result: `[SMOKE] Extended full program smoke test passed: 79 checks`
  - Note: `Godot.exe` returned no stdout, and sandboxed console/editor-script attempts either crashed or hit the known `AppData` sandbox issue. The final validation run was repeated outside the sandbox.
- `git diff --check`
  - Passed with no output.
