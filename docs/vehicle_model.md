# Vehicle model baseline

This document describes the current vehicle model after the runtime, powertrain, chassis and reset extraction.

It is a behavior-preservation reference, not a physics-design document. Use it when reviewing future changes to `scripts/car/car_controller.gd`, `scripts/car/car_runtime_state.gd`, `scripts/car/car_drive_config.gd`, `scripts/car/car_powertrain_controller.gd`, `scripts/car/car_chassis_controller.gd`, `scripts/car/car_reset_controller.gd`, drivetrain code, tire code and tuning Resources.

## Current model boundaries

Current car root type:

```text
CharacterBody3D
```

Current public controller class:

```text
PlayerCarController
```

Current main files:

| Path | Responsibility |
|---|---|
| `scripts/car/car_controller.gd` | Thin runtime coordinator and public telemetry/control API |
| `scripts/car/car_runtime_state.gd` | Runtime forward/lateral speed, RPM, gear, shift timer, input snapshot, tire slip and start transform |
| `scripts/car/car_drive_config.gd` | Sanitized runtime copy of car tuning values |
| `scripts/car/car_drive_config_builder.gd` | Builds runtime config from `CarSpecs` first or legacy controller exports as fallback |
| `scripts/car/car_powertrain_controller.gd` | Transmission input, shift timer, engine RPM, torque, resistance and forward-speed update |
| `scripts/car/car_chassis_controller.gd` | Steering, slip-limited steering, tire model update, skid dispatch, gravity and `move_and_slide()` |
| `scripts/car/car_reset_controller.gd` | Reset-to-start coordination |
| `scripts/car/car_input.gd` | Player/external drive input sampling and input state |
| `scripts/car/manual_transmission_model.gd` | Manual gear-up/gear-down request helper |
| `scripts/car/automatic_transmission_model.gd` | Automatic gear-selection decision helper |
| `scripts/car/shift_timer_model.gd` | Shift-timer update and delay-selection helper |
| `scripts/car/engine_model.gd` | RPM state, free-rev blending, torque multiplier and rev limiter multiplier |
| `scripts/car/drivetrain_model.gd` | Gear-ratio lookup, wheel-coupled RPM, wheel force and drive acceleration helper calculations |
| `scripts/car/torque_converter_model.gd` | Torque converter RPM-coupling and torque-multiplication helper calculations |
| `scripts/car/tire_model.gd` | Lateral grip recovery and tire slip-intensity helper calculations |
| `scripts/car/resistance_model.gd` | Aerodynamic drag and rolling resistance |
| `scripts/car/vehicle_motion_model.gd` | Local forward/lateral speed to global horizontal velocity projection and reverse projection |
| `scripts/car/skid_mark_emitter.gd` | Skid mark visual effect emission and reconfigurable mark parameters |
| `scripts/car/car_specs.gd` | Resource-backed tuning data |
| `scripts/car/engine_audio.gd` | Procedural engine audio driven by controller telemetry |
| `scripts/car/tire_squeal_audio.gd` | Procedural tire audio driven by tire slip intensity |

The current model is intentionally simple and game-oriented. It is not a full rigid-body vehicle simulation.

## Per-physics-frame flow

The current `PlayerCarController._physics_process(delta)` flow is:

1. Check reset input through `CarInput`.
2. If reset was requested, delegate reset to `CarResetController` and return.
3. Read player or external AI drive input through `CarInput`.
4. Store throttle/brake telemetry in `CarRuntimeState`.
5. Let `CarPowertrainController` update shift timer, transmission state, engine RPM and forward speed.
6. Let `CarChassisController` update steering/yaw.
7. Let `CarChassisController` update tire recovery, slip intensity and skid mark dispatch.
8. Let `CarChassisController` apply horizontal velocity, floor stick/gravity and `move_and_slide()`.

In simplified pseudocode:

```gdscript
if car_input.should_reset_car():
    reset_controller.reset_to_start(...)
    return

car_input.read_drive_input()

state.set_drive_input_snapshot(car_input.throttle, car_input.brake)
powertrain_controller.update(
    state,
    car_input.throttle,
    car_input.brake,
    car_input.handbrake_active,
    car_input.gear_up_pressed,
    car_input.gear_down_pressed,
    delta
)
chassis_controller.update_steering(state, car_input.steering, self, delta)
chassis_controller.update_tires(state, car_input.steering, car_input.handbrake_active, self, skid_mark_emitter, delta)
chassis_controller.apply_velocity(state, self, delta)
```

Future refactors should preserve this order unless the change explicitly documents a behavior change.

## Public telemetry and control API

`PlayerCarController` exposes:

| Method | Purpose |
|---|---|
| `get_forward_speed()` | Internal forward speed in m/s-like game units |
| `get_speed_kmh()` | Forward speed converted by `* 3.6` |
| `get_engine_rpm()` | Current engine RPM used by tachometer/audio |
| `get_throttle_input()` | Current throttle input telemetry |
| `get_engine_load()` | Engine load approximation for audio |
| `get_tire_slip_intensity()` | Tire slip telemetry for tire squeal/audio |
| `get_gear_text()` | Gear display text for HUD |
| `set_player_input_enabled(enabled)` | Enable/disable player input, used by race flow |
| `set_external_input_enabled(enabled)` | Enable/disable external AI input |
| `set_external_drive_inputs(throttle, brake, steering, handbrake_active)` | Feed AI/control inputs |

