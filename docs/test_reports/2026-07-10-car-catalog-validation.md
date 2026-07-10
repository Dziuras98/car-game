# Car catalog validation test — 2026-07-10

## Environment

Reported test environment:

- Godot Engine v4.7.stable.official.5b4e0cb0f
- Vulkan 1.3.284
- Forward Mobile renderer
- Qualcomm Adreno 830 GPU

## Test scene

```text
scenes/tests/car_catalog_validation_test.tscn
```

## Result

Passed.

The scene reported:

```text
[CAR_CATALOG_VALIDATION_TEST] Passed: 110 checks
```

## Covered checks

The reported run passed these validation points:

- root catalog resource loads;
- catalog exposes at least one car model;
- catalog model entries are valid `CarModelDefinition` resources;
- model IDs are non-empty and unique;
- model display/menu names are non-empty;
- model production-year range is coherent;
- model exposes valid variants;
- model variant count matches `get_variants()`;
- every model has exactly one default variant;
- model resolves valid, negative and out-of-range variant indexes correctly;
- variant IDs are non-empty and globally unique;
- variant `sort_order` values are unique inside the model;
- variants have non-empty menu names;
- variants have car scenes;
- variants have `CarSpecs`;
- variants have engine, transmission and drivetrain labels;
- variants have positive metadata mass;
- variant scenes instantiate with `PlayerCarController` on the root node;
- variant specs have display names;
- variant specs have coherent speed, braking, steering, RPM, drivetrain, mass, grip, skid-mark, gravity and floor-stick values;
- every forward gear ratio is positive;
- catalog returns every validated model variant;
- catalog scene and menu-name lists contain one entry per variant;
- catalog resolves every variant ID and model ID used in the data.

## Notes

This validates the scene-runnable catalog gate added before removing duplicated scene override tuning. It should be run after adding or editing car models, variants, scenes or `CarSpecs` resources.
