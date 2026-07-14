# Vehicle model baseline

This document describes the current game-oriented vehicle runtime. The project uses `CharacterBody3D`; it is a deterministic arcade model with explicit longitudinal/lateral state, not a rigid-body wheel solver.

## Main runtime types

| Path | Responsibility |
|---|---|
| `scripts/car/car_controller.gd` | Thin runtime coordinator and public telemetry/control API |
| `scripts/car/car_specs.gd` | Authoritative persistent vehicle tuning resource |
| `scripts/car/car_drive_config.gd` | Sanitized runtime copy of tuning values |
| `scripts/car/car_drive_config_builder.gd` | Validates and maps `CarSpecs` into runtime config |
| `scripts/car/car_runtime_state.gd` | Mutable speed, RPM, gear, input, lateral/longitudinal slip and contact state |
| `scripts/car/car_powertrain_controller.gd` | Transmission, clutch/CVT/converter, RPM, requested longitudinal acceleration and tire-limited speed integration |
| `scripts/car/car_chassis_controller.gd` | Cached ground probes, lateral tire state, steering and collision-resolved movement |
| `scripts/car/ground_contact_model.gd` | Probe placement and per-contact spring math |
| `scripts/car/tire_model.gd` | Lateral recovery, longitudinal acceleration capacity, slip-ratio response and combined-slip intensity |
| `scripts/car/car_reset_controller.gd` | Reset-to-start coordination |
| `scripts/car/car_input.gd` | Keyboard/gamepad input and independent external-AI input |
| `scripts/car/engine_model.gd` | RPM response, torque curve, coupling and limiter |
| `scripts/car/drivetrain_model.gd` | Discrete ratios, coupled RPM, wheel force and acceleration |
| `scripts/car/automatic_transmission_model.gd` | Conventional automatic shifts and direction interlock |
| `scripts/car/manual_transmission_model.gd` | Manual gear-step requests |
| `scripts/car/cvt_transmission_model.gd` | Continuous ratio control, centrifugal clutch, direction handling and drive acceleration |
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
- a variant scene may embed the exact same authoritative `CarSpecs` resource for direct scene use, but must not contain divergent tuning copies;
- changing `car_specs` at runtime safely reconfigures controllers and preserves motion where requested.

## Input ownership

`CarInput` has two ordered sources:

1. standard Godot actions mapped to keyboard and gamepad;
2. typed external throttle, brake, steering, handbrake and one-shot gear requests for AI and deterministic tests.

External input owns the command while enabled. Disabling player control clears the input snapshot. Disabling external input neutralizes stored AI values and gear requests.

Gear-up/down actions affect manual transmissions only. Conventional automatic and CVT direction changes are derived from throttle/brake requests near zero speed.

## Runtime state

`CarRuntimeState` stores:

- forward and lateral speed;
- engine RPM;
- signed gear and shift timer;
- clutch engagement;
- throttle and brake telemetry;
- lateral slip intensity;
- signed longitudinal slip ratio;
- longitudinal slip intensity;
- combined tire-slip intensity;
- surface-grip multiplier;
- active ground-contact count;
- averaged ground normal;
- summed suspension-support acceleration;
- captured reset transform.

Persistent tuning does not belong in runtime state. `CarTelemetrySnapshot` currently exposes the combined tire-slip intensity rather than the two internal components separately.

## Per-physics-frame pipeline

`PlayerCarController._physics_process(delta)` performs:

1. handle reset requests;
2. sample player or external input once;
3. store requested throttle/brake telemetry;
4. clamp the frame interval and split it into bounded simulation substeps;
5. for each substep, sample ground contact through four cached probes;
6. recover lateral speed and calculate lateral slip intensity;
7. update transmission, shift assistance, clutch/converter/CVT state and engine RPM;
8. calculate requested drive, reverse or braking acceleration;
9. resolve that request through the longitudinal tire model, record longitudinal slip and update forward speed;
10. combine lateral and longitudinal slip intensity;
11. update steering while valid tire contact exists;
12. apply bounded gravity and suspension support;
13. after all substeps, call `move_and_slide()` once for collision resolution and project resolved velocity back into local speed;
14. update the skid-mark visual buffer once for the outer physics frame.

