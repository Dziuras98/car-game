# Vehicle model baseline

This document describes the current game-oriented vehicle runtime. The project uses `CharacterBody3D`; it is an arcade model with explicit longitudinal/lateral state, not a rigid-body wheel solver.

## Main runtime types

| Path | Responsibility |
|---|---|
| `scripts/car/car_controller.gd` | Thin runtime coordinator and public telemetry/control API |
| `scripts/car/car_specs.gd` | Authoritative persistent vehicle tuning resource |
| `scripts/car/car_drive_config.gd` | Sanitized runtime copy of tuning values |
| `scripts/car/car_drive_config_builder.gd` | Validates and maps `CarSpecs` into runtime config |
| `scripts/car/car_runtime_state.gd` | Mutable speed, RPM, gear, input, slip and contact state |
| `scripts/car/car_powertrain_controller.gd` | Transmission, clutch, RPM, drive/brake force and resistance |
| `scripts/car/car_chassis_controller.gd` | Cached ground probes, tire state, steering and collision-resolved movement |
| `scripts/car/ground_contact_model.gd` | Probe placement and per-contact spring math |
| `scripts/car/tire_model.gd` | Lateral recovery, slip intensity and longitudinal grip budget |
| `scripts/car/car_reset_controller.gd` | Reset-to-start coordination |
| `scripts/car/car_input.gd` | Keyboard/gamepad input and independent external-AI input |
| `scripts/car/engine_model.gd` | RPM response, torque curve, coupling and limiter |
| `scripts/car/drivetrain_model.gd` | Ratios, coupled RPM, wheel force and acceleration |
| `scripts/car/automatic_transmission_model.gd` | Automatic shifts and direction interlock |
| `scripts/car/manual_transmission_model.gd` | Manual gear-step requests |
| `scripts/car/clutch_model.gd` | Manual clutch engagement and transmitted torque |
| `scripts/car/torque_converter_model.gd` | Automatic RPM coupling and stall multiplication |
| `scripts/car/resistance_model.gd` | Aerodynamic and grounded rolling resistance |
| `scripts/car/vehicle_motion_model.gd` | Local/global horizontal velocity projection |
| `scripts/car/skid_mark_emitter.gd` | Bounded skid-mark visual buffer |

## Authoritative tuning path

```text
CarVariantDefinition -> CarSpecs -> CarDriveConfig -> runtime controllers
```

Rules:

- each catalog variant supplies a scene and `CarSpecs`;
- specs are assigned before the car enters the scene tree;
- invalid or null specs disable physics and report an error;
- runtime controllers receive sanitized defensive copies;
- `CarSpecs.transmission_type` is the only transmission-mode state;
- the car scene owns visual, collision and audio structure, not tuning overrides;
- changing `car_specs` at runtime safely reconfigures controllers and preserves motion where requested.

## Input ownership

`CarInput` has two ordered sources:

1. standard Godot actions mapped to keyboard and gamepad;
2. typed external throttle, brake, steering and handbrake values for AI and deterministic tests.

External input owns the command while enabled. Disabling player control clears the input snapshot. Disabling external input neutralizes stored AI values.

## Runtime state

`CarRuntimeState` stores:

- forward and lateral speed;
- engine RPM;
- signed gear and shift timer;
- clutch engagement;
- throttle and brake telemetry;
- tire-slip intensity;
- surface-grip multiplier;
- active ground-contact count;
- averaged ground normal;
- summed suspension-support acceleration;
- captured reset transform.

Persistent tuning does not belong in runtime state.

## Per-physics-frame pipeline

`PlayerCarController._physics_process(delta)` performs:

1. handle reset requests;
2. sample player or external input once;
3. store throttle/brake telemetry;
4. split the bounded frame interval into simulation substeps;
5. for each substep, sample ground contact through four cached probes;
6. recover lateral speed and calculate current slip;
7. update transmission, clutch, engine RPM and longitudinal speed;
8. update steering while tire contact exists;
9. apply bounded gravity and suspension support;
10. call `move_and_slide()` for the substep;
11. project collision-resolved world velocity back into local speed before the next substep;
12. update the skid-mark visual buffer once for the outer physics frame.

One-shot gear inputs are consumed only by the first internal substep. Current-substep contact and slip affect drive, braking, steering and collision resolution without a one-frame delay.

## Bounded integration

The vehicle simulation clamps a frame interval to `CarPowertrainController.MAX_FRAME_DELTA` and uses substeps no larger than `MAX_SIMULATION_SUBSTEP`.

The same bounded interval and substep schedule are used for:

- ground-contact acquisition;
- tire recovery and slip;
- transmission, engine and longitudinal forces;
- steering rotation;
- gravity and suspension support;
- collision-resolved movement and local-speed reconstruction.

This prevents the powertrain and chassis from integrating different effective time intervals after a frame hitch. Regression coverage requires a hitch-sized frame to execute matching contact, tire and movement substeps and compares coarse versus fine integration for speed, RPM and steering orientation.

## Engine and transmission

### Gear representation

| Value | Meaning |
|---:|---|
| `-1` | Reverse |
| `0` | Neutral |
| `1..N` | Forward gears |

### Engine coupling

A disconnected engine follows a throttle-controlled free-rev target. A coupled engine follows wheel-driven RPM. Manual clutch engagement blends between those states; the automatic uses torque-converter coupling.

### Manual transmission

A gear change starts a shift delay and releases the clutch. `ClutchModel` re-engages it according to gear, speed, throttle and shift state. Wheel torque is multiplied by clutch transmission. The current input model does not expose an analog clutch pedal.

