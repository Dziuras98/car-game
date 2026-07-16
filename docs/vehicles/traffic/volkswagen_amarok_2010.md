# Volkswagen Amarok I type 2H full-generation Double Cab — research and approved scope

- Model number in Traffic Rider bundle: **23**
- Source GLB: `23_volkswagen_amarok_2010.glb`
- Source Git blob SHA-1: `2cb28a59e50ef4daf6707ae67a3d930de6a5687f`
- Source SHA-256: **pending direct binary hash capture before integration**
- Research date: 2026-07-16
- Owner decision date: 2026-07-16
- Workflow status: **`approved`**
- Approved implementation scope: **19 full-generation Volkswagen Amarok I configurations**
- Physics dependency: **implementation is blocked until PR #118 (`Rework per-wheel vehicle physics and recalibrate DPI v3`) is completed and its final physics changes are integrated into `master`**
- Physics baseline inspected during research: historical `master` after `a22eb5ee8776ae3e4aa294de9de8fc57af69609a`; this is not an implementation baseline

## Visual identity and approved body policy

The source represents a **first-generation Volkswagen Amarok type 2H from the original 2010 body phase**, most plausibly a four-door Double Cab with the standard cargo bed.

The source-body anchor is:

- original 2010–2016 four-cylinder front and rear treatment;
- four-door Double Cab passenger compartment;
- standard-width open pickup bed;
- body-on-frame stance with independent front suspension and a leaf-sprung live rear axle;
- ordinary production bumpers, arches and road/off-road ride height;
- no Single Cab, cab-chassis, extended-bed, hardtop, military or specialist body.

The approved mechanical scope is wider than the source appearance. It covers every retained factory engine calibration from the complete first-generation type 2H lifecycle, including the 2016 V6 facelift and the 2024 South-American visual update.

The owner approved all 19 mechanical configurations and did not request separate facelift geometry. Therefore every retained row uses the original source Double Cab body as an explicit visual homogenization. V6 and 2024 rows retain their correct mechanical, mass, drivetrain and performance calibration, but no claim is made that the original 2010 exterior is visually exact for those later phases. Mechanically duplicate facelift rows remain merged.

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

## Approved full-generation research boundary

The approved scope covers the complete **first-generation Amarok type 2H**, across original, 2016-facelift and 2024 South-American body states, provided that the powertrain was factory offered in this generation.

Nine production engine calibrations are retained:

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

Three fundamentally different drive systems remain separate:

1. **Rear-wheel drive / 4×2** — longitudinal engine, gearbox, prop shaft and live rear axle only.
2. **Selectable 4MOTION** — part-time transfer case with driver-selectable rear drive, high-range four-wheel drive and low range; no centre differential in locked 4WD operation.
3. **Permanent 4MOTION** — full-time four-wheel drive through a torque-sensing centre differential with a rear-biased nominal split; no selectable low range in the eight-speed automatic architecture.

## Approved configuration matrix

### Original 2010–2012 diesel range — 5 configurations

| # | Engine / calibration | Transmission | Drivetrain | Status |
|---:|---|---|---|---|
| 1 | EA189 2.0 TDI 90 kW / 122 PS, approximately 340 Nm | 6-speed conventional manual | RWD / 4×2 | **approved** |
| 2 | EA189 2.0 TDI 90 kW / 122 PS | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | **approved** |
| 3 | EA189 2.0 BiTDI 120 kW / 163 PS, approximately 400 Nm | 6-speed conventional manual | RWD / 4×2 | **approved** |
| 4 | EA189 2.0 BiTDI 120 kW / 163 PS | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | **approved** |
| 5 | EA189 2.0 BiTDI 120 kW / 163 PS | 6-speed conventional manual | permanent 4MOTION with torque-sensing centre differential | **approved scope / market and final-drive evidence blocked** |

### Updated 2012–2016 four-cylinder diesel range — 6 configurations

| # | Engine / calibration | Transmission | Drivetrain | Status |
|---:|---|---|---|---|
| 6 | EA189 2.0 TDI 103 kW / 140 PS, approximately 340 Nm | 6-speed conventional manual | RWD / 4×2 | **approved** |
| 7 | EA189 2.0 TDI 103 kW / 140 PS | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | **approved** |
| 8 | EA189 2.0 BiTDI 132 kW / 180 PS, manual calibration | 6-speed conventional manual | RWD / 4×2 | **approved** |
| 9 | EA189 2.0 BiTDI 132 kW / 180 PS, manual calibration | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | **approved** |
| 10 | EA189 2.0 BiTDI 132 kW / 180 PS, approximately 420-Nm automatic calibration | ZF-engineered 8-speed hydrodynamic torque-converter planetary automatic | RWD / 4×2 | **approved scope / regional application and gearbox suffix evidence blocked** |
| 11 | EA189 2.0 BiTDI 132 kW / 180 PS, approximately 420-Nm automatic calibration | ZF-engineered 8-speed hydrodynamic torque-converter planetary automatic | permanent 4MOTION with torque-sensing centre differential | **approved** |

### Regional four-cylinder petrol range — 1 configuration

