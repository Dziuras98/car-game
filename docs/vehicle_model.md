# Vehicle physics model

This document describes the authoritative runtime after the per-wheel physics and DPI v3 revision.

## Design target

The project uses `CharacterBody3D` and a deterministic fixed-order solver. It is not a rigid-body wheel simulation, but it now resolves tire state, wheel rotation, load share and force contribution independently for all four wheels.

The intended balance is:

- deterministic behavior suitable for AI, tests and replay-oriented systems;
- stable handling during frame hitches through bounded substeps;
- physically interpretable tuning values;
- enough per-wheel detail to distinguish FWD, RWD, AWD, open and limited-slip differentials, tire balance and driver aids;
- no dependency on `VehicleBody3D` or an unstable constraint stack.

## Runtime components

| Path | Responsibility |
|---|---|
| `scripts/car/car_controller.gd` | Simulation coordinator and public telemetry/control API |
| `scripts/car/car_specs.gd` | Persistent authoritative tuning resource |
| `scripts/car/car_drive_config.gd` | Sanitized defensive runtime configuration |
| `scripts/car/car_drive_config_builder.gd` | Validation and `CarSpecs` → runtime mapping |
| `scripts/car/car_runtime_state.gd` | Chassis, wheel, contact, force, slip and attitude state |
| `scripts/car/wheel_tire_state.gd` | Per-wheel contact, road speed, rotation, load and tire-force state |
| `scripts/car/car_powertrain_controller.gd` | Transmission, engine coupling, differential, wheel torque and longitudinal force |
| `scripts/car/car_chassis_controller.gd` | Ground probes, lateral force, yaw, suspension support and movement |
| `scripts/car/tire_model.gd` | Longitudinal force curve and combined-grip usage |
| `scripts/car/lateral_tire_dynamics_model.gd` | Slip angle, lateral force curve, Ackermann and yaw inertia |
| `scripts/car/wheel_rotational_dynamics_model.gd` | Wheel torque integration and slip ratio |
| `scripts/car/differential_model.gd` | Open-to-locked axle and center torque redistribution |
| `scripts/car/resistance_model.gd` | Vector aerodynamic drag and rolling resistance |
| `scripts/car/vehicle_motion_model.gd` | Ground-tangent local/world velocity projection |
| `scripts/car/ground_contact_model.gd` | Probe geometry and spring/damper response |

## Authoritative tuning path

```text
CarVariantDefinition -> CarSpecs -> CarDriveConfig -> runtime controllers
```

Rules:

- every production variant supplies one authoritative `CarSpecs` resource;
- invalid or null specs disable physics rather than silently using partial defaults;
- runtime controllers receive sanitized copies;
- live reconfiguration preserves motion where requested and rebuilds dependent caches;
- catalog metadata, runtime physics and DPI all consume the same specs.

## Physics-frame pipeline

`PlayerCarController._physics_process(delta)`:

1. handles reset and samples input once;
2. clamps frame time and divides it into steps no larger than `1/120 s`;
3. initializes a predicted transform used by contact probes during the substeps;
4. for each substep:
   - samples four contacts at the predicted pose;
   - updates filtered steering and per-wheel road speed;
   - calculates wheel load shares from achievable acceleration and suspension support;
   - resolves lateral tire forces and yaw;
   - updates transmission, clutch/converter/CVT and engine RPM;
   - predicts wheel slip from drive and brake torque;
   - performs a two-pass longitudinal solution with corrected load transfer;
   - performs a combined-slip lateral correction;
   - integrates chassis velocity and advances the predicted pose;
5. calls `move_and_slide()` once for authoritative collision resolution;
6. projects the collision-resolved velocity back onto the active ground tangent plane;
7. applies off-center collision yaw response;
8. updates wheel/body visuals and effects once per outer frame.

Gear-step requests are consumed only by the first substep.

## Coordinate and force conventions

The local 2D chassis force convention is:

```text
Vector2(longitudinal, lateral)
```

Each tire first resolves forces in its own wheel plane. Front-wheel forces are rotated by the steering angle into chassis coordinates. Chassis yaw moment uses the complete planar cross product:

```text
Mz = longitudinal_offset * lateral_force
   - lateral_offset * longitudinal_force
```

This permits split-grip braking, asymmetric drive and a steered driven wheel to generate the correct yaw contribution.

## Per-wheel road speed and slip

Each wheel receives the velocity of its own contact patch:

```text
wheel_velocity = chassis_linear_velocity + yaw_rate × wheel_offset
road_speed = dot(wheel_velocity, wheel_forward_direction)
```

Longitudinal slip ratio compares wheel circumferential speed with this value, not with center-of-mass forward speed. This prevents fictitious slip on inner/outer and steered wheels during a turn.

Drive and braking use the same predicted-slip path. Torque is integrated over the current substep, a predicted slip ratio is calculated, and the tire force is resolved from that state. Braking therefore no longer has a separate artificial instant-force path.

## Wheel and drivetrain inertia

Wheel angular acceleration uses the effective inertia passed by the powertrain controller:

- physical wheel/tire inertia;
- reflected engine-side inertia;
- squared active gear and final-drive ratio;
- clutch or converter coupling;
- driven-wheel torque share.

`engine_inertia_kg_m2 = 0` requests the calibrated estimate; a positive value overrides it.

The same inertia assumptions are used by DPI v3.

## Differentials

The runtime supports a continuous open-to-locked approximation for:

- front differential;
- rear differential;
- AWD center coupling.

A lock value of `0` preserves the configured nominal split. Higher values transfer more torque toward the slower/loaded side, bounded to avoid unstable instantaneous redistribution. Driver-aid braking remains separate from mechanical differential behavior.

