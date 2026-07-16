# Škoda Octavia III Combi 2013 pre-facelift — research and owner-scope gate

- Model number in Traffic Rider bundle: **20**
- Source GLB: `20_skoda_octavia_combi_2013.glb`
- Source Git blob SHA-1: `5f19949ae8f6d29ba0e4a58caeaf14d4044b75ec`
- Source SHA-256: **pending direct binary hash capture before integration**
- Research date: 2026-07-16
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected during research: current `master` after merge commit `a22eb5ee8776ae3e4aa294de9de8fc57af69609a`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source filename and bundle identity represent a **third-generation Škoda Octavia Combi, type 5E, from the initial 2013 pre-facelift production phase**.

The strict visual anchor is:

- standard Octavia III Combi estate body rather than the liftback;
- pre-2017 front and rear treatment;
- ordinary road ride height and standard bumpers;
- five doors and full-length estate roof;
- no RS bumpers, exhaust treatment or lowered sports chassis;
- no Scout cladding, raised suspension or underbody styling;
- no facelift split-headlamp front end.

The source contains **2,010 triangles** according to the committed inventory. Direct binary inspection remains required to record its node hierarchy, AABB, wheel centres, source front axis and wheelbase-derived scale.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Platform / generation | MQB, Octavia III type 5E |
| Combi production phase | initial pre-facelift range from 2013 |
| Wheelbase | approximately 2,686 mm |
| Standard Combi length | approximately 4,659 mm |
| Standard body width excluding mirrors | approximately 1,814 mm |
| Standard Combi luggage volume | approximately 610 L |
| Source triangles | 2,010 |
| Source Git blob SHA-1 | `5f19949ae8f6d29ba0e4a58caeaf14d4044b75ec` |
| Source topology and bounds | pending direct GLB inspection |

The committed GLB remains unchanged. Integration must create four independent hub-centred wheel nodes, explicit wheel bindings and project-authored collision. Scale must be based primarily on the 2,686-mm wheelbase and cross-checked against body length and width.

## Research boundary

The candidate scope covers the **pre-facelift Octavia III Combi range from 2013 through the 2016 model-year updates**, including mechanically distinct:

- standard front-wheel-drive petrol and diesel cars;
- standard/Laurin & Klement-style 4×4 drivetrains;
- G-TEC factory CNG/petrol drivetrain;
- Octavia RS Combi and RS 230 performance variants;
- Octavia Scout raised 4×4 chassis;
- late pre-facelift 1.0 TSI, 1.2 TSI 81-kW, 1.4 TSI 110-kW and 1.6 TDI 81-kW revisions.

The boundary excludes:

- the Octavia liftback body;
- 2017 split-headlamp facelift engines and bodywork;
- later 1.5 TSI and RS 245 rows;
- regional naturally aspirated MPI derivatives unless primary Škoda ordering data proves a relevant European Combi application;
- aftermarket LPG/CNG, tuning, police, ambulance and specialist conversions.

## Mechanically consolidated candidate matrix

### Standard-body petrol and G-TEC FWD — 15 candidates

| # | Engine / calibration | Transmission | Drivetrain / chassis | Evidence state |
|---:|---|---|---|---|
| 1 | EA211 1.2 TSI 63 kW / 86 PS | 5-speed manual | FWD, standard chassis | `verified_family` |
| 2 | EA211 1.2 TSI 77 kW / 105 PS | 5-speed manual | FWD, standard chassis | `regional_application_evidence_blocked` |
| 3 | EA211 1.2 TSI 77 kW / 105 PS | 6-speed manual | FWD, standard chassis | `verified_family` |
| 4 | EA211 1.2 TSI 77 kW / 105 PS | DQ200 7-speed dry-clutch DSG | FWD, standard chassis | `verified_family` |
| 5 | late EA211 1.2 TSI 81 kW / 110 PS | 6-speed manual | FWD, standard chassis | `verified_family` |
| 6 | late EA211 1.2 TSI 81 kW / 110 PS | DQ200 7-speed DSG | FWD, standard chassis | `candidate`; exact pre-facelift market dates require primary ordering table |
| 7 | late pre-facelift EA211 1.0 TSI 85 kW / 115 PS inline-three | 6-speed manual | FWD, standard chassis | `verified_family` |
| 8 | late pre-facelift EA211 1.0 TSI 85 kW / 115 PS inline-three | DQ200 7-speed DSG | FWD, standard chassis | `candidate`; exact Combi market coverage requires primary ordering table |
| 9 | EA211 1.4 TSI 103 kW / 140 PS | 6-speed manual | FWD, standard chassis | `verified_family` |
| 10 | EA211 1.4 TSI 103 kW / 140 PS | DQ200 7-speed DSG | FWD, standard chassis | `verified_family` |
| 11 | late EA211 1.4 TSI 110 kW / 150 PS | 6-speed manual | FWD, standard chassis | `verified_family` |
| 12 | late EA211 1.4 TSI 110 kW / 150 PS | DQ200 7-speed DSG | FWD, standard chassis | `verified_family` |
| 13 | EA888 1.8 TSI 132 kW / 180 PS | 6-speed manual | FWD, multilink rear chassis where applicable | `verified_family` |
| 14 | EA888 1.8 TSI 132 kW / 180 PS | DQ200/DQ250-family DSG application | FWD, multilink rear chassis | `gearbox_code_evidence_blocked`; exact dry/wet DSG market application must be retained from primary data |
| 15 | EA211 1.4 TSI G-TEC 81 kW / 110 PS bi-fuel CNG/petrol | 6-speed manual | FWD; factory CNG tanks, regulators and fuel switching | `verified_family` |

