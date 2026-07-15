# Volkswagen Golf VII hatchback — research and owner-scope gate

- Model number in Traffic Rider bundle: **10**
- Source GLB: `10_volkswagen_golf_vii_2013.glb`
- Source SHA-256: `d8ff27d0dd2dbfed76723cbe7c04d042af891a127a68fe0dbdbe8946f2220260`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents a **European/German-market 2013 Volkswagen Golf VII five-door hatchback**, Type 5G/AU, with the original pre-facelift exterior and a standard non-performance TSI presentation.

Visible source evidence includes:

- five-door hatchback body;
- German `WOB` plate treatment;
- standard pre-facelift grille, bumpers, lamps and exhaust presentation;
- Volkswagen alloy wheels and ordinary road tyres rather than GTI, GTD or R equipment;
- rear `TSI` marking, while the low-resolution texture does not reliably distinguish the exact 1.2/1.4 engine calibration or trim line;
- no GTI red striping, GTD detailing, R quad exhaust, GTE blue accents, e-Golf charging treatment or post-2017 lamp design.

Identity confidence is **high for a 2013 European five-door pre-facelift standard TSI Golf VII; exact TSI output and Trendline/Comfortline/Highline trim are unresolved**.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Wheelbase | 2,637 mm / 2.637 m |
| Overall length | approximately 4,255 mm / 4.255 m for the standard hatchback |
| Width excluding mirrors | approximately 1,799 mm / 1.799 m |
| Standard-body height | approximately 1,452 mm / 1.452 m |
| Source meshes | 3 |
| Body mesh | `AI_Golf7_High_VW_Golf_VII_2013_0` |
| Front wheel-pair mesh | `on_teker.009_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.010_wheel_0` |
| Body triangles | 1,406 |
| Front wheel-pair triangles | 288 |
| Rear wheel-pair triangles | 288 |
| Total triangles | 1,982 |
| Source scene AABB | approximately 2.721769 × 2.123957 × 6.047423 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 3.866569 source units |
| Approximate wheelbase-derived scale | 0.682000 |

The committed GLB remains unchanged. Four independent wheels, collision, catalog, physics, transmission and audio remain deferred by the global research gate.

## Research boundary

The complete candidate research covers the **European Golf VII hatchback generation from 2012 through 2020**, including:

- original 2012–2016 pre-facelift hatchback represented by the source;
- 2017–2020 facelift hatchback;
- standard TSI and TDI engines;
- TGI compressed-natural-gas models;
- GTD, GTI, GTI Performance, Clubsport, Clubsport S, TCR and R;
- GTE plug-in hybrid;
- both e-Golf battery/motor generations;
- front-wheel drive and factory 4Motion applications;
- mechanically distinct manual, dry-clutch DSG, wet-clutch DSG, hybrid DSG and electric reduction transmissions.

The body boundary excludes Golf Variant, Alltrack, Sportsvan and Cabriolet. North-American-only 1.8 TSI/conventional-automatic combinations and regional tuning derivatives such as R360S are not core European hatchback rows.

## Mechanically consolidated candidate matrix

Each listed transmission or drivetrain alternative is a separate candidate configuration. Model years are merged where engine output, transmission architecture and drivetrain remain mechanically equivalent. Exact country/order restrictions remain subject to retained Volkswagen primary documentation before parameters are committed.

### Standard petrol and TGI rows

