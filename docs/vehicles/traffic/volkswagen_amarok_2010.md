# Volkswagen Amarok I type 2H full-generation Double Cab — research and owner-scope gate

- Model number in Traffic Rider bundle: **23**
- Source GLB: `23_volkswagen_amarok_2010.glb`
- Source Git blob SHA-1: `2cb28a59e50ef4daf6707ae67a3d930de6a5687f`
- Source SHA-256: **pending direct binary hash capture before integration**
- Research date: 2026-07-16
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected during research: current `master` after `a22eb5ee8776ae3e4aa294de9de8fc57af69609a`; later master physics changes must be inspected again before implementation
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents a **first-generation Volkswagen Amarok type 2H from the original 2010 body phase**, most plausibly a four-door Double Cab with the standard cargo bed.

The source-body anchor is:

- original 2010–2016 four-cylinder front and rear treatment;
- four-door Double Cab passenger compartment;
- standard-width open pickup bed;
- body-on-frame stance with independent front suspension and a leaf-sprung live rear axle;
- ordinary production bumpers, arches and road/off-road ride height;
- no Single Cab, cab-chassis, extended-bed, hardtop, military or specialist body.

The research scope is intentionally wider than the source appearance. It now covers every evidenced factory engine calibration from the complete first-generation type 2H lifecycle, including the 2016 V6 facelift and the 2024 South-American visual update. Later body phases do not automatically create duplicate mechanical rows.

The committed inventory records **2,684 triangles**. Direct binary inspection remains required to confirm the node hierarchy, paired wheel meshes, AABB, wheel centres, front axis and wheelbase-derived scale.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Platform / generation | Volkswagen Amarok I, type 2H |
| Full-generation research phase | 2010 launch through the continuing South-American first-generation lifecycle |
| Source visual phase | original 2010–2016 Double Cab |
| First major facelift | 2016 V6 body/interior update |
| South-American visual update | 2024 second facelift; mechanically duplicate rows remain merged |
| Wheelbase | approximately 3,095 mm |
| Double Cab length | approximately 5,254 mm before regional facelift differences |
| Body width excluding mirrors | approximately 1,944 mm before regional facelift differences |
| Standard bed length | approximately 1,555 mm |
| Source triangles | 2,684 |
| Source Git blob SHA-1 | `2cb28a59e50ef4daf6707ae67a3d930de6a5687f` |
| Source topology and bounds | pending direct GLB inspection |

The committed GLB remains unchanged. Integration must create four independent hub-centred wheel nodes, explicit wheel bindings and project-authored collision. Scale must use the wheelbase as the primary reference and cross-check overall length, width, track and tyre diameter.

## Full first-generation research boundary

The candidate scope covers the complete **first-generation Amarok type 2H**, across original, 2016-facelift and 2024 South-American body states, provided that the powertrain was factory offered in this generation.

Nine production engine calibrations are retained for scope consideration:

1. **EA189 2.0 TDI 90 kW / 122 PS**, single-turbo common-rail diesel, approximately 340 Nm;
2. **EA189 2.0 BiTDI 120 kW / 163 PS**, sequential twin-turbo common-rail diesel, approximately 400 Nm;
3. **EA189 2.0 TDI 103 kW / 140 PS**, later single-turbo diesel revision, approximately 340 Nm;
4. **EA189 2.0 BiTDI 132 kW / 180 PS**, later twin-turbo diesel, approximately 400 Nm with manual transmission and 420-Nm-class automatic calibration;
5. **EA888 2.0 TSI 118 kW / 160 PS**, regional turbocharged direct-injection petrol inline-four, approximately 300 Nm;
6. **EA897 evo 3.0 V6 TDI DDXA, 120 kW / 163 PS**, approximately 450 Nm;
7. **EA897 evo 3.0 V6 TDI DDXB, 150 kW / 204 PS**, approximately 500 Nm;
8. **EA897 evo 3.0 V6 TDI DDXC, 165 kW / 224 PS**, approximately 550 Nm in the automatic calibration and 500 Nm in the Australian manual low-range calibration;
9. **EA897 evo 3.0 V6 TDI DDXE, 190 kW / 258 PS**, approximately 580 Nm.

