# Car chassis motion test — 2026-07-10

## Environment

Reported test environment:

- Godot Engine v4.7.stable.official.5b4e0cb0f
- Vulkan 1.3.284
- Forward Mobile renderer
- Qualcomm Adreno 830 GPU

## Test scene

```text
scenes/tests/car_chassis_motion_test.tscn
```

## Result

Passed.

The scene reported:

```text
[CAR_CHASSIS_MOTION_TEST] Passed: 13 checks
```

## Covered checks

The reported run passed these validation points:

- `VehicleMotionModel` projects identity forward/lateral speeds to horizontal velocity;
- `VehicleMotionModel` restores identity local speeds from horizontal velocity;
- `VehicleMotionModel` round-trips local speeds through a rotated transform;
- `CarChassisController` restores forward speed from horizontal velocity;
- `CarChassisController` restores lateral speed from horizontal velocity;
- steering rotates the car when speed and steering are significant;
- steering preserves horizontal velocity after yaw rotation;
- steering ignores very low forward speed;
- steering limits same-direction steering under lateral slip;
- tire update recovers lateral speed with normal grip;
- tire update clears slip intensity when the car is airborne;
- handbrake reduces lateral grip recovery;
- handbrake applies the configured lateral grip multiplier.

## Notes

The first attempt exposed a test harness issue: test `CharacterBody3D` instances were created outside the scene tree, which caused `global_transform` warnings in Godot 4.7. The test was corrected to add test bodies to the scene before reading or writing `global_transform`.

This validates the focused scene-runnable regression test for chassis projection, steering and tire-recovery behavior.
