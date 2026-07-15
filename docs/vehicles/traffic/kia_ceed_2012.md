# Kia cee'd JD five-door hatchback — research and owner-scope gate

- Model number in Traffic Rider bundle: **11**
- Source GLB: `11_kia_ceed_2012.glb`
- Source SHA-256: `bc84bc41e7a4ca000826b38153a64b3f66d0d2532c068da30038046d614ac941`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents a **European/UK-market Kia cee'd JD five-door hatchback from the 2012–2015 pre-facelift phase**, using a standard EcoDynamics-style road-car appearance rather than GT bodywork.

Visible texture evidence includes:

- five-door hatchback body;
- UK plate treatment;
- `cee'd` rear marking and an EcoDynamics-style green efficiency badge;
- original JD grille, bumpers, lamps and tail lamps;
- ordinary alloy wheels and a single standard exhaust presentation;
- no GT-specific bumpers, 18-inch wheels, red trim, twin exhaust or pro_cee'd three-door body.

The exact source engine and equipment grade are not resolved by the low-resolution badge texture. Identity confidence is **high for a standard pre-facelift five-door JD cee'd and low for the exact engine/trim**.

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

The wheelbase-derived dimensions are consistent with the five-door JD hatchback. The committed GLB remains unchanged; wheel separation, collision, catalog, physics, transmission and audio work remain blocked by the global research gate.

## Research boundary

The complete candidate scope covers the **European second-generation Kia cee'd JD five-door hatchback from 2012 through 2018**, including the 2012–2015 original phase and the 2015–2018 facelift.

The body boundary excludes the pro_cee'd three-door hatchback and cee'd Sportswagon. All production rows are transverse-engine, front-wheel-drive configurations; no factory AWD row is evidenced for the European JD cee'd.

## Mechanically consolidated candidate matrix

Rows separate materially different engines, calibrations and transmission architectures. Pure trim, paint, emissions-standard and model-year duplicates are not counted.

### Petrol rows

| # | Period | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|---|
| 1 | 2012–early 2013 | 1.4L Gamma CVVT MPI naturally aspirated inline-four, approximately 100 PS / 137 Nm | 5-speed conventional manual transaxle | FWD | `verified_family`; exact market cut-off pending |
| 2 | 2013–2015 | 1.4L Gamma CVVT MPI naturally aspirated inline-four, approximately 100 PS / 137 Nm | 6-speed conventional manual transaxle | FWD | `verified_family` |
| 3 | 2015–2018 | 1.4L Kappa MPI naturally aspirated inline-four, approximately 100 PS / 134 Nm | 6-speed conventional manual transaxle | FWD | `verified_family`; mechanically distinct 1,368-cc facelift engine |
| 4 | 2012–2018 | 1.6L Gamma GDI naturally aspirated direct-injected inline-four, 135 PS / approximately 165 Nm | 6-speed conventional manual transaxle | FWD | `verified_family`; Euro revisions merged |
| 5 | 2012–2018 | 1.6L Gamma GDI naturally aspirated direct-injected inline-four, 135 PS / approximately 165 Nm | Hyundai-Kia 6-speed dry dual-clutch transaxle | FWD | `verified_family`; exact DCT code/ratios pending |
| 6 | 2015–2018 | 1.0L Kappa T-GDI turbocharged direct-injected inline-three, 100 PS / approximately 172 Nm | 6-speed conventional manual transaxle | FWD | `verified_facelift_family` |
| 7 | 2015–2018 | 1.0L Kappa T-GDI turbocharged direct-injected inline-three, 120 PS / approximately 172 Nm | 6-speed conventional manual transaxle | FWD | `verified_facelift_family` |
| 8 | 2013–2018 | cee'd GT 1.6L Gamma T-GDI turbocharged direct-injected inline-four, 204 PS / 265 Nm | 6-speed conventional manual transaxle | FWD | `verified`; five-door GT existed, but requires GT chassis/visual treatment if factory accuracy is selected |

### Diesel rows