One-shot gear inputs are consumed only by the first internal substep. Current-substep contact and lateral slip affect longitudinal capacity without a one-frame delay. The longitudinal result then affects combined slip and steering in the same substep.

## Bounded integration

The vehicle simulation clamps a frame interval to `CarPowertrainController.MAX_FRAME_DELTA` and uses substeps no larger than `MAX_SIMULATION_SUBSTEP`.

The same bounded interval and substep schedule are used for:

- ground-contact acquisition;
- lateral tire recovery and slip;
- transmission, engine and longitudinal forces;
- steering rotation;
- gravity and suspension support.

Horizontal movement is assembled from the final substep state and resolved once through `move_and_slide()`. The collision-resolved result is written back into local forward/lateral speed before the next physics frame.

This prevents the powertrain and chassis from integrating different effective time intervals after a frame hitch. Regression coverage compares coarse versus fine integration for speed, RPM and steering orientation and verifies the number of bounded contact/tire/powertrain steps.

## Engine and transmission

### Transmission types

`CarSpecs.TransmissionType` currently contains:

| Value | Meaning |
|---|---|
| `DIRECT_DRIVE` | Legacy/simple non-geared path |
| `MANUAL` | Discrete forward gears with manual requests and clutch model |
| `AUTOMATIC` | Discrete self-shifting gears with torque converter |
| `CVT` | Continuous variator ratio with centrifugal clutch |

### Gear representation

| Value | Meaning |
|---:|---|
| `-1` | Reverse |
| `0` | Neutral, used by manual/discrete transitions |
| `1..N` | Forward gear or forward-drive state |

For a CVT, forward state is represented as gear `1`; the continuously changing ratio is stored by `CvtTransmissionModel` rather than encoded as fake gears.

### Engine coupling

A disconnected engine follows a throttle-controlled free-rev target. A coupled engine follows wheel-driven RPM.

- manual clutch engagement blends between free-rev and wheel-coupled states;
- conventional automatic uses torque-converter coupling and stall multiplication;
- CVT uses the variator ratio and a centrifugal-clutch engagement factor;
- an airborne geared car may free-rev because tire contact is absent.

### Manual transmission and shift assist

A gear change starts a shift delay and releases the clutch. `ClutchModel` re-engages it according to gear, speed, throttle and shift state. Wheel torque is multiplied by clutch transmission.

Forward-gear changes include built-in throttle assistance:

- an upshift cuts applied throttle to zero for the active shift delay;
- a downshift calculates the RPM coupled to the requested lower gear and applies at least the throttle needed to approach that target;
- neutral/reverse transitions do not trigger the forward-gear throttle assist.

The assist modifies applied powertrain throttle and telemetry during the shift; it does not add an analog clutch input. The current input model has no clutch pedal action.

### Conventional automatic transmission

Throttle requests forward drive and brake requests braking/reverse. Direction changes are interlocked near zero speed. Automatic shifts interrupt wheel torque for the configured delay. The torque converter provides bounded stall multiplication and load-dependent RPM coupling.

### Continuously variable transmission

The CVT path is a separate transmission type, not a conventional automatic with artificial forward ratios. It uses:

- `cvt_max_ratio` as the shortest/highest numerical variator ratio;
- final drive and reverse ratio;
- a throttle-dependent target RPM range;
- a bounded ratio response rate;
- centrifugal-clutch engagement/full-coupling RPM thresholds.

At increasing speed the variator ratio can move continuously toward a small internal epsilon; no configurable longest-ratio floor is stored. Direction changes use the same near-zero-speed interlock pattern as the conventional automatic. The HUD displays `D` or `R`.

## Ground contact and suspension

`GroundContactModel` creates four local probe origins from wheelbase, axle-track width and probe height. `CarChassisController.configure()` caches these positions; they are rebuilt only when the runtime config changes.

