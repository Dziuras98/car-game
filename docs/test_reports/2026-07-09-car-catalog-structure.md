# Car catalog structure report — 2026-07-09

## Scope

This report records the introduction of a model/variant/catalog car data layer.

Changed files:

- `scripts/car/car_catalog.gd`
- `scripts/car/car_model_definition.gd`
- `scripts/car/car_variant_definition.gd`
- `resources/cars/catalog.tres`
- `resources/cars/nissan/370z/model.tres`
- `resources/cars/nissan/370z/variants/370z_7at.tres`
- `resources/cars/nissan/370z/variants/370z_6mt.tres`
- `resources/cars/nissan/370z/specs/370z_7at_specs.tres`
- `resources/cars/nissan/370z/specs/370z_6mt_specs.tres`
- `docs/car_catalog.md`
- `README.md`

## Design goal

The data model now treats a car model and a playable car as separate concepts.

A car model contains multiple variants:

```text
CarCatalog
  CarModelDefinition
    CarVariantDefinition
      CarSpecs
```

This supports future cars where every model can have many selectable versions with different:

- engines;
- transmissions;
- drivetrain layouts;
- masses;
- tire/steering tuning;
- scene files, if visual differences require it.

## Current 370Z structure

Current catalog root:

```text
resources/cars/catalog.tres
```

Current model:

```text
resources/cars/nissan/370z/model.tres
```

Current variants:

```text
resources/cars/nissan/370z/variants/370z_7at.tres
resources/cars/nissan/370z/variants/370z_6mt.tres
```

Current specs:

```text
resources/cars/nissan/370z/specs/370z_7at_specs.tres
resources/cars/nissan/370z/specs/370z_6mt_specs.tres
```

## Integration status

The data layer exists and the 370Z data is represented in the catalog.

The existing runtime flow still uses the flat `available_cars` array in `scenes/main.tscn`. This is intentional. The menu and `GameManager` should be wired to the catalog in a separate refactor to avoid mixing data structure work with UI/game-flow changes.

## Behavior intended to remain unchanged

This refactor intentionally does not change:

- car physics;
- current 370Z scene behavior;
- menu behavior;
- spawn behavior;
- race behavior;
- AI behavior;
- input mapping;
- smoke-test flow.

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

- project opens without missing Resource errors;
- automatic and manual 370Z scenes still instantiate;
- both 370Z variants still work from the current flat menu;
- catalog Resources can be opened in the inspector;
- `resources/cars/catalog.tres` contains the Nissan 370Z model;
- `resources/cars/nissan/370z/model.tres` contains both 370Z variants.

## Next recommended work

1. Run the full-program smoke test after this structure change.
2. If it passes, record the successful result in this report.
3. In a separate refactor, make the menu read `CarCatalog` and display model -> variant choices.
