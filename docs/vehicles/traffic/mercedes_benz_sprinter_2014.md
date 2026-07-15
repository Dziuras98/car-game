# Mercedes-Benz Sprinter W906 facelift long high-roof van — research and owner-scope gate

- Model number in Traffic Rider bundle: **15**
- Source GLB: `15_mercedes_benz_sprinter_2014.glb`
- Source SHA-256: `e787e83373d2b454d4f47c46f5d5c7c2bffdf862edc9f85f8b16370bd86dbc3f`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents a **facelift Mercedes-Benz Sprinter W906/NCV3 from approximately model year 2014**, using the 2013–2018 front treatment. Its proportions and wheel locations match the long 4,325-mm wheelbase and approximately 6,945-mm body length.

Visible source evidence includes:

- facelift grille, headlamps and bumper introduced for the 2014 model year;
- white long-body van with a high roof;
- sliding side door and extensive side/rear glazing consistent with a Kombi/passenger or crew-van presentation rather than a closed unglazed panel van;
- single rear wheels rather than dual rear wheels;
- European-style plate treatment;
- standard road ride height, not the raised Sprinter 4x4 chassis;
- no pickup, chassis-cab, minibus coach body or specialist conversion.

Identity confidence is **high for facelift W906 long-wheelbase high-roof single-rear-wheel van; moderate for the exact Kombi/passenger grade and engine**.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Most likely wheelbase | 4,325 mm / 4.325 m |
| Matching factory body length | approximately 6,945 mm / 6.945 m |
| Factory body width excluding mirrors | approximately 1,993 mm / 1.993 m |
| High-roof height family | approximately 2.7–2.9 m depending on chassis/tyres |
| Source meshes | 3 |
| Body mesh | `AI_Mb_Sprinter_High_MB_Sprinter_2014_0` |
| Front wheel-pair mesh | `on_teker.014_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.015_wheel_0` |
| Body triangles | 960 |
| Front wheel-pair triangles | 288 |
| Rear wheel-pair triangles | 288 |
| Total triangles | 1,536 |
| Source scene AABB | approximately 3.557675 × 3.953974 × 8.887679 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 5.539680 source units |
| Approximate 4,325-mm-wheelbase scale | 0.780731 |
| Scaled source envelope | approximately 2.778 × 3.087 × 6.939 m including mirrors/outer geometry |

The wheelbase and scaled length strongly support the 4,325-mm long body. The scaled width includes mirrors and outer geometry. The committed GLB remains unchanged; four independent wheel nodes, collision, catalog, physics, transmission and audio remain blocked by the global research gate.

## Research boundary

The candidate scope covers the **facelift W906/NCV3 Sprinter from the 2013 update through the end of second-generation production in 2018**. It intentionally excludes the 2006–2013 pre-facelift body and the earlier OM646 engine family.

The researched factory powertrain families are:

- OM651 2.143L four-cylinder diesels at 95, 129 and 163 PS in the initial facelift phase;
- revised 114- and 143-PS OM651 calibrations introduced for the late W906 phase, while 163 PS continued;
- OM642 3.0L V6 diesel at approximately 190 PS / 440 Nm;
- M271 1.8L supercharged petrol at approximately 156 PS / 240 Nm;
- factory 316 NGT natural-gas derivative using the M271 family;
- RWD with six-speed ECO Gear manual, 7G-TRONIC PLUS, and the North-American V6 five-speed automatic application;
- selectable Sprinter 4x4 with raised chassis, transfer case and driven front axle.

Body choices such as short/medium/long/extra-long vans, normal/high/super-high roofs, cargo/crew/passenger vans, chassis cabs, pickups, dual-rear-wheel heavy chassis and factory minibus derivatives materially alter mass and handling but do not automatically create a new engine/transmission row. They remain an owner body-policy decision.

## Mechanically consolidated candidate matrix

Rows separate engine calibration, transmission architecture or driven-axle layout. Model designations and GVW classes using the same mechanical combination are not duplicated.

### Diesel RWD rows