The 2013 275-PS V6 Wörthersee pickup was a concept and is excluded. Audi/Porsche-only 250/272-PS EA897 calibrations are not Amarok production engines and are excluded. The Ford-derived engines of the second-generation Amarok are outside the type 2H generation.

Three fundamentally different drive systems must remain separate:

1. **Rear-wheel drive / 4×2** — longitudinal engine, gearbox, prop shaft and live rear axle only.
2. **Selectable 4MOTION** — part-time transfer case with driver-selectable rear drive, high-range four-wheel drive and low range; no centre differential in locked 4WD operation.
3. **Permanent 4MOTION** — full-time four-wheel drive through a torque-sensing centre differential with a rear-biased nominal split; no selectable low range in the eight-speed automatic architecture.

## Mechanically consolidated candidate matrix

### Original 2010–2012 diesel range — 5 candidates

| # | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|
| 1 | EA189 2.0 TDI 90 kW / 122 PS, approximately 340 Nm | 6-speed conventional manual | RWD / 4×2 | `verified_family` |
| 2 | EA189 2.0 TDI 90 kW / 122 PS | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | `verified_family` |
| 3 | EA189 2.0 BiTDI 120 kW / 163 PS, approximately 400 Nm | 6-speed conventional manual | RWD / 4×2 | `verified_family` |
| 4 | EA189 2.0 BiTDI 120 kW / 163 PS | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | `verified_family` |
| 5 | EA189 2.0 BiTDI 120 kW / 163 PS | 6-speed conventional manual | permanent 4MOTION with torque-sensing centre differential | `drive_concept_verified`; exact market and final-drive application evidence blocked |

### Updated 2012–2016 four-cylinder diesel range — 6 candidates

| # | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|
| 6 | EA189 2.0 TDI 103 kW / 140 PS, approximately 340 Nm | 6-speed conventional manual | RWD / 4×2 | `verified_family` |
| 7 | EA189 2.0 TDI 103 kW / 140 PS | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | `verified_family` |
| 8 | EA189 2.0 BiTDI 132 kW / 180 PS, manual calibration | 6-speed conventional manual | RWD / 4×2 | `verified_family` |
| 9 | EA189 2.0 BiTDI 132 kW / 180 PS, manual calibration | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | `verified_family` |
| 10 | EA189 2.0 BiTDI 132 kW / 180 PS, approximately 420-Nm automatic calibration | ZF-engineered 8-speed hydrodynamic torque-converter planetary automatic | RWD / 4×2 | `regional_application_evidence_blocked`; exact ordering market and gearbox suffix require primary data |
| 11 | EA189 2.0 BiTDI 132 kW / 180 PS, approximately 420-Nm automatic calibration | ZF-engineered 8-speed hydrodynamic torque-converter planetary automatic | permanent 4MOTION with torque-sensing centre differential | `verified_family` |

### Regional four-cylinder petrol range — 1 candidate

| # | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|
| 12 | EA888 2.0 TSI 118 kW / 160 PS, approximately 300 Nm | 6-speed conventional manual | RWD / 4×2 | `regional_application_verified_family`; exact market dates and code evidence blocked |

### 2016-onward V6 diesel range — 7 candidates

| # | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|
| 13 | EA897 evo DDXA 3.0 V6 TDI 120 kW / 163 PS, approximately 450 Nm | 6-speed conventional manual | RWD / 4×2 | `engine_verified`; exact RWD ordering application evidence blocked |
| 14 | EA897 evo DDXA 3.0 V6 TDI 120 kW / 163 PS | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | `engine_and_architecture_verified`; exact market table required |
| 15 | EA897 evo DDXB 3.0 V6 TDI 150 kW / 204 PS, approximately 500 Nm | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | `verified_family`; gearbox suffix and market restrictions require primary data |
| 16 | EA897 evo DDXB 3.0 V6 TDI 150 kW / 204 PS | ZF-engineered 8-speed hydrodynamic torque-converter planetary automatic | permanent 4MOTION with torque-sensing centre differential | `verified_family` |
| 17 | EA897 evo DDXC 3.0 V6 TDI 165 kW / 224 PS, approximately 550 Nm | ZF-engineered 8-speed hydrodynamic torque-converter planetary automatic | permanent 4MOTION with torque-sensing centre differential | `verified` |
| 18 | EA897 evo 3.0 V6 TDI 165 kW / 224 PS, Australian TDI500 calibration at approximately 500 Nm | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | `verified_regional_family`; exact engine suffix and ratios require primary Australian data |
| 19 | EA897 evo DDXE 3.0 V6 TDI 190 kW / 258 PS, approximately 580 Nm | ZF-engineered 8-speed hydrodynamic torque-converter planetary automatic | permanent 4MOTION with torque-sensing centre differential | `verified` |

