# Vehicle model baseline

This document describes the current game-oriented vehicle model. The project uses `CharacterBody3D`; it is not a full rigid-body wheel and suspension simulation.

## Main runtime types

| Path | Responsibility |
|---|---|
| `scripts/car/car_controller.gd` | Runtime coordinator and public telemetry/control API |
| `scripts/car/car_specs.gd` | Authoritative vehicle tuning Resource |
| `scripts/car/car_drive_config.gd` | Sanitized runtime copy of tuning values |
| `scripts/car/car_drive_config_builder.gd` | Copies `CarSpecs` into `CarDriveConfig` |
| `scripts/car/car_runtime_state.gd` | Mutable speed, RPM, gear, input and slip state |
| `scripts/car/car_powertrain_controller.gd` | Transmission, RPM, drive force, braking and resistance |
| `scripts/car/car_chassis_controller.gd` | Tire state, steering, gravity, movement and collision response |
| `scripts/car/car_reset_controller.gd` | Reset-to-start coordination |
| `scripts/car/car_input.gd` | Player and external input sampling |
| `scripts/car/automatic_transmission_model.gd` | Automatic shifting and direction interlock |
| `scripts/car/manual_transmission_model.gd` | Manual gear-step requests |
| `scripts/car/engine_model.gd` | RPM state, torque curve and limiter |
| `scripts/car/drivetrain_model.gd` | Ratios, coupled RPM, wheel force and acceleration |
| `scripts/car/torque_converter_model.gd` | Automatic RPM coupling and torque multiplication |
| `scripts/car/tire_model.gd` | Lateral recovery and slip calculations |
| `scripts/car/resistance_model.gd` | Aerodynamic and rolling resistance |
| `scripts/car/vehicle_motion_model.gd` | Local/global horizontal velocity projection |
| `scripts/car/skid_mark_emitter.gd` | Skid-mark effects |

## Authoritative tuning path

The only active tuning path is:

```text
CarVariantDefinition -> CarSpecs -> CarDriveConfig -> runtime controllers
```

`PlayerCarController` exports only `car_specs`. Engine, transmission, resistance, tire, steering and grounding values are not exported on the controller.

`CarDriveConfigBuilder` accepts a non-null `CarSpecs` and copies all supported fields into a sanitized `CarDriveConfig`. It no longer contains a controller-export fallback.

Current scene rules:

- every catalog variant must provide `CarSpecs`;
- every car scene must expose a non-null `car_specs` value;
- the scene resource and catalog variant must reference the same `CarSpecs`;
- `CarInstanceFactory` rejects variants or scenes without specs;
- fallback AI selection searches for a scene whose specs enable automatic transmission instead of mutating controller fields.

The generic controller currently initializes `car_specs` with the 370Z 6MT Resource so direct programmatic construction remains valid. Catalog variants still replace that value explicitly before entering the scene tree.

### Removed legacy scene properties

The old tuning exports have been removed from `PlayerCarController` and no longer appear in its property list.

The large base `scenes/cars/370z.tscn` still contains serialized keys written by older controller versions. `_set()` accepts those known removed keys solely to keep the existing visual scene loadable. Their values are ignored and never reach `CarDriveConfig`.

New scenes must not serialize those removed keys. The compatibility list can be deleted after the base visual scene is resaved without them in the Godot editor.

## Per-physics-frame flow

`PlayerCarController._physics_process(delta)` performs:

1. reset-input handling;
2. player or AI input sampling;
3. throttle/brake telemetry snapshot;
4. powertrain and transmission update;
5. grounded tire recovery and current-frame slip calculation;
6. steering using the newly calculated slip;
7. velocity application and `move_and_slide()`;
8. synchronization of collision-resolved horizontal velocity back to runtime state.

Simplified flow:

```gdscript
powertrain_controller.update(state, throttle, brake, handbrake, gear_up, gear_down, delta)
chassis_controller.update_tires(state, steering, handbrake, self, skid_mark_emitter, delta)
chassis_controller.update_steering(state, steering, self, delta)
chassis_controller.apply_velocity(state, self, delta)
```

