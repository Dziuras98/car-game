# Ford Mustang Shelby G.T. 500 (1967) content root

This directory reserves the canonical catalog location for the production 1967 Shelby G.T. 500 fastback.

## Current phase

The visual foundation and production powertrain matrix are documented:

- detailed wrapper: `res://scenes/cars/mustang_shelby_gt500_1967_visuals.tscn`;
- low-detail fallback: `res://scenes/cars/mustang_shelby_gt500_1967_low_detail_visuals.tscn`;
- inspection scene: `res://scenes/dev/mustang_shelby_gt500_1967_visual_preview.tscn`;
- source asset record: `res://assets/third_party/sketchfab/ford_mustang_shelby_gt500_1967/README.md`;
- powertrain research: `res://docs/cars/ford_mustang_shelby_gt500_1967.md`.

The model is intentionally not referenced by `resources/cars/catalog.tres` yet. Registering it now would require fabricated gearbox, axle, torque-curve or scene data.

## Verified production variant boundary

The 1967 production model uses one shared 428 FE Police Interceptor-based dual-four-barrel V8 and two transmission choices:

1. four-speed Ford manual, Toploader family;
2. three-speed Ford C6 SelectShift Cruise-O-Matic automatic.

Planned stable IDs:

- model: `ford_mustang_shelby_gt500_1967`;
- manual variant: `ford_mustang_shelby_gt500_1967_4mt`;
- automatic variant: `ford_mustang_shelby_gt500_1967_3at`.

The 427 FE Super Snake is a one-off prototype and is not part of this production model's normal variant list.

## Planned canonical structure

```text
resources/cars/ford/mustang_shelby_gt500_1967/
  model.tres
  specs/
    gt500_428_pi_torque_curve.tres
    gt500_428_4mt_specs.tres
    gt500_428_3at_specs.tres
  variants/
    gt500_428_4mt.tres
    gt500_428_3at.tres
```

Both specs resources will reference the same torque curve. Transmission-specific ratios, shift behavior, driveline losses, axle ratio and mass must remain separate.

`model.tres`, both variant resources and their specs should be added together only after the visual scene bindings, collision, exact gearbox ratios, final-drive ratios, mass and engine curve have been verified.