**Mechanically consolidated candidate total: 19 full-generation Amarok I configurations.**

Rows 5, 10, 12, 13, 14, 15 and 18 remain confirmation-gated in at least one market, gearbox-code, engine-suffix or drivetrain-application detail. Primary Volkswagen ordering data may remove or refine a row, but unsupported combinations may not be invented.

## Uncounted combinations requiring primary confirmation

The following possibilities are not counted because current evidence does not establish a complete factory engine, gearbox and drive-system combination:

- 122-PS or 140-PS permanent 4MOTION;
- 163-PS or 140-PS eight-speed automatic;
- 180-PS six-speed-manual permanent 4MOTION without low range;
- 2.0 TSI selectable or permanent 4MOTION;
- V6 163 PS with eight-speed automatic permanent 4MOTION;
- V6 204 PS in RWD form;
- V6 224 PS or 258 PS in RWD form;
- V6 258 PS with six-speed manual and selectable low range;
- any automatic paired with the selectable low-range transfer case.

A primary price list, type-approval table or service application list may promote one of these to the matrix. Until then, each remains excluded rather than guessed.

## Facelift and body policy candidates

The first generation has at least three relevant visual states:

1. original 2010–2016 four-cylinder body represented by the source GLB;
2. 2016–2024 V6 facelift with revised front, interior and V6-specific details;
3. 2024 South-American second facelift, which remains on the first-generation type 2H structure.

Recommended implementation policy:

- use the source-like Double Cab and standard bed for all mechanical rows unless the owner requests project-authored facelift derivatives;
- if one common source body is used, record V6 and 2024 rows as explicit visual homogenizations rather than claiming factory visual accuracy;
- do not create duplicate catalog rows solely for the 2016 or 2024 appearance when engine, gearbox, drivetrain and calibration are unchanged;
- use one representative unladen/light-payload state per powertrain row;
- assign drivetrain-correct kerb mass, front/rear axle load, centre of gravity, suspension, brakes and tyre calibration;
- preserve transfer-case hardware on selectable 4MOTION and the centre differential on permanent 4MOTION;
- omit Single Cab, cab-chassis, bed-length, payload, trim, wheel and special-edition duplicates.

## Transmission and 4MOTION architecture requirements

### Six-speed manual

The manual requires its exact gearset, reverse ratio, clutch capacity, flywheel behaviour and final drive. V6 and four-cylinder manuals may not share ratios unless primary documentation proves the same gearbox application. The low first gear does not replace the selectable transfer-case reduction.

### Selectable 4MOTION

The part-time system requires:

- explicit 2H, 4H and 4L states where documented;
- transfer-case high and low ratios;
- front prop shaft, front differential and half-shafts;
- locked front/rear coupling behaviour in 4H/4L;
- driveline wind-up protection on high-grip surfaces;
- low-range engine, clutch and brake control;
- optional rear differential lock only when selected as the one standard row state.

It may not be represented by a generic traction multiplier.

### Permanent 4MOTION

The permanent system requires a continuously driven front axle and torque-sensing centre differential with the verified nominal front/rear split and locking response. It must remain mechanically distinct from the selectable transfer case.

### Eight-speed automatic