Each simulation substep casts rays from the cached positions. For each accepted hit the chassis reads:

- hit distance;
- normalized surface normal;
- typed `TrackSurfaceBody` grip multiplier;
- chassis velocity along the contact normal.

A hit is accepted only when:

- the collider is a `TrackSurfaceBody`;
- it is reachable through `ground_probe_collision_mask`;
- its normal satisfies `minimum_ground_normal_dot`.

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

## Lateral tire state

Lateral speed recovery uses the axle-weighted configured grip, handbrake multiplier, active-contact fraction, surface multiplier and substep duration.

Lateral slip intensity is a bounded gameplay signal assembled from:

- residual lateral speed relative to `slip_speed_threshold`;
- steering demand scaled by current forward speed;
- a handbrake bonus above the minimum speed.

It is not a physical per-wheel slip angle. The signal reserves part of the friction circle, reduces steering authority and contributes to tire effects.

## Longitudinal tire state

Drive, reverse, service braking and handbrake requests all pass through `TireModel.resolve_longitudinal_acceleration()`.

Peak longitudinal acceleration capacity is:

```text
peak_capacity =
    standard_gravity
    * longitudinal_grip_coefficient
    * surface_grip_multiplier
    * sqrt(1 - lateral_slip_intensity²)
    * active_contact_fraction
```

Inputs are bounded before use. Therefore:

- lower-grip surfaces reduce acceleration and braking;
- losing contacts proportionally reduces capacity;
- lateral tire use consumes longitudinal capacity;
- engine torque or `brake_deceleration` cannot bypass tire grip.

The demand ratio is:

```text
demand_ratio = abs(requested_acceleration) / peak_capacity
```

The signed runtime slip ratio scales with demand:

```text
longitudinal_slip_ratio =
    sign(requested_acceleration)
    * longitudinal_peak_slip_ratio
    * demand_ratio
```

When demand is at or below peak, the requested acceleration is applied. Above peak, a smooth overload progression moves the available acceleration from peak grip toward:

```text
peak_capacity * longitudinal_slide_grip_multiplier
```

The transition reaches its full sliding target at the fixed `FULL_SLIDE_DEMAND_RATIO` used by `TireModel`. This represents wheelspin or tire lockup as a car-level signal; it is not a wheel angular-velocity solver and does not distinguish individual driven/braked wheels.

Longitudinal slip intensity becomes visible around `0.75 × peak slip ratio` and reaches full intensity around `1.5 × peak slip ratio`, using a smoothstep response.

## Combined slip and effects

Combined tire-slip intensity is the bounded Euclidean magnitude of lateral and longitudinal intensities:

```text
combined = clamp(sqrt(lateral² + longitudinal²), 0, 1)
```

This combined signal currently drives:

- steering grip reduction;
- skid-mark emission;
- tire-squeal/effect telemetry exposed by the controller.

The friction-circle capacity calculation itself uses lateral slip intensity; longitudinal overload is then represented by the applied acceleration reduction and longitudinal slip signal. This is a one-body approximation rather than a fully iterative tire-force solver.

## Typed surface grip

Generated asphalt, shoulder and grass bodies are `TrackSurfaceBody` instances. Grip is an exported typed property, not string-keyed object metadata.

The averaged multiplier affects:

- lateral-speed recovery;
- drive acceleration;
- service braking;
- reverse acceleration;
- handbrake deceleration.

Surface grip is combined with the active-contact fraction and lateral friction-circle usage for all tire-generated longitudinal forces.

## Airborne behavior

When no probe contacts the ground:

- lateral speed is preserved;
- lateral, longitudinal and combined grounded slip signals are cleared;
- surface grip resets to neutral during contact sampling;
- no new skid marks are emitted;
- tire-generated drive, braking, handbrake and steering forces are disabled;
- the engine may free-rev;
- aerodynamic drag and gravity continue.

## Movement and collision response

Horizontal velocity is reconstructed from local forward/lateral state and the car transform. Gravity and suspension support are integrated through bounded substeps. `move_and_slide()` resolves the assembled frame movement, and the resulting velocity is projected back into local coordinates.