## Transmission types

### Manual

Discrete ratios, automatic clutch assistance and rev-matched shift assistance. The input model still has no analog clutch pedal.

### Torque-converter automatic

Discrete self-shifting ratios, direction interlock, stall multiplication and speed/load-dependent coupling. A dedicated lock-up clutch energy model is not yet simulated.

### SMG / automated manual

Uses the common powertrain controller and `SmgTransmissionModel`; BMW-specific controller subclasses no longer duplicate the entire powertrain implementation.

### CVT

The configuration stores:

- `cvt_max_ratio`: shortest/highest numerical ratio;
- `cvt_min_ratio`: longest/lowest numerical ratio;
- target RPM range;
- ratio response;
- centrifugal-clutch thresholds.

`cvt_min_ratio = 0.0` means that no physical longest-ratio stop is specified. The ratio may continue toward the numerical epsilon `0.01` as road speed rises. A positive value supplies a real minimum ratio.

## Tire model

### Lateral

Each contacted wheel calculates:

- local contact-patch velocity;
- slip angle;
- peak slip angle from grip, tire width and steering response;
- load-sensitive maximum acceleration;
- post-peak force using configurable `lateral_slide_grip_multiplier`.

Two different signals are retained:

- grip usage: how much of the friction budget the force consumes;
- slip severity: how far the tire has moved beyond its peak region.

Effects use severity. Combined-force capacity uses grip usage.

### Longitudinal

Peak per-wheel capacity is proportional to:

```text
standard_gravity
* longitudinal_grip_coefficient
* surface_grip
* normal_load_share
* remaining_combined_grip
```

Post-peak force moves smoothly toward `longitudinal_slide_grip_multiplier`.

### Combined grip

Longitudinal force reduces lateral capacity and lateral force reduces longitudinal capacity. A predictor/corrector pass within each substep removes the previous one-directional frame delay.

## Load transfer and suspension support

Longitudinal and lateral load transfer use actual achievable acceleration rather than raw engine/brake demand. The longitudinal solver performs an initial pass, recomputes load shares from the predicted force and resolves a corrected pass.

Probe spring support is summed as a vector:

```text
support_vector += contact_normal * support_acceleration
```

Per-wheel normal-load shares blend:

- analytical static/dynamic weight transfer;
- relative support measured by the four springs.

The blend is normalized over active contacts, so a barely loaded wheel cannot retain a full nominal tire capacity.

The suspension remains an arcade support model: it does not simulate unsprung masses, control-arm geometry or tire carcass compliance.

## Ground orientation, slopes and banking

Local forward/lateral speed is projected onto the tangent plane of the current averaged ground normal. Gravity remains a world-space force. This allows slopes and banking to affect motion without forcing the car to remain in the horizontal XZ plane.

The body remains collision-upright for `CharacterBody3D` stability. Filtered pitch and roll states drive the visual body attitude.

## Resistance and speed limits

Aerodynamic drag acts against the complete local velocity vector. The lateral area can be adjusted with `aerodynamic_lateral_area_multiplier`. Rolling resistance acts only while grounded.

`max_forward_speed` and `max_reverse_speed` are soft safety/governor limits. Excess speed is removed with a configurable bounded deceleration rather than an instantaneous clamp. Normal top speed should still emerge from power, gearing, limiter and drag; the soft limiter represents an electronic governor or a final safety envelope.

## Driver aids

Optional per-vehicle controls:

- `traction_control_strength` reduces excessive predicted positive drive slip;
- `abs_strength` reduces excessive brake torque before wheel lock.

A value of `0` disables the aid. The controllers do not add available tire force or engine power; they only avoid operation deep in the post-peak region.

## Collision response

`move_and_slide()` remains authoritative for translation. After collision resolution, the change in chassis momentum and reported collision point are used to estimate a bounded yaw impulse. A lateral or off-center wall strike can therefore rotate the vehicle instead of only deleting linear velocity.

## Body attitude

Filtered visual pitch and roll use measured longitudinal and lateral acceleration. Their response rates and maximum angles are configurable. They do not modify collision geometry and are not used as an additional source of tire load transfer.

## DPI v3

`CarPerformanceIndexCalculator` uses the same physical assumptions as the runtime for:

- gearing, engine curve and limiter;
- wheel and reflected engine inertia;
- CVT minimum-ratio semantics;
- two-pass longitudinal load transfer;
- drive layout and brake bias;
- tire widths and front/rear grip balance;
- combined grip, ABS and traction control;
- aerodynamic and rolling resistance;
- transmission shift delay.

It calculates idealized technical, mixed and fast course times. The current 2016 Nissan 370Z 7AT resource is the dynamic 1000-point reference; its reference times are recalculated from the resource rather than frozen as magic constants.

Detailed real-world targets and sources are listed in `docs/performance_calibration.md`.

## Remaining intentional limitations

- no rigid-body pitch/roll dynamics or unsprung mass;
- no suspension geometry, camber or toe change;
- no tire temperature, wear, pressure or wet-temperature model;
- no analog clutch pedal, clutch heat or drivetrain damage;
- no explicit torque-converter lock-up clutch energy model;
- differential locking is a stable torque-redistribution approximation, not a gear/clutch constraint solver;
- ABS and traction control are scalar per-wheel interventions without hydraulic/controller timing;
- no aerodynamic downforce map or center-of-pressure transfer;
- collisions use a bounded yaw impulse rather than a full rigid-body contact manifold.

These limitations are explicit tuning boundaries, not hidden parameters that imply unsupported fidelity.
