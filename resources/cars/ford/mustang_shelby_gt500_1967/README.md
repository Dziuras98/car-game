# Ford Mustang Shelby G.T. 500 (1967) content root

This directory is the canonical catalog location for the production 1967 Shelby G.T. 500 fastback.

## Implemented content

- model definition: `model.tres`;
- shared reconstructed 428 FE PI curve: `specs/gt500_428_pi_torque_curve.tres`;
- four-speed manual specs: `specs/gt500_428_4mt_specs.tres`;
- C6 automatic specs: `specs/gt500_428_3at_specs.tres`;
- four-speed variant: `variants/gt500_428_4mt.tres`;
- automatic variant: `variants/gt500_428_3at.tres`;
- player scenes: `res://scenes/cars/mustang_shelby_gt500_1967_4mt.tscn` and `res://scenes/cars/mustang_shelby_gt500_1967_3at.tscn`;
- shared base scene, collision and procedural V8 audio;
- detailed imported wrapper and low-detail fallback;
- catalog, engine-anchor and deterministic performance regression tests.

The model is registered in `resources/cars/catalog.tres` with stable model ID `ford_mustang_shelby_gt500_1967`.

## Production variant boundary

The normal-production model exposes exactly:

1. `ford_mustang_shelby_gt500_1967_4mt` — 428 FE, close-ratio four-speed Toploader, 3.89 axle;
2. `ford_mustang_shelby_gt500_1967_3at` — 428 FE, three-speed C6 automatic, 3.50 axle.

Both versions share the same engine curve and differ in gearbox, converter, driveline efficiency, launch traction and mass calibration.

The 427 FE Super Snake remains a separate one-off prototype and is not part of this model's variant list.

## Remaining restrictions

Both variants are deliberately `ai_eligible = false` until the imported detailed model has four verified wheel bindings and dedicated AI scenes. The binary GLB also remains in the repository root until its source transform and asset relocation can be changed atomically.

See `res://docs/cars/ford_mustang_shelby_gt500_1967.md` for the complete research, uncertainty and performance-calibration record.
