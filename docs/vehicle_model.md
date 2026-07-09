# Vehicle model baseline

This document describes the current vehicle model before deeper drivetrain, tire and motion refactors.

It is a behavior-preservation reference, not a physics-design document. Use it when reviewing future changes to `scripts/car/car_controller.gd`, `scripts/car/engine_model.gd`, `scripts/car/drivetrain_model.gd`, `scripts/car/manual_transmission_model.gd`, `scripts/car/automatic_transmission_model.gd`, `scripts/car/shift_timer_model.gd`, `scripts/car/torque_converter_model.gd`, `scripts/car/resistance_model.gd`, drivetrain code and tire code.

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
| `scripts/car/car_controller.gd` | Main movement coordinator, applying selected gears, steering, tire slip and reset |
| `scripts/car/car_input.gd` | Player/external drive input sampling and input state |
| `scripts/car/manual_transmission_model.gd` | Manual gear-up/gear-down request helper |
| `scripts/car/automatic_transmission_model.gd` | Automatic gear-selection decision helper |
| `scripts/car/shift_timer_model.gd` | Shift-timer update and delay-selection helper |
| `scripts/car/engine_model.gd` | RPM state, free-rev blending, torque multiplier and rev limiter multiplier |
| `scripts/car/drivetrain_model.gd` | Gear-ratio lookup, wheel-coupled RPM, wheel force and drive acceleration helper calculations |
| `scripts/car/torque_converter_model.gd` | Torque converter RPM-coupling and torque-multiplication helper calculations |
| `scripts/car/resistance_model.gd` | Aerodynamic drag and rolling resistance |
| `scripts/car/skid_mark_emitter.gd` | Skid mark visual effect emission |
| `scripts/car/engine_audio.gd` | Procedural engine audio driven by controller telemetry |
| `scripts/car/tire_squeal_audio.gd` | Procedural tire audio driven by tire slip intensity |

The current model is intentionally simple and game-oriented. It is not a full rigid-body vehicle simulation.

## Per-physics-frame flow

The current `PlayerCarController._physics_process(delta)` flow is:

1. Check reset input through `CarInput`.
2. Update shift timer through `ShiftTimerModel`.
3. Read player or external AI drive input.
4. Store throttle and brake telemetry for HUD/audio/engine-load output.
5. Update transmission input.
6. Update engine RPM.
7. Update forward speed.
8. Update steering/yaw.
9. Update tire slip model.
10. Apply velocity through `move_and_slide()`.

In simplified pseudocode:

```gdscript
if car_input.should_reset_car():
    reset_to_start()
    return

shift_timer = shift_timer_model.update_timer(shift_timer, delta)
car_input.read_drive_input()

throttle = car_input.throttle
brake = car_input.brake
steering = car_input.steering
handbrake_active = car_input.handbrake_active

update_transmission_input(throttle, brake)
update_engine(throttle, delta)
update_speed(throttle, brake, handbrake_active, delta)
update_steering(steering, delta)
update_tire_model(steering, handbrake_active, delta)
apply_velocity(delta)
```

Future refactors should preserve this order unless the change explicitly documents a behavior change.

## Public telemetry and control API

The controller currently exposes:

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

These methods are part of the effective integration contract with camera/HUD/audio/race/AI systems. Avoid changing their names or meanings during cleanup.

## Exported parameter groups

The current controller keeps tuning values in exported fields so car scenes can override them in the Godot inspector.

### Driving

- `acceleration`
- `brake_deceleration`
- `reverse_acceleration`
- `coast_deceleration`
- `handbrake_deceleration`
- `max_forward_speed`
- `max_reverse_speed`
- `steering_speed`
- `wheel_base`
- `max_steering_angle_degrees`

### Engine

- `idle_rpm`
- `peak_torque_rpm`
- `redline_rpm`
- `rev_limiter_rpm`
- `low_rpm_torque_multiplier`
- `mid_rpm_torque_multiplier`
- `redline_torque_multiplier`
- `engine_force`
- `engine_brake_force`
- `rpm_response`

### Transmission / drivetrain

