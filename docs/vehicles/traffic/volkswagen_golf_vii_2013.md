# Volkswagen Golf VII hatchback — research and approved scope

- Model number in Traffic Rider bundle: **10**
- Source GLB: `10_volkswagen_golf_vii_2013.glb`
- Source SHA-256: `d8ff27d0dd2dbfed76723cbe7c04d042af891a127a68fe0dbdbe8946f2220260`
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **38 mechanically consolidated five-door Golf VII configurations**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity and body policy

The source represents a **European/German-market 2013 Volkswagen Golf VII five-door hatchback**, Type 5G/AU, with the original pre-facelift standard-TSI exterior. It has the standard grille, bumpers, lamps, exhaust presentation and ordinary Volkswagen alloy wheels; it is not a GTI, GTD, R, GTE or e-Golf visual derivative.

The owner approved only the five-door hatchback body. Golf Variant, Alltrack, Sportsvan, Cabriolet and three-door-only derivatives are excluded. All approved powertrains use the source-like five-door standard exterior; facelift and e-Golf mechanics do not create separate visual bodies. This is an explicit project homogenization rather than a claim of factory-correct exterior availability for every row.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Wheelbase | 2,637 mm / 2.637 m |
| Overall length | approximately 4,255 mm / 4.255 m |
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
| Source wheelbase | approximately 3.866569 source units |
| Approximate wheelbase-derived scale | 0.682000 |

The committed GLB remains unchanged. Four independent wheels, collision, catalog, physics, transmission and audio remain deferred by the global research gate.

## Owner-directed scope rules

- include all previously listed standard TSI configurations except TGI;
- include all previously listed ordinary TDI configurations except GTD;
- include both e-Golf motor/battery generations;
- exclude every GTI, GTI Performance, Clubsport, Clubsport S, TCR and Golf R row;
- exclude GTE and every TGI/CNG row;
- retain every distinct manual, DQ200, DQ250, DQ381, 4Motion and electric-reduction architecture that remains in the selected groups;
- use one verified standard final drive and one standard differential or 4Motion-coupling state per row;
- do not create optional gearing or differential duplicates;
- do not store DPF, OPF, emissions-standard, stop/start or similar aftertreatment/revision states as catalog rows or selectable metadata; select one evidence-backed representative calibration for each row;
- keep only the five-door hatchback body;
- no expected variant is missing according to the owner.

## Approved standard petrol matrix — 22 configurations

| Engine / calibration | Transmission and drivetrain alternatives | Rows |
|---|---|---:|
| 1.2 TSI 85 PS / 160 Nm | 5-speed manual FWD | 1 |
| 1.2 TSI 105 PS / 175 Nm | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.2 TSI 110 PS / 175 Nm | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.0 TSI 85 PS / 175 Nm | 5-speed manual FWD | 1 |
| 1.0 TSI 110 PS / 200 Nm | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.0 TSI 115 PS / 200 Nm | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.4 TSI 122 PS / 200 Nm | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.4 TSI 125 PS / 200 Nm | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.4 TSI ACT 140 PS / 250 Nm | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.4 TSI ACT 150 PS / 250 Nm | 6-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 1.5 TSI ACT 130 PS / 200 Nm | 6-speed manual FWD; DQ200-family 7-speed dry DSG FWD | 2 |
| 1.5 TSI ACT 150 PS / 250 Nm | 6-speed manual FWD; DQ200-family 7-speed dry DSG FWD | 2 |

## Approved ordinary-diesel matrix — 14 configurations

| Engine / calibration | Transmission and drivetrain alternatives | Rows |
|---|---|---:|
| 1.6 TDI 90 PS / 230 Nm | 5-speed manual FWD | 1 |
| 1.6 TDI 105 PS / 250 Nm | 5-speed manual FWD; DQ200 7-speed dry DSG FWD; 6-speed manual 4Motion | 3 |
| 1.6 TDI 110 PS / 250 Nm | 5-speed manual FWD; DQ200 7-speed dry DSG FWD; dedicated 6-speed manual BlueMotion FWD; 6-speed manual 4Motion | 4 |
| 1.6 TDI 115 PS / 250 Nm | 5-speed manual FWD; DQ200 7-speed dry DSG FWD | 2 |
| 2.0 TDI 150 PS / 320–340 Nm | 6-speed manual FWD; DQ250 6-speed wet DSG FWD; DQ381 7-speed wet DSG FWD; 6-speed manual 4Motion | 4 |

## Approved electric matrix — 2 configurations

| Model | Powertrain | Transmission / drivetrain |
|---|---|---|
| e-Golf early | 85-kW / 270-Nm permanent-magnet synchronous motor; 24.2-kWh gross battery | EQ270-family single-speed fixed-reduction transaxle, FWD |
| e-Golf facelift | 100-kW / 290-Nm motor; 35.8-kWh battery | revised single-speed fixed-reduction transaxle, FWD |

**Approved total: 22 standard petrol + 14 ordinary diesel + 2 electric = 38 configurations.**

## Explicit exclusions

- GTD;
- every TGI/CNG row;
- GTE;
- GTI, GTI Performance, Clubsport, Clubsport S, TCR and Golf R;
- Variant, Alltrack, Sportsvan, Cabriolet and alternative body rows;
- North-American-only 1.8 TSI/conventional-automatic combinations;
- regional tuning derivatives;
- optional final-drive and differential duplicates;
- DPF, OPF, emissions-standard and stop/start catalog or metadata subdivisions.

## Chassis and drivetrain requirements

Lower-output FWD rows must use their torsion-beam rear axle where applicable, while higher-output and 4Motion rows use the correct multi-link rear architecture. The remaining 4Motion diesel rows require a PTU, prop shaft, electronically controlled rear coupling/final drive and driven rear half-shafts. They must not be represented as FWD cars with a traction multiplier.

Every manual, DQ200, DQ250 and DQ381 row remains a distinct transmission architecture. DQ200 requires two dry clutch paths and preselection; DQ250 and DQ381 require their correct wet clutch packs, ratios, hydraulics and thermal behaviour. The e-Golf rows require complete motor, inverter, battery, regenerative-braking and fixed-reduction models rather than a combustion DSG locked in one gear.

## Evidence still required before parameter commitment

Before implementation retain primary Volkswagen evidence for exact engine codes and dates, gearbox ratios and clutch limits, one standard final drive per row, 4Motion coupling data, rear-suspension applicability, battery usable energy and motor/inverter limits, plus body-correct mass, tyres, brakes, drag and performance targets. These evidence gaps do not reopen the approved 38-row scope and do not authorize guessed hardware.

## Owner decision recorded

The owner decided to include every listed standard petrol and ordinary diesel configuration plus both e-Golf generations, while excluding GTD, TGI, GTE and every performance petrol model. Only the five-door hatchback body remains. Every row uses one standard gearing and differential/coupling state, and emissions/aftertreatment revisions such as DPF are not retained as separate rows or selectable metadata. Missing expected variants: **none identified by the owner**.

Model 10 is **`approved`** with **38** configurations. Implementation remains blocked by the global all-model research gate. Research proceeds to model 11.