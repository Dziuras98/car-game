# Land Rover Freelander 2 / LR2 L359 — research and approved scope

- Model number in Traffic Rider bundle: **09**
- Source GLB: `09_land_rover_freelander_2_2012.glb`
- Source SHA-256: `ba2cd619b59ff52a0e44ff48e17ea5fc91f89d59cdb4012597dc3b2628a20191`
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **8 mechanically distinct Freelander 2 / LR2 engine, transmission and drivetrain configurations**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity and common HSE policy

The source represents a **North American 2012 Land Rover LR2 HSE**, equivalent to the Freelander 2 L359, using the 2011–2012 first-facelift appearance.

Visible source evidence includes `LR2` and `HSE` rear badging, North American plate treatment, five-door L359 body, first-facelift grille, bumper, lamps, fog lamps, side vents and HSE-style alloy wheels.

The owner approved one common visual/equipment presentation for all eight powertrains:

- source-like 2011–2012 LR2 HSE exterior;
- one HSE-style trim rather than S, GS/SE, HST, Dynamic or market-package duplicates;
- no separate original 2007–2010 or second-facelift 2013–2014 body derivative;
- real engine and model-year availability remains metadata even when the source HSE appearance is reused.

This is an explicit project visual homogenization. It is not a claim that eD4, early TD4 or Si4 were all sold with the exact 2012 North American HSE exterior.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Wheelbase | approximately 2,660 mm / 2.660 m |
| Overall length | approximately 4,500 mm / 4.500 m |
| Width excluding mirrors | approximately 1,910 mm / 1.910 m |
| Height | approximately 1,740 mm / 1.740 m |
| Source meshes | 3 |
| Body mesh | `AI_Freelander_High_LR_Freelander_LR2_2012_0` |
| Front wheel-pair mesh | `on_teker.008_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.009_wheel_0` |
| Body triangles | 1,410 |
| Front wheel-pair triangles | 360 |
| Rear wheel-pair triangles | 360 |
| Total triangles | 2,130 |
| Source scene AABB | approximately 3.062419 × 2.439575 × 6.475932 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 3.877631 source units |
| Approximate wheelbase-derived scale | 0.685986 |

The committed GLB remains unchanged. Four independent wheels, collision, catalog, physics, transmission and audio work remain deferred by the global research gate.

## Owner-directed scope rules

- include all eight researched engine/transmission/drivetrain configurations;
- include the front-wheel-drive eD4 as a genuine separate chassis architecture;
- keep manual and automatic TD4 versions separate;
- use one verified standard final-drive ratio and one standard differential/Haldex-coupling state per row;
- do not create optional gearing, differential or coupling-generation duplicates;
- retain Haldex generation, stop/start, DPF, catalyst, EGR and emissions-standard revisions as selected-year metadata;
- use one common source-like HSE appearance;
- exclude LPG and all other non-core conversions;
- no expected production configuration is missing according to the owner.

## Approved configuration matrix

| # | Model-year application | Engine / calibration | Transmission | Drivetrain | Status |
|---:|---|---|---|---|---|
| 1 | 2007–2010 | 2.2L TD4 common-rail turbo-diesel inline-four, approximately 160 PS / 400 Nm | six-speed conventional manual transaxle, working identification Getrag/Ford M66-family | on-demand AWD; one standard final drive and Haldex/differential state | **approved** |
| 2 | 2007–2010 | 2.2L TD4 common-rail turbo-diesel inline-four, approximately 160 PS / 400 Nm | Aisin AWF21 / TF-80SC-family six-speed planetary torque-converter automatic | on-demand AWD; one standard final drive and Haldex/differential state | **approved** |
| 3 | 2007–2012 | Volvo SI6 3.2L naturally aspirated transverse inline-six petrol, approximately 233 PS / 317 Nm; North American rating approximately 230 hp | Aisin AWF21 / TF-80SC-family six-speed planetary torque-converter automatic | on-demand AWD; one standard final drive and Haldex/differential state | **approved** |
| 4 | 2011–2014 | 2.2L eD4 turbo-diesel inline-four, 150 PS / approximately 400 Nm | six-speed conventional manual transaxle with stop/start where selected | **front-wheel drive only**; one standard final drive and differential | **approved** |
| 5 | 2011–2014 | 2.2L TD4 turbo-diesel inline-four, 150 PS / approximately 420 Nm | six-speed conventional manual transaxle | on-demand AWD; one standard final drive and Haldex/differential state | **approved** |
| 6 | 2011–2014 | 2.2L TD4 turbo-diesel inline-four, 150 PS / approximately 420 Nm | Aisin AWF21 / TF-80SC-family six-speed planetary torque-converter automatic | on-demand AWD; one standard final drive and Haldex/differential state | **approved** |
| 7 | 2011–2014 | 2.2L SD4 turbo-diesel inline-four, 190 PS / approximately 420–430 Nm | Aisin AWF21 / TF-80SC-family six-speed planetary torque-converter automatic | on-demand AWD; one standard final drive and Haldex/differential state | **approved** |
| 8 | 2013–2014 | 2.0L Si4 direct-injected turbocharged petrol inline-four, approximately 240–241 PS / 340 Nm | Aisin AWF21 / TF-80SC-family six-speed planetary torque-converter automatic | on-demand AWD; one standard final drive and Haldex/differential state | **approved** |

