# Track Options Menu Refactor

Date: 2026-07-09

## Scope

- Added `MainMenu.set_track_options(next_track_options: Array[Dictionary])`.
- Added `_track_options: Array[Dictionary]` in `MainMenu`.
- Updated the track selection step to render options from `_track_options`.
- Kept `track_names` compatibility through a fallback option builder.
- Added minimal `GameManager` wiring for one track option:
  - `label = "Prosty owal"`
  - `track_id = "simple_oval"`

## Gameplay Impact

- No physics changes.
- No tuning changes.
- No car catalog or car scene changes.
- No AI changes.
- No track scene changes.
- No race flow changes.
- Visible behavior remains unchanged: the menu still shows one track, `"Prosty owal"`, with selected ID `"simple_oval"`.

## Validation

- `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --version`
  - Passed: `4.7.stable.official.5b4e0cb0f`
- `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --path . --scene res://scenes/tests/full_program_smoke_test.tscn`
  - Sandbox run crashed in native Godot before test output.
  - Re-run outside the sandbox passed.
  - Result: `[SMOKE] Extended full program smoke test passed: 79 checks`
  - Note: the passing run emitted existing `follow_camera.gd` shutdown `!is_inside_tree()` errors after the PASS line, but exited with code 0.
- `git diff --check`
  - Passed.