| Engine / calibration | Model-year phase | Factory transmission and drivetrain alternatives | Candidate rows |
|---|---|---|---:|
| 1.2 TSI 85 PS / 160 Nm | pre-facelift | 5-speed manual, FWD | 1 |
| 1.2 TSI 105 PS / 175 Nm | pre-facelift | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.2 TSI 110 PS / 175 Nm | later pre-facelift | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.0 TSI 85 PS / 175 Nm | facelift | 5-speed manual, FWD | 1 |
| 1.0 TSI 110 PS / 200 Nm | transition/facelift | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.0 TSI 115 PS / 200 Nm | BlueMotion/late applications | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.4 TSI 122 PS / 200 Nm | early pre-facelift | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.4 TSI 125 PS / 200 Nm | later pre-facelift | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.4 TSI ACT 140 PS / 250 Nm | early pre-facelift | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.4 TSI ACT 150 PS / 250 Nm | later pre-facelift | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.5 TSI ACT 130 PS / 200 Nm | facelift | 6-speed manual FWD; DQ200-family 7-speed dry DSG FWD | 2 |
| 1.5 TSI ACT 150 PS / 250 Nm | facelift | 6-speed manual FWD; DQ200-family 7-speed dry DSG FWD | 2 |
| 1.4 TGI 110 PS / 200 Nm | pre-facelift factory CNG | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.5 TGI 130 PS / 200 Nm | late facelift factory CNG | 6-speed manual FWD; DQ200-family 7-speed dry DSG FWD | 2 |

**Standard petrol/TGI subtotal: 26 configurations.**

### Diesel rows

| Engine / calibration | Model-year phase | Factory transmission and drivetrain alternatives | Candidate rows |
|---|---|---|---:|
| 1.6 TDI 90 PS / 230 Nm | generation applications | 5-speed manual FWD | 1 |
| 1.6 TDI 105 PS / 250 Nm | early pre-facelift | 5-speed manual FWD; DQ200 7-speed dry DSG FWD; 6-speed manual 4Motion | 3 |
| 1.6 TDI 110 PS / 250 Nm | later pre-facelift | 5-speed manual FWD; DQ200 7-speed dry DSG FWD; dedicated 6-speed manual BlueMotion FWD; 6-speed manual 4Motion | 4 |
| 1.6 TDI 115 PS / 250 Nm | facelift | 5-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 2.0 TDI 150 PS / 320–340 Nm | generation applications | 6-speed manual FWD; DQ250 6-speed wet DSG FWD; DQ381 7-speed wet DSG FWD; 6-speed manual 4Motion | 4 |
| GTD 2.0 TDI 184 PS / 380 Nm | pre- and post-facelift | 6-speed manual FWD; DQ250 6-speed wet DSG FWD; DQ381 7-speed wet DSG FWD | 3 |

**Diesel subtotal: 17 configurations.**

### Performance petrol rows

| Model / calibration | Model-year phase | Factory transmission and drivetrain alternatives | Candidate rows |
|---|---|---|---:|
| GTI 220 PS / 350 Nm | pre-facelift | 6-speed manual FWD; DQ250 6-speed wet DSG FWD | 2 |
| GTI Performance 230 PS / 350 Nm | pre-facelift | 6-speed manual FWD; DQ250 6-speed wet DSG FWD; VAQ front differential required | 2 |
| GTI 230 PS | facelift | 6-speed manual FWD; DQ381 7-speed wet DSG FWD | 2 |
| GTI Performance 245 PS / 370 Nm | facelift | 6-speed manual FWD; DQ381 7-speed wet DSG FWD; VAQ front differential required | 2 |
| GTI Clubsport 265 PS, temporary 290-PS overboost | pre-facelift special | 6-speed manual FWD; DQ250 6-speed wet DSG FWD; VAQ required | 2 |
| GTI Clubsport S 310 PS | pre-facelift, limited three-door | 6-speed manual FWD; VAQ and model-specific chassis | 1 |
| GTI TCR 290 PS / 380 Nm | facelift special, available as hatchback without a three-door-only restriction | DQ381 7-speed wet DSG FWD; VAQ required | 1 |
| Golf R 300 PS / 380 Nm | pre-facelift | 6-speed manual 4Motion; DQ250 6-speed wet DSG 4Motion | 2 |
| Golf R 310 PS / 400 Nm | early facelift | 6-speed manual 4Motion; DQ381 7-speed wet DSG 4Motion | 2 |
| Golf R 300 PS late emissions calibration | late facelift | DQ381 7-speed wet DSG 4Motion | 1 |

