# Vehicle model baseline

This document describes the current game-oriented vehicle model after the runtime, powertrain, chassis and reset extraction.

It is a behavior and regression reference for changes to the controller, powertrain, chassis, tire, drivetrain and tuning code. The project uses `CharacterBody3D`; it is not a full rigid-body wheel and suspension simulation.

## Current model boundaries

Current car root type:

```text
CharacterBody3D
```

Current public controller class:

```text
PlayerCarController
```

Main files:

| Path | Responsibility |
|---|---|
| `scripts/car/car_controller.gd` | Runtime coordinator and public telemetry/control API |
| `scripts/car/car_runtime_state.gd` | Mutable forward/lateral speed, RPM, gear, inputs, slip and reset transform |
| `scripts/car/car_drive_config.gd` | Sanitized runtime copy of tuning values |
| `scripts/car/car_drive_config_builder.gd` | Builds runtime config from `CarSpecs` or legacy exports |
| `scripts/car/car_powertrain_controller.gd` | Transmission, RPM, drive force, braking and resistance |
| `scripts/car/car_chassis_controller.gd` | Tire state, steering, gravity, movement and collision response |
| `scripts/car/car_reset_controller.gd` | Reset-to-start coordination |
| `scripts/car/car_input.gd` | Player and external input sampling |
| `scripts/car/automatic_transmission_model.gd` | Automatic gear-selection and direction-interlock decisions |
| `scripts/car/manual_transmission_model.gd` | Manual gear-step requests |
| `scripts/car/engine_model.gd` | RPM state, torque curve and limiter multiplier |
| `scripts/car/drivetrain_model.gd` | Ratios, coupled RPM, wheel force and drive acceleration |
| `scripts/car/torque_converter_model.gd` | Automatic RPM coupling and torque multiplication |
| `scripts/car/tire_model.gd` | Lateral recovery and slip-intensity calculations |
| `scripts/car/resistance_model.gd` | Aerodynamic drag and rolling resistance |
| `scripts/car/vehicle_motion_model.gd` | Local/global horizontal velocity projection |
| `scripts/car/skid_mark_emitter.gd` | Skid-mark visual effects |
| `scripts/car/car_specs.gd` | Resource-backed tuning data |

## Per-physics-frame flow

`PlayerCarController._physics_process(delta)` currently performs:

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

chassis_controller.update_tires(
    state,
    car_input.steering,
    car_input.handbrake_active,
    self,
    skid_mark_emitter,
    delta
)
chassis_controller.update_steering(state, car_input.steering, self, delta)
chassis_controller.apply_velocity(state, self, delta)
```

## Public telemetry and control API

`PlayerCarController` exposes:

| Method | Purpose |
|---|---|
| `get_forward_speed()` | Local forward speed |
| `get_speed_kmh()` | Forward speed converted with `* 3.6` |
| `get_engine_rpm()` | Current engine RPM |
| `get_throttle_input()` | Current throttle telemetry |
| `get_engine_load()` | Engine-load approximation for audio |
| `get_tire_slip_intensity()` | Slip telemetry for audio and effects |
| `get_gear_text()` | HUD gear text |
| `set_player_input_enabled(enabled)` | Enables or disables player input |
| `set_external_input_enabled(enabled)` | Enables or disables external input |
| `set_external_drive_inputs(...)` | Supplies AI drive input |

Current test helpers:

| Method | Purpose |
|---|---|
| `get_current_gear_for_test()` | Returns the runtime gear |
| `get_lateral_speed_for_test()` | Returns the runtime lateral speed |

## Tuning data path

Preferred path:

```text
CarVariantDefinition -> CarSpecs -> CarDriveConfig -> runtime controllers
```

Temporary fallback path:

```text
PlayerCarController legacy exports -> CarDriveConfig -> runtime controllers
```

`CarSpecs` is the preferred source for the current 370Z variants. Legacy controller exports remain until all duplicated scene tuning is removed.

When `car_specs` changes at runtime, the controller rebuilds `CarDriveConfig`, reconfigures the powertrain and chassis, clamps the selected gear and updates the existing skid-mark emitter. The powertrain also synchronizes its internal `EngineModel` RPM with the preserved `CarRuntimeState.engine_rpm`, clamped to the new idle and rev-limiter range.

## Runtime state

`CarRuntimeState` owns:

| Field | Meaning |
|---|---|
| `start_transform` | Reset target transform |
| `forward_speed` | Local longitudinal speed |
| `lateral_speed` | Local lateral speed |
| `engine_rpm` | Current RPM telemetry |
| `current_gear` | `-1` reverse, `0` neutral, `1..N` forward |
| `shift_timer` | Remaining shift delay |
| `throttle_input` | Last throttle snapshot |
| `brake_input` | Last brake snapshot |
| `tire_slip_intensity` | Current grounded slip signal |

`reset_drive_state(idle_rpm)` clears motion and inputs, resets RPM and slip, and selects first gear.

## Input model

Player input maps:

| Output | Source |
|---|---|
| throttle | `accelerate` |
| brake/reverse request | `brake` |
| steering | `steer-right - steer-left` |
| handbrake | `handbrake` |
| gear up/down | `gear-up`, `gear-down` |
| reset | `reset-car` |

External AI input is clamped to throttle/brake `0.0..1.0` and steering `-1.0..1.0`.

## Powertrain model

Per physics frame, `CarPowertrainController`:

1. decays the shift timer;
2. processes manual or automatic gear requests;
3. updates engine RPM;
4. applies drive force, braking, coasting, engine braking and handbrake deceleration;
5. applies aerodynamic and rolling resistance;
6. clamps speed to forward and reverse limits.

### Gear conventions

| Value | Meaning |
|---:|---|
| `-1` | Reverse |
| `0` | Neutral |
| `1..N` | Forward gears |

Manual display uses `R`, `N` or the gear number. Automatic display uses `R` or `D#`.

