# Traffic Rider NPC vehicles — physics v3 implementation baseline

## Recorded baseline

- authoritative `master` physics commit: `3743f5e95391b63a97e81b95050984b8240b7f30`;
- merged work: PR #118, **Rework per-wheel vehicle physics and recalibrate DPI v3**;
- baseline review date: 2026-07-16;
- PR #107 synchronization result: the Traffic Rider branch contains the complete physics commit and is zero commits behind `master` at the time this baseline was recorded;
- implementation activation: model 01 may enter `integrating` only after the complete current PR-head workflow passes.

This document records the interfaces against which all 285 approved Traffic Rider configurations must be implemented and calibrated. It does not claim that every required transmission, AWD or audio architecture already exists.

## Authoritative runtime interfaces

### Per-wheel state

`WheelTireState` is the authoritative state for all four wheel positions. Each wheel independently records:

- contact state, surface grip, contact normal and contact position;
- suspension support and normal-load share;
- contact-patch road speed and steering angle;
- longitudinal slip ratio and lateral slip angle;
- longitudinal and lateral force, grip usage and combined slip intensity;
- wheel radius, rotational inertia, angular velocity, angular acceleration and angular position;
- drive, brake and tire torque.

Traffic Rider resources must therefore provide physically coherent wheel radius and front/rear wheel inertia. Runtime vehicle scenes and visual wrappers must preserve the canonical wheel order: front-left, front-right, rear-left and rear-right.

### Longitudinal force and load transfer

`CarPowertrainController` uses bounded simulation substeps and resolves drive, service-brake, engine-brake and handbrake torque per wheel. It performs a predictive longitudinal-force pass, updates dynamic wheel-load shares from achievable acceleration, and then performs the applied-force pass.

Calibration must use the final per-wheel grip, mass distribution, centre-of-mass height, wheelbase, track widths, brake bias and suspension support model. Variants may not compensate for incorrect mass or driveline data with false engine torque, arbitrary grip or speed caps.

### Differential and AWD behaviour

`CarDriveConfig.get_drive_torque_fraction()` supplies the base torque split. `DifferentialModel` then applies front-axle, rear-axle and centre coupling from wheel-speed difference, wheel inertia and configured lock strength.

This is sufficient for static drive-layout and generic lock behaviour, but it is not a complete generation-specific active AWD controller. BMW F32 xDrive variants require a dedicated transfer-clutch control strategy or an architecture-specific extension that models speed-, slip- and demand-dependent front/rear torque transfer. A fixed `awd_front_torque_fraction` alone is not accepted as final xDrive fidelity.

### Braking and tires

The baseline exposes:

- front brake bias;
- ABS and traction-control strength;
- front/rear tire width and lateral grip;
- longitudinal peak-slip ratio and slide-grip multipliers;
- combined longitudinal/lateral grip use;
- per-wheel surface grip and load.

Each variant requires researched tire dimensions and a defensible axle-grip balance. Driver aids may control operation within available tire capacity; they may not add tire force beyond that capacity.

### Steering, yaw and body attitude

The authoritative resource includes wheelbase, front/rear track, steering angle, steering response, yaw-rate and damping controls, load-sensitive tire force, collision yaw response and body pitch/roll response. Model-specific geometry and mass distribution must be reflected in these inputs instead of copied from unrelated vehicles.

### Aerodynamic and rolling resistance

Resistance is evaluated from vehicle mass, drag coefficient, frontal area, air density and rolling-resistance coefficient as a local velocity vector. Traffic Rider variants require evidenced drag and frontal-area values or explicitly documented estimates derived from the represented body. Top speed must emerge from available wheel power, gearing and resistance except where the real vehicle has a documented electronic limiter.

## Transmission findings

### Conventional manual

The existing manual path supports discrete ratios, clutch engagement, safe gear selection, upshift torque cut and downshift rev-match assistance. Exact gear ratios, reverse ratio, final drive, clutch behaviour, shift delay and engine inertia still remain variant data.