### Automatic transmission

Throttle requests forward drive and brake requests braking/reverse. Direction changes are interlocked near zero speed. Automatic shifts interrupt wheel torque for the configured delay. The torque converter provides bounded stall multiplication and load-dependent RPM coupling.

## Ground contact and suspension

`GroundContactModel` creates four local probe origins from wheelbase, axle-track width and probe height. `CarChassisController.configure()` caches these positions; they are rebuilt only when the runtime config changes.

Each simulation substep casts rays from the cached positions. For each hit the chassis reads:

- hit distance;
- normalized surface normal;
- typed `TrackSurfaceBody` grip multiplier;
- chassis velocity along the contact normal.

The hot loop uses running aggregates rather than allocating temporary arrays:

```text
contact_count
normal_sum
grip_sum
support_acceleration_sum
```

After sampling:

- the ground normal is the normalized sum of active contact normals;
- surface grip is the arithmetic mean over active contacts;
- suspension support is the explicit sum of per-probe spring accelerations;
- tire-generated longitudinal, lateral and steering authority is multiplied by `contact_count / 4`.

The summed-support decision is intentional: each probe represents one support point. Losing a contact removes that probe's support and proportionally reduces tire authority. `CarSpecs.validate()` requires positive suspension stiffness and verifies that the maximum four-probe support acceleration exceeds configured gravity with a reserve margin.

This remains a lightweight chassis model. It does not simulate unsprung mass, suspension geometry, tire deformation or dynamic load transfer.

## Typed surface grip

Generated asphalt, shoulder and grass bodies are `TrackSurfaceBody` instances. Grip is an exported typed property, not string-keyed object metadata.

The averaged multiplier affects:

- lateral-speed recovery;
- drive acceleration;
- service braking;
- reverse acceleration;
- handbrake deceleration.

`TireModel.get_longitudinal_grip_factor()` combines surface grip with a friction-circle approximation:

```text
longitudinal_factor = surface_grip * sqrt(1 - slip_intensity²)
```

The result is then multiplied by the active-contact fraction. As lateral slip approaches `1.0`, or as contact points are lost, less longitudinal drive/braking force remains.

## Airborne behavior

When no probe contacts the ground:

- lateral speed is preserved;
- grounded slip intensity is cleared;
- surface grip resets to neutral;
- no new skid marks are emitted;
- tire-generated drive, braking, handbrake and steering forces are disabled;
- the engine may free-rev;
- aerodynamic drag and gravity continue.

## Movement and collision response

Horizontal velocity is reconstructed from local forward/lateral state and the car transform for every simulation substep. Gravity and suspension support are applied, `move_and_slide()` resolves that substep, and the resulting velocity is immediately projected back into local coordinates. Walls remove the velocity component into the collision while preserving tangential slide. The car scenes set `floor_snap_length` to zero so the explicit probe/spring model remains the only grounding mechanism.

## Spawn, reset and reconfiguration

Spawners apply the requested global transform before calling `capture_current_transform_as_start()`. Reset restores that captured transform, clears velocity and drive state, resets the powertrain and clears transient skid-mark state.

When specs change on a live car:

1. validate and rebuild `CarDriveConfig`;
2. reconfigure powertrain and chassis controllers;
3. rebuild cached probe positions;
4. refresh skid-mark parameters;
5. clamp gear to the new gearbox;
6. preserve motion and clamp RPM;
7. restore clutch state appropriate to the transmission.

## Public controller API

| Method | Purpose |
|---|---|
| `get_forward_speed()` | Longitudinal speed in m/s |
| `get_lateral_speed()` | Lateral speed in m/s |
| `get_speed_kmh()` | Display speed |
| `get_engine_rpm()` | Engine RPM |
| `get_current_gear()` | Signed gear index |
| `get_throttle_input()` | Throttle telemetry |
| `get_engine_load()` | Audio load approximation |
| `get_tire_slip_intensity()` | Slip signal for effects/audio |
| `get_gear_text()` | HUD gear label |
| `capture_current_transform_as_start()` | Capture runtime reset origin |
| `set_player_input_enabled()` | Enable/disable player sampling |
| `set_external_input_enabled()` | Enable/disable external ownership |
| `set_external_drive_inputs()` | Supply AI/test controls |

## Regression gates

Automatically discovered tests cover:

- complete `CarSpecs` validation and mapping, including suspension support reserve;
- live reconfiguration and cached-controller reuse;
- transmission, clutch, torque converter and engine coupling;
- bounded frame-hitch integration;
- exact 1/2/3/4-probe suspension contact sets and proportional tire authority;
- typed surface grip and mixed-contact averaging;
- friction-circle coupling;
- airborne force isolation;
- per-substep steering and collision synchronization;
- spawn/reset transforms and opponent-grid admission;
- keyboard/gamepad and external input routing;
- bounded skid marks and procedural audio;
- complete free-drive and race smoke flows.

Run the complete Windows suite rather than relying on one focused scene because powertrain, chassis, input, HUD and packaged-startup contracts interact.

## Current limitations

- no independent rigid-body wheels or true suspension geometry;
- no dynamic load transfer or tire temperature/wear;
- no analog clutch input;
- scalar slip rather than per-wheel slip angles/ratios;
- simplified automatic gearbox logic;
- no drivetrain damage, stalling or mechanical failure;
- `CarSpecs` remains a flat resource until sub-resources become justified.