**Approved total: 8 mechanically distinct Land Rover Freelander 2 / LR2 L359 configurations.**

## Explicit exclusions

- trim duplicates including S, GS/SE, HST and Dynamic;
- separate original and second-facelift visual bodies;
- optional final-drive ratios;
- separate Haldex-generation or coupling-calibration catalog rows;
- separate DPF/non-DPF, Euro-standard, EGR, catalyst or stop/start rows;
- LPG, CNG and other aftermarket or fleet fuel conversions;
- merging manual and automatic TD4 rows;
- implementing eD4 as an AWD vehicle with the rear driveline merely disabled.

## Drivetrain architecture

### eD4 front-wheel drive

The eD4 omits the AWD power-transfer unit, prop shaft, Haldex coupling, driven rear final drive and rear half-shafts. It also lacks the AWD Terrain Response and Hill Descent Control implementation. It requires its own mass, inertia, traction, torque-steer and rear-axle calibration.

### AWD rows

The seven AWD configurations require a transverse engine and transaxle, front differential and half-shafts, power-transfer unit, prop shaft, electronically controlled Haldex rear coupling, rear final drive and rear half-shafts. The system must coordinate with Terrain Response and stability control where fitted.

Haldex generation and control-map changes remain mandatory selected-year metadata. The AWD system must not be represented as a generic fixed 50:50 centre differential.

## Transmission architecture assessment

Manual diesel rows require a driver-operated dry clutch and a real six-speed transaxle with exact forward and reverse ratios, final drive, clutch capacity and inertia, synchronizer behaviour, launch, engine braking and stop/start integration where applicable.

The 3.2 i6, automatic TD4, SD4 and Si4 use the transverse Aisin AWF21 / TF-80SC-family six-speed planetary automatic with a hydrodynamic torque converter. It requires converter multiplication and slip, creep, progressive lock-up, exact forward and reverse ratios, torque and inertia shift phases, multi-gear kickdown, grade/load scheduling, thermal protection and AWD-coupling coordination.

## Engine and driveline audio architecture

| Engine | Required treatment |
|---|---|
| 2.2 TD4 early 160 | early common-rail four-cylinder diesel combustion, turbo and emissions layers |
| 2.2 eD4 / TD4 150 | later diesel architecture with calibration-specific boost, injection, stop/start and load response |
| 2.2 SD4 190 | distinct higher-output turbo and combustion response |
| 3.2 SI6 | dedicated naturally aspirated transverse inline-six firing cadence, intake resonance and exhaust grouping |
| 2.0 Si4 | dedicated direct-injected turbo petrol inline-four with compressor, turbine, wastegate/bypass and boosted induction response |

The SI6 may not be synthesized from a V6 waveform, and the Si4 may not be a naturally aspirated four-cylinder waveform with generic turbo noise.

## Evidence still required before parameter commitment

Before implementation retain primary Land Rover workshop, order-guide or technical evidence for:

- exact model-year and market restrictions;
- manual gearbox codes, ratios, clutch and final drives;
- AWF21/TF-80SC ratios, converter and engine-specific calibration;
- Haldex generation, coupling limits, rear final drive and control maps by selected year;
- one standard final-drive ratio and differential/coupling state per approved row;
- selected-year DPF, catalyst, EGR and stop/start hardware;
- exact kerb mass, axle loads, tyres, brakes, drag and performance targets;
- source HSE wheel and tyre size.

These gaps do not reopen the eight-row approved catalog scope and do not authorize guessed parameters.

## Owner decision recorded

The owner decided:

1. Include all eight researched configurations.
2. Include eD4 FWD and all seven AWD configurations.
3. Preserve manual and automatic variants as separate mechanical rows.
4. Use one common HSE-style version without trim duplication.
5. Use one standard final drive and one standard differential/Haldex state per row.
6. Store Haldex generation, stop/start and emissions revisions as selected-year metadata.
7. Exclude LPG and other conversions.
8. Missing expected variants: **none identified by the owner**.

Model 09 is **`approved`** with **8** configurations. Implementation remains blocked by the global all-model research gate. Research proceeds to model 10.