### Automatic transmission direction interlock

The automatic control scheme uses:

- throttle as the forward-drive request;
- brake as braking while moving forward and reverse drive after stopping.

`AutomaticTransmissionModel.DIRECTION_CHANGE_SPEED_THRESHOLD` is `0.25` speed units. A direction change is allowed only when:

```text
abs(forward_speed) <= 0.25
```

Behavior:

- pressing brake while moving forward keeps the current forward gear and brakes toward zero;
- reverse is selected only after speed reaches the near-zero threshold;
- pressing throttle while reversing keeps reverse selected and brakes toward zero;
- first forward gear is selected only after reverse speed reaches the near-zero threshold;
- drive force in the opposite direction is not applied before the interlock releases.

Normal automatic shifting still includes kickdown, RPM-based upshifts, RPM-based downshifts and lower-gear over-rev protection.

### Engine model

`EngineModel` stores internal RPM. The powertrain supplies wheel-coupled RPM and throttle-derived free-rev RPM:

```text
free_rev_rpm = idle_rpm + throttle * (redline_rpm - idle_rpm) * 0.35
target_rpm = max(wheel_rpm, free_rev_rpm)
rpm_blend = 1.0 - exp(-rpm_response * delta)
current_rpm = lerp(current_rpm, target_rpm, rpm_blend)
current_rpm = clamp(current_rpm, idle_rpm, rev_limiter_rpm)
```

`EngineModel.set_rpm()` is used during runtime powertrain reconfiguration. `CarPowertrainController` keeps a reference to the active runtime state, restores the preserved RPM after applying the new configuration and writes the same clamped value back to `CarRuntimeState.engine_rpm`. The first subsequent powertrain update therefore continues from the preserved RPM rather than from idle.

## Chassis model

### Tire state

When airborne, `update_tires()`:

- leaves lateral speed unchanged;
- clears grounded slip intensity;
- skips skid-mark emission.

When grounded, it:

1. recovers lateral speed toward zero;
2. calculates current-frame slip intensity;
3. updates skid marks.

The controller calculates tire state before steering, so the current frame's slip immediately affects yaw response.

### Steering

`update_steering()`:

1. clamps steering input;
2. limits same-direction steering during substantial lateral slip;
3. ignores very low-speed steering;
4. stores global horizontal velocity;
5. calculates speed-dependent steering and slip grip factors;
6. rotates the body around Y;
7. reprojects the preserved global velocity into local forward/lateral speed.

### Movement and collision response

`apply_velocity()`:

1. converts local speed to global horizontal velocity;
2. applies floor stick or gravity;
3. calls `move_and_slide()`;
4. reads the collision-resolved `CharacterBody3D.velocity`;
5. writes the resolved horizontal velocity back to `CarRuntimeState`.

The last step prevents stale pre-collision speed from being reapplied on the next frame.

## Reset behavior

`CarResetController` restores the start transform, clears Godot body velocity, resets runtime drive state, resets powertrain RPM and resets the skid-mark timer.

## Current limitations

- no suspension, wheel load transfer or damage model;
- manual clutch behavior is abstracted;
- automatic behavior is arcade-oriented rather than a complete TCU simulation;
- tire slip is a scalar gameplay signal, not a complete tire-force model;
- `CarSpecs`, `CarDriveConfig` and legacy exports still duplicate tuning values.

## Regression checklist

After vehicle-model changes, verify:

1. project imports without parse errors;
2. `scenes/tests/full_program_smoke_test.tscn` passes;
3. `scenes/tests/car_powertrain_controller_test.tscn` passes;
4. `scenes/tests/car_chassis_motion_test.tscn` passes;
5. automatic forward acceleration works from rest;
6. automatic reverse works from rest;
7. automatic `D -> R` does not change direction while moving forward;
8. automatic `R -> D` does not change direction while reversing;
9. manual reverse, neutral and forward gears work;
10. collisions update runtime forward/lateral speed;
11. lateral tire recovery occurs only while grounded;
12. current-frame slip affects steering immediately;
13. runtime `CarSpecs` reconfiguration preserves synchronized engine RPM through the next powertrain update;
14. reset clears forward and lateral speed;
15. AI opponents can still follow the racing line.

## Safe next vehicle tasks

Recommended order:

1. remove legacy tuning exports after all scenes use `CarSpecs` explicitly;
2. expose active drive-config telemetry to HUD and audio;
3. split `CarSpecs` into sub-resources only if the flat Resource becomes difficult to maintain.

Do not mix detailed handling tuning or new vehicle imports with architecture cleanup.