Current test/debug helpers:

| Method | Purpose |
|---|---|
| `get_current_gear_for_test()` | Returns runtime gear integer |
| `get_lateral_speed_for_test()` | Returns runtime lateral speed |

These methods are part of the effective integration contract with UI, audio, race and AI systems. Avoid changing their names or meanings during cleanup.

## Tuning data path

Preferred runtime data flow:

```text
CarVariantDefinition -> CarSpecs -> CarDriveConfig -> runtime controllers
```

Fallback runtime data flow:

```text
PlayerCarController legacy exports -> CarDriveConfig -> runtime controllers
```

`CarSpecs` is the Resource-backed source used by the current catalog-driven 370Z variants. Legacy export fields remain on `PlayerCarController` for scene compatibility and fallback behavior when `car_specs == null`.

When `car_specs` changes while the car is inside the scene tree, `PlayerCarController` rebuilds `CarDriveConfig`, reconfigures the powertrain and chassis controllers, clamps the runtime gear if needed and reconfigures the existing `SkidMarkEmitter` with the new skid-mark thresholds and dimensions.

Current `CarSpecs`/`CarDriveConfig` groups:

- driving;
- engine;
- transmission/drivetrain;
- automatic transmission/torque converter;
- resistance;
- tires/skid marks;
- grounding.

Cleanup rule: add a new tuning field only if it is copied consistently through `CarSpecs`, `CarDriveConfig`, `CarDriveConfig.duplicate_config()`, `CarDriveConfigBuilder` and relevant tests.

## Runtime state

`CarRuntimeState` owns the mutable driving state:

| Field | Meaning |
|---|---|
| `start_transform` | Captured reset target transform |
| `forward_speed` | Local forward speed |
| `lateral_speed` | Local lateral speed |
| `engine_rpm` | Current engine RPM |
| `current_gear` | `-1` reverse, `0` neutral, `1..N` forward |
| `shift_timer` | Remaining shift delay |
| `throttle_input` | Last throttle telemetry snapshot |
| `brake_input` | Last brake telemetry snapshot |
| `tire_slip_intensity` | Current slip telemetry |

`reset_drive_state(idle_rpm)` clears local speeds, resets RPM to the requested idle RPM, resets current gear to first gear, clears shift timer, clears input telemetry and clears tire slip.

## Input model

`CarInput` owns player/external input state.

Player input reads:

| Output | Source |
|---|---|
| `throttle` | `Input.get_action_strength("accelerate")` |
| `brake` | `Input.get_action_strength("brake")` |
| `steering` | `steer-right - steer-left` |
| `handbrake_active` | `Input.is_action_pressed("handbrake")` |
| `gear_up_pressed` | `Input.is_action_just_pressed("gear-up")` |
| `gear_down_pressed` | `Input.is_action_just_pressed("gear-down")` |
| reset check | `Input.is_action_just_pressed("reset-car")` |

External input is used by AI and is clamped to:

| Value | Range |
|---|---|
| throttle | `0.0..1.0` |
| brake | `0.0..1.0` |
| steering | `-1.0..1.0` |
| handbrake | boolean |

Reset input is only accepted when external input is disabled and player input is enabled.

## Powertrain model

`CarPowertrainController` owns the runtime powertrain update.

Per physics frame, it:

1. decays `state.shift_timer` through `ShiftTimerModel`;
2. handles manual or automatic transmission requests;
3. updates engine RPM through `EngineModel`;
4. updates local forward speed through drivetrain acceleration, braking, coasting, engine braking, handbrake deceleration and resistance;
5. clamps forward speed to configured forward/reverse limits.

### Gear conventions

| Gear value | Meaning |
|---:|---|
| `-1` | Reverse |
| `0` | Neutral |
| `1..N` | Forward gears |

Manual display:

- reverse => `R`
- neutral => `N`
- forward => gear number

Automatic display:

- reverse => `R`
- forward => `D#`

Fallback non-geared display:

- negative forward speed => `R`
- positive forward speed => `D`
- otherwise => `N`

### Manual transmission

`ManualTransmissionModel` increments gear on `gear-up`, decrements gear on `gear-down`, clamps the minimum to reverse and clamps the maximum to the configured forward gear count.

`CarPowertrainController` applies the requested gear and sets shift delay through `ShiftTimerModel`.

### Automatic transmission

`AutomaticTransmissionModel` owns these decisions:

- braking at near-zero speed with no throttle requests reverse;
- throttle while not in forward gear requests first gear;
- shifting is skipped while `shift_timer > 0.0`;
- braking while moving can request a downshift if the lower gear stays below `redline_rpm * 0.97`;
- kickdown can request a downshift when throttle exceeds `automatic_kickdown_throttle` and RPM is below `automatic_kickdown_rpm`;
- upshift threshold blends from `automatic_upshift_rpm` to `redline_rpm * 0.98` based on throttle;
- downshift threshold is `automatic_downshift_rpm + throttle * 900.0`;
- downshifts are blocked if the lower gear would exceed `redline_rpm * 0.97`.