| # | Period | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|---|
| 9 | 2012–early 2013 | 1.4L U2 CRDi common-rail turbo-diesel inline-four, 90 PS / approximately 220 Nm | 5-speed conventional manual transaxle | FWD | `verified_family`; exact changeover pending |
| 10 | 2013–2017 | 1.4L U2 CRDi common-rail turbo-diesel inline-four, 90 PS / approximately 220 Nm | 6-speed conventional manual transaxle | FWD | `verified_family`; emissions revisions merged |
| 11 | 2012–2015 | 1.6L U2 CRDi common-rail turbo-diesel inline-four, 110 PS / approximately 260 Nm | 6-speed conventional manual transaxle | FWD | `verified_family` |
| 12 | 2012–2015 | 1.6L U2 CRDi common-rail turbo-diesel inline-four, 128 PS / 260 Nm | 6-speed conventional manual transaxle | FWD | `verified_family` |
| 13 | 2012–2015 | 1.6L U2 CRDi common-rail turbo-diesel inline-four, 128 PS / 260 Nm | Hyundai-Kia 6-speed planetary torque-converter automatic | FWD | `verified_family`; exact automatic code/ratios pending |
| 14 | 2015–2018 | 1.6L U2 CRDi common-rail turbo-diesel inline-four, 110 PS / approximately 280 Nm | 6-speed conventional manual transaxle | FWD | `verified_facelift_family`; higher-torque calibration |
| 15 | 2015–2018 | 1.6L U2 CRDi common-rail turbo-diesel inline-four, 136 PS / approximately 280 Nm | 6-speed conventional manual transaxle | FWD | `verified_facelift_family` |
| 16 | 2015–2018 | 1.6L U2 CRDi common-rail turbo-diesel inline-four, 136 PS / up to approximately 300 Nm in DCT calibration | Hyundai-Kia 7-speed dry dual-clutch transaxle | FWD | `verified_facelift_family`; exact DCT code/limits pending |

**Mechanically consolidated candidate total: 16 configurations.**

The 1.6 GDI manual and six-speed DCT remain separate because the clutch paths and shifting architecture differ. The 1.6 CRDi 128 manual and torque-converter automatic, and the 136 manual and seven-speed DCT, likewise remain separate.

## Body and visual policy candidates

- **Source 2012–2015 standard five-door:** exact visual anchor.
- **Facelift 2015–2018:** revised bumpers, grille, lamps and detail trim.
- **cee'd GT:** dedicated bumpers, grille, lights, 18-inch wheels, larger brakes, twin exhaust and sport suspension.
- **pro_cee'd:** three-door body and therefore outside the current body boundary.
- **Sportswagon:** longer estate body and outside the current body boundary.

Possible policies are to retain only the source-like standard pre-facelift body for every powertrain, create correct facelift and GT derivatives, or restrict mechanics to source-phase standard versions.

## Chassis and drivetrain architecture

Every row uses a transverse front engine, front transaxle and FWD. The JD platform uses MacPherson-strut front suspension and a multi-link rear axle. Each approved row still requires engine/transmission-correct mass, front axle load, tyres, brakes, spring/damper rates and steering calibration.

The GT row requires its larger brakes, sport spring/damper calibration, wheel/tyre package and electronic-control tuning if it remains in scope. It must not be represented only by increasing engine torque in the standard chassis.

## Transmission architecture assessment

- Five- and six-speed manuals require a driver-operated dry clutch, exact ratios, final drive, engine braking and synchronizer behaviour.
- The six-speed DCT used with 1.6 GDI requires two dry clutch paths, odd/even preselection, clutch-temperature/wear behaviour, launch and creep without a torque converter.
- The 1.6 CRDi 128 automatic requires a genuine six-speed planetary torque-converter model with multiplication, slip, creep, lock-up, shift phases, kickdown and thermal protection.
- The facelift 136-PS diesel seven-speed DCT is a distinct dry dual-clutch architecture with its own ratios, clutch limits and calibration; it must not be approximated by adding a seventh gear to the earlier six-speed DCT.

## Engine and driveline audio architecture

Required families include naturally aspirated MPI inline-four, naturally aspirated GDI inline-four, turbocharged three-cylinder T-GDI, turbocharged four-cylinder GT, 1.4 CRDi and multiple 1.6 CRDi calibrations. The three-cylinder 1.0 T-GDI requires its actual uneven three-cylinder cadence; GT and diesel variants may not be generated only through pitch or volume changes from the standard petrol engine.

## Evidence still required before parameter commitment

Before implementation retain primary Kia brochures, technical data or workshop information for exact model-year/market availability, gearbox codes and ratios, clutch/converter limits, one standard final drive and differential state per approved row, body-correct mass and axle loads, tyres, brakes, drag and performance targets, and exact facelift/GT chassis changes.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Cover all 16 listed configurations or select specific engine/transmission groups?
2. Keep the five-door hatchback body only, excluding pro_cee'd and Sportswagon?
3. Include the five-door cee'd GT 204-PS row?
4. Preserve only the source-like standard 2012–2015 appearance for every row, or create correct facelift and GT visual derivatives?
5. Keep early 5-speed and later 6-speed 1.4 petrol/diesel manuals as separate configurations?
6. Keep the 1.6 GDI 6MT and six-speed DCT separate?
7. Keep 1.6 CRDi manual, torque-converter automatic and seven-speed DCT rows separate?
8. Use one verified standard final drive and one standard differential state per row?
9. Exclude LPG/CNG and all aftermarket or fleet conversions?
10. Omit DPF, emissions-standard and stop/start subdivisions from the catalog, using one representative calibration per row?
11. Is any expected engine, transmission, body or model-year variant missing?

No implementation begins after this individual decision. Research proceeds to model 12 only after the owner fixes model 11 scope, and implementation begins only after every included model has reached `approved`.