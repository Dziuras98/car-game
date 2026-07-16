# Škoda Octavia III Combi 2013 pre-facelift — research and approved scope

- Model number in Traffic Rider bundle: **20**
- Source GLB: `20_skoda_octavia_combi_2013.glb`
- Source Git blob SHA-1: `5f19949ae8f6d29ba0e4a58caeaf14d4044b75ec`
- Source SHA-256: **pending direct binary hash capture before integration**
- Research date: 2026-07-16
- Owner decision date: 2026-07-16
- Workflow status: **`approved`**
- Approved implementation scope: **35 pre-facelift Škoda Octavia III Combi configurations**
- Physics baseline inspected during research: current `master` after merge commit `a22eb5ee8776ae3e4aa294de9de8fc57af69609a`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity and approved body policy

The source represents a **third-generation Škoda Octavia Combi, type 5E, from the initial 2013 pre-facelift production phase**.

The common approved visual anchor is:

- standard Octavia III Combi estate body rather than the liftback;
- pre-2017 front and rear treatment;
- ordinary road ride height and standard bumpers;
- five doors and full-length estate roof;
- no Scout cladding, raised suspension or underbody styling;
- no facelift split-headlamp front end.

The owner explicitly accepted **standard-body visual homogenization for every RS row**. RS variants retain their real engine, gearbox, differential, brakes, steering, suspension, tyres, mass and performance calibration, but do not receive RS-specific bumpers, grille, exhaust outlets, wheels or other exterior geometry. This is a recorded visual approximation and must not be interpreted as a claim that a factory RS used the standard exterior.

The source contains **2,010 triangles**. Direct binary inspection remains required to record its node hierarchy, AABB, wheel centres, source front axis and wheelbase-derived scale.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Platform / generation | MQB, Octavia III type 5E |
| Combi production phase | pre-facelift 2013–2016 scope |
| Wheelbase | approximately 2,686 mm |
| Standard Combi length | approximately 4,659 mm |
| Standard body width excluding mirrors | approximately 1,814 mm |
| Standard Combi luggage volume | approximately 610 L |
| Source triangles | 2,010 |
| Source Git blob SHA-1 | `5f19949ae8f6d29ba0e4a58caeaf14d4044b75ec` |
| Source topology and bounds | pending direct GLB inspection |

The committed GLB remains unchanged. Integration must create four independent hub-centred wheel nodes, explicit wheel bindings and project-authored collision. Scale must be based primarily on the 2,686-mm wheelbase and cross-checked against body length and width.

## Approved research boundary

The approved scope covers the **pre-facelift Octavia III Combi range from 2013 through the 2016 model-year updates**, including:

- standard front-wheel-drive petrol and diesel cars;
- standard/Laurin & Klement-style 4×4 drivetrains;
- factory G-TEC CNG/petrol drivetrain;
- GreenLine drivetrain and efficiency calibration;
- Octavia RS Combi and RS 230 performance variants;
- late pre-facelift 1.0 TSI, 1.2 TSI 81-kW, 1.4 TSI 110-kW and 1.6 TDI 81-kW revisions.

The approved boundary excludes:

- all three Octavia Scout rows;
- the Octavia liftback body;
- 2017 split-headlamp facelift engines and bodywork;
- later 1.5 TSI and RS 245 rows;
- regional naturally aspirated MPI derivatives unless separately approved later;
- aftermarket LPG/CNG, tuning, police, ambulance and specialist conversions.

## Owner-directed scope rules

- retain candidate rows 1–35 from the researched matrix;
- exclude former Scout rows 36–38 completely;
- retain all five ordinary 4×4 rows and the RS Combi diesel 4×4 row;
- retain all seven RS rows, including RS 230;
- retain G-TEC, GreenLine and all late pre-facelift engine revisions;
- retain rows 2, 6, 8 and 14 as approved-scope but evidence-blocked until primary ordering and gearbox data confirms them;
- use the standard source Combi exterior for ordinary, 4×4, G-TEC, GreenLine and RS rows;
- do not create RS-specific exterior geometry;
- preserve RS-specific mechanical calibration despite the shared exterior;
- use one verified standard tyre, final drive and differential/coupling state per row;
- omit trim, wheel, option-package, emissions-state and mechanically duplicate catalog entries;
- no additional pre-facelift Combi powertrain was requested by the owner.

## Approved configuration matrix

### Standard-body petrol and G-TEC FWD — 15 configurations

