# Vehicle model baseline

This document describes the current game-oriented vehicle runtime. The project uses `CharacterBody3D`; it is an arcade model with explicit longitudinal/lateral state, not a rigid-body wheel solver.

## Main runtime types

| Path | Responsibility |
|---|---|
| `scripts/car/car_controller.gd` | Thin runtime coordinator and public telemetry/control API |
| `scripts/car/car_specs.gd` | Authoritative persistent vehicle tuning Resource |
| `scripts/car/car_drive_config.gd` | Sanitized runtime copy of tuning values |
| `scripts/car/car_drive_config_builder.gd` | Validates and copies `CarSpecs` into runtime config |
| `scripts/car/car_runtime_state.gd` | Mutable speed, RPM, gear, input, slip and contact state |
| `scripts/car/car_powertrain_controller.gd` | Transmission, clutch, RPM, drive/brake force and resistance |
| `scripts/car/car_chassis_controller.gd` | Ground probes, tire state, steering and movement/collision response |
| `scripts/car/ground_contact_model.gd` | Probe placement, spring support and contact averaging math |
| `scripts/car/tire_model.gd` | Lateral recovery, slip intensity and longitudinal grip budget |
| `scripts/car/car_reset_controller.gd` | Reset-to-start coordination |
| `scripts/car/car_input.gd` | Player keyboard/gamepad actions and independent external-AI input |
| `scripts/car/engine_model.gd` | RPM response, torque curve, driveline coupling and rev limiter |
| `scripts/car/drivetrain_model.gd` | Ratios, coupled RPM, wheel force and acceleration |
| `scripts/car/automatic_transmission_model.gd` | Automatic shifts, braking downshifts and direction interlock |
| `scripts/car/manual_transmission_model.gd` | Manual gear-step requests |
| `scripts/car/clutch_model.gd` | Manual clutch engagement and transmitted-torque factor |
| `scripts/car/torque_converter_model.gd` | Automatic RPM coupling and stall torque multiplication |
| `scripts/car/resistance_model.gd` | Aerodynamic and contact-dependent rolling resistance |
| `scripts/car/vehicle_motion_model.gd` | Local/global horizontal velocity projection |
| `scripts/car/skid_mark_emitter.gd` | Bounded skid-mark visual buffer |

## Authoritative tuning path

The active tuning path is:

```text
CarVariantDefinition -> CarSpecs -> CarDriveConfig -> runtime controllers
```

Rules:

- each catalog variant provides a car scene and `CarSpecs`;
- each instantiated car receives its variant specs before entering the scene tree;
- `CarDriveConfigBuilder` rejects null or invalid specs;
- the runtime config is a defensive copy and sanitizes unsafe values;
- `CarSpecs.transmission_type` is the sole transmission-mode state;
- consumers use `PlayerCarController` telemetry/control methods rather than reading tuning fields directly;
- switching `car_specs` at runtime reconfigures the existing controller safely.

### Scene ownership

`scenes/cars/370z.tscn` owns visual meshes, collision structure and audio child nodes only. It does not serialize vehicle tuning values. `PlayerCarController` exposes only the `car_specs` Resource for persistent tuning and does not intercept or ignore unknown properties.

This separation ensures that changing a variant resource changes runtime behavior, while editing or replacing the visual scene cannot silently override physics configuration.

## Input ownership

`CarInput` exposes two mutually ordered sources:

1. standard Godot actions for the player, mapped to keyboard and gamepad events in `project.godot`;
2. typed external throttle, brake, steering and handbrake values used by AI and deterministic tests.

While external input is enabled it owns the drive command. Player input is sampled only when the external source is disabled and player control is enabled. Reset, gear-step and camera actions remain standard player actions.

Disabling player control clears the current input snapshot. Disabling the external channel neutralizes its stored values so stale AI commands cannot survive driver shutdown.

## Runtime state

`CarRuntimeState` stores the mutable values shared by the controllers:

- forward and lateral speed;
- engine RPM;
- selected gear and shift timer;
- manual clutch engagement;
- throttle and brake telemetry;
- tire slip intensity;
- surface grip multiplier;
- ground contact count;
- averaged ground normal;
- suspension support acceleration;
- captured reset transform.

Persistent tuning does not belong in runtime state.

## Per-physics-frame pipeline