| # | Period / market | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|---|
| 1 | 2013–2016 Europe | OM651 2.143L four-cylinder diesel, 95 PS / 250 Nm | 6-speed ECO Gear manual | RWD | `verified_family` |
| 2 | 2013–2016 Europe | OM651 95 PS / 250 Nm | 7G-TRONIC PLUS 7-speed torque-converter automatic | RWD | `verified_architecture`; exact low-output availability pending retained price list |
| 3 | 2013–2016 Europe | OM651 129 PS / 305 Nm | 6-speed ECO Gear manual | RWD | `verified_family` |
| 4 | 2013–2016 Europe | OM651 129 PS / 305 Nm | 7G-TRONIC PLUS | RWD | `verified_family` |
| 5 | 2013–2018 Europe/global | OM651 163 PS / 360 Nm | 6-speed ECO Gear manual | RWD | `verified_family` |
| 6 | 2013–2018 Europe/global and North America | OM651 163 PS / 360 Nm | 7G-TRONIC PLUS | RWD | `verified`; North-American 2.1L source-era architecture included |
| 7 | 2013–2018 Europe/global | OM642 3.0L V6 diesel, approximately 190 PS / 440 Nm | 6-speed ECO Gear manual | RWD | `verified_family`; exact body/GVW restrictions pending |
| 8 | 2013–2018 Europe/global | OM642 V6, approximately 190 PS / 440 Nm | 7G-TRONIC PLUS | RWD | `verified_family` |
| 9 | 2014–2018 North America | OM642 V6, approximately 188–190 hp/PS and 440 Nm-class torque | 5-speed 5G-TRONIC/NAG1 torque-converter automatic | RWD | `verified`; distinct North-American transmission architecture |
| 10 | 2016–2018 Europe | revised OM651 low-output calibration, 114 PS / 300 Nm | 6-speed ECO Gear manual | RWD | `verified_output_family` |
| 11 | 2016–2018 Europe | revised OM651 114 PS / 300 Nm | 7G-TRONIC PLUS | RWD | `provisional_availability`; retain only with primary price-list confirmation |
| 12 | 2016–2018 Europe | revised OM651 middle-output calibration, 143 PS / 350 Nm | 6-speed ECO Gear manual | RWD | `verified_output_family` |
| 13 | 2016–2018 Europe | revised OM651 143 PS / 350 Nm | 7G-TRONIC PLUS | RWD | `verified_output_family`; exact body restrictions pending |

### Petrol and factory natural-gas RWD rows

| # | Period / market | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|---|
| 14 | facelift generation, selected markets | M271 E18 ML 1.8L supercharged petrol inline-four, approximately 156 PS / 240 Nm | 6-speed manual | RWD | `verified_engine_family`; facelift transmission/body availability requires primary closure |
| 15 | facelift generation, selected markets | M271 E18 ML petrol, approximately 156 PS / 240 Nm | 7G-TRONIC PLUS | RWD | `provisional_primary_gap` |
| 16 | facelift generation, selected markets | factory 316 NGT M271 1.8L supercharged natural-gas/petrol-capable engine, approximately 156 PS / 240 Nm | 6-speed manual | RWD | `verified_factory_family`; exact tank/body restrictions pending |
| 17 | facelift generation, selected markets | factory 316 NGT M271, approximately 156 PS / 240 Nm | 7G-TRONIC PLUS | RWD | `provisional_primary_gap` |

### Sprinter 4x4 rows

| # | Period / market | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|---|
| 18 | 2013–2016 Europe | OM651 129 PS / 305 Nm | 6-speed ECO Gear manual | selectable Sprinter 4x4 with transfer case and driven front axle | `verified`; 313/513 BlueTEC 4x4 family |
| 19 | 2013–2018 Europe | OM651 163 PS / 360 Nm | 6-speed ECO Gear manual | selectable Sprinter 4x4 | `verified`; 316/516 BlueTEC 4x4 family |
| 20 | 2016–2018 Europe | revised OM651 143 PS / 350 Nm | 6-speed ECO Gear manual | selectable Sprinter 4x4 | `provisional_continuation`; primary late-W906 price list required |
| 21 | 2013–2018 Europe and 2015–2018 North America | OM642 V6, approximately 190 PS / 440 Nm | 5-speed torque-converter automatic | selectable Sprinter 4x4 | `verified`; 319/519 and North-American V6 4x4 family |

**Mechanically consolidated candidate total: 21 configurations.**

Rows 2, 11, 15, 17 and 20 remain catalog candidates but are explicitly evidence-blocked where exact facelift market/body availability has not yet been retained from a primary Mercedes price list or technical guide. They may be approved as scope, but guessed implementation is prohibited.

## Body and chassis candidates

### Strict source body

The source-compatible physical configuration is:

