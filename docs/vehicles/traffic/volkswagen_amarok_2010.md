# Volkswagen Amarok 2010 double-cab pre-V6 — research and owner-scope gate

- Model number in Traffic Rider bundle: **23**
- Source GLB: `23_volkswagen_amarok_2010.glb`
- Source Git blob SHA-1: `2cb28a59e50ef4daf6707ae67a3d930de6a5687f`
- Source SHA-256: **pending direct binary hash capture before integration**
- Research date: 2026-07-16
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected during research: current `master` after `a22eb5ee8776ae3e4aa294de9de8fc57af69609a`; later master physics changes must be inspected again before implementation
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents a **first-generation Volkswagen Amarok type 2H from the original 2010 pre-V6 body phase**, most plausibly the launch-period four-door Double Cab with the standard cargo bed.

The source-body anchor is:

- pre-2016 four-cylinder Amarok front and rear treatment;
- four-door Double Cab passenger compartment;
- standard-width open pickup bed;
- body-on-frame stance with independent front suspension and a leaf-sprung live rear axle;
- ordinary production bumpers, arches and road/off-road ride height;
- no 2016 V6 front-end revision;
- no Single Cab, cab-chassis, extended-bed, hardtop, military or specialist body.

The committed inventory records **2,684 triangles**. Direct binary inspection remains required to confirm the node hierarchy, paired wheel meshes, AABB, wheel centres, front axis and wheelbase-derived scale.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Platform / generation | Volkswagen Amarok I, type 2H |
| Strict source-era body | 2010 launch-period pre-V6 Double Cab |
| Candidate research phase | four-cylinder pre-V6 range, 2010–2016 |
| Wheelbase | approximately 3,095 mm |
| Double Cab length | approximately 5,254 mm |
| Body width excluding mirrors | approximately 1,944 mm |
| Standard bed length | approximately 1,555 mm |
| Source triangles | 2,684 |
| Source Git blob SHA-1 | `2cb28a59e50ef4daf6707ae67a3d930de6a5687f` |
| Source topology and bounds | pending direct GLB inspection |

The committed GLB remains unchanged. Integration must create four independent hub-centred wheel nodes, explicit wheel bindings and project-authored collision. Scale must use the wheelbase as the primary reference and cross-check overall length, width, track and tyre diameter.

## Research boundary

The candidate scope covers the **four-cylinder first-generation Amarok before the 2016 V6 revision**, retaining mechanically distinct powertrain and drive-system combinations from the original 122/163-PS range and the later 140/180-PS update.

Five engine calibrations are relevant:

- **2.0 TDI 90 kW / 122 PS**, EA189 single-turbo common-rail diesel, approximately 340 Nm;
- **2.0 BiTDI 120 kW / 163 PS**, EA189 sequential twin-turbo common-rail diesel, approximately 400 Nm;
- **2.0 TDI 103 kW / 140 PS**, later single-turbo diesel revision, approximately 340 Nm;
- **2.0 BiTDI 132 kW / 180 PS**, later sequential twin-turbo diesel revision, approximately 400 Nm with manual transmission and 420-Nm-class automatic calibration;
- **2.0 TSI 118 kW / 160 PS**, regional EA888 turbocharged direct-injection petrol inline-four, approximately 300 Nm.

Three fundamentally different drive systems must remain separate:

1. **Rear-wheel drive / 4×2** — longitudinal engine, gearbox, prop shaft and live rear axle only.
2. **Selectable 4MOTION** — part-time transfer case with driver-selectable rear drive, high-range four-wheel drive and low range; no centre differential in locked 4WD operation.
3. **Permanent 4MOTION** — full-time four-wheel drive through a torque-sensing centre differential with a rear-biased nominal split; no selectable low range in the four-cylinder automatic architecture.

The boundary excludes:

- all 3.0 V6 TDI engines and the 2016 exterior revision;
- later South American facelifts;
- special-edition-only cosmetic packages;
- aftermarket engine tuning, LPG/CNG conversions and competition vehicles;
- body duplicates that do not change the mechanical powertrain.

## Mechanically consolidated candidate matrix

### Original 2010–2012 diesel range — 5 candidates

| # | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|
| 1 | EA189 2.0 TDI 90 kW / 122 PS, approximately 340 Nm | 6-speed conventional manual | RWD / 4×2 | `verified_family` |
| 2 | EA189 2.0 TDI 90 kW / 122 PS | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | `verified_family` |
| 3 | EA189 2.0 BiTDI 120 kW / 163 PS, approximately 400 Nm | 6-speed conventional manual | RWD / 4×2 | `verified_family` |
| 4 | EA189 2.0 BiTDI 120 kW / 163 PS | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | `verified_family` |
| 5 | EA189 2.0 BiTDI 120 kW / 163 PS | 6-speed conventional manual | permanent 4MOTION with Torsen-type centre differential | `drive_concept_verified`; exact market and gearbox/final-drive application evidence blocked |

### Updated 2012–2016 diesel range — 6 candidates

| # | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|
| 6 | EA189 2.0 TDI 103 kW / 140 PS, approximately 340 Nm | 6-speed conventional manual | RWD / 4×2 | `verified_family` |
| 7 | EA189 2.0 TDI 103 kW / 140 PS | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | `verified_family` |
| 8 | EA189 2.0 BiTDI 132 kW / 180 PS, manual calibration | 6-speed conventional manual | RWD / 4×2 | `verified_family` |
| 9 | EA189 2.0 BiTDI 132 kW / 180 PS, manual calibration | 6-speed conventional manual | selectable 4MOTION with high/low transfer case | `verified_family` |
| 10 | EA189 2.0 BiTDI 132 kW / 180 PS, approximately 420-Nm automatic calibration | ZF 8-speed hydrodynamic torque-converter planetary automatic | RWD / 4×2 | `regional_application_evidence_blocked`; exact ordering market and gearbox suffix require primary data |
| 11 | EA189 2.0 BiTDI 132 kW / 180 PS, approximately 420-Nm automatic calibration | ZF 8-speed hydrodynamic torque-converter planetary automatic | permanent 4MOTION with torque-sensing centre differential | `verified_family` |