`PlayerCarController._physics_process(delta)` performs:

1. handle player reset input;
2. sample player or external AI input;
3. store throttle/brake telemetry;
4. cast four suspension/ground-contact probes;
5. calculate averaged normal, current surface grip and spring support;
6. recover lateral speed and calculate current-frame slip;
7. update shift timing, requested gear, clutch, engine RPM and longitudinal speed using current-frame contact and grip;
8. update steering using the newly calculated slip and only when tire contact exists;
9. project local speed into world velocity;
10. apply gravity and suspension support;
11. call `move_and_slide()`;
12. project collision-resolved world velocity back into local speed.

The order is intentional. Current-frame contact and slip affect drive, braking and steering without a one-frame delay. Collision response is then written back so the next frame starts from actual resolved motion.

## Powertrain integration

`CarPowertrainController` clamps the incoming frame delta and divides it into substeps no larger than the configured simulation limit. This prevents a long frame from applying one unstable torque or resistance impulse.

Each substep updates:

- manual clutch engagement;
- engine RPM and driveline coupling;
- drive, brake, reverse or coasting force;
- engine braking and handbrake deceleration;
- aerodynamic drag and grounded rolling resistance;
- forward/reverse speed limits.

Tire-generated longitudinal forces require at least one active suspension contact. When airborne, throttle can still change engine RPM, but it cannot accelerate the chassis; service brakes, handbrake, coasting friction and rolling resistance likewise cannot change horizontal translation. Aerodynamic drag remains active.

Gear values are:

| Value | Meaning |
|---:|---|
| `-1` | Reverse |
| `0` | Neutral |
| `1..N` | Forward gears |

### Engine and driveline coupling

A disconnected engine uses the throttle-controlled free-rev target. A fully coupled geared engine follows wheel-driven RPM. Manual clutch engagement blends between these states; the automatic uses torque-converter coupling. This prevents full throttle from forcing a geared engine directly toward the limiter regardless of vehicle speed.

### Manual transmission

A gear change starts a shift delay and releases the clutch. `ClutchModel` re-engages it over time according to gear, speed, throttle and shift state. Drive acceleration is multiplied by transmitted clutch torque, so a manual shift cannot apply full wheel torque instantly.

The current game input does not expose an analog clutch pedal; clutch operation remains automatic within the manual gearbox abstraction.

### Automatic transmission

The automatic uses throttle as the forward request and brake as braking/reverse request. Direction changes are interlocked near zero speed:

```text
abs(forward_speed) <= 0.25
```

Before the threshold:

- brake while moving forward keeps a forward gear, may request a safe downshift and decelerates;
- throttle while reversing keeps reverse and decelerates;
- opposite-direction drive force is not applied.

Every automatic gear change starts `automatic_shift_delay`. Wheel torque is interrupted until that timer completes, preventing the selected gear from applying drive force in the same interval that represents the shift.

The torque converter raises engine coupling RPM under load and applies a bounded stall torque multiplier.

## Ground contact and suspension support

`GroundContactModel` generates four probe origins from:

- wheelbase;
- axle track width;
- local probe height.

`CarChassisController` casts downward rays from those origins and excludes the car itself. The cast length is limited to suspension rest length plus travel and a small numerical margin; the local probe height positions the origin and is not counted a second time as additional suspension reach.

For each contact the chassis reads:

- hit distance;
- surface normal;
- collider `surface_grip_multiplier` metadata;
- chassis velocity along the contact normal.

The contact model calculates spring support from rest length, travel, stiffness and damping. The chassis averages contact normals and grip values, counts active contacts and sums support acceleration.

This is a lightweight chassis support model. It can follow slopes and distinguish partial/airborne contact, but it does not simulate independent wheel masses, suspension geometry, tire deformation or load transfer.

## Surface grip and friction budget

Generated asphalt, shoulder and grass collision bodies publish grip multipliers. While tire contact exists, the averaged contact multiplier affects:

- lateral-speed recovery;
- drive acceleration;
- normal braking;
- reverse acceleration;
- handbrake deceleration.

`TireModel.get_longitudinal_grip_factor()` combines surface grip with a friction-circle approximation:

```text
longitudinal_factor = surface_grip * sqrt(1 - slip_intensity²)
```

