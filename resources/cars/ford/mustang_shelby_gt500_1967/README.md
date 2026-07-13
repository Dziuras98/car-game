# Ford Mustang Shelby GT500 (1967) content root

This directory reserves the canonical catalog location for the 1967 Shelby GT500 model.

## Current phase

Only the visual foundation exists:

- detailed wrapper: `res://scenes/cars/mustang_shelby_gt500_1967_visuals.tscn`;
- low-detail fallback: `res://scenes/cars/mustang_shelby_gt500_1967_low_detail_visuals.tscn`;
- inspection scene: `res://scenes/dev/mustang_shelby_gt500_1967_visual_preview.tscn`;
- source asset record: `res://assets/third_party/sketchfab/ford_mustang_shelby_gt500_1967/README.md`.

The model is intentionally not referenced by `resources/cars/catalog.tres` yet. Registering it now would require an incomplete or fabricated playable variant.

## Planned canonical structure

```text
resources/cars/ford/mustang_shelby_gt500_1967/
  model.tres
  specs/
    <variant>_specs.tres
    <engine>_torque_curve.tres
  variants/
    <variant>.tres
```

Proposed stable model ID: `ford_mustang_shelby_gt500_1967`.

`model.tres`, variant resources and specs should be added together only after the exact production configuration, transmission choice, mass, tyre geometry, engine curve and scene bindings have been verified.
