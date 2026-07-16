# Kia cee'd JD five-door hatchback — research and approved scope

- Model number in Traffic Rider bundle: **11**
- Source GLB: `11_kia_ceed_2012.glb`
- Source SHA-256: `bc84bc41e7a4ca000826b38153a64b3f66d0d2532c068da30038046d614ac941`
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **15 mechanically consolidated Kia cee'd JD five-door configurations**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity and body policy

The source represents a **European/UK-market Kia cee'd JD five-door hatchback from the 2012–2015 pre-facelift phase**, using a standard EcoDynamics-style appearance. Visible evidence includes a UK plate treatment, `cee'd` rear marking, green efficiency badge, original JD grille and lamps, ordinary alloy wheels and a standard single-exhaust presentation.

The owner retained only the existing five-door source body and appearance for every approved row:

- source-like standard 2012–2015 pre-facelift exterior;
- no pro_cee'd three-door body;
- no cee'd Sportswagon body;
- no separate facelift exterior;
- no separate GT exterior, despite retaining the five-door GT powertrain and its required running gear.

This is an explicit project visual homogenization. It is not a claim that facelift engines or the GT were factory-sold with the exact source exterior.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Wheelbase | 2,650 mm / 2.650 m |
| Overall length | approximately 4,310 mm / 4.310 m |
| Width excluding mirrors | approximately 1,780 mm / 1.780 m |
| Height | approximately 1,470 mm / 1.470 m |
| Source meshes | 3 |
| Body mesh | `AI_Kia_Ceed_High_Kia_cee_d_2012_0` |
| Front wheel-pair mesh | `on_teker.010_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.011_wheel_0` |
| Body triangles | 1,414 |
| Front wheel-pair triangles | 360 |
| Rear wheel-pair triangles | 360 |
| Total triangles | 2,134 |
| Source scene AABB | approximately 2.914642 × 2.122200 × 6.199878 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 3.885440 source units |
| Approximate wheelbase-derived scale | 0.682033 |

The committed GLB remains unchanged. Four independent wheels, collision, catalog, physics, transmission and audio remain deferred by the global research gate.

## Owner-directed scope rules

- include every previously listed petrol and diesel engine/transmission row;
- merge only the pre-facelift and facelift **1.6 CRDi 110 PS six-speed-manual** rows into one mechanically consolidated entry;
- keep the 1.6 CRDi 128 PS and 136 PS calibrations separate;
- keep manual, six-speed DCT, six-speed torque-converter automatic and seven-speed DCT architectures separate;
- retain the five-door cee'd GT 204 PS row;
- use one verified standard final-drive ratio and one standard differential state per row;
- do not create optional gearing or differential duplicates;
- exclude LPG, CNG and all aftermarket or fleet conversions;
- do not retain DPF, emissions-standard, catalyst, EGR or stop/start subdivisions as catalog rows or selectable metadata; each approved row receives one evidence-backed representative calibration;
- no expected variant is missing according to the owner.

## Approved petrol matrix — 8 configurations

| # | Engine / calibration | Transmission | Drivetrain | Status |
|---:|---|---|---|---|
| 1 | 1.4L Gamma CVVT MPI naturally aspirated inline-four, approximately 100 PS / 137 Nm | 5-speed conventional manual transaxle | FWD; one standard final drive and differential | **approved** |
| 2 | 1.4L Gamma CVVT MPI naturally aspirated inline-four, approximately 100 PS / 137 Nm | 6-speed conventional manual transaxle | FWD; one standard final drive and differential | **approved** |
| 3 | 1.4L Kappa MPI naturally aspirated inline-four, approximately 100 PS / 134 Nm | 6-speed conventional manual transaxle | FWD; one standard final drive and differential | **approved** |
| 4 | 1.6L Gamma GDI naturally aspirated direct-injected inline-four, 135 PS / approximately 165 Nm | 6-speed conventional manual transaxle | FWD; one standard final drive and differential | **approved** |
| 5 | 1.6L Gamma GDI naturally aspirated direct-injected inline-four, 135 PS / approximately 165 Nm | Hyundai-Kia 6-speed dry dual-clutch transaxle | FWD; one standard final drive and differential | **approved** |
| 6 | 1.0L Kappa T-GDI turbocharged direct-injected inline-three, 100 PS / approximately 172 Nm | 6-speed conventional manual transaxle | FWD; one standard final drive and differential | **approved** |
| 7 | 1.0L Kappa T-GDI turbocharged direct-injected inline-three, 120 PS / approximately 172 Nm | 6-speed conventional manual transaxle | FWD; one standard final drive and differential | **approved** |
| 8 | cee'd GT 1.6L Gamma T-GDI turbocharged direct-injected inline-four, 204 PS / 265 Nm | 6-speed conventional manual transaxle | FWD; one standard final drive and differential; GT running gear required | **approved** |

## Approved diesel matrix — 7 configurations

| # | Engine / calibration | Transmission | Drivetrain | Status |
|---:|---|---|---|---|
| 9 | 1.4L U2 CRDi common-rail turbo-diesel inline-four, 90 PS / approximately 220 Nm | 5-speed conventional manual transaxle | FWD; one standard final drive and differential | **approved** |
| 10 | 1.4L U2 CRDi common-rail turbo-diesel inline-four, 90 PS / approximately 220 Nm | 6-speed conventional manual transaxle | FWD; one standard final drive and differential | **approved** |
| 11 | 1.6L U2 CRDi common-rail turbo-diesel inline-four, **merged 110-PS pre-/post-facelift row**; one evidence-backed representative torque calibration selected at implementation | 6-speed conventional manual transaxle | FWD; one standard final drive and differential | **approved** |
| 12 | 1.6L U2 CRDi common-rail turbo-diesel inline-four, 128 PS / 260 Nm | 6-speed conventional manual transaxle | FWD; one standard final drive and differential | **approved** |
| 13 | 1.6L U2 CRDi common-rail turbo-diesel inline-four, 128 PS / 260 Nm | Hyundai-Kia 6-speed planetary torque-converter automatic | FWD; one standard final drive and differential | **approved** |
| 14 | 1.6L U2 CRDi common-rail turbo-diesel inline-four, 136 PS / approximately 280 Nm | 6-speed conventional manual transaxle | FWD; one standard final drive and differential | **approved** |
| 15 | 1.6L U2 CRDi common-rail turbo-diesel inline-four, 136 PS / up to approximately 300 Nm in DCT calibration | Hyundai-Kia 7-speed dry dual-clutch transaxle | FWD; one standard final drive and differential | **approved** |

**Approved total: 8 petrol + 7 diesel = 15 mechanically consolidated configurations.**

## Explicit exclusions

- a second 1.6 CRDi 110 PS 6MT row for the facelift torque revision;
- pro_cee'd and Sportswagon bodies;
- separate facelift and GT exterior derivatives;
- LPG, CNG and other conversions;
- optional final-drive and differential duplicates;
- separate DPF/non-DPF, emissions-standard, catalyst, EGR or stop/start rows or selectable metadata;
- merging the 1.6 GDI manual and six-speed DCT;
- merging the 1.6 CRDi 128 manual and torque-converter automatic;
- merging the 1.6 CRDi 136 manual and seven-speed DCT.

## Chassis and transmission requirements

Every row uses a transverse front engine, front transaxle and FWD, with MacPherson-strut front suspension and a multi-link rear axle. Engine/transmission-specific mass, front-axle load, tyres, brakes, springs, dampers and steering calibration remain mandatory.

The GT row retains its larger brakes, sport spring/damper calibration, wheel/tyre specification and electronic-control tuning even though the shared source exterior is used.

The five- and six-speed manuals require a driver-operated dry clutch and exact ratios. The 1.6 GDI six-speed DCT requires two dry clutch paths and preselection. The 1.6 CRDi 128 six-speed automatic requires a real hydrodynamic torque converter, creep, lock-up and planetary shift phases. The 136-PS seven-speed DCT is a separate architecture and may not be represented by adding one gear to the earlier six-speed DCT.

## Engine-audio architecture

Required families include naturally aspirated MPI inline-four, naturally aspirated GDI inline-four, turbocharged three-cylinder T-GDI, turbocharged four-cylinder GT, 1.4 CRDi and the distinct 1.6 CRDi calibrations. The 1.0 T-GDI requires its actual three-cylinder cadence; GT and diesel rows may not be generated only by pitch or volume changes from the standard petrol engine.

## Evidence still required before parameter commitment

Before implementation retain primary Kia documentation for exact market dates, gearbox codes and ratios, clutch/converter limits, the representative merged 110-PS diesel calibration, one standard final drive and differential per row, body-correct mass and axle loads, tyres, brakes, drag, performance targets and exact GT chassis data. These gaps do not reopen the approved 15-row catalog scope and do not authorize guessed hardware.

## Owner decision recorded

The owner decided to keep every listed configuration, merge the two 1.6 CRDi 110 PS six-speed-manual rows, retain every other engine and transmission separately, use one standard final drive and differential per row, exclude conversions and emissions subdivisions, and proceed with no additional missing variant.

Model 11 is **`approved`** with **15** configurations. Implementation remains blocked by the global all-model research gate. Research proceeds to model 12.
