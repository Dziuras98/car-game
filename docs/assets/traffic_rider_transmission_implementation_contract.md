# Traffic Rider transmission and driveline implementation contract

## Purpose

This document is the authoritative Stage 6 procedure for every Traffic Rider powertrain. It preserves the implementation methods established during the 20-model research phase and prevents a researched transmission from being reduced to a gear-count label, a generic shift delay or an unrelated existing backend.

A catalog row remains unavailable when its exact transmission or driveline cannot be represented faithfully. Owner approval fixes scope; it does not authorize fallback hardware or invented parameters.

## Fundamental rule

A **transmission model** represents the complete torque path and its control states, not only a ratio array.

The implementation boundary includes, where applicable:

- launch device: driver clutch, automated clutch, two DCT clutches, hydrodynamic converter or electric fixed coupling;
- physical gearset or continuously variable ratio mechanism;
- selectors, synchronizers, clutch packs, bands and actuators;
- torque interruption or torque handover during shifts;
- converter multiplication, slip and lock-up;
- shift scheduling, skip-shift, kickdown, grade logic and engine braking;
- thermal or protection behaviour when mechanically material;
- reverse implementation and direction-change restrictions;
- transfer case, range group, centre coupling/differential and driven-axle topology;
- runtime state exposed to engine RPM, wheel torque, AI, UI and audio.

Changing only ratios, gear count, thresholds or `shift_delay` is not a new architecture.

## Required research input before code

Each candidate row must have a retained structured record containing, or explicitly blocking:

1. marketing name, manufacturer/family and exact engineering suffix/code;
2. architecture and launch-device type;
3. every forward ratio, reverse ratio and final drive;
4. maximum input torque and engine-specific application;
5. clutch/converter type and known control characteristics;
6. shift times or phase behaviour where documented;
7. lock-up range and slip policy where applicable;
8. vehicle modes, kickdown, skip-shift and grade logic where applicable;
9. drivetrain topology, nominal torque split, differential/coupling type and range ratios;
10. thermal/protection limits when they materially affect repeated launches or shifts;
11. source identifiers and evidence classification.

An exact code may remain empty only with an explicit evidence status. Ratios, mass or behaviour may not be copied from another family merely because the gear count matches.

## Reuse decision

Use the following decision in order:

1. **Exact architecture and required behaviour already exist.** Reuse the shared model with a new evidence-backed configuration resource. Add regression coverage for the new ratio set and vehicle integration.
2. **The architecture exists, but required shared behaviour is missing.** Extend the architecture model through explicit configuration/state, not vehicle-name conditionals. Existing users must retain their previous behaviour through defaults and regression tests.
3. **The architecture is absent or fundamentally different.** Add a dedicated model and integrate it cleanly into `CarDriveConfig`, `CarPowertrainController`, runtime state, AI, UI and tests.
4. **The evidence or implementation is incomplete.** Keep the candidate approved but unimplemented. Do not route it through a fallback.

Low-level utilities may be shared. Physical state machines may be shared only when the underlying architecture and semantics are genuinely the same.

## Common implementation decomposition

Every new architecture or material extension must separate:

- **configuration data** — exact ratios, capacities and control parameters;
- **persistent runtime state** — selected/engaged gear, target gear, clutch or converter state, shift phase, temperatures and mode;
- **gear-request logic** — driver/AI request and automatic scheduler;
- **shift execution** — time-resolved torque path rather than an instantaneous ratio swap hidden by a timer;
- **launch-device model** — clutch or converter torque transfer and slip;
- **driveline distribution** — axle and wheel torque after transfer case/differentials/couplings;
- **telemetry** — stable values used by engine load, sound, UI, debugging and deterministic tests.

The selected gear and the torque-carrying gear may differ during a shift. Runtime state must represent that distinction when the architecture requires it.

## Architecture-specific contracts

### Conventional manual

Implement:

- exact forward/reverse ratios and final drive;
- driver-operated clutch with engagement, slip, capacity and thermal behaviour where relevant;
- engine/flywheel and driveline inertia interaction;
- shift safety and over-rev prevention;
- torque interruption while disengaged;
- optional rev-match or shift assistance only when the represented vehicle provides it;
- correct AI clutch launch, shift timing and stall avoidance.

A low first gear is not a substitute for a transfer-case low range.

### Planetary torque-converter automatic

Implement:

- hydrodynamic converter torque multiplication as a function of speed ratio;
- converter slip, coupling and creep;
- progressive lock-up with commanded slip, unlock conditions and re-engagement;
- gear-specific planetary ratios and exact final drive;
- clutch-to-clutch/band shift phases: torque reduction, handover/inertia phase and reapplication;
- engine torque coordination and shift flare/tie-up prevention;
- multi-gear kickdown and skip-shift where the real controller uses them;
- grade braking and engine-braking behaviour;
- thermal/protection response when relevant;
- direction-change restrictions and reverse converter behaviour.

The current generic behaviour must not be treated as proof that a specific ZF 8HP, GM 6L80/8L90, Ford 6R80, Aisin or Mercedes automatic is complete. Each family requires its own evidenced control/configuration profile and tests. An automatic is not implemented by changing `current_gear` immediately and using `shift_timer` only as a torque cut.

### Automated manual / SMG / EPS-EAS

Implement the real synchronized manual gearset plus:

- one physical clutch path unless the source architecture proves otherwise;
- automated clutch disengagement/re-engagement;
- electro-hydraulic/electro-pneumatic selector timing;
- engine torque cut on upshift and rev-match/blip on downshift;
- launch and creep only when the real controller provides them;
- interruption and re-engagement phases distinct from a planetary automatic;
- manual/automatic control modes where applicable;
- range groups, reversing units or off-road groups as separate driveline states.