| # | Engine / calibration | Transmission | Drivetrain | Status |
|---:|---|---|---|---|
| 12 | EA888 2.0 TSI 118 kW / 160 PS, approximately 300 Nm | 6-speed conventional manual | RWD / 4×2 | **approved scope / exact market dates and engine code evidence blocked** |

### 2016-onward V6 diesel range — 7 configurations

| # | Engine / calibration | Transmission | Drivetrain | Status |
|---:|---|---|---|---|
| 13 | EA897 evo DDXA 3.0 V6 TDI 120 kW / 163 PS, approximately 450 Nm | 6-speed conventional manual | RWD / 4×2 | **approved scope / exact RWD ordering application evidence blocked** |
| 14 | EA897 evo DDXA 3.0 V6 TDI 120 kW / 163 PS | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | **approved scope / exact market table evidence blocked** |
| 15 | EA897 evo DDXB 3.0 V6 TDI 150 kW / 204 PS, approximately 500 Nm | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | **approved scope / gearbox suffix and market restrictions evidence blocked** |
| 16 | EA897 evo DDXB 3.0 V6 TDI 150 kW / 204 PS | ZF-engineered 8-speed hydrodynamic torque-converter planetary automatic | permanent 4MOTION with torque-sensing centre differential | **approved** |
| 17 | EA897 evo DDXC 3.0 V6 TDI 165 kW / 224 PS, approximately 550 Nm | ZF-engineered 8-speed hydrodynamic torque-converter planetary automatic | permanent 4MOTION with torque-sensing centre differential | **approved** |
| 18 | EA897 evo 3.0 V6 TDI 165 kW / 224 PS, Australian TDI500 calibration at approximately 500 Nm | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | **approved scope / exact engine suffix and ratios evidence blocked** |
| 19 | EA897 evo DDXE 3.0 V6 TDI 190 kW / 258 PS, approximately 580 Nm | ZF-engineered 8-speed hydrodynamic torque-converter planetary automatic | permanent 4MOTION with torque-sensing centre differential | **approved** |

**Approved total: 5 original diesel + 6 updated diesel + 1 regional petrol + 7 V6 = 19 full-generation Amarok I configurations.**

Rows 5, 10, 12, 13, 14, 15 and 18 remain confirmation-gated in at least one market, gearbox-code, engine-suffix or drivetrain-application detail. They are retained in the approved scope, but no implementation may invent missing transmission architecture, ratios, final drive, engine suffix or market application. A row whose complete factory application cannot be confirmed before parameter commitment must remain unimplemented rather than receive guessed data.

## Explicitly uncounted combinations

The following possibilities remain outside the approved matrix because current evidence does not establish a complete factory engine, gearbox and drive-system combination:

- 122-PS or 140-PS permanent 4MOTION;
- 163-PS or 140-PS eight-speed automatic;
- 180-PS six-speed-manual permanent 4MOTION without low range;
- 2.0 TSI selectable or permanent 4MOTION;
- V6 163 PS with eight-speed automatic permanent 4MOTION;
- V6 204 PS in RWD form;
- V6 224 PS or 258 PS in RWD form;
- V6 258 PS with six-speed manual and selectable low range;
- any automatic paired with the selectable low-range transfer case.

A primary price list, type-approval table or service application list may promote one of these only through a new owner-scope amendment. Until then, each remains excluded rather than guessed.

## Approved body, payload and duplicate policy

- use the original source-like Double Cab and standard bed for all 19 rows as an explicit visual homogenization;
- retain correct facelift-era mechanical mass, brakes, tyres, suspension and drivetrain calibration even where the exterior remains the original mesh;
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

## Mandatory PR #118 implementation dependency

Research and owner-scope work are complete, but implementation remains prohibited while PR #118 is unfinished.

No Traffic Rider vehicle may enter `integrating`, and no source relocation, processed GLB, runtime scene, catalog resource, transmission implementation, engine-audio implementation or physics calibration may be committed until all of the following are true:

1. PR #118, **Rework per-wheel vehicle physics and recalibrate DPI v3**, is completed and its final physics changes are merged into `master`, or an explicitly identified successor carrying the same work is merged instead;
2. this Traffic Rider branch is synchronized with that resulting `master`;
3. the final physics commit is recorded as the implementation baseline;
4. changes to per-wheel contact, slip, load transfer, drivetrain inertia, differentials, AWD, braking, steering/yaw, drag, transmissions and DPI/performance evaluation are reviewed;
5. the integration plan and every shared calibration assumption are updated for the new interfaces;
6. the full current test suite passes before model 01 moves to `integrating`.

Closing PR #118 without integrating its intended physics work does not satisfy the dependency unless the owner explicitly identifies a merged successor.

## Owner decision recorded

The owner approved all 19 researched first-generation Amarok configurations, including all nine engine calibrations, all four V6 outputs, the Australian manual low-range V6 row and all seven evidence-blocked rows. The original source Double Cab is retained as the common visual body, mechanically duplicate facelift entries remain merged, and concepts, non-Amarok calibrations, conversions and second-generation engines remain excluded.

Model 23 is **`approved`** with **19** configurations. All 20 Traffic Rider model scopes are now approved. Implementation remains blocked by the mandatory PR #118 physics dependency.