The eight-speed is a conventional hydrodynamic torque-converter planetary automatic. It requires converter multiplication, creep, progressive lock-up, hydraulic clutch-to-clutch shifts, kickdown, thermal behaviour and the exact ratio/final-drive set. It is not DSG and may not reuse a dual-clutch or shortened manual-shift model.

## Chassis and performance requirements

Every retained row requires:

- ladder frame, independent double-wishbone front suspension and leaf-sprung live rear axle;
- drivetrain- and body-phase-correct mass and load distribution;
- tyre, brake, steering and differential calibration;
- pickup-body drag and frontal area;
- correct payload-sensitive centre of gravity without using cargo mass to hide an incorrect kerb setup;
- validation against documented top speed, acceleration, gradeability, towing and low-range targets where available.

Performance may not be matched through false torque, arbitrary speed caps or one shared drivetrain-loss value.

## Engine and driveline audio architecture

Four combustion families are required:

1. **EA189 2.0 single-turbo TDI** — common-rail inline-four diesel with output-specific injection, turbo spool, combustion harshness and governor calibration.
2. **EA189 2.0 BiTDI** — sequential twin-turbo inline-four diesel with low/high-pressure turbo transition and distinct 163/180-PS calibrations.
3. **EA888 2.0 TSI** — turbocharged direct-injection petrol inline-four with petrol combustion, intake, wastegate, exhaust and overrun behaviour.
4. **EA897 evo 3.0 V6 TDI** — dedicated V6 common-rail diesel architecture with six-cylinder firing cadence, SCR/DPF exhaust path, variable-geometry turbo behaviour and separate 163/204/224/258-PS boost, injection, governor and exhaust calibrations.

The V6 may not be created by pitch-shifting the inline-four diesel waveform. Its bank geometry, firing order, firing intervals, collector routing and turbo/exhaust behaviour must be researched and synthesized from first principles. Selectable low range, permanent 4MOTION, rear differential lock, automatic converter and pickup-bed/body resonance require drivetrain-specific audio layers.

## Evidence still required before parameter commitment

Before implementation retain primary Volkswagen Commercial Vehicles brochures, price lists, type-approval data, workshop manuals and self-study material for:

- exact engine codes and production dates for all nine retained calibrations;
- valid engine/transmission/drive-system combinations by market, body and facelift phase;
- six-speed manual gearbox codes, all forward/reverse ratios, clutch and final drive;
- eight-speed automatic code/suffix, all ratios, converter characteristics, lock-up and shift controls;
- selectable transfer-case high/low ratios and engagement restrictions;
- permanent 4MOTION centre-differential type, nominal torque split and locking response;
- rear differential options and one standard state per row;
- sampled torque curves, idle, rev limit, turbo control, SCR/DPF controls and engine-brake behaviour;
- kerb mass, payload, axle ratings, wheelbase, track, centre of gravity, tyres, brakes and steering;
- drag, frontal area and documented acceleration, top-speed, towing and gradeability targets;
- direct GLB SHA-256, hierarchy, wheel centres, AABB, front axis and scale.

The engine families and three driveline architectures are established, but seven rows and all exact ratio/final-drive data remain confirmation-gated.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Include all 19 candidate configurations across the complete first generation?
2. Include all nine engine calibrations, including V6 163, 204, 224 and 258 PS?
3. Include all three drivetrain architectures: RWD, selectable low-range 4MOTION and permanent 4MOTION?
4. Include the Australian V6 224-PS six-speed-manual low-range row?
5. Retain evidence-blocked rows 5, 10, 12, 13, 14, 15 and 18 pending primary Volkswagen confirmation?
6. Use the original source Double Cab body for all rows as an explicit visual homogenization, or require separate project-authored 2016 and 2024 facelift derivatives?
7. Merge facelift/body-phase duplicates when their mechanical configuration is unchanged?
8. Omit Single Cab, cab-chassis, bed, payload, trim, wheel and special-edition duplicates?
9. Exclude concepts, non-Amarok EA897 calibrations, conversions and all second-generation engines?
10. Is an expected first-generation Amarok engine, transmission or drivetrain combination missing?

This is the final individual model gate. After the owner fixes model 23 scope, every included model will have a decided research scope and the global implementation gate may move to its next stage.