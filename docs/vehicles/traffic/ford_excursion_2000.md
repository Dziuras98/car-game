# Ford Excursion — research and approved scope

- Model number in Traffic Rider bundle: **06**
- Source GLB: `06_ford_excursion_2000.glb`
- Source SHA-256: `7e6909692533a21392cb7bdfa03f52db5fe58da59fba6ea5727a76070d91baf7`
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **5 pre-facelift XLT-style Ford Excursion 4x2 engine/calibration configurations**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents a **2000-model-year Ford Excursion, pre-facelift body, XLT exterior treatment**. It uses the original egg-crate grille and Super Duty-derived front clip, XLT-style lower cladding and chrome steel-wheel treatment, original rear tri-panel door and vertical rear lamps, roof rack and running boards.

The approved visual scope is strictly the source-like **2000–2004 pre-facelift XLT appearance**. The 2005 facelift, Limited, Eddie Bauer, XLS/fleet and other trim derivatives are excluded. Later powertrains may be represented only where they were factory-available before the 2005 visual facelift.

All approved vehicles are **4x2 rear-wheel drive**. The source mesh itself does not visually prove 4x2, but the owner deliberately selected the 4x2 chassis architecture and excluded every 4x4 configuration.

## Reference dimensions and source inspection

| Parameter | Result |
|---|---:|
| Overall length | 226.7 in / 5.758 m |
| Wheelbase | 137.1 in / 3.48234 m |
| Width | approximately 80.0 in |
| 4x2 height | approximately 77.2–77.4 in |
| Source meshes | 3 |
| Body mesh | `AI_Ford_Excursion_High_Ford_Excursion_2000_Black_0` |
| Front wheel-pair mesh | `on_teker.005_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.005_wheel_0` |
| Body triangles | 1,460 |
| Front wheel-pair triangles | 360 |
| Rear wheel-pair triangles | 360 |
| Total triangles | 2,180 |
| Source wheelbase | approximately 5.098955 units |
| Approximate wheelbase-derived scale | 0.682952 |

The source GLB remains unchanged. Wheel separation, collision, catalog, physics, transmission and audio work remain blocked by the global research gate.

## Owner-directed scope rules

- use 4x2 rear-wheel drive only;
- retain the 4x2 Twin-I-Beam front suspension with coil springs;
- include every factory engine family represented in the 2000–2004 pre-facelift production phase;
- represent the 7.3L Power Stroke with only an **early** and a **late** calibration;
- exclude the intermediate 2001 250 hp / 505 lb-ft calibration;
- preserve only the source-like pre-facelift XLT exterior;
- use one verified standard rear-axle ratio for each engine/calibration row;
- use one verified standard differential state for each row, without open/limited-slip duplicates;
- exclude the Mexico-only 2006 continuation;
- no additional expected variant was identified by the owner.

## Approved configuration matrix

| # | Application | Engine / calibration | Transmission | Drivetrain | Status |
|---:|---|---|---|---|---|
| 1 | 2000–2004 pre-facelift | 5.4L Triton Modular SOHC 2-valve naturally aspirated cross-plane V8, 255 hp / 350 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and differential | **approved** |
| 2 | 2000–2004 pre-facelift | 6.8L Triton Modular SOHC 2-valve naturally aspirated even-fire V10, 310 hp / 425 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and differential | **approved** |
| 3 | **7.3 early**, model year 2000 | 7.3L Power Stroke / Navistar T444E HEUI turbo-diesel V8, 235 hp / 500 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and differential | **approved** |
| 4 | **7.3 late**, 2002–early 2003 | 7.3L Power Stroke / Navistar T444E HEUI turbo-diesel V8, 250 hp / 525 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and differential | **approved** |
| 5 | late 2003–2004 pre-facelift | 6.0L Power Stroke / Navistar VT365 HEUI turbo-diesel V8, 325 hp / 560 lb-ft | Ford TorqShift 5R110W 5-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and differential | **approved** |

**Approved total: 5 pre-facelift Ford Excursion 4x2 configurations.**

## Explicit exclusions

- every part-time 4x4 configuration, transfer case, front drive axle and 4x4 suspension;
- the intermediate 2001 7.3L calibration at 250 hp / 505 lb-ft;
- the 2005 facelift appearance;
- the Mexico-only 2006 continuation;
- Limited, Eddie Bauer, XLS/fleet, XLT Value/Premium and other trim duplicates;
- separate 3.73, 4.10 or 4.30 axle-ratio catalog rows;
- separate open and limited-slip differential rows;
- manual transmission configurations.

## Chassis and physics architecture

Every approved row must use the 4x2 Excursion architecture:

- body-on-frame Super Duty-derived chassis;
- longitudinal front engine and rear-wheel drive;
- Ford Twin-I-Beam independent front suspension with coil springs;
- solid rear drive axle on leaf springs;
- no transfer case, front driveshaft or driven front axle;
- year-, engine- and equipment-correct mass, axle loads, ride height and centre of gravity;
- heavy-SUV steering, braking, tyre and load-transfer behaviour.

A 4x4 chassis with its front driveline disabled, or a generic passenger-SUV suspension, is not acceptable.

## Transmission architecture assessment

The 5.4L, 6.8L and both 7.3L rows use the longitudinal 4R100 four-speed planetary automatic with a hydrodynamic torque converter. Each engine requires its documented converter, shift schedule, lock-up behaviour and thermal calibration.

The 6.0L uses the TorqShift 5R110W five-speed planetary automatic. It must remain a distinct transmission architecture with its own ratios, converter, adaptive shifting, tow/haul behaviour, lock-up strategy and thermal model.

Both transmissions require converter multiplication and slip, creep, progressive lock-up, exact forward and reverse ratios, torque and inertia shift phases, kickdown, grade/load scheduling and thermal protection.

## Engine-audio architecture assessment

| Engine | Required treatment |
|---|---|
| 5.4L Triton V8 | naturally aspirated Modular cross-plane V8 with displacement- and load-specific intake/exhaust |
| 6.8L Triton V10 | dedicated even-fire V10 cadence and collector grouping; never a pitch-shifted V8 |
| 7.3L Power Stroke early/late | Navistar T444E HEUI diesel V8 with fixed-geometry turbo; early and late calibrations may share architecture but require distinct torque and transient data |
| 6.0L Power Stroke | separate VT365 HEUI diesel profile with variable-geometry turbo and materially different combustion/transient behaviour |

The 7.3L and 6.0L must not share one generic diesel waveform.

## Evidence still required before parameter commitment

Before implementation retain exact Ford order-guide or service evidence for:

- the late-2003 7.3L-to-6.0L production split;
- exact 4R100 and 5R110W ratios, converter and engine-specific calibration;
- one standard axle code, ratio and differential state for every approved row;
- exact kerb mass, axle loads and centre of gravity;
- tyre sizes, drag, braking and documented performance targets.

These gaps do not reopen the five-row owner-approved catalog scope and do not authorize guessed hardware.

## Owner decision recorded

The owner decided:

1. Include 4x2 variants only.
2. Include every engine family: 5.4 V8, 6.8 V10, 7.3 diesel and 6.0 diesel.
3. Retain only the oldest and newest 7.3L calibrations, named **7.3 early** and **7.3 late**.
4. Preserve only the original pre-facelift XLT-style appearance.
5. Use one standard axle ratio and one standard differential state per engine/calibration.
6. Exclude the Mexico-only 2006 continuation.
7. Missing expected variants: **none identified by the owner**.

Model 06 is **`approved`** with **5** configurations. Implementation remains blocked by the global all-model research gate. Research proceeds to model 07.