| # | Engine / calibration | Transmission | Drivetrain / chassis | Status |
|---:|---|---|---|---|
| 1 | EA211 1.2 TSI 63 kW / 86 PS | 5-speed manual | FWD, standard chassis | **approved** |
| 2 | EA211 1.2 TSI 77 kW / 105 PS | 5-speed manual | FWD, standard chassis | **approved scope / regional application evidence blocked** |
| 3 | EA211 1.2 TSI 77 kW / 105 PS | 6-speed manual | FWD, standard chassis | **approved** |
| 4 | EA211 1.2 TSI 77 kW / 105 PS | DQ200 7-speed dry-clutch DSG | FWD, standard chassis | **approved** |
| 5 | late EA211 1.2 TSI 81 kW / 110 PS | 6-speed manual | FWD, standard chassis | **approved** |
| 6 | late EA211 1.2 TSI 81 kW / 110 PS | DQ200 7-speed DSG | FWD, standard chassis | **approved scope / date and market evidence blocked** |
| 7 | late pre-facelift EA211 1.0 TSI 85 kW / 115 PS inline-three | 6-speed manual | FWD, standard chassis | **approved** |
| 8 | late pre-facelift EA211 1.0 TSI 85 kW / 115 PS inline-three | DQ200 7-speed DSG | FWD, standard chassis | **approved scope / Combi market evidence blocked** |
| 9 | EA211 1.4 TSI 103 kW / 140 PS | 6-speed manual | FWD, standard chassis | **approved** |
| 10 | EA211 1.4 TSI 103 kW / 140 PS | DQ200 7-speed DSG | FWD, standard chassis | **approved** |
| 11 | late EA211 1.4 TSI 110 kW / 150 PS | 6-speed manual | FWD, standard chassis | **approved** |
| 12 | late EA211 1.4 TSI 110 kW / 150 PS | DQ200 7-speed DSG | FWD, standard chassis | **approved** |
| 13 | EA888 1.8 TSI 132 kW / 180 PS | 6-speed manual | FWD, multilink rear chassis where applicable | **approved** |
| 14 | EA888 1.8 TSI 132 kW / 180 PS | DQ200/DQ250-family DSG application | FWD, multilink rear chassis | **approved scope / exact gearbox code evidence blocked** |
| 15 | EA211 1.4 TSI G-TEC 81 kW / 110 PS bi-fuel CNG/petrol | 6-speed manual | FWD; factory CNG tanks, regulators and fuel switching | **approved** |

### Standard-body diesel FWD — 8 configurations

| # | Engine / calibration | Transmission | Drivetrain / chassis | Status |
|---:|---|---|---|---|
| 16 | EA288 1.6 TDI 66 kW / 90 PS | 5-speed manual | FWD, standard chassis | **approved** |
| 17 | EA288 1.6 TDI 77 kW / 105 PS | 5-speed manual | FWD, standard chassis | **approved** |
| 18 | EA288 1.6 TDI 77 kW / 105 PS | DQ200 7-speed DSG | FWD, standard chassis | **approved** |
| 19 | late EA288 1.6 TDI 81 kW / 110 PS | 5-speed manual | FWD, standard chassis | **approved** |
| 20 | late EA288 1.6 TDI 81 kW / 110 PS | DQ200 7-speed DSG | FWD, standard chassis | **approved** |
| 21 | EA288 1.6 TDI GreenLine 81 kW / 110 PS | 6-speed manual | FWD; GreenLine gearing, aero and rolling-resistance state | **approved** |
| 22 | EA288 2.0 TDI 110 kW / 150 PS | 6-speed manual | FWD, multilink rear chassis | **approved** |
| 23 | EA288 2.0 TDI 110 kW / 150 PS | DQ250 6-speed wet-clutch DSG | FWD, multilink rear chassis | **approved** |

### Standard/L&K-style 4×4 — 5 configurations

| # | Engine / calibration | Transmission | Drivetrain / chassis | Status |
|---:|---|---|---|---|
| 24 | EA288 1.6 TDI 77 kW / 105 PS | 6-speed manual | Haldex fifth-generation AWD, multilink rear axle | **approved** |
| 25 | late EA288 1.6 TDI 81 kW / 110 PS | 6-speed manual | Haldex AWD, multilink rear axle | **approved** |
| 26 | EA288 2.0 TDI 110 kW / 150 PS | 6-speed manual | Haldex AWD, multilink rear axle | **approved** |
| 27 | EA888 1.8 TSI 132 kW / 180 PS | DQ250 6-speed wet-clutch DSG | Haldex AWD, multilink rear axle | **approved** |
| 28 | EA288 2.0 TDI 135 kW / 184 PS | DQ250 6-speed wet-clutch DSG | Haldex AWD, multilink rear axle | **approved** |

### Octavia RS Combi — 7 mechanically accurate, visually homogenized configurations