### Generic torque-converter automatic

The current automatic path provides:

- discrete gear selection;
- throttle-dependent upshift threshold;
- downshift and kickdown decisions;
- direction interlock;
- a generic torque-converter stall/coupling multiplier;
- generic shift delay;
- wheelspin upshift-hold protection.

It does **not** yet reproduce the complete ZF 8HP architecture required by BMW F32 8AT variants. Before any F32 8AT resource is treated as implemented, the project must add an architecture-specific planetary automatic model or profile supporting at minimum:

- speed-ratio-dependent converter capacity and torque ratio;
- controlled creep and launch;
- progressive lock-up clutch application by gear and operating state;
- torque and inertia phases during shifts instead of a generic complete interruption;
- multi-gear kickdown and skip-shift selection;
- mode-dependent shift maps;
- exact gearbox-family ratios, reverse ratio and final drive;
- generation- and torque-capacity-specific behaviour where mechanically material.

The existing generic automatic may be used as a test harness during development, but it is prohibited as the final fidelity path for approved ZF 8HP variants.

### Automated manual, DCT and CVT

The baseline contains separate SMG and CVT semantics, but it does not establish a general dual-clutch transmission architecture. Any approved DCT variant requires two clutch paths, odd/even gearsets, preselection and overlap/torque-phase behaviour. It may not be represented by reducing a generic automatic shift delay.

CVT variants must use their actual ratio range and launch device. A configured `cvt_min_ratio` is a physical longest-ratio stop; zero means no physical stop and only the numerical epsilon remains.

## DPI v3 and performance validation

`CarPerformanceIndexCalculator` uses the current Nissan 370Z 7AT resource as a dynamic 1000-point reference and computes technical, mixed and fast course times. Its acceleration model includes:

- torque curve and rev limiter;
- exact gearing and final drive;
- converter multiplication where applicable;
- vehicle, engine and wheel rotational inertia;
- mass and aerodynamic/rolling resistance;
- drive layout, dynamic axle load and tire capacity;
- braking and combined-slip reserve;
- transmission-specific shift delay.

Every integrated Traffic Rider variant must produce finite course times and a finite DPI. DPI is a derived consistency check, not a calibration target that may be matched by falsifying physics inputs. Performance validation must additionally use sourced acceleration, standing-distance, in-gear, braking and top-speed envelopes.

## Visual interface

`CarVisualController` requires explicit detailed wheel bindings. Runtime name scanning and heuristic discovery are rejected. Each processed model must expose four independent, hub-centred wheel nodes with explicit front-left, front-right, rear-left and rear-right bindings. Visual wheel rotation should consume the corresponding authoritative wheel angular positions.

## Model 01 — BMW F32 implementation consequences

Before BMW F32 enters `integrating`, the following are mandatory:

1. the current complete PR-head workflow passes;
2. this baseline remains present and its master commit remains an ancestor of the branch;
3. the BMW research record is updated from the pre-PR-118 baseline to commit `3743f5e95391b63a97e81b95050984b8240b7f30`;
4. exact transmission codes, ratios and final drives are resolved per approved row before resource creation;
5. the dedicated ZF 8HP behaviour described above is implemented before any 8AT row is considered complete;
6. xDrive receives dynamic transfer-clutch behaviour before any xDrive row is considered complete;
7. N20, B48, B38, N55, B58, N47, B47 and N57 audio families receive architecture-correct synthesis rather than pitch/EQ substitution;
8. the source GLB remains unchanged and any processed derivative is measured, reproducible and explicitly bound.

## Baseline invalidation triggers

This review must be repeated when:

- `master` changes any per-wheel contact, tire-force, load-transfer, differential, AWD, braking, steering/yaw, resistance, transmission or DPI interface used by Traffic Rider vehicles;
- the Nissan 370Z DPI reference or course model changes materially;
- a new shared transmission or AWD architecture replaces assumptions recorded here;
- model-specific calibration exposes a defect in the shared physics contract.
