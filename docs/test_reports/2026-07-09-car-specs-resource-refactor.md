# CarSpecs resource refactor report — 2026-07-09

## Scope

This report records the first Resource-backed car tuning refactor.

Changed files:

- `scripts/car/car_specs.gd`
- `resources/cars/370z_manual.tres`
- `resources/cars/370z_automatic.tres`
- `scripts/car/car_controller.gd`
- `scenes/cars/370zat.tscn`
- `README.md`

## Behavior intended to remain unchanged

This refactor intentionally does not change:

- car physics formulas;
- acceleration, braking or resistance algorithms;
- manual or automatic shifting algorithms;
- torque converter algorithm;
- steering algorithm;
- tire slip algorithm;
- gravity, floor-stick or `move_and_slide()` behavior;
- AI, race, menu, HUD or minimap flow.

## Implementation summary

`CarSpecs` is a `Resource` class that stores car tuning data previously spread across controller export values and scene overrides.

Current Resource files:

- `resources/cars/370z_manual.tres`
- `resources/cars/370z_automatic.tres`

`PlayerCarController` now exposes:

```gdscript
@export var car_specs: CarSpecs
```

At `_ready()`, the controller calls `_apply_car_specs()` before preparing engine, resistance, drivetrain, torque converter and skid-mark helpers.

The base controller has a default manual 370Z specs Resource. The automatic 370Z scene explicitly overrides `car_specs` with `resources/cars/370z_automatic.tres`.

Existing exported values in the scenes are intentionally kept for now as fallback/diagnostic data. They can be removed in a later cleanup after Resource-backed tuning passes smoke testing.

## Validation status

Post-change full-program smoke test was reported as successful by the project owner.

Validated command/scene:

```text
scenes/tests/full_program_smoke_test.tscn
```

Expected passing result remains:

```text
[SMOKE] Extended full program smoke test passed: <N> checks
```

Manual spot checks to repeat if this area changes again:

- menu still lists both 370Z variants;
- automatic 370Z still starts in automatic drive behavior and can reverse from near stop;
- manual 370Z still uses manual gear controls;
- speedometer, RPM, gear text, engine audio and tire squeal still react normally;
- race mode still spawns AI and reaches results screen.

## Next recommended work

1. Prepare a model/variant/catalog data layer so each car model can contain many variants.
2. Keep `CarSpecs` as the tuning payload for each variant.
3. Wire menu selection to the catalog in a separate refactor.