- `manual_transmission_enabled`
- `automatic_transmission_enabled`
- `gear_ratios`
- `reverse_gear_ratio`
- `final_drive_ratio`
- `peak_engine_torque`
- `wheel_radius`
- `drivetrain_efficiency`
- `shift_delay`

### Automatic transmission / torque converter

- `automatic_upshift_rpm`
- `automatic_downshift_rpm`
- `automatic_kickdown_throttle`
- `automatic_kickdown_rpm`
- `automatic_shift_delay`
- `torque_converter_stall_rpm`
- `torque_converter_coupling_rpm`
- `torque_converter_stall_torque_multiplier`

### Resistance

- `vehicle_mass`
- `drag_coefficient`
- `frontal_area`
- `air_density`
- `rolling_resistance_coefficient`

### Tires and skid marks

- `lateral_grip`
- `handbrake_lateral_grip_multiplier`
- `steering_slip_gain`
- `slip_speed_threshold`
- `slip_steering_lock_threshold`
- `slip_steering_same_direction_multiplier`
- `skid_mark_min_slip`
- `skid_mark_interval`
- `skid_mark_lifetime`
- `skid_mark_width`
- `skid_mark_length`

### Grounding

- `gravity`
- `floor_stick_force`

Until `CarSpecs` resources exist, cleanup changes should keep these exports on `PlayerCarController` to avoid breaking existing scene overrides.

## Input model

`CarInput` owns player/external input state.

Player input reads:

| Output | Source |
|---|---|
| `throttle` | `Input.get_action_strength("accelerate")` |
| `brake` | `Input.get_action_strength("brake")` |
| `steering` | `steer-right - steer-left` |
| `handbrake_active` | `Input.is_action_pressed("handbrake")` |
| reset check | `Input.is_action_just_pressed("reset-car")` |

External input is used by AI and is clamped to:

| Value | Range |
|---|---|
| throttle | `0.0..1.0` |
| brake | `0.0..1.0` |
| steering | `-1.0..1.0` |
| handbrake | boolean |

Reset input is only accepted when external input is disabled and player input is enabled.

## Engine model

`EngineModel` owns current RPM and engine multiplier helpers.

### RPM update

The controller calculates wheel-driven RPM and passes it to `EngineModel.update(throttle, wheel_rpm, delta)`.

For geared transmissions, wheel-driven RPM comes from `DrivetrainModel.get_coupled_engine_rpm_for_gear(gear, forward_speed)`. For automatic transmission, that coupled RPM is passed through `TorqueConverterModel.get_coupled_rpm(coupled_rpm, drive_input)`. For non-geared fallback behavior, the controller still maps speed ratio directly to RPM.

The engine model calculates:

```text
free_rev_rpm = idle_rpm + throttle * (redline_rpm - idle_rpm) * 0.35
target_rpm = max(wheel_rpm, free_rev_rpm)
rpm_blend = 1.0 - exp(-rpm_response * delta)
current_rpm = lerp(current_rpm, target_rpm, rpm_blend)
current_rpm = clamp(current_rpm, idle_rpm, rev_limiter_rpm)
```

### Torque multiplier

Torque multiplier is a piecewise smooth curve:

1. low RPM blends from `low_rpm_torque_multiplier` to `mid_rpm_torque_multiplier`;
2. mid RPM blends from `mid_rpm_torque_multiplier` to `1.0` around `peak_torque_rpm`;
3. high RPM blends from `1.0` to `redline_torque_multiplier` near redline.

The helper uses a local smoothstep function:

```text
smoothstep(x) = x * x * (3.0 - 2.0 * x)
```

### Rev limiter multiplier

Below `redline_rpm`, limiter multiplier is `1.0`.

Between `redline_rpm` and `rev_limiter_rpm`, multiplier fades toward `0.0`.

If `rev_limiter_rpm <= redline_rpm`, multiplier becomes `0.0` once redline is reached.

## Transmission and wheel RPM

Manual gear-up/gear-down requests are handled by `ManualTransmissionModel`.

Automatic gear-selection decisions are handled by `AutomaticTransmissionModel`.

Shift-timer update and shift-delay selection are handled by `ShiftTimerModel`.