| # | Engine / calibration | Transmission | Drivetrain / chassis | Status |
|---:|---|---|---|---|
| 29 | EA888 2.0 TSI RS 162 kW / 220 PS | 6-speed manual | FWD; RS brakes, steering, suspension and electronic differential functions | **approved** |
| 30 | EA888 2.0 TSI RS 162 kW / 220 PS | DQ250 6-speed wet-clutch DSG | FWD; RS chassis | **approved** |
| 31 | EA288 2.0 TDI RS 135 kW / 184 PS | 6-speed manual | FWD; RS chassis | **approved** |
| 32 | EA288 2.0 TDI RS 135 kW / 184 PS | DQ250 6-speed wet-clutch DSG | FWD; RS chassis | **approved** |
| 33 | EA888 2.0 TSI RS 230 169 kW / 230 PS | 6-speed manual | FWD; RS 230 VAQ/electronic locking hardware and chassis state | **approved** |
| 34 | EA888 2.0 TSI RS 230 169 kW / 230 PS | DQ250 6-speed wet-clutch DSG | FWD; RS 230 chassis | **approved** |
| 35 | EA288 2.0 TDI RS 135 kW / 184 PS | DQ250 6-speed wet-clutch DSG | Haldex AWD; RS Combi 4×4 chassis | **approved** |

**Approved total: 23 standard FWD + 5 ordinary 4×4 + 7 RS Combi = 35 configurations.**

## Explicitly excluded Scout configurations

The following researched rows are excluded and receive no catalog, chassis or visual implementation:

- 1.8 TSI 180 PS wet-clutch DSG Haldex Scout;
- 2.0 TDI 150 PS 6MT Haldex Scout;
- 2.0 TDI 184 PS DQ250 Haldex Scout.

No raised Scout suspension, cladding, bumper treatment, underbody protection or Scout tyre calibration is required.

## Transmission and AWD architecture requirements

- five- and six-speed manuals require their exact gearsets, clutches and final drives;
- DQ200 must use a dry dual-clutch model with two clutch paths, preselection, creep and thermal limits;
- DQ250 must use a wet dual-clutch model with oil-cooled clutch packs, hydraulic control, preselection and AWD-compatible output where applicable;
- no DSG row may use a shortened torque-converter automatic shift delay;
- Haldex fifth-generation AWD requires an actively controlled rear clutch, rear differential, front/rear wheel-speed coupling logic, launch allocation and thermal protection;
- FWD, ordinary 4×4 and RS 4×4 require distinct mass, suspension, steering, brake and tyre calibration;
- GreenLine must include its gearing, tyre and aerodynamic state;
- G-TEC requires petrol/CNG tanks, regulator pressure, fuel switching, mass distribution and gas-specific engine calibration.

## Engine and driveline audio architecture

Required combustion families include:

- EA211 1.0 TSI turbocharged inline-three with its three-cylinder firing cadence;
- EA211 1.2/1.4 TSI turbocharged inline-four family;
- EA888 1.8/2.0 TSI inline-four family, including ordinary, RS and RS 230 intake/exhaust/boost calibrations;
- EA288 1.6/2.0 TDI common-rail turbo-diesel family with displacement- and output-specific injection, turbo and exhaust behaviour;
- G-TEC CNG combustion state with gas-injection transients and petrol/CNG switching.

The 1.0 TSI may not reuse a four-cylinder waveform. RS rows require their own intake, exhaust, differential, tyre and driveline calibration even though the owner accepted the standard exterior mesh.

## Evidence still required before parameter commitment

Before implementation retain primary Škoda brochures, price lists, homologation data and service documentation for:

- exact pre-facelift Combi market dates and valid engine/transmission/drivetrain combinations;
- engine codes, sampled torque curves, rev limits and transient controls;
- MQ-series manual gearbox codes, every forward/reverse ratio and final drive;
- DQ200/DQ250 codes, clutch limits, ratio sets, launch, creep and shift-control maps;
- Haldex generation, coupling logic, final drives and thermal limits;
- torsion-beam versus multilink allocation by engine and drivetrain;
- RS and RS 230 suspension, brakes, steering, tyre sizes, ride heights and mass;
- G-TEC tank capacity, pressure regulation, fuel switching and mass distribution;
- body mass, axle loads, drag, frontal area and documented performance targets for every approved row;
- direct GLB SHA-256, node hierarchy, hub centres, AABB, source front and scale.

Rows 2, 6, 8 and 14 may not be implemented with guessed market applicability or gearbox architecture.

## Owner decision recorded

The owner approved every researched pre-facelift Octavia III Combi configuration except the three Scout rows. All seven RS rows are retained with mechanically correct RS calibration and the unchanged standard Combi exterior as an explicit accepted visual approximation.

Model 20 is **`approved`** with **35** configurations. Implementation remains blocked by the global all-model research gate. Research proceeds to model 23.