### Regional petrol range — 1 candidate

| # | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|
| 12 | EA888 2.0 TSI 118 kW / 160 PS, approximately 300 Nm | 6-speed conventional manual | RWD / 4×2 | `regional_application_verified_family`; exact market dates and code evidence blocked |

**Mechanically consolidated candidate total: 12 pre-V6 Amarok configurations.**

Rows 5, 10 and 12 remain confirmation-gated. Primary Volkswagen ordering data may remove a row or refine its market, engine code, gearbox suffix and final drive, but no unsupported combination may be invented.

## Uncounted combinations requiring primary confirmation

The following possibilities are not counted because current evidence does not establish a complete factory combination:

- 122-PS permanent 4MOTION;
- 140-PS permanent 4MOTION;
- 163-PS or 140-PS eight-speed automatic;
- 180-PS six-speed-manual permanent 4MOTION without low range;
- 2.0 TSI selectable or permanent 4MOTION;
- any four-cylinder automatic with the selectable low-range transfer case.

A primary price list or type-approval table may promote one of these to the matrix. Until then, they remain excluded rather than guessed.

## Body, payload and axle policy candidates

Recommended policy:

- use the source-like pre-V6 Double Cab and standard bed for every approved row;
- use one representative unladen/light-payload state per powertrain row;
- assign drivetrain-correct kerb mass, front/rear axle load, centre of gravity and suspension calibration;
- retain ordinary versus heavy-duty rear leaf-spring packages only when required by a verified row, not as catalog duplicates;
- use one verified tyre size, final drive and rear-differential state per row;
- preserve the transfer-case mass, front differential, front prop shaft and half-shafts on selectable 4MOTION rows;
- preserve the permanent centre differential and its nominal torque split on permanent 4MOTION rows;
- omit Single Cab, cab-chassis, bed-length, payload, trim, wheel and special-edition duplicates.

## Transmission and 4MOTION architecture requirements

### Six-speed manual

The manual requires its exact gearset, reverse ratio, clutch capacity, flywheel behaviour and final drive. The low first gear of the manual does not replace the selectable transfer-case reduction.

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
- drivetrain-specific mass and load distribution;
- tyre, brake, steering and differential calibration;
- pickup-body drag and frontal area;
- correct payload-sensitive centre of gravity without using cargo mass to hide an incorrect kerb setup;
- validation against documented top speed, acceleration, gradeability, towing and low-range targets where available.

Performance may not be matched through false torque, arbitrary speed caps or a single shared drivetrain-loss value.

## Engine and driveline audio architecture

Three combustion families are required:

1. **EA189 2.0 single-turbo TDI** — common-rail four-cylinder diesel with output-specific injection, turbo spool, combustion harshness and governor calibration.
2. **EA189 2.0 BiTDI** — sequential twin-turbo four-cylinder diesel with low/high-pressure turbo transition, stronger load response and distinct 163/180-PS calibrations.
3. **EA888 2.0 TSI** — turbocharged direct-injection petrol inline-four with petrol firing, intake, wastegate, exhaust and overrun behaviour.

The BiTDI may share the four-cylinder firing engine with the single-turbo TDI but requires a different first-principles induction, boost and transient system. The TSI may not use a diesel waveform. Selectable low range, permanent 4MOTION, rear differential lock, automatic converter and pickup-bed/body resonance require drivetrain-specific audio layers.

## Evidence still required before parameter commitment

Before implementation retain primary Volkswagen Commercial Vehicles brochures, price lists, type-approval data, workshop manuals and self-study material for:

- exact engine codes and production dates for the 122, 163, 140, 180 and 160-PS rows;
- valid engine/transmission/drive-system combinations by market and body;
- six-speed manual gearbox codes, all forward/reverse ratios, clutch and final drive;
- eight-speed automatic code/suffix, all ratios, converter characteristics, lock-up and shift controls;
- selectable transfer-case high/low ratios and engagement restrictions;
- permanent 4MOTION centre-differential type, nominal torque split and locking response;
- rear differential options and one standard state per row;
- sampled torque curves, idle, rev limit, turbo control and engine-brake behaviour;
- kerb mass, payload, axle ratings, wheelbase, track, centre of gravity, tyres, brakes and steering;
- drag, frontal area and documented acceleration, top-speed, towing and gradeability targets;
- direct GLB SHA-256, hierarchy, wheel centres, AABB, front axis and scale.

The engine families and three driveline architectures are established, but rows 5, 10 and 12 and all exact ratio/final-drive data remain confirmation-gated.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Include all 12 candidate configurations?
2. Include all three drivetrain architectures: RWD, selectable low-range 4MOTION and permanent 4MOTION?
3. Include both early 122/163-PS and later 140/180-PS diesel calibrations?
4. Include both 180-PS automatic rows, including the evidence-blocked RWD application?
5. Include the regional 2.0 TSI 160-PS RWD row?
6. Retain evidence-blocked rows 5, 10 and 12 pending primary Volkswagen confirmation?
7. Use the source-like pre-V6 Double Cab body for all rows and omit Single Cab, cab-chassis, bed, payload and trim duplicates?
8. Exclude all V6, later-facelift, special-edition and conversion rows?
9. Is an expected pre-V6 engine, transmission or drivetrain combination missing?

This is the final individual model gate. After the owner fixes model 23 scope, every included model will have a decided research scope and the global implementation gate may move to its next stage.