Do not add converter multiplication or seamless DCT torque handover to an automated manual.

### Dual-clutch transmission

Implement:

- two distinct clutch torque paths for odd/even gearsets;
- active gear and preselected gear state;
- launch-clutch slip and creep policy;
- clutch overlap and torque handover during up/downshifts;
- preselection cancellation and recovery when the requested gear differs from the predicted gear;
- engine torque intervention and rev matching;
- kickdown/skip-shift through valid preselection steps;
- wet- or dry-clutch thermal/capacity behaviour appropriate to the exact family;
- family-specific ratios, hydraulic/electric actuation and limits.

DQ200 dry, DQ250 wet, DQ381 wet and Renault DC4/6DCT250 dry are separate implementations/configuration families. A DCT must not be represented by shortening a conventional automatic delay.

### Continuously variable transmission

Implement:

- actual minimum/maximum ratio range and final drive;
- time-resolved ratio actuation and target-RPM strategy;
- the real launch device: clutch or torque converter;
- ratio and torque limits, belt/chain protection and thermal response where relevant;
- reverse mechanism;
- coast/engine-braking behaviour;
- simulated steps only as a controller mode over the continuous mechanism, never as separate physical gears.

### Electric fixed reduction

Implement:

- motor torque-speed and power limits rather than a combustion torque curve;
- inverter current/power limits;
- fixed reduction and differential;
- battery voltage, usable energy, power and state limits;
- regenerative braking and brake blending;
- motor/inverter/battery thermal derating where relevant;
- forward/reverse direction without a fake multi-speed combustion gearbox.

A combustion transmission locked in one gear is not an EV driveline model.

## Drivetrain and range-system contracts

### On-demand coupling: xDrive/Haldex-style systems

A constant front-torque fraction plus a centre-lock correction is insufficient. Implement:

- nominal/base axle request;
- demand-dependent clutch command;
- wheel/axle-slip and speed-difference response;
- clutch capacity and rate limits;
- launch and stability-control pre-emptive engagement where documented;
- coast/overrun and high-speed release behaviour;
- thermal/protection state where relevant;
- correct front/rear differentials and inertia.

### Permanent AWD with centre differential

Implement a continuously driven front and rear axle, verified nominal split, torque-bias/locking response and centre-differential constraints. Do not model it as part-time coupling or generic traction multiplication.

### Selectable part-time 4WD

Implement explicit documented states such as 2H, 4H and 4L, high/low transfer ratios, engagement restrictions, locked front/rear coupling in 4H/4L, driveline wind-up on high-grip surfaces and low-range engine/clutch/brake behaviour.

### Electric rear-axle assist

Represent the rear motor, power supply, speed/torque limits and control logic independently. Do not add a mechanical prop shaft or permanent fixed torque split when the real system is an electric assist axle.

### Portal hubs and secondary reductions

Portal or hub reductions must affect wheel torque, wheel speed, reflected inertia and gear-speed validation. They may not be represented only through ride height or a hidden acceleration multiplier.

## Integration procedure

For a new or extended transmission architecture:

1. create/extend the architecture model and typed configuration fields;
2. add persistent runtime state required by the mechanism;
3. integrate configuration sanitization and backward-compatible defaults;
4. integrate time-resolved update order in `CarPowertrainController`;
5. expose truthful engine-load, clutch/converter, selected/engaged gear and shift-phase telemetry;
6. integrate differential, transfer-case and per-wheel torque distribution;
7. integrate player controls, AI requests and direction changes;
8. integrate gear display without lying about neutral, range, preselection or shift state;
9. feed engine audio with driver throttle, applied torque/load, RPM, boost and shift/lock-up events using correct semantics;
10. add architecture tests before any vehicle row is exposed;
11. add vehicle-level performance and durability tests;
12. rerun every existing transmission and catalog regression.

Vehicle-specific tuning belongs in resources. Generic code must not branch on badge, model name or candidate ID.

## Mandatory deterministic tests

### Architecture unit tests

Cover at minimum:

- configuration validation and exact ratio count;
- launch from rest, creep/stall or clutch engagement as applicable;
- torque multiplication/slip or clutch capacity;
- every shift direction and phase transition;
- no instantaneous impossible RPM/torque discontinuity;
- kickdown, skip-shift, rev-match and rejected over-rev shift;
- lock-up command, slip and unlock;
- reverse and direction-change protection;
- thermal/protection transitions where implemented;
- fixed-step determinism and finite outputs.

### Driveline tests

Cover:

- axle/wheel torque conservation within modeled losses;
- open/locked differential response;
- on-demand coupling response to throttle and slip;
- permanent AWD nominal split and bias response;
- 2H/4H/4L state and low-range ratio;
- wind-up or engagement restrictions;
- portal/e-axle effects on wheel speed and torque.

### Vehicle integration tests

Cover:

- correct scene/resource architecture and no fallback path;
- AI launch and shifting;
- UI gear/range display;
- engine-load/audio telemetry through shifts and limiter operation;
- acceleration, in-gear, top-speed, grade and repeated-shift targets;
- no gear hunting under sustained wheel slip;
- no catalog exposure before all required data and tests pass.

## Catalog gate

A candidate may be exposed only when:

- its exact architecture is supported;
- every required configuration value is retained with evidence state;
- no fallback or family proxy is active;
- architecture, drivetrain and vehicle integration tests pass;
- documented performance emerges without false torque, mass, gearing, losses or hidden caps;
- existing vehicles retain green regressions.