### Standard-body diesel FWD — 8 candidates

| # | Engine / calibration | Transmission | Drivetrain / chassis | Evidence state |
|---:|---|---|---|---|
| 16 | EA288 1.6 TDI 66 kW / 90 PS | 5-speed manual | FWD, standard chassis | `verified_family` |
| 17 | EA288 1.6 TDI 77 kW / 105 PS | 5-speed manual | FWD, standard chassis | `verified_family` |
| 18 | EA288 1.6 TDI 77 kW / 105 PS | DQ200 7-speed DSG | FWD, standard chassis | `verified_family` |
| 19 | late EA288 1.6 TDI 81 kW / 110 PS | 5-speed manual | FWD, standard chassis | `verified_family` |
| 20 | late EA288 1.6 TDI 81 kW / 110 PS | DQ200 7-speed DSG | FWD, standard chassis | `verified_family` |
| 21 | EA288 1.6 TDI GreenLine 81 kW / 110 PS | 6-speed manual | FWD; GreenLine gearing/aero/rolling-resistance state | `verified_family`; exact GreenLine body restrictions require primary table |
| 22 | EA288 2.0 TDI 110 kW / 150 PS | 6-speed manual | FWD, multilink rear chassis | `verified_family` |
| 23 | EA288 2.0 TDI 110 kW / 150 PS | DQ250 6-speed wet-clutch DSG | FWD, multilink rear chassis | `verified_family` |

### Standard/L&K-style 4×4 — 5 candidates

| # | Engine / calibration | Transmission | Drivetrain / chassis | Evidence state |
|---:|---|---|---|---|
| 24 | EA288 1.6 TDI 77 kW / 105 PS | 6-speed manual | Haldex fifth-generation AWD, multilink rear axle | `verified_family` |
| 25 | late EA288 1.6 TDI 81 kW / 110 PS | 6-speed manual | Haldex AWD, multilink rear axle | `verified_family` |
| 26 | EA288 2.0 TDI 110 kW / 150 PS | 6-speed manual | Haldex AWD, multilink rear axle | `verified_family` |
| 27 | EA888 1.8 TSI 132 kW / 180 PS | DQ250 6-speed wet-clutch DSG | Haldex AWD, multilink rear axle | `verified_family` |
| 28 | EA288 2.0 TDI 135 kW / 184 PS | DQ250 6-speed wet-clutch DSG | Haldex AWD, multilink rear axle | `verified_family`; trim/market restrictions require primary table |

### Octavia RS Combi — 7 candidates

| # | Engine / calibration | Transmission | Drivetrain / chassis | Evidence state |
|---:|---|---|---|---|
| 29 | EA888 2.0 TSI RS 162 kW / 220 PS | 6-speed manual | FWD; RS brakes, steering, suspension and electronic differential functions | `verified` |
| 30 | EA888 2.0 TSI RS 162 kW / 220 PS | DQ250 6-speed wet-clutch DSG | FWD; RS chassis | `verified` |
| 31 | EA288 2.0 TDI RS 135 kW / 184 PS | 6-speed manual | FWD; RS chassis | `verified` |
| 32 | EA288 2.0 TDI RS 135 kW / 184 PS | DQ250 6-speed wet-clutch DSG | FWD; RS chassis | `verified` |
| 33 | EA888 2.0 TSI RS 230 169 kW / 230 PS | 6-speed manual | FWD; RS 230 VAQ/electronic locking hardware and chassis state | `verified_family` |
| 34 | EA888 2.0 TSI RS 230 169 kW / 230 PS | DQ250 6-speed wet-clutch DSG | FWD; RS 230 chassis | `verified_family` |
| 35 | EA288 2.0 TDI RS 135 kW / 184 PS | DQ250 6-speed wet-clutch DSG | Haldex AWD; RS Combi 4×4 chassis | `verified_family` |

### Octavia Scout — 3 candidates

| # | Engine / calibration | Transmission | Drivetrain / chassis | Evidence state |
|---:|---|---|---|---|
| 36 | EA888 1.8 TSI 132 kW / 180 PS | wet-clutch DSG | Haldex AWD; raised Scout suspension, cladding, tyre and protection package | `verified_family / gearbox_suffix_evidence_blocked` |
| 37 | EA288 2.0 TDI 110 kW / 150 PS | 6-speed manual | Haldex AWD; raised Scout chassis | `verified` |
| 38 | EA288 2.0 TDI 135 kW / 184 PS | DQ250 6-speed wet-clutch DSG | Haldex AWD; raised Scout chassis | `verified` |

