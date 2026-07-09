# Model -> variant menu selection report - 2026-07-09

## Scope

This report records the menu refactor from a flat car variant list to a two-level car choice:

```text
tryb -> tor -> model auta -> wariant auta
```

Changed runtime/test files:

- `scripts/ui/main_menu.gd`
- `scripts/game/game_manager.gd`
- `scripts/tests/full_program_smoke_test.gd`

Changed documentation:

- `docs/car_catalog.md`
- `README.md`
- `docs/test_reports/2026-07-09-catalog-driven-car-selection.md`
- `docs/test_reports/2026-07-09-model-variant-menu-selection.md`

## Implementation summary

`GameManager` still uses `resources/cars/catalog.tres` as the source of truth for car selection.

`GameManager` now passes catalog-derived model data to `MainMenu`. `MainMenu` does not load the catalog from disk.

The visible menu flow now shows:

```text
Dowolny -> Prosty owal -> Nissan 370Z -> 370Z automat
Dowolny -> Prosty owal -> Nissan 370Z -> 370Z manual
Wyscig -> Prosty owal -> Nissan 370Z -> 370Z automat
```

`MainMenu.selection_completed` now emits `variant_id` instead of a flat car index. `GameManager` maps that `variant_id` back to the matching catalog variant index before calling `CarSpawner`, so catalog lookup remains outside `CarSpawner`.

Current expected variant IDs:

- `370Z automat`: `nissan_370z_7at`
- `370Z manual`: `nissan_370z_6mt`

## Unchanged behavior

This refactor intentionally did not change:

- car physics;
- car tuning values;
- `CarSpecs`;
- gearbox ratios;
- engine tuning;
- AI driving logic;
- lap tracking;
- track generation;
- input mappings;
- mobile controls;
- car scenes.

`switch-car` remains free-drive only. Race mode still spawns AI opponents.

## Smoke test instructions

Run:

```text
C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn
```

Expected result:

```text
[SMOKE] Extended full program smoke test passed: <N> checks
```

## Result

Final validation passed on 2026-07-09:

```text
[SMOKE] Extended full program smoke test passed: 79 checks
```

The test covered:

- `Dowolny -> Prosty owal -> Nissan 370Z -> 370Z automat`;
- `Dowolny -> Prosty owal -> Nissan 370Z -> 370Z manual`;
- `Wyscig -> Prosty owal -> Nissan 370Z -> 370Z automat`;
- automatic selected variant ID `nissan_370z_7at`;
- manual selected variant ID `nissan_370z_6mt`;
- back navigation from variant -> model -> track -> mode;
- free-drive `switch-car`;
- race-mode `switch-car` blocking;
- AI opponent spawn and movement;
- post-race cleanup and free-drive reentry.
