# UI Scene-Driven Baseline

Date: 2026-07-09

## Scope

Documentation-only baseline update after the race/menu UI scene-driven refactors.

The following UI surfaces are now scene-driven:

- `MainMenu` through `scenes/ui/main_menu.tscn`
- `CountdownOverlay` through `scenes/ui/countdown_overlay.tscn`
- `LapPositionHud` through `scenes/ui/lap_position_hud.tscn`
- `ResultsScreen` through `scenes/ui/results_screen.tscn`

The scripts still own control flow, signal wiring, visibility updates and runtime-generated content where needed. Dynamic option buttons and result rows remain script-created because they depend on current menu/catalog/result data.

## Validation

- Full-program smoke test baseline: `[SMOKE] Extended full program smoke test passed: 79 checks`
- This commit is documentation-only.
- No gameplay code, scenes, car assets, physics, tuning, AI, track generation, input map or mobile controls were changed.