As lateral slip approaches `1.0`, less longitudinal drive/braking force remains available. This is a gameplay coupling, not a per-wheel tire-force solver.

## Tire slip and steering

While grounded, the chassis:

1. recovers lateral speed according to grip and handbrake state;
2. derives slip intensity from lateral speed, steering load and handbrake contribution;
3. updates skid marks;
4. reduces steering authority under high slip.

Same-direction steering is limited more strongly when the car is already sliding laterally in that direction. Counter-steering remains available.

When no probe contacts the ground:

- lateral speed is preserved;
- grounded tire-slip intensity is cleared;
- surface grip resets to neutral;
- no new skid marks are emitted, but existing mark lifetimes continue to advance;
- drive, service-brake, handbrake and steering tire forces are disabled;
- the engine can free-rev independently;
- aerodynamic drag and gravity continue to act.

## Movement and collision response

The horizontal velocity is reconstructed from local forward/lateral state and the car transform. After `move_and_slide()`, the resolved `CharacterBody3D.velocity` is projected back into local coordinates.

This ensures:

- walls remove the velocity component directed into the collision;
- tangential slide velocity is retained;
- the next frame starts from actual resolved motion;
- rotation does not invent or discard horizontal momentum.

## Spawn and reset lifecycle

A car scene enters the tree before its caller can assign the requested global spawn transform. Spawners therefore assign the transform first and then explicitly call `capture_current_transform_as_start()`. Reset restores that captured runtime transform, clears world velocity and drive state, resets the powertrain and clears the skid-mark timer.

This applies to player cars, switched free-drive cars and AI opponents.

## Runtime reconfiguration

When `car_specs` changes on a live car:

1. validate and rebuild `CarDriveConfig`;
2. reconfigure powertrain and chassis helpers;
3. refresh existing skid-mark parameters without duplicating the emitter;
4. clamp the selected gear to the new gearbox;
5. preserve forward/lateral motion when requested;
6. preserve and clamp engine RPM to the new valid range;
7. retain or restore clutch state according to transmission type.

A null or invalid specs resource disables physics processing and reports an error rather than silently selecting fallback tuning.

## Public controller API

| Method | Purpose |
|---|---|
| `get_forward_speed()` | Local longitudinal speed in m/s |
| `get_lateral_speed()` | Local lateral speed in m/s |
| `get_speed_kmh()` | Display conversion source (`m/s * 3.6`) |
| `get_engine_rpm()` | Current engine RPM |
| `get_current_gear()` | Current signed gear index |
| `get_throttle_input()` | Current throttle telemetry |
| `get_engine_load()` | Load approximation for procedural audio |
| `get_tire_slip_intensity()` | Slip signal for audio/effects |
| `get_gear_text()` | HUD gear label |
| `capture_current_transform_as_start()` | Capture the already assigned runtime spawn/reset transform |
| `set_player_input_enabled()` | Enable/disable player action sampling |
| `set_external_input_enabled()` | Enable/disable AI/external ownership |
| `set_external_drive_inputs()` | Supply AI or deterministic-test controls |

## Regression gates

Vehicle changes are covered by automatically discovered tests for:

- `CarSpecs` validation and complete runtime mapping;
- live specs replacement and emitter reuse;
- clutch and transmission behavior;
- powertrain stability, engine coupling and shift torque interruption;
- ground-contact math and suspension-range probes;
- surface-grip and friction-circle behavior;
- full current-frame contact -> tire -> powertrain -> steering -> movement integration;
- airborne force isolation;
- chassis projection, steering and collision synchronization;
- spawn/reset transform lifecycle;
- keyboard action and external-input routing;
- skid-mark bounds and procedural-audio voice budgets;
- speedometer range refresh;
- catalog/scene/spec consistency;
- full free-drive and race integration.

Run the complete Windows suite rather than relying on one focused scene, because powertrain, chassis, input, HUD and exported-startup contracts interact.

## Current limitations

- no independent rigid-body wheels or true suspension geometry;
- no dynamic load transfer or tire temperature/wear;
- no analog manual clutch input;
- scalar slip rather than combined per-wheel slip ratios/angles;
- arcade automatic gearbox logic rather than a complete TCU;
- no drivetrain damage, stalling or mechanical failure;
- `CarSpecs` remains a flat resource until its maintenance cost justifies sub-resources.