Walls remove the velocity component into the collision while preserving tangential slide. The car scenes set `floor_snap_length` to zero so the explicit probe/spring model remains the only grounding mechanism.

## Spawn, reset and reconfiguration

Spawners apply the requested global transform before calling `capture_current_transform_as_start()`. Reset restores that captured transform, clears velocity and drive state, resets the powertrain/CVT state and clears transient skid-mark state.

When specs change on a live car:

1. validate and rebuild `CarDriveConfig`;
2. reconfigure powertrain and chassis controllers;
3. rebuild cached probe positions;
4. refresh skid-mark parameters;
5. clamp gear/state to the new transmission;
6. preserve motion and clamp RPM;
7. restore clutch state appropriate to manual, automatic or CVT mode.

## Public controller API

Selected public methods:

| Method | Purpose |
|---|---|
| `get_forward_speed()` | Longitudinal speed in m/s |
| `get_lateral_speed()` | Lateral speed in m/s |
| `get_speed_kmh()` | Signed display speed |
| `get_engine_rpm()` | Engine RPM |
| `get_current_gear()` | Signed gear/drive-state index |
| `get_cvt_ratio()` | Current variator ratio, or zero for non-CVT cars |
| `get_forward_gear_count()` | Discrete gear count or one forward CVT state |
| `get_throttle_input()` | Applied throttle telemetry, including shift assist |
| `get_engine_load()` | Audio load approximation |
| `get_tire_slip_intensity()` | Combined slip signal for effects/audio |
| `get_telemetry_snapshot()` | Immutable public runtime snapshot |
| `get_gear_text()` | HUD gear label (`N`, numbered gear, `D#`, `D` or `R`) |
| `capture_current_transform_as_start()` | Capture runtime reset origin |
| `set_player_input_enabled()` | Enable/disable player sampling |
| `set_external_input_enabled()` | Enable/disable external ownership |
| `set_external_drive_inputs()` | Supply AI/test controls |
| `request_external_gear_up/down()` | Send guarded one-shot manual shift requests |
| `try_apply_car_specs()` | Transactionally replace runtime tuning |

## Regression gates

Automatically discovered tests cover:

- complete `CarSpecs` validation and mapping, including CVT fields, longitudinal tire fields and suspension support reserve;
- catalog-wide explicit tire calibration for all production variants;
- live reconfiguration and cached-controller reuse;
- manual/automatic/CVT transmission, clutch, torque converter and engine coupling;
- manual upshift throttle cut and downshift RPM blip;
- bounded frame-hitch integration;
- exact 1/2/3/4-probe suspension contact sets and proportional tire authority;
- typed surface grip and mixed-contact averaging;
- lateral friction-circle coupling;
- longitudinal acceleration/braking saturation, slip ratio and sliding-grip behavior;
- combined lateral/longitudinal slip intensity;
- airborne force isolation;
- steering and collision synchronization;
- spawn/reset transforms and opponent-grid admission;
- keyboard/gamepad and external input routing;
- manual AI shifting and automatic/CVT recovery behavior;
- bounded skid marks and procedural audio;
- complete free-drive and race smoke flows.

Run the complete Windows suite rather than relying on one focused scene because powertrain, chassis, input, HUD, AI and packaged-startup contracts interact.

## Current limitations

- no independent rigid-body wheels or true suspension geometry;
- no dynamic load transfer or tire temperature/wear;
- no analog clutch input;
- lateral and longitudinal slip are car-level signals rather than per-wheel slip angles, wheel speeds and load-sensitive force curves;
- the friction-circle approximation is one-directional within a substep: lateral use limits longitudinal capacity, while combined slip subsequently reduces steering/effects authority;
- simplified automatic and CVT control logic;
- no differential model, driven-axle torque split, ABS or traction-control controller;
- no drivetrain damage, stalling or mechanical failure;
- `CarSpecs` remains a flat resource until sub-resources become justified.