- facelift W906;
- windowed Kombi/passenger-style van;
- 4,325-mm long wheelbase;
- approximately 6,945-mm body length;
- high roof;
- single rear wheels;
- RWD ride height and standard road suspension;
- one representative passenger/cargo mass state.

### Other factory bodies

The generation also used multiple wheelbases, roof heights, cargo/crew/passenger layouts, chassis cabs, pickups, dual rear wheels, super-single rear tyres and factory minibus bodies. These require separate geometry, mass, axle-load, drag and tyre/brake calibration and should not be represented merely by changing payload on the source shell.

## Chassis and drivetrain architecture

RWD rows require a longitudinal front engine, dry clutch or torque converter, gearbox, prop shaft and live driven rear axle. The source single-rear-wheel body requires two physical rear tyres and its correct rear-axle/leaf-spring calibration.

Sprinter 4x4 rows require the raised chassis, front transfer drive, transfer case, front differential, driven front half-shafts and selectable 4x4 control logic. Optional low range and differential-lock packages should be metadata or a selected standard state rather than duplicate catalog rows unless the owner explicitly requests them.

## Transmission architecture assessment

- ECO Gear six-speed manuals require a driver-operated dry clutch, exact gear and reverse ratios, final drive, synchronizer behaviour, engine braking and commercial-vehicle driveline compliance.
- 7G-TRONIC PLUS requires a real hydrodynamic torque converter, multiplication, creep, progressive lock-up, seven planetary ratios, hydraulic shift phases, kickdown and thermal protection.
- The North-American/4x4 five-speed automatic is a separate NAG1/5G-TRONIC architecture and must not reuse the seven-speed ratios or shift schedule.
- A 4x4 transfer case is downstream of the transmission and cannot be approximated by an axle-traction multiplier.

## Engine and driveline audio architecture

Required families include OM651 four-cylinder common-rail diesel, OM642 V6 diesel with even 120-degree firing cadence, M271 supercharged petrol four, NGT gaseous-fuel combustion, six-speed manual gear/driveline layers, five-/seven-speed converter automatics and transfer-case/front-driveline layers for 4x4. The V6, petrol/NGT and four-cylinder diesel rows require genuinely distinct combustion and induction models.

## Evidence still required before parameter commitment

Before implementation retain primary Mercedes-Benz brochures, price lists, body-builder information and service data for:

- exact facelift engine/output dates and body/GVW restrictions;
- confirmation or removal of evidence-blocked rows 2, 11, 15, 17 and 20;
- ECO Gear, 5G-TRONIC and 7G-TRONIC PLUS codes, ratios, converter/clutch limits and reverse ratios;
- one standard final-drive ratio and differential state per approved RWD row;
- transfer-case ratios, front/rear final drives, torque distribution and low-range availability for 4x4;
- source Kombi wheelbase, roof, kerb mass, passenger/payload state, axle ratings, tyres, brakes, spring/damper rates and steering;
- drag, frontal area, crosswind behaviour and performance targets;
- NGT tank mass, fuel capacity and engine-control differences.

The 2013 Mercedes facelift press material, 2013 Sprinter 4x4 launch information and North-American Sprinter specifications establish the principal engine and transmission families. Detailed European ordering combinations remain provisional where the original price-list tables have not yet been retained.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Include all **21** listed configurations or select specific engine/transmission groups?
2. Retain the evidence-blocked rows 2, 11, 15, 17 and 20 subject to mandatory primary confirmation, or remove them now?
3. Keep only the source-like facelift long-wheelbase high-roof windowed single-rear-wheel body?
4. Exclude short/medium/extra-long bodies, other roofs, cargo shell, chassis cab, pickup, dual-rear-wheel and minibus body duplicates?
5. Include factory petrol and 316 NGT rows?
6. Include the distinct North-American OM642 plus five-speed-automatic RWD row?
7. Include all four Sprinter 4x4 rows with the complete transfer case and front driveline?
8. Use one representative body mass/passenger-payload state per powertrain?
9. Use one verified standard final drive and one standard differential/4x4 state per row?
10. Omit BlueTEC/DPF/SCR/Euro-standard, ECO start/stop, low-range and assistance-system revisions as duplicate catalog rows or selectable metadata, selecting one representative state per row?
11. Exclude LPG, aftermarket CNG, camper, ambulance, armoured, tuning and other conversions?
12. Is any expected engine, transmission, drivetrain, body or market variant missing?

No implementation begins after this individual decision. Research proceeds to model 16 only after the owner fixes model 15 scope, and implementation begins only after every included model has reached `approved`.