### Engine model

`EngineModel` owns current RPM and engine multiplier helpers.

The powertrain calculates wheel-driven RPM and passes it to `EngineModel.update(throttle, wheel_rpm, delta)`.

For geared transmissions, wheel-driven RPM comes from `DrivetrainModel.get_coupled_engine_rpm_for_gear(gear, forward_speed)`. For automatic transmission, that coupled RPM is passed through `TorqueConverterModel.get_coupled_rpm(coupled_rpm, drive_input)`. For non-geared fallback behavior, the powertrain maps speed ratio directly to RPM.

RPM update:

```text
free_rev_rpm = idle_rpm + throttle * (redline_rpm - idle_rpm) * 0.35
target_rpm = max(wheel_rpm, free_rev_rpm)
rpm_blend = 1.0 - exp(-rpm_response * delta)
current_rpm = lerp(current_rpm, target_rpm, rpm_blend)
current_rpm = clamp(current_rpm, idle_rpm, rev_limiter_rpm)
```

### Resistance

`ResistanceModel` applies aerodynamic drag and rolling resistance to local forward speed after throttle/brake/coast/handbrake changes.

## Chassis model

`CarChassisController` owns steering, tire update and movement application.

### Steering

`update_steering()`:

1. clamps steering input to `-1.0..1.0`;
2. reduces same-direction steering under high lateral slip;
3. ignores steering if steering amount is tiny or forward speed is below a small threshold;
4. stores the current global horizontal velocity;
5. computes speed-based steering limit;
6. computes yaw rate from steering angle, forward speed, wheel base and grip factor;
7. rotates the car around Y;
8. converts the preserved horizontal velocity back into local forward/lateral speeds after yaw rotation.

### Tire slip

`update_tires()`:

1. recovers lateral speed toward zero through `TireModel.recover_lateral_speed()`;
2. calculates tire slip intensity through `TireModel.calculate_slip_intensity()`;
3. forces slip intensity to zero when airborne;
4. dispatches skid-mark updates when grounded.

### Velocity and grounding

`apply_velocity()`:

1. converts local forward/lateral speeds to global horizontal velocity through `VehicleMotionModel`;
2. assigns `velocity.x` and `velocity.z`;
3. applies floor stick when grounded;
4. applies gravity when airborne;
5. calls `move_and_slide()`.

This keeps the game-oriented `CharacterBody3D` approach. There is no wheel collider or full rigid-body suspension simulation yet.

## Reset behavior

`CarResetController` owns reset-to-start coordination.

On reset:

- the car global transform is restored to `state.start_transform`;
- Godot body velocity is cleared;
- runtime drive state is reset using the active config idle RPM;
- powertrain RPM state is reset;
- skid mark timer is reset if the emitter exists.

Current design choice: reset returns the current gear to first gear. This is arcade-friendly and covered by the runtime config test. If the manual transmission should later reset to neutral, that should be an explicit behavior change and test update.

## Current limitations

- The model is not a physically complete vehicle simulation.
- There is no suspension model, tire load transfer, wheel rotation state or collision damage model.
- Manual clutch behavior is abstracted away; manual shifting is gear-step based.
- Automatic transmission is game-oriented and does not model every hydraulic/TCU detail.
- Steering is bicycle-model inspired but simplified.
- Tire slip is a scalar gameplay signal, not a full tire-force model.
- `CarSpecs`, `CarDriveConfig` and legacy exports duplicate tuning fields until legacy scene overrides are removed.
- Runtime `car_specs` reconfiguration now updates existing skid-mark emitter parameters; focused tests for runtime reconfiguration are still recommended.

## Regression checklist for vehicle changes

After any vehicle model change, run or verify:

1. project opens without parse errors;
2. `scenes/tests/full_program_smoke_test.tscn` passes;
3. `scripts/tests/car_controller_runtime_config_test.gd` passes;
4. automatic 370Z accelerates from stop;
5. automatic 370Z brakes and reverses from near stop;
6. manual 370Z starts in first gear;
7. manual gear up/down reaches reverse, neutral and forward gears correctly;
8. reset clears forward and lateral speed;
9. steering still preserves speed projection after yaw rotation;
10. handbrake increases slip telemetry and can trigger skid/tire audio;
11. race countdown locks and unlocks player/AI input;
12. AI opponents can still drive the generated racing line.

## Safe next vehicle tasks

Recommended order:

1. add focused tests for `CarPowertrainController` forward/reverse/manual/automatic behavior;
2. add focused tests for `CarChassisController` and `VehicleMotionModel` projection behavior;
3. add focused tests for runtime `car_specs` reconfiguration behavior;
4. remove legacy export fallback only after all scenes and catalog variants use `CarSpecs`;
5. split `CarSpecs` into sub-resources only after the flat Resource becomes difficult to maintain.

Do not tune handling, add new vehicles or import detailed vehicle models in the same change as architecture cleanup.