**Performance petrol subtotal: 17 configurations.**

### Electrified rows

| Model | Powertrain | Transmission / drivetrain | Candidate rows |
|---|---|---|---:|
| Golf GTE | 1.4 TSI 150 PS plus 75-kW motor; 204-PS / 350-Nm system; approximately 8.7-kWh battery | DQ400e six-speed hybrid DSG with K0 disconnect clutch, FWD | 1 |
| e-Golf early | 85-kW / 270-Nm permanent-magnet synchronous motor; 24.2-kWh gross, approximately 21.2-kWh usable battery | EQ270-family single-speed fixed-reduction transaxle, FWD | 1 |
| e-Golf facelift | 100-kW / 290-Nm motor; 35.8-kWh battery | revised single-speed fixed-reduction transaxle, FWD | 1 |

**Electrified subtotal: 3 configurations.**

## Candidate total

- standard petrol/TGI: **26**;
- diesel: **17**;
- performance petrol: **17**;
- GTE/e-Golf: **3**.

**Mechanically consolidated candidate total: 63 configurations.**

This total does not create duplicate trim, paint, equipment, model-year or emissions-state entries. Exact low-volume and country-specific ordering evidence may remove or refine provisional rows before implementation, but no unsupported hardware may be guessed.

## Body, visual and package subdivisions

The source is a standard five-door pre-facelift TSI. Other groups require distinct physical presentation if factory visual accuracy is selected:

- 2017–2020 facelift requires revised bumpers, lamps, grille and interior details;
- GTI, GTD and GTI Performance require their own bumpers, grille bands, exhaust, brakes, wheels and trim;
- Clubsport, Clubsport S and TCR require dedicated aero, wheels and brakes; Clubsport S additionally requires three-door body work;
- Golf R requires R bumpers, quad exhaust, brakes, wheels and 4Motion chassis presentation;
- GTE and e-Golf require charging-port, lighting, aero-wheel and badging changes;
- TGI requires CNG tank mass, fuel-system packaging and fuel-state behaviour even if exterior differences are small.

A source-body homogenization is possible only as an explicit owner decision and must not be described as factory-correct trim availability.

## Chassis and drivetrain architecture

All rows use an MQB unit body, transverse front power unit, MacPherson-strut front suspension and electric steering.

The rear suspension is not uniform:

- lower-output front-drive cars below approximately 90 kW use a torsion-beam rear axle;
- higher-output, performance and 4Motion cars use a multi-link rear axle;
- 4Motion uses a PTU, prop shaft, electronically controlled rear coupling/final drive and driven rear half-shafts;
- GTI Performance, Clubsport, Clubsport S and TCR require the VAQ electronically controlled front differential rather than a generic open differential;
- e-Golf and GTE require battery-specific mass distribution, spring/damper rates, braking blending and thermal limits.

Each approved row must carry its correct rear axle, brakes, tyres, mass, centre of gravity and differential/coupling architecture.

## Transmission architecture assessment

### Conventional manuals

Five- and six-speed manuals require a driver-operated dry clutch, exact forward and reverse ratios, final drive, clutch inertia/capacity, launch, engine braking and synchronizer behaviour.

### DQ200 seven-speed dry DSG

Lower-torque TSI, TGI and TDI rows use the DQ200-family dual-dry-clutch transaxle. It requires two clutch paths, odd/even gear preselection, dry-clutch launch and creep, temperature/wear behaviour and torque interruption. It must not use a torque converter.

### DQ250 six-speed wet DSG

Pre-facelift high-torque, GTI, GTD and R applications use the DQ250-family wet dual-clutch transaxle. It requires oil-cooled clutch packs, preselection, launch-control and thermal behaviour, and 4Motion output where applicable.

### DQ381 seven-speed wet DSG

