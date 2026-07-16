# Traffic Rider evidence-constrained simulation policy

## Decision

The owner directed on 2026-07-16 that every approved Traffic Rider model must be implemented in sequence using all retained evidence. A missing value no longer blocks the complete workflow by itself. Missing values must instead be reconstructed through the most accurate available physical simulation, while exact and simulated facts remain distinguishable.

This policy does not permit silent defaults, badge-based copies, or unrelated fallback implementations.

## Data-quality classes

Every completed runtime row uses one of these classes:

1. `factory_exact` — the value is retained directly from a source applicable to the exact body, engine, transmission, drivetrain, market and production phase.
2. `evidence_constrained_simulation` — the value is reconstructed from applicable factory anchors, same-family hardware, dimensions, ratios, physical equations and validation targets.
3. `engineering_estimate` — no sufficiently specific anchor survives; the value is an explicit engineering estimate bounded by comparable hardware and sensitivity tests.

A row may contain exact and simulated fields simultaneously. The row-level class is the least certain material field, while `simulated_fields`, `evidence_basis` and `confidence_score` retain field-level transparency.

## Reconstruction hierarchy

For each missing value, use the first applicable method:

1. exact retained value for the candidate;
2. exact same hardware in another directly applicable official specification;
3. interpolation between documented calibrations of the same engine/transmission/body family;
4. physical derivation from power, torque, RPM, mass, dimensions, gearing, tyre size or measured geometry;
5. calibration against sourced acceleration, speed, braking and gradeability targets without falsifying another known parameter;
6. engineering estimate from the closest architecture, with explicit uncertainty and sensitivity coverage.

A lower method may not overwrite a higher-quality retained value.

## Torque curves

Missing full-load curves are reconstructed from all retained anchors, including peak torque, torque plateau, peak power and its RPM, idle, governed/redline speed, aspiration, displacement and combustion type.

The generated curve must:

- pass through retained peak-torque and peak-power constraints;
- remain continuous and physically plausible at idle, spool, plateau and redline;
- reproduce stated power within the declared tolerance;
- preserve material architecture differences rather than sharing one normalized curve across unrelated engines;
- be identified as simulated and never represented as a measured dyno trace.

## Transmission and driveline controls

Exact gear ratios and final drives are retained when known. Missing ratios use documented same-family gearsets before any engineering estimate.

Control simulation must still implement the real architecture: converter multiplication and lock-up, clutch-to-clutch phases, DCT preselection, automated clutch interruption, continuous CVT ratio control, transfer-case modes, controlled AWD coupling, electric axle torque or portal reductions as applicable. A generic shift timer or fixed AWD fraction is not an acceptable simulation.

## Engine audio

Every engine family is rebuilt from its physical structure. The minimum profile includes:

- cylinder count and layout;
- bank angle and crank architecture where applicable;
- firing order and event intervals;
- cylinder-to-bank and cylinder-to-collector routing;
- combustion and injection system;
- valvetrain/mechanical source type;
- intake and exhaust architecture;
- naturally aspirated, turbo, supercharged, sequential, VGT or electric source states;
- cylinder-deactivation transitions where fitted;
- idle, operating and limiter behaviour.

Unrelated engines may share low-level DSP utilities, but not a waveform, event schedule or architecture profile. Pitch/EQ-only substitutions remain prohibited.

## Validation

A simulated candidate can become runtime-visible only after:

- schema and relationship validation;
- torque/power consistency tests;
- transmission/driveline architecture tests;
- explicit tyre/brake calibration registration;
- acceleration, speed and braking target checks within declared tolerance;
- deterministic simulation under frame subdivision;
- architecture-identity, peak-safety and operating-state audio tests;
- player, AI, LOD, catalog, DPI, export and packaged smoke tests.

Simulation uncertainty must be narrowed later when stronger evidence appears, without changing the stable candidate ID.