**Mechanically consolidated candidate total: 38 pre-facelift Octavia III Combi configurations.**

Candidate rows 2, 6, 8, 14 and 36 remain evidence-blocked in at least one market, date or gearbox-code detail. Approval may retain them as confirmation-gated rows, but implementation may not invent a transmission architecture, final drive or regional application.

## Body and visual policy candidates

The strict source mesh is a standard Combi. Three visual/chassis families are mechanically and visually distinct:

1. **Standard Combi / G-TEC / ordinary 4×4** — may use the source body with trim-neutral materials and drivetrain-specific ride height, exhaust and underbody details.
2. **RS Combi** — requires RS-specific bumpers, grille, exhaust outlets, wheels, brakes and lowered chassis. Reusing the standard mesh without a documented visual approximation would misrepresent the vehicle.
3. **Scout** — requires raised ride height, protective cladding, bumper/underbody treatment and Scout-specific wheel/tyre calibration.

The owner must decide whether RS and Scout receive project-authored visual derivatives or are omitted. A standard-body visual homogenization is possible only as an explicit accepted approximation.

## Transmission and AWD architecture requirements

- five- and six-speed manuals require their exact gearsets, clutches and final drives;
- DQ200 must use a dry dual-clutch model with two clutch paths, preselection, creep and thermal limits;
- DQ250 must use a wet dual-clutch model with oil-cooled clutch packs, hydraulic control, preselection and AWD-compatible output where applicable;
- no DSG row may use a shortened torque-converter automatic shift delay;
- Haldex fifth-generation AWD requires an actively controlled rear clutch, rear differential, front/rear wheel-speed coupling logic, launch allocation and thermal protection;
- FWD, standard 4×4, RS 4×4 and Scout require distinct mass, suspension, steering, brake and tyre calibration;
- GreenLine may not be simulated only with reduced engine torque; its gearing, tyre and aerodynamic state must be represented;
- G-TEC requires petrol/CNG tanks, regulator pressure, fuel switching, mass distribution and gas-specific engine calibration.

## Engine and driveline audio architecture

Required combustion families include:

- EA211 1.0 TSI turbocharged inline-three with its three-cylinder firing cadence;
- EA211 1.2/1.4 TSI turbocharged inline-four family;
- EA888 1.8/2.0 TSI inline-four family, including ordinary, RS and RS 230 intake/exhaust/boost calibrations;
- EA288 1.6/2.0 TDI common-rail turbo-diesel family with displacement- and output-specific injection, turbo and exhaust behaviour;
- G-TEC CNG combustion state with gas-injection transients and petrol/CNG switching.

The 1.0 TSI may not reuse a four-cylinder waveform. RS, Scout, ordinary FWD and AWD cars also require distinct exhaust, intake, tyre, differential, DSG and body-resonance layers rather than pitch-only variants.

## Evidence still required before parameter commitment

Before implementation retain primary Škoda brochures, price lists, homologation data and service documentation for:

- exact pre-facelift Combi market dates and valid engine/transmission/drivetrain combinations;
- engine codes, sampled torque curves, rev limits and transient controls;
- MQ-series manual gearbox codes, every forward/reverse ratio and final drive;
- DQ200/DQ250 codes, clutch limits, ratio sets, launch, creep and shift-control maps;
- Haldex generation, coupling logic, final drives and thermal limits;
- torsion-beam versus multilink allocation by engine and drivetrain;
- RS, RS 230 and Scout suspension, brakes, steering, tyre sizes, ride heights and mass;
- G-TEC tank capacity, pressure regulation, fuel switching and mass distribution;
- body mass, axle loads, drag, frontal area and documented performance targets for every approved row;
- direct GLB SHA-256, node hierarchy, hub centres, AABB, source front and scale.

The broad engine and drivetrain families are established, but exact regional ordering and several gearbox-code details remain confirmation-gated.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Include all 38 candidate configurations, or restrict the scope to ordinary standard-body Combi rows?
2. Include all five ordinary 4×4 rows and the RS Combi 4×4 row?
3. Include the seven RS Combi rows, including RS 230?
4. Include the three Scout rows with their distinct raised chassis?
5. Include the factory G-TEC CNG/petrol row and GreenLine row?
6. Include late pre-facelift 2015–2016 engine revisions such as 1.0 TSI, 1.2 TSI 81 kW, 1.4 TSI 110 kW and 1.6 TDI 81 kW?
7. Retain evidence-blocked rows 2, 6, 8, 14 and 36 pending primary confirmation, or exclude them now?
8. For RS and Scout, create project-authored visual derivatives, accept standard-body visual homogenization, or omit those families?
9. Exclude the liftback, 2017 facelift, later 1.5 TSI/RS 245, regional MPI, conversions and specialist vehicles?
10. Is any expected pre-facelift Octavia III Combi engine, transmission or drivetrain combination missing?

No implementation begins after this individual decision. Research proceeds to model 23 only after the owner fixes model 20 scope, and implementation begins only after every included model has reached `approved`.