## Public controller API

| Method | Purpose |
|---|---|
| `get_forward_speed()` | Local longitudinal speed |
| `get_speed_kmh()` | Forward speed converted with `* 3.6` |
| `get_engine_rpm()` | Current engine RPM |
| `get_throttle_input()` | Throttle telemetry |
| `get_engine_load()` | Engine-load approximation for audio |
| `get_tire_slip_intensity()` | Slip telemetry for effects/audio |
| `get_gear_text()` | HUD gear text |
| `set_player_input_enabled(enabled)` | Enables or disables player input |
| `set_external_input_enabled(enabled)` | Enables or disables external input |
| `set_external_drive_inputs(...)` | Supplies AI drive input |

## Runtime reconfiguration

When `car_specs` changes while the controller is in the scene tree:

1. `CarDriveConfig` is rebuilt from the new Resource;
2. powertrain and chassis helpers are reconfigured;
3. the selected gear is clamped to the new forward-gear count;
4. skid-mark parameters are updated on the existing emitter;
5. forward and lateral speed are preserved;
6. internal `EngineModel` RPM is synchronized with `CarRuntimeState.engine_rpm`;
7. preserved RPM is clamped to the new idle and rev-limiter range.

A null `car_specs` disables physics processing and reports an error instead of silently creating default tuning.

## Powertrain behavior

Per physics frame, `CarPowertrainController`:

1. decays the shift timer;
2. processes manual or automatic gear requests;
3. updates engine RPM;
4. applies drive force, braking, coasting, engine braking and handbrake deceleration;
5. applies aerodynamic and rolling resistance;
6. clamps speed to forward and reverse limits.

Gear values:

| Value | Meaning |
|---:|---|
| `-1` | Reverse |
| `0` | Neutral |
| `1..N` | Forward gears |

### Automatic direction interlock

The automatic controls use throttle as the forward request and brake as braking/reverse request.

A direction change is allowed only when:

```text
abs(forward_speed) <= 0.25
```

Before that threshold:

- brake while moving forward keeps the forward gear and brakes toward zero;
- throttle while reversing keeps reverse and brakes toward zero;
- opposite-direction drive force is not applied.

## Tire and steering behavior

When airborne, `update_tires()`:

- leaves lateral speed unchanged;
- clears grounded slip intensity;
- skips skid-mark emission.

When grounded, it recovers lateral speed, calculates current-frame slip and updates skid marks.

Tire state is calculated before steering, so current-frame slip immediately affects yaw response.

## Movement and collision response

`CarChassisController.apply_velocity()`:

1. converts local speed to global horizontal velocity;
2. applies floor stick or gravity;
3. calls `move_and_slide()`;
4. reads collision-resolved `CharacterBody3D.velocity`;
5. writes resolved horizontal velocity back to `CarRuntimeState`.

This prevents stale pre-collision velocity from being reapplied on the next frame.

## Regression gates

After vehicle-model changes, verify:

1. project imports without parse errors;
2. `scripts/tests/car_controller_runtime_config_test.gd` passes;
3. `scenes/tests/car_catalog_validation_test.tscn` passes;
4. `scenes/tests/car_specs_runtime_reconfiguration_test.tscn` passes;
5. `scenes/tests/car_powertrain_controller_test.tscn` passes;
6. `scenes/tests/car_chassis_motion_test.tscn` passes;
7. `scenes/tests/full_program_smoke_test.tscn` passes;
8. automatic `D -> R` and `R -> D` interlocks remain effective;
9. collisions update runtime speed;
10. lateral tire recovery occurs only while grounded;
11. current-frame slip affects steering immediately;
12. catalog scenes and variants reference the same specs.

## Current limitations

- no suspension, wheel load transfer or damage model;
- manual clutch behavior is abstracted;
- automatic behavior is arcade-oriented rather than a complete TCU simulation;
- tire slip is a scalar gameplay signal;
- the base 370Z scene still needs to be resaved once to remove inert legacy serialized keys;
- `CarSpecs` remains a flat Resource until its size becomes difficult to maintain.