Facelift high-torque applications use the mechanically distinct DQ381-family seven-speed wet DSG. It must retain its own ratios, clutch and hydraulic behaviour rather than adding a seventh ratio to DQ250 timing.

### DQ400e hybrid DSG

The GTE uses a hybrid-specific six-speed DSG with an integrated traction motor and K0 disconnect clutch between the combustion engine and electric drive. It requires electric-only driving, engine start by the traction motor, blended torque, regenerative braking and battery/inverter limits.

### e-Golf single-speed reduction

Both e-Golf rows require a complete electric drive model with motor torque/speed envelope, inverter, battery state and temperature, regenerative braking, coast modes, auxiliary load and their real fixed-reduction transaxle. They must not use a combustion DSG with one selected gear.

## Engine and driveline audio architecture

Required families include:

- EA211 three- and four-cylinder TSI, with cylinder-count, ACT and turbo-specific treatment;
- EA211 evo 1.5 TSI/TGI with its own combustion and boost behaviour;
- EA288 common-rail TDI calibrations, including GTD high-output treatment;
- EA888 GTI/R calibrations with model-specific exhaust, turbo and load response;
- TGI CNG combustion and tank/valve system layers;
- GTE combustion, electric motor, inverter and blended-operation transitions;
- e-Golf electromagnetic motor orders, inverter switching, reduction whine and regenerative-load response.

A three-cylinder TSI may not be synthesized from a four-cylinder waveform, and GTI/R/GTD variants may not be produced only through pitch or volume changes.

## Evidence still required before parameter commitment

Before implementation retain primary Volkswagen brochures, order guides, self-study programmes or workshop data for:

- exact engine-code, output, market and model-year availability;
- exact 5MT/6MT gearbox codes, ratios, clutch and final drives;
- DQ200, DQ250, DQ381 and DQ400e ratios, clutch limits and control behaviour;
- 4Motion coupling generation, limits, final drive and control map;
- VAQ differential limits and calibration;
- one standard final-drive and differential/coupling state for every approved row;
- torsion-beam versus multi-link applicability;
- DPF, OPF, catalyst, ACT, stop/start and emissions revisions;
- GTE battery usable energy and hybrid limits;
- both e-Golf battery, inverter, motor and reduction specifications;
- body-correct mass, axle loads, tyres, brakes, drag and performance targets.

These evidence gates prevent guessed implementation and do not replace the owner-scope decision.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Cover the complete 2012–2020 Golf VII generation, or only the source-compatible 2012–2016 pre-facelift phase?
2. Include all **63** mechanically consolidated configurations, or select engine/powertrain groups?
3. Preserve the five-door hatchback body only, excluding the three-door-only Clubsport S unless its body is adapted?
4. Use only the source-like standard pre-facelift TSI appearance for every approved row, or create correct facelift, GTI/GTD/R, GTE and e-Golf visual derivatives?
5. Include GTI, GTI Performance, Clubsport, Clubsport S, TCR, GTD and R performance versions?
6. Include factory TGI compressed-natural-gas rows?
7. Include GTE and both e-Golf generations, with complete dedicated hybrid/electric drivetrain models?
8. Include factory 4Motion rows and their real rear driveline?
9. Keep every manual, DQ200, DQ250, DQ381, DQ400e and electric-reduction combination separate?
10. Use one standard final drive and one standard differential/VAQ/4Motion state per row, without optional gearing duplicates?
11. Keep DPF, OPF, ACT, stop/start, emissions and coupling-generation changes as selected-year metadata rather than duplicate rows?
12. Exclude Variant, Alltrack, Sportsvan, North-American 1.8 TSI/automatic and regional tuning derivatives as proposed?
13. Is any expected engine, transmission, drivetrain, fuel type, body or special model missing?

No implementation begins after this individual decision. Research proceeds to model 11 only after the owner fixes model 10 scope, and implementation begins only after every included model has reached `approved`.