`PlayerCarController` still owns applying selected gears.

`DrivetrainModel` owns gear-ratio lookup and wheel-coupled RPM helper calculations.

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

### Gear-ratio lookup

`DrivetrainModel.get_gear_ratio_for_gear(gear)` returns:

- `reverse_gear_ratio` when gear is negative;
- `1.0` when `gear_ratios` is empty;
- otherwise `gear_ratios[clamped_gear_index]`.

### Wheel-coupled engine RPM

`DrivetrainModel.get_coupled_engine_rpm_for_gear(gear, forward_speed)` calculates:

```text
wheel_circumference = TAU * wheel_radius
wheel_rpm = abs(forward_speed) / wheel_circumference * 60.0
coupled_rpm = max(idle_rpm, wheel_rpm * gear_ratio * final_drive_ratio)
```

If wheel circumference is invalid, it returns `idle_rpm`.

### Manual transmission

When `manual_transmission_enabled` is true, `PlayerCarController` asks `ManualTransmissionModel.get_requested_gear(current_gear, gear_ratios.size())` for a requested gear.

`ManualTransmissionModel`:

- increments gear when `gear-up` is pressed, up to `gear_ratios.size()`;
- decrements gear when `gear-down` is pressed, down to `-1`;
- returns unchanged gear when there is no gear request.

`PlayerCarController` still owns applying the requested gear through `_set_transmission_gear()`.

### Automatic transmission

When `automatic_transmission_enabled` is true, `PlayerCarController` calculates `lower_gear_rpm` when needed and asks `AutomaticTransmissionModel.get_requested_gear(...)` for a requested gear.

`AutomaticTransmissionModel` owns these decisions:

- braking at near-zero speed with no throttle requests reverse;
- throttle while not in forward gear requests first gear;
- shifting is skipped while `_shift_timer > 0.0`;
- braking while moving can request a downshift if the lower gear stays below `redline_rpm * 0.97`;
- kickdown can request a downshift when throttle exceeds `automatic_kickdown_throttle` and RPM is below `automatic_kickdown_rpm`;
- upshift threshold blends from `automatic_upshift_rpm` to `redline_rpm * 0.98` based on throttle;
- downshift threshold is `automatic_downshift_rpm + throttle * 900.0`;
- downshifts are blocked if the lower gear would exceed `redline_rpm * 0.97`.

`PlayerCarController` still owns applying the requested gear through `_set_transmission_gear()`.

### Shift timing

`ShiftTimerModel.update_timer(current_timer, delta)` handles timer decay:

```text
if current_timer <= 0.0:
    return 0.0
return max(current_timer - delta, 0.0)
```

`ShiftTimerModel.get_shift_delay(automatic_enabled, automatic_delay, manual_delay)` selects:

```text
automatic_delay if automatic_enabled else manual_delay
```

`PlayerCarController` still owns storing `_shift_timer` and deciding when `_set_transmission_gear()` is called.

Drive force is still disabled while `manual_transmission_enabled and _shift_timer > 0.0`.

## Torque converter model

`TorqueConverterModel` owns torque converter RPM coupling and torque multiplication. `PlayerCarController` still decides when automatic mode is active and which drive input to pass to the helper.

### RPM coupling

For automatic transmission, wheel-coupled RPM is passed through `_get_torque_converter_rpm(coupled_rpm)`.

The controller derives:

```text
drive_input = brake if current gear is reverse else throttle
```

Then `TorqueConverterModel.get_coupled_rpm(coupled_rpm, drive_input)` calculates:

```text
stall_target_rpm = lerp(idle_rpm, torque_converter_stall_rpm, drive_input)
unlocked_rpm = max(coupled_rpm, stall_target_rpm)
coupling_ratio = clamp((coupled_rpm - idle_rpm) / (torque_converter_coupling_rpm - idle_rpm), 0.0, 1.0)
engine_rpm = lerp(unlocked_rpm, coupled_rpm, coupling_ratio)
```

### Torque multiplication

For automatic transmission, drive force uses torque converter torque multiplication.

`TorqueConverterModel.get_torque_multiplier(engine_rpm, drive_input)` calculates:

