# Mercedes-Benz Sprinter W906 facelift long high-roof van — research and approved scope

- Model number in Traffic Rider bundle: **15**
- Source GLB: `15_mercedes_benz_sprinter_2014.glb`
- Source SHA-256: `e787e83373d2b454d4f47c46f5d5c7c2bffdf862edc9f85f8b16370bd86dbc3f`
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **17 mechanically consolidated facelift Sprinter RWD configurations**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity and body policy

The source represents a **facelift Mercedes-Benz Sprinter W906/NCV3 from approximately model year 2014**, using the 2013–2018 front treatment. Its proportions match a long 4,325-mm-wheelbase, approximately 6,945-mm, high-roof windowed Kombi/passenger-style van with single rear wheels and standard RWD ride height.

The owner retained the source-like physical body for all approved rows:

- facelift W906 exterior;
- 4,325-mm long wheelbase;
- high roof and extensive side/rear glazing;
- single rear wheels;
- standard RWD ride height and road suspension;
- one representative passenger/cargo mass and axle-loading state per powertrain;
- no short, medium or extra-long body duplicates;
- no other roof heights, closed panel-van shell, chassis cab, pickup, dual-rear-wheel chassis, super-single chassis or factory minibus derivatives.

This is an explicit project body homogenization and does not assert that every regional engine/transmission row was sold with the exact source glazing and body grade.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Most likely wheelbase | 4,325 mm / 4.325 m |
| Matching factory body length | approximately 6,945 mm / 6.945 m |
| Factory body width excluding mirrors | approximately 1,993 mm / 1.993 m |
| High-roof height family | approximately 2.7–2.9 m depending on chassis/tyres |
| Body mesh | `AI_Mb_Sprinter_High_MB_Sprinter_2014_0` |
| Front wheel-pair mesh | `on_teker.014_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.015_wheel_0` |
| Body triangles | 960 |
| Front wheel-pair triangles | 288 |
| Rear wheel-pair triangles | 288 |
| Total triangles | 1,536 |
| Source wheelbase | approximately 5.539680 source units |
| Approximate 4,325-mm-wheelbase scale | 0.780731 |
| Scaled source envelope | approximately 2.778 × 3.087 × 6.939 m including mirrors/outer geometry |

The committed GLB remains unchanged. Four independent wheels, project-authored collision, catalog, physics, transmission and audio remain deferred by the global research gate.

## Owner-directed scope rules

- retain exactly candidate rows 1–17 from the presented table;
- exclude all four Sprinter 4x4 rows 18–21;
- retain OM651 95, 114, 129, 143 and 163-PS calibrations separately;
- retain OM642 V6 manual, European seven-speed automatic and North-American five-speed automatic rows separately;
- retain factory M271 petrol and 316 NGT rows;
- retain evidence-blocked RWD rows 2, 11, 15 and 17 in approved scope, but prohibit implementation until primary Mercedes ordering evidence confirms them;
- keep six-speed ECO Gear manual, 5G-TRONIC/NAG1 and 7G-TRONIC PLUS architectures separate;
- use one verified standard final-drive ratio and one standard differential state per row;
- omit BlueTEC, DPF, SCR, emissions-standard, start/stop and assistance-system subdivisions as catalog rows or selectable metadata;
- exclude aftermarket LPG/CNG conversions, camper, ambulance, armoured, tuning and other specialist conversions;
- no additional expected RWD powertrain variant was requested by the owner.

## Approved diesel RWD matrix — 13 configurations

