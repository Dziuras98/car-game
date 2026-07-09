# Main menu scene refactor test report

Date: 2026-07-09

## Scope

- Moved the static `MainMenu` UI layout from `scripts/ui/main_menu.gd` into `scenes/ui/main_menu.tscn`.
- Kept dynamic option button creation in `Options`, because menu entries still depend on the current step and supplied car model data.
- Preserved the menu behavior target: mode -> track -> model -> variant.
- Preserved the back navigation target: variant -> model, model -> track, track -> mode.
- Preserved the public API: `set_car_models(...)`, `reset_menu()`, and `selection_completed(...)`.

## Unchanged Areas

The refactor was intended to leave menu behavior unchanged. Physics, tuning, AI, track generation, input map, mobile controls, car scenes, `GameManager`, `CarSpawner`, `CarCatalog`, and `CarSpecs` were not changed.

## Validation

- Smoke test: passed with `[SMOKE] Extended full program smoke test passed: 79 checks`.
- `git diff --check`: passed with no output.
