# Mobile controls scene refactor report — 2026-07-09

## Scope

This report records the code change that converts the Android mobile driving overlay from procedural runtime UI construction to a scene-driven UI.

Changed files:

- `scenes/ui/mobile_drive_controls.tscn`
- `scripts/ui/mobile_drive_controls.gd`
- `scripts/game/game_manager.gd`
- `README.md`
- `docs/architecture.md`

## Behavior intended to remain unchanged

The mobile controls still press the same existing input actions:

- `accelerate`
- `brake`
- `steer-left`
- `steer-right`
- `handbrake`
- `gear-up`
- `gear-down`
- `reset-car`
- `camera-back`

The overlay still uses Android-only visibility by default through `OS.has_feature("android")`, with `force_visible` available for testing.

The refactor intentionally does not change:

- car physics;
- drivetrain behavior;
- transmission behavior;
- AI behavior;
- race flow;
- menu flow;
- input map bindings.

## Implementation summary

`GameManager` now preloads and instantiates `scenes/ui/mobile_drive_controls.tscn` instead of constructing the overlay directly from `scripts/ui/mobile_drive_controls.gd`.

`MobileDriveControls` now binds existing scene buttons to input actions. It no longer creates buttons, anchors or offsets in script.

## Validation status

Pre-change manual Android validation was reported as successful by the project owner.

Post-change full-program smoke test was reported as successful by the project owner after the scene-driven mobile controls refactor.

Validated command/scene:

```text
scenes/tests/full_program_smoke_test.tscn
```

Expected passing result remains:

```text
[SMOKE] Extended full program smoke test passed: <N> checks
```

Manual Android follow-up checklist, if the overlay is touched again:

- the overlay appears only on Android unless `force_visible` is enabled;
- `GAS`, `BRAKE`, steering and `HB` work as hold actions;
- `G+`, `G-`, `RESET` and `CAM` work as tap actions;
- held actions are released when the app loses focus or exits the scene.

## Next recommended work

1. Continue with the narrow `VehicleMotionModel` extraction from `car_controller.gd`.
2. After that refactor, run the full-program smoke test again.
3. Do not add new gameplay features until the smoke test has passed again on the current code.