```text
coupling_ratio = clamp((engine_rpm - idle_rpm) / (torque_converter_coupling_rpm - idle_rpm), 0.0, 1.0)
slipping_multiplier = lerp(torque_converter_stall_torque_multiplier, 1.0, coupling_ratio)
converter_multiplier = lerp(1.0, slipping_multiplier, drive_input)
```

Manual and non-automatic modes still use multiplier `1.0` from `PlayerCarController`.

## Drive force model

`DrivetrainModel` owns wheel-force and geared drive-acceleration helper calculations.

For geared transmission, drive acceleration is calculated as:

```text
wheel_force = wheel_drive_force(throttle)
drive_acceleration = wheel_force / vehicle_mass
forward_speed += drive_acceleration * delta
```

Wheel force is:

```text
engine_torque = peak_engine_torque * torque_multiplier * rev_limiter_multiplier * throttle * converter_multiplier
wheel_torque = engine_torque * gear_ratio * final_drive_ratio * drivetrain_efficiency
wheel_force = wheel_torque / wheel_radius * drive_direction
```

Drive direction is `-1.0` in reverse gear and `1.0` otherwise.

If `gear_ratios` is empty, current gear is neutral, or manual shift delay is active, geared drive acceleration is `0.0`.

For non-geared fallback behavior, forward acceleration still remains in `PlayerCarController` and uses:

```text
forward_speed += throttle * engine_force * torque_multiplier * rev_limiter_multiplier * delta
```

## Braking, coasting and resistance

`_update_speed()` handles braking and coasting before applying resistance.

### Braking

Manual transmission:

```text
forward_speed = move_toward(forward_speed, 0.0, brake_deceleration * brake * delta)
```

Automatic transmission:

- if moving forward or throttle is active, brake slows toward zero;
- if nearly stopped and braking, reverse gear is selected and reverse drive acceleration is applied.

Non-geared fallback:

- if moving forward, brake slows toward zero;
- otherwise brake accelerates backward using `reverse_acceleration`.

### Coasting and engine braking

When throttle and brake are both zero:

```text
forward_speed = move_toward(forward_speed, 0.0, coast_deceleration * delta)
```

When throttle is zero and forward speed is positive:

```text
forward_speed = move_toward(forward_speed, 0.0, engine_brake_force * delta)
```

### Handbrake longitudinal effect

When handbrake is active:

```text
forward_speed = move_toward(forward_speed, 0.0, handbrake_deceleration * delta)
```

### Resistance model

`ResistanceModel.apply(forward_speed, delta)` applies:

```text
drag_force = 0.5 * air_density * drag_coefficient * frontal_area * forward_speed^2
drag_acceleration = drag_force / max(vehicle_mass, 1.0)
rolling_acceleration = rolling_resistance_coefficient * 9.81
resistance_delta = (drag_acceleration + rolling_acceleration) * delta
```

If `abs(forward_speed) <= resistance_delta`, speed becomes `0.0`. Otherwise speed is reduced against the sign of current speed.

Finally, forward speed is clamped:

```text
forward_speed = clamp(forward_speed, -max_reverse_speed, max_forward_speed)
```

## Steering model

Steering is applied after speed update.

If steering amount is near zero or absolute forward speed is below `0.35`, steering update exits early.

Otherwise:

```text
horizontal_velocity = current forward/right velocity vector
speed_ratio = clamp(abs(forward_speed) / max_forward_speed, 0.0, 1.0)
high_speed_steering_limit = lerp(1.0, 0.42, smoothstep(speed_ratio))
steer_angle = deg_to_rad(max_steering_angle_degrees) * steering_amount * high_speed_steering_limit
grip_factor = lerp(1.0, 0.38, tire_slip_intensity)
yaw_rate = tan(steer_angle) * forward_speed / wheel_base * grip_factor
yaw_rate = clamp(yaw_rate, -steering_speed, steering_speed)
rotate_y(-yaw_rate * delta)
```

After rotation, local forward/lateral speeds are recalculated from the pre-rotation horizontal velocity vector.

## Slip-limited steering

Steering input is limited when lateral slip is high.

