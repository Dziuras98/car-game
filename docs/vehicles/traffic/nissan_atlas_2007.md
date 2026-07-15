# Nissan Atlas / Cabstar F24 single-cab flatbed — research and owner-scope gate

- Model number in Traffic Rider bundle: **17**
- Source GLB: `17_nissan_atlas_2007.glb`
- Source Git blob SHA-1: `8dcc240c7b26ec1821d30da11d3cf08e7f9daccf`
- Source SHA-256: **pending direct binary hash capture before integration**
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source is the low-polygon **2007 Nissan Atlas / Cabstar F24 single-cab flatbed** sold by TAURUS3D/TurboSquid as product 720552 and subsequently included in the Traffic Rider bundle.

The source product and committed inventory agree on:

- Nissan F24 cab introduced in Europe as Cabstar and in Japan as Atlas in 2007;
- narrow single cab with three-seat-class front bench layout;
- open steel dropside flatbed;
- single rear tyres rather than dual rear wheels;
- rear-wheel-drive road stance;
- white cab and silver/grey bed;
- 1,996 rendered triangles and 1,012 source vertices;
- no box, tipper, crew cab, refrigerated body, camper, crane or specialist equipment.

The visual is therefore closest to a light Japanese Atlas F24 / Atlas 10 flatbed, not the heavier Isuzu-derived H43 Atlas and not the later Mitsubishi-Fuso-derived NT450 Atlas.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| F24 launch payload range | approximately 1.15–2.0 t |
| F24 wheelbase family | approximately 2,270–3,355 mm depending on body and market |
| Provisional source wheelbase target | approximately 2,500 mm; must be confirmed from direct hub-centre measurement |
| Narrow-cab width family | approximately 1,695 mm |
| Source product polygons | 1,144 |
| Source product triangles / committed inventory | 1,996 |
| Source product vertices | 1,012 |
| Source texture | one baked 2,048 × 1,024 PNG diffuse texture |
| Source topology | body plus paired front and rear wheel meshes; exact node names and bounds pending direct binary inspection |

The committed GLB remains unchanged. Before integration, the source must be parsed directly to capture its SHA-256, node hierarchy, hub centres, AABB, front axis and wheelbase-derived scale. Four independent hub-centred wheel nodes and project-authored collision remain mandatory.

## Research boundary

The represented generation is the **Nissan F24 light-truck platform**, launched as Cabstar in Europe in 2006 and as Atlas in Japan on 14 June 2007.

Two distinct market scopes exist:

1. **Japanese Atlas F24 / Atlas 10 source scope**
   - QR20DE 1.998L naturally aspirated petrol inline-four;
   - ZD30DDTi 2.953L common-rail turbo-diesel inline-four;
   - five-speed manual, six-speed manual and five-speed torque-converter automatic architectures;
   - rear-wheel drive, with a documented diesel 4WD branch in the F24 lifecycle;
   - 1.15-, 1.5-, 1.75- and 2.0-ton-class chassis/body applications.

2. **European Nissan Cabstar F24 / later NT400 scope**
   - YD25DDTi 2.5L turbo-diesel at approximately 110 and 130 PS in the original range;
   - ZD30DDTi 3.0L turbo-diesel at approximately 150 PS;
   - five- and six-speed conventional manual gearboxes;
   - rear-wheel drive;
   - mechanically close to the Renault Maxity rows already researched for model 12.

The source visual can represent either badge family externally, but the Japanese and European powertrain matrices may not be mixed into fictional combinations.

## Mechanically consolidated candidate matrix

### Japanese Atlas F24 source-era candidates

| # | Engine | Transmission | Drivetrain / chassis policy | Evidence state |
|---:|---|---|---|---|
| 1 | QR20DE 1.998L naturally aspirated petrol inline-four, source-era truck calibration | 5-speed conventional manual | RWD; one representative light flatbed final drive, differential and approximately 1.5-t payload state | `verified_engine_and_architecture`; exact launch ordering code, ratios and output require primary table |
| 2 | QR20DE 1.998L petrol | 5-speed Aisin-family torque-converter automatic | RWD; one representative light flatbed final drive, differential and approximately 1.5-t payload state | `candidate`; exact QR20DE/5AT launch application and gearbox code require primary confirmation |
| 3 | ZD30DDTi 2.953L common-rail turbo-diesel inline-four, initial F24 calibration | 5-speed conventional manual | RWD; one representative 1.5-t flatbed state | `verified_engine_and_architecture`; exact model code, output, ratios and final drive require primary table |
| 4 | ZD30DDTi 2.953L common-rail turbo-diesel | 5-speed torque-converter automatic | RWD; one representative 1.5-t flatbed state | `candidate`; exact diesel/5AT launch application and gearbox code require primary confirmation |
| 5 | ZD30DDTi 2.953L common-rail turbo-diesel | 6-speed conventional manual | RWD; one representative heavier 1.75/2.0-t gearing and axle state | `verified_architecture`; contemporary range evidence ties 1.75–2.0-t models to six-speed gearing, exact model code pending |
| 6 | ZD30DDTi 2.953L common-rail turbo-diesel | 5-speed conventional manual | 4WD; one representative 1.5-t transfer-case/front-drive state | `verified_lifecycle_branch / source-era evidence blocked`; exact introduction date and launch combination require primary confirmation |

### European Nissan Cabstar F24 candidates

