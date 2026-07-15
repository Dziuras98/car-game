# Renault Maxity F24 single-cab box truck — research and owner-scope gate

- Model number in Traffic Rider bundle: **12**
- Source GLB: `12_renault_maxity_2008.glb`
- Source SHA-256: `37dd295636b56ebaecee37c1d461ee64349ee0c0bb697dfb484e94e49b0132f3`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents an **original-body Renault Maxity, approximately model year 2008, with a single cab, enclosed box body and dual rear wheels**. It belongs to the Nissan F24-derived first Maxity phase introduced in 2007 rather than the later NT400-style front treatment.

Visible source evidence includes:

- Renault diamond and `MAXITY` branding;
- original narrow F24/Maxity cab and headlamp treatment;
- single-row cab rather than a crew cab;
- white enclosed box body with rear double doors and a side access door;
- dual tyres on each side of the driven rear axle;
- a small cab-side power badge whose texture is most consistent with **130**, although the low resolution prevents treating the exact suffix/GVW code as proven;
- standard road-chassis ride height rather than a 4x4 conversion.

The geometry and proportions are most consistent with the short **2,500-mm wheelbase**, but this remains a provisional identification until retained body-builder or Renault dimensional evidence is matched to the exact box length and rear overhang.

Identity confidence is **high for original-body Maxity single-cab box truck with dual rear wheels; moderate for 2,500-mm wheelbase and 130-PS source calibration**.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Provisional source wheelbase | 2,500 mm / 2.500 m |
| Cab width | approximately 1,870 mm / 1.870 m |
| Source meshes | 3 |
| Body mesh | `AI_Maxity_High_Renault_Maxity_2008_0` |
| Front wheel-pair mesh | `on_teker.011_wheel_0` |
| Rear dual-wheel mesh | `arka_teker.012_wheel_0` |
| Body triangles | 1,022 |
| Front wheel assembly triangles | 396 |
| Rear dual-wheel assembly triangles | 684 |
| Total triangles | 2,102 |
| Source scene AABB | approximately 3.580934 × 4.153715 × 7.380428 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 3.912804 source units |
| Provisional 2,500-mm-wheelbase scale | approximately 0.638928 |
| Scaled source envelope at that factor | approximately 2.288 × 2.654 × 4.716 m |

The scaled width includes the box body and mirrors/outer geometry rather than only the 1.870-m cab. The committed GLB remains unchanged. Integration must separate two front wheels and four physical rear tyres, create project-authored collision and retain the box body's mass and aerodynamic effects.

## Research boundary

The candidate scope covers the **original Nissan F24-derived Renault Maxity body from 2007 through the early 2010s**, before the later NT400-style exterior. The researched production families are:

- initial Euro-IV-era DXi2.5 110 and 130 calibrations;
- initial/continuing DXi3 150 calibration;
- later Euro-V-era DXi2.5 120 and 140 calibrations;
- the PVI-integrated Renault Maxity Electric sold as a complete electric derivative.

The body range included different gross-vehicle-weight classes, single and crew cabs, approximately 2,500/2,900/3,400-mm wheelbases and chassis-cab, platform, tipper and box applications. Those body/GVW choices do not automatically duplicate an identical powertrain, but each materially changes mass, axle load, centre of gravity, drag and tyre/brake requirements.

All production combustion candidates use a front-mounted longitudinal engine and rear-wheel drive through a live rear axle. No core factory AWD row is evidenced for the Renault Maxity range represented here.

## Mechanically consolidated candidate matrix

The table separates nominally different engine outputs and transmission architectures. Exact changeover dates, gearbox codes and country/GVW restrictions remain evidence gates.

| # | Period | Powertrain | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|---|
| 1 | approximately 2007–2010 | DXi2.5 / Nissan YD25DDTi 2.5L common-rail turbo-diesel inline-four, approximately 110 PS | 5-speed conventional manual gearbox | RWD, live rear axle | `verified_family`; exact gearbox code, torque and GVW availability pending |
| 2 | approximately 2007–2010 | DXi2.5 / Nissan YD25DDTi 2.5L common-rail turbo-diesel inline-four, approximately 130 PS | 6-speed conventional manual gearbox | RWD, live rear axle | `verified_family`; likely source power class, exact badge suffix pending |
| 3 | generation application | DXi3 / Nissan ZD30DDTi 3.0L common-rail turbo-diesel inline-four, approximately 150 PS / 350 Nm | 6-speed conventional manual gearbox | RWD, live rear axle | `verified_family`; Euro revisions may be selected-year hardware rather than duplicate rows |
| 4 | later original-body Euro-V phase | DXi2.5 / YD25-family 2.5L common-rail turbo-diesel inline-four, approximately 120 PS / 250 Nm | 5-speed conventional manual gearbox | RWD, live rear axle | `verified_output_family`; exact date and gearbox code pending |
| 5 | later original-body Euro-V phase | DXi2.5 / YD25-family 2.5L common-rail turbo-diesel inline-four, approximately 140 PS / 270 Nm | 6-speed conventional manual gearbox | RWD, live rear axle | `verified_output_family`; exact date and gearbox code pending |
| 6 | approximately 2011–2013 commercial derivative | Renault Maxity Electric by PVI: electric traction motor approximately 47 kW and 270 Nm with approximately 40-kWh lithium-ion battery | dedicated single-speed fixed-reduction electric driveline | RWD; electric drive to rear axle | `verified_derivative`; exact motor type, inverter limits and reduction ratio pending primary retention |

