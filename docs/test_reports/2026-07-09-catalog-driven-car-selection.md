# Catalog-driven car selection report — 2026-07-09

## Scope

This report records the refactor that wires the current menu/game spawning flow to the car catalog data layer.

Changed files:

- `scripts/game/game_manager.gd`
- `scripts/game/car_spawner.gd`
- `scripts/ui/main_menu.gd`
- `scripts/tests/game_test_adapter.gd`
- `resources/cars/nissan/370z/variants/370z_7at.tres`
- `resources/cars/nissan/370z/variants/370z_6mt.tres`
- `docs/car_catalog.md`

## Behavior intended to remain unchanged

This refactor intentionally does not change:

- car physics;
- car tuning values;
- manual or automatic transmission algorithms;
- race flow;
- AI driving logic;
- track generation;
- input mappings;
- visual menu layout;
- existing car button labels.

The menu still shows the existing labels:

- `370Z automat`
- `370Z manual`

## Implementation summary

`GameManager` now uses `resources/cars/catalog.tres` as the primary source of car selection data.

The catalog is flattened into:

- `_available_car_variants`
- `_available_car_scenes`

`MainMenu` now exposes `set_car_names()` so `GameManager` can pass catalog-derived car labels without changing the menu layout or selection signal.

`MainMenu` still emits:

```gdscript
selection_completed(mode_id, track_id, car_index)
```

The selected `car_index` now refers to the flattened catalog variant list.

`CarSpawner` now receives both scenes and variants. If variants are available, it instantiates cars through `CarVariantDefinition`, applies the variant's `CarSpecs` before the car is added to the scene tree, and keeps the old scene array only as a fallback.

Opponent spawning prefers automatic variants when catalog variants are available, so AI does not accidentally receive a manual-transmission variant.

`GameManager` now also stores `selected_car_variant_id` for diagnostics and future save/menu logic.

## Validation status

Post-change validation is still required. Run:

```text
scenes/tests/full_program_smoke_test.tscn
```

Expected result:

```text
[SMOKE] Extended full program smoke test passed: <N> checks
```

Recommended manual spot checks:

- menu still shows `370Z automat` and `370Z manual`;
- selecting `370Z automat` spawns the automatic variant;
- selecting `370Z manual` spawns the manual variant;
- `switch-car` still cycles cars in free-drive mode;
- `switch-car` is still blocked in race mode;
- race opponents spawn and move after countdown;
- return-to-menu still clears the current car and opponents.

## Next recommended work

1. Run the full-program smoke test after this refactor.
2. If it passes, record the successful result in this report.
3. In a separate UI refactor, change the car-selection step from one flat list to model -> variant selection.