| # | Engine | Transmission | Drivetrain / chassis policy | Evidence state |
|---:|---|---|---|---|
| 7 | YD25DDTi 2.5L common-rail turbo-diesel, approximately 110 PS | 5-speed conventional manual | RWD; one standard final drive and differential | `verified_family`; mechanically overlaps Renault Maxity row 1 |
| 8 | YD25DDTi 2.5L common-rail turbo-diesel, approximately 130 PS | 6-speed conventional manual | RWD; one standard final drive and differential | `verified_family`; mechanically overlaps Renault Maxity row 2 |
| 9 | ZD30DDTi 3.0L common-rail turbo-diesel, approximately 150 PS / 350-Nm class | 6-speed conventional manual | RWD; one standard final drive and differential | `verified_family`; mechanically overlaps Renault Maxity row 3 |

**Mechanically consolidated candidate total: 9 configurations.**

Rows 2, 4 and 6 remain evidence-blocked. Approval would retain them in scope only as confirmation-gated rows: implementation may not invent gearbox codes, ratios, launch devices, transfer-case behaviour or final drives if primary Nissan ordering data fails to confirm them.

## Calibration-revision policy candidates

The Japanese F24 received documented engine-output and transmission-ratio revisions in 2009 and further emissions/fuel-economy changes in 2010–2012. These revisions should not automatically create duplicate catalog rows.

Recommended policy:

- use the initial 2007 calibration for the strict source-era rows;
- treat 2009/2010/2012 emissions, injection, exhaust and ratio changes as metadata unless a revision changes performance or gearing enough to be mechanically distinct;
- add a separate late calibration only when primary Nissan specifications demonstrate a different output curve or gearbox/final-drive set;
- exclude 2013 Mitsubishi Fuso Canter Guts rebadges, Ashok Leyland Partner/Garuda, Dongfeng Captain and other OEM derivatives from the Nissan Atlas catalog.

## Body, payload and axle policy candidates

The source is one narrow single-cab flatbed with single rear wheels. Available F24 production bodies also include crew cabs, longer wheelbases, low-floor beds, dual-rear-wheel chassis, boxes, tippers and refrigerated bodies.

Recommended project policy:

- use the source-like narrow single-cab dropside flatbed for all approved rows;
- use one representative light/unladen state per row rather than payload-selectable duplicates;
- retain different axle, gearing and mass calibration where the approved mechanical row represents a 1.5-t versus 1.75/2.0-t chassis;
- do not visually claim that the same single-rear-wheel flatbed was the exact factory body for every Cabstar and heavy-payload combination;
- exclude body, cab, wheelbase, bed-height, GVW and payload-state duplicates from the catalog.

## Chassis and transmission requirements

Every RWD row requires a cab-over ladder frame, longitudinal engine, dry clutch or hydrodynamic converter, exact gearbox, prop shaft, live driven rear axle, leaf-spring rear suspension and source-body-correct mass, tyre, brake and drag calibration.

The five-speed automatic must be represented as a conventional torque-converter planetary automatic with converter multiplication, creep, progressive lock-up, hydraulic shift phases and kickdown. It may not reuse a manual or automated-manual model.

The six-speed manual is a separate gearset from the five-speed manual. Heavy-payload gearing may not be reproduced by applying only a speed cap.

The 4WD candidate requires its real transfer case, front differential, front half-shafts, torque split and engagement state. It may not use a generic traction multiplier.

## Engine and driveline audio architecture

The QR20DE requires a commercial-vehicle naturally aspirated petrol inline-four profile with a truck exhaust/intake system and lower-load delivery than a passenger-car calibration.

The ZD30DDTi requires a dedicated large-displacement common-rail commercial-diesel profile with four-cylinder cadence, injection transients, turbocharger, low-speed load response and engine-braking behaviour.

The YD25DDTi Cabstar rows require a separate 2.5L common-rail commercial-diesel family. They may share low-level four-cylinder diesel DSP utilities with Maxity, but badge/body-specific intake, exhaust and driveline layers must remain calibrated independently.

## Evidence still required before parameter commitment

Before implementation retain primary Nissan Japan and Nissan Europe documentation for:

- exact 2007 Japanese model codes and valid engine/transmission/drivetrain combinations;
- QR20DE truck output, torque curve, idle, rev limit and emissions calibration;
- ZD30DDTi initial and revised output/torque curves;
- five-speed manual, six-speed manual and automatic gearbox codes and all ratios;
- automatic converter stall ratio, lock-up map and shift behaviour;
- exact 4WD introduction date, transfer-case architecture and permitted engine/gearbox combinations;
- one standard final drive, differential and tyre size per approved row;
- source-body wheelbase, kerb mass, payload, axle loads, centre of gravity, steering, brakes and suspension;
- drag/frontal area and documented performance targets;
- direct GLB SHA-256, hierarchy, wheel centres, AABB and scale.

Secondary sources establish the platform, engine families, broad transmission architectures and market split, but they do not yet justify guessing the evidence-blocked combinations.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Include all six Japanese candidates, or only the five RWD rows?
2. Include the three European Cabstar rows even though they mechanically overlap the already approved Renault Maxity diesel rows?
3. Retain evidence-blocked rows 2, 4 and 6 pending primary confirmation, or exclude them now?
4. Use the source-like narrow single-cab dropside flatbed with single rear wheels for every approved row?
5. Use one representative light/unladen payload state per row and omit body, cab, wheelbase, bed-height and GVW duplicates?
6. Keep the initial 2007 Japanese calibration as the default and add later revisions only when primary data proves a mechanically distinct curve or ratio set?
7. Exclude Canter Guts, Ashok Leyland, Dongfeng, UD/Isuzu OEM badges and specialist body conversions?
8. Is any expected F24 engine, transmission or drivetrain variant missing?

No implementation begins after this individual decision. Research proceeds to model 18 only after the owner fixes model 17 scope, and implementation begins only after every included model has reached `approved`.