**Mechanically consolidated candidate total: 6 configurations.**

The 110/120 and 130/140 rows remain separate candidates because their rated outputs and calibration periods differ. The 150-PS DXi3 remains one mechanically merged row unless retained service evidence proves a materially different transmission or engine architecture. The electric derivative is a complete drivetrain, not a fuel-state duplicate of a diesel truck.

## Body, cab and GVW candidates

### Strict source body

The source-compatible physical configuration is:

- single cab;
- provisional 2,500-mm short wheelbase;
- enclosed white box body;
- rear double doors and side access door;
- dual rear wheels;
- source-like original 2007–2010 cab exterior;
- approximately 3.5-tonne-class road chassis, pending exact badge/GVW evidence.

### Other production bodies

The generation also supported longer wheelbases, crew cab, platform, tipper and chassis-cab applications, plus multiple GVW/axle-rating classes. These should create catalog rows only if the owner wants their physical mass, dimensions and handling differences represented. An empty chassis-cab, loaded tipper and tall box truck cannot share one mass, drag or centre-of-gravity calibration.

## Chassis and physics architecture

Every diesel row requires:

- ladder-frame chassis;
- longitudinal front engine and rear-wheel drive;
- manual clutch and gearbox;
- prop shaft;
- live rear axle with leaf springs and dual rear tyres for the source body;
- body/GVW-correct front suspension, steering, brakes and tyre ratings;
- box-body aerodynamic drag, side area and crosswind response;
- empty and payload mass states that respect axle limits;
- load-sensitive rear grip and braking behaviour.

The source rear mesh contains four physical tyres. Integration must not collapse the dual rear wheels into a single visual tyre or a single-width contact patch without a documented equivalent tyre model.

## Transmission architecture assessment

The five- and six-speed diesel gearboxes are conventional driver-operated manuals. They require exact forward and reverse ratios, final drive, dry-clutch inertia/capacity, launch, engine braking, synchronizer behaviour and driveline compliance. The six-speed may not be implemented as the five-speed with one arbitrary added ratio.

No production automated manual or torque-converter automatic row is committed by the current evidence. Such a row must not be added from a generic Cabstar/Atlas market without Renault Maxity-specific proof.

The electric row requires a dedicated motor-to-fixed-reduction path with no gear changes. It must include motor speed/torque limits, inverter current and thermal limits, battery state of charge and voltage sag, regenerative braking, auxiliary loads and the actual rear-axle reduction. It must not use a diesel manual gearbox locked in one gear.

## Engine and driveline audio architecture

| Powertrain | Required treatment |
|---|---|
| DXi2.5 / YD25 | four-cylinder common-rail diesel combustion, turbocharger, injection and gear/driveline layers, with output-specific calibration |
| DXi3 / ZD30 | distinct 3.0L four-cylinder diesel combustion, turbo and load character rather than a pitch-shifted 2.5L profile |
| Maxity Electric | motor electromagnetic orders, inverter switching, fixed-reduction and final-drive whine, tyre/box-body noise and regenerative-load response; no combustion waveform |

## Evidence still required before parameter commitment

Before implementation retain primary Renault Trucks, Nissan or PVI documentation for:

- exact production dates and market/GVW availability of 110, 120, 130, 140 and 150-PS calibrations;
- exact YD25/ZD30 engine codes, torque curves, rev limits and emissions hardware;
- five- and six-speed gearbox codes, ratios, clutch capacities and reverse ratios;
- one standard final-drive ratio and differential state per approved row;
- exact 2,500/2,900/3,400-mm wheelbase dimensions and source-box body match;
- source GVW, kerb mass, payload, axle ratings, tyre sizes and brake hardware;
- suspension architecture and rates by GVW;
- drag, frontal area, crosswind and documented performance targets;
- electric motor continuous/peak envelope, inverter limits, battery gross/usable energy, battery mass, fixed reduction, regeneration and charging data.

These evidence gates prevent guessed implementation but do not block the owner from selecting catalog scope.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Cover all six listed powertrain configurations, or only the 2008-source-period diesels?
2. Keep the 110, 120, 130 and 140-PS DXi2.5 calibrations as separate rows?
3. Include the PVI Maxity Electric with a complete dedicated motor, inverter, battery, regeneration and fixed-reduction model?
4. Keep only the source-like single-cab short-wheelbase box body with dual rear wheels?
5. Exclude crew cab, platform, tipper, chassis-cab and longer-wheelbase/GVW body duplicates?
6. Preserve only the original source cab/exterior for every approved powertrain?
7. Use one evidence-backed representative kerb/payload state per powertrain rather than duplicating empty and loaded vehicles in the catalog?
8. Use one verified standard final drive and one standard differential state per row?
9. Omit DPF, Euro-standard and other emissions revisions as catalog rows or selectable metadata, using one representative calibration per row?
10. Exclude aftermarket LPG/CNG, 4x4 and other conversions?
11. Is any expected engine, transmission, electric drivetrain, cab, wheelbase or body variant missing?

No implementation begins after this individual decision. Research proceeds to model 13 only after the owner fixes model 12 scope, and implementation begins only after every included model has reached `approved`.
