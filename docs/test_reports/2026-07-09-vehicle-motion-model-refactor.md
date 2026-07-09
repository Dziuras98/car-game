# Vehicle motion model refactor report — 2026-07-09

## Scope

This report records the behavior-preserving extraction of local/global horizontal velocity projection from `scripts/car/car_controller.gd` into `scripts/car/vehicle_motion_model.gd`.

Changed files:

- `scripts/car/vehicle_motion_model.gd`
- `scripts/car/car_controller.gd`
- `README.md`
- `docs/architecture.md`
- `docs/roadmap.md`

## Behavior intended to remain unchanged

This refactor intentionally does not change:

- car tuning values;
- acceleration or braking logic;
- manual or automatic transmission behavior;
- torque converter behavior;
- resistance logic;
- tire slip calculation;
- slip-limited steering calculation;
- gravity or floor-stick behavior;
- `move_and_slide()` ownership;
- reset behavior;
- race, AI, menu or mobile-control flow.

## Implementation summary

`VehicleMotionModel` is a small `RefCounted` helper. It exposes:

- `get_horizontal_velocity_vector(body_transform, forward_speed, lateral_speed)`
- `get_local_speeds_from_horizontal_velocity(body_transform, horizontal_velocity)`
- `get_forward_vector(body_transform)`
- `get_right_vector(body_transform)`

`PlayerCarController` now owns one `_vehicle_motion_model` instance and delegates the previous local/global velocity projection math to it.

`PlayerCarController` still owns:

- `_forward_speed` and `_lateral_speed` state;
- `velocity.x` / `velocity.y` / `velocity.z` assignment;
- gravity;
- floor stick force;
- `move_and_slide()`;
- steering rotation;
- reset-to-start.

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

- free-drive automatic 370Z accelerates and steers normally;
- manual 370Z shifts and reverses normally;
- steering does not visibly lose or gain speed after turning;
- handbrake still creates lateral slip/skid behavior;
- reset clears movement as before;
- race mode still spawns AI and reaches results screen.

## Next recommended work

1. Introduce `CarSpecs` Resources for 370Z manual and automatic variants.
2. Keep current controller export values as a fallback until Resource-backed tuning passes smoke testing.
3. Continue deeper vehicle-model changes only after Resource-backed tuning is validated.