| # | Engine / calibration | Transmission | Drivetrain | Status |
|---:|---|---|---|---|
| 1 | OM651 2.143L four-cylinder diesel, 95 PS / 250 Nm | 6-speed ECO Gear manual | RWD; one standard final drive and differential | **approved** |
| 2 | OM651 95 PS / 250 Nm | 7G-TRONIC PLUS 7-speed torque-converter automatic | RWD; one standard final drive and differential | **approved scope / evidence blocked** |
| 3 | OM651 129 PS / 305 Nm | 6-speed ECO Gear manual | RWD; one standard final drive and differential | **approved** |
| 4 | OM651 129 PS / 305 Nm | 7G-TRONIC PLUS | RWD; one standard final drive and differential | **approved** |
| 5 | OM651 163 PS / 360 Nm | 6-speed ECO Gear manual | RWD; one standard final drive and differential | **approved** |
| 6 | OM651 163 PS / 360 Nm | 7G-TRONIC PLUS | RWD; one standard final drive and differential | **approved** |
| 7 | OM642 3.0L V6 diesel, approximately 190 PS / 440 Nm | 6-speed ECO Gear manual | RWD; one standard final drive and differential | **approved** |
| 8 | OM642 V6, approximately 190 PS / 440 Nm | 7G-TRONIC PLUS | RWD; one standard final drive and differential | **approved** |
| 9 | North-American OM642 V6, approximately 188–190 hp/PS and 440-Nm-class torque | 5-speed 5G-TRONIC/NAG1 torque-converter automatic | RWD; one standard final drive and differential | **approved** |
| 10 | late OM651 low-output calibration, 114 PS / 300 Nm | 6-speed ECO Gear manual | RWD; one standard final drive and differential | **approved** |
| 11 | late OM651 114 PS / 300 Nm | 7G-TRONIC PLUS | RWD; one standard final drive and differential | **approved scope / evidence blocked** |
| 12 | late OM651 middle-output calibration, 143 PS / 350 Nm | 6-speed ECO Gear manual | RWD; one standard final drive and differential | **approved** |
| 13 | late OM651 143 PS / 350 Nm | 7G-TRONIC PLUS | RWD; one standard final drive and differential | **approved** |

## Approved petrol and factory NGT RWD matrix — 4 configurations

| # | Engine / calibration | Transmission | Drivetrain | Status |
|---:|---|---|---|---|
| 14 | M271 E18 ML 1.8L supercharged petrol inline-four, approximately 156 PS / 240 Nm | 6-speed manual | RWD; one standard final drive and differential | **approved** |
| 15 | M271 E18 ML petrol, approximately 156 PS / 240 Nm | 7G-TRONIC PLUS | RWD; one standard final drive and differential | **approved scope / evidence blocked** |
| 16 | factory 316 NGT M271 1.8L supercharged natural-gas/petrol-capable engine, approximately 156 PS / 240 Nm | 6-speed manual | RWD; one standard final drive and differential | **approved** |
| 17 | factory 316 NGT M271, approximately 156 PS / 240 Nm | 7G-TRONIC PLUS | RWD; one standard final drive and differential | **approved scope / evidence blocked** |

**Approved total: 13 diesel RWD + 4 petrol/NGT RWD = 17 mechanically consolidated configurations.**

## Explicitly excluded Sprinter 4x4 rows

The following previously presented rows are excluded from the catalog:

- OM651 129 PS plus six-speed manual Sprinter 4x4;
- OM651 163 PS plus six-speed manual Sprinter 4x4;
- late OM651 143 PS plus six-speed manual Sprinter 4x4;
- OM642 V6 plus five-speed automatic Sprinter 4x4.

No transfer case, driven front axle, raised 4x4 chassis, low-range package or 4x4 differential-lock state will be implemented for model 15.

## Chassis and transmission requirements

Every approved row requires a longitudinal front engine, dry clutch or hydrodynamic converter, exact gearbox, prop shaft, live driven rear axle and source-body-correct leaf-spring, tyre, brake, mass, drag and crosswind calibration.

ECO Gear requires a driver-operated dry clutch and exact six-speed/reverse ratios. 7G-TRONIC PLUS requires converter multiplication, creep, progressive lock-up, seven planetary ratios, hydraulic shift phases, kickdown and thermal protection. The North-American five-speed NAG1/5G-TRONIC is a separate architecture and may not reuse the seven-speed ratios or shift schedule.

## Engine and driveline audio architecture

Required families include OM651 four-cylinder common-rail diesel, OM642 V6 diesel with its actual firing cadence, M271 supercharged petrol four and the factory NGT gaseous-fuel combustion state. Manual, five-speed converter and seven-speed converter driveline layers remain separate. The V6, petrol/NGT and four-cylinder diesel rows may not be produced only through pitch or equalisation changes from one shared waveform.

## Evidence still required before parameter commitment

Before implementation retain primary Mercedes-Benz brochures, price lists, body-builder information and service data for exact dates/body restrictions, confirmation or removal of evidence-blocked rows 2, 11, 15 and 17, gearbox codes and ratios, clutch/converter limits, one standard final drive per row, source-body mass/axle loads/tyres/brakes/suspension, drag and NGT tank/fuel-control data. These gaps do not reopen the approved 17-row scope and do not authorize guessed parameters.

## Owner decision recorded

The owner approved every previously presented RWD row and excluded all four 4x4 rows. No remaining RWD engine or transmission row was merged or removed.

Model 15 is **`approved`** with **17** configurations. Implementation remains blocked by the global all-model research gate. Research proceeds to model 16.