```text
lateral_slip_ratio = abs(lateral_speed) / slip_speed_threshold
```

If `lateral_slip_ratio < slip_steering_lock_threshold`, steering is unchanged.

If steering is opposite the slip direction, steering is unchanged.

If steering is in the same direction as the slip, steering is multiplied down toward `slip_steering_same_direction_multiplier` as slip rises above the threshold.

This gives the prototype a simple counter-steer-friendly behavior: steering into the slide becomes less effective than steering against the slide.

## Tire model

The tire model currently handles lateral grip recovery and slip intensity, not a full tire force model.

Active lateral grip:

```text
grip_multiplier = handbrake_lateral_grip_multiplier if handbrake_active else 1.0
active_lateral_grip = max(lateral_grip * grip_multiplier, 0.1)
lateral_speed = move_toward(lateral_speed, 0.0, active_lateral_grip * delta)
```

Slip intensity:

```text
lateral_ratio = abs(lateral_speed) / max(slip_speed_threshold, 0.1)
steering_load = abs(steering) * abs(forward_speed) * steering_slip_gain / max(max_forward_speed, 1.0)
handbrake_bonus = 0.35 if handbrake_active and abs(forward_speed) > 4.0 else 0.0
tire_slip_intensity = clamp(lateral_ratio + steering_load + handbrake_bonus, 0.0, 1.0)
```

If the car is not on the floor, tire slip intensity is forced to `0.0` and skid mark update is skipped.

Skid marks are emitted by `SkidMarkEmitter` when tire slip exceeds the configured threshold.

## Velocity and grounding

Horizontal velocity is reconstructed from local forward and lateral speeds:

```text
horizontal_velocity = -global_transform.basis.z.normalized() * forward_speed
                    + global_transform.basis.x.normalized() * lateral_speed
```

Then:

```text
velocity.x = horizontal_velocity.x
velocity.z = horizontal_velocity.z
```

Vertical behavior:

- if on floor: `velocity.y = -floor_stick_force`;
- otherwise: `velocity.y -= gravity * delta`.

Movement is applied with:

```gdscript
move_and_slide()
```

## Reset behavior

Reset restores:

- global transform to `_start_transform`;
- `velocity` to `Vector3.ZERO`;
- `_forward_speed` to `0.0`;
- `_lateral_speed` to `0.0`;
- engine RPM to idle through `EngineModel.reset()`;
- current gear to `1`;
- shift timer to `0.0`;
- throttle/brake telemetry to `0.0`;
- tire slip intensity to `0.0`;
- skid mark emitter timer.

Reset does not currently reset external input values inside `CarInput`.

## Regression checklist for future vehicle refactors

After any vehicle-model refactor, test both manual and automatic variants:

1. Project opens without script parse errors.
2. Free drive spawns the selected car.
3. Player input works: accelerate, brake, steering, handbrake, reset.
4. AI external input still drives opponent cars.
5. Speedometer still tracks speed.
6. Tachometer still tracks RPM.
7. Engine audio still follows RPM/load/throttle.
8. Tire squeal still follows tire slip.
9. Skid marks still appear only during meaningful slip and fade out.
10. Manual gear up/down still works.
11. Automatic starts in forward drive on throttle.
12. Automatic selects reverse from near stop when braking.
13. Automatic upshifts and downshifts under normal driving.
14. Kickdown downshift still works under high throttle.
15. Reset returns car position, speed and RPM to baseline.
16. Coasting and engine braking still feel unchanged.
17. Handbrake still reduces speed and increases slip.
18. Top speed is not obviously changed.

## Safe refactor sequence from here

Preferred sequence for stabilization:

1. Keep this document updated.
2. Extract drivetrain helpers without changing equations.
3. Keep exported tuning values on `PlayerCarController` until `CarSpecs` exists.
4. Move one responsibility per change.
5. Run the regression checklist before behavior-sensitive merges.

Recommended next code extraction:

```text
scripts/car/tire_model.gd
```

The next vehicle-model change should move only lateral grip recovery and slip-intensity calculation. Steering, velocity and movement should remain in `PlayerCarController` until that smaller extraction is tested.
