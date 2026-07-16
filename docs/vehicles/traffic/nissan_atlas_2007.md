# Nissan Atlas / Cabstar F24 single-cab flatbed — research and approved scope

- Model number in Traffic Rider bundle: **17**
- Source GLB: `17_nissan_atlas_2007.glb`
- Source Git blob SHA-1: `8dcc240c7b26ec1821d30da11d3cf08e7f9daccf`
- Source SHA-256: **pending direct binary hash capture before integration**
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **8 RWD Nissan Atlas / Cabstar F24 configurations**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity and body policy

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

The visual is closest to a light Japanese Atlas F24 / Atlas 10 flatbed, not the heavier Isuzu-derived H43 Atlas and not the later Mitsubishi-Fuso-derived NT450 Atlas.

The owner approved the source-like narrow single-cab dropside flatbed with single rear wheels for every retained row. This is an explicit body homogenization and does not claim that every European Cabstar or heavier-payload drivetrain was sold with the exact source body.

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

## Approved research boundary

The approved generation is the **Nissan F24 light-truck platform**, launched as Cabstar in Europe in 2006 and as Atlas in Japan on 14 June 2007.

Two market families remain in scope:

1. **Japanese Atlas F24 / Atlas 10**
   - QR20DE 1.998L naturally aspirated petrol inline-four;
   - ZD30DDTi 2.953L common-rail turbo-diesel inline-four;
   - five-speed manual, six-speed manual and five-speed torque-converter automatic architectures;
   - rear-wheel drive only in the approved project scope;
   - one representative 1.5-t or heavier 1.75/2.0-t chassis calibration where mechanically required.

2. **European Nissan Cabstar F24 / later NT400 family**
   - YD25DDTi 2.5L turbo-diesel at approximately 110 and 130 PS in the original range;
   - ZD30DDTi 3.0L turbo-diesel at approximately 150 PS;
   - five- and six-speed conventional manual gearboxes;
   - rear-wheel drive;
   - mechanical overlap with the Renault Maxity rows already approved for model 12 is accepted because this remains a separate Nissan model and body.

Japanese and European engines, transmissions and gearing may not be mixed into fictional combinations.

## Owner-directed scope rules

- retain every researched RWD row: five Japanese Atlas rows and three European Cabstar rows;
- exclude the ZD30DDTi 4WD row and all transfer-case/front-drive implementation for model 17;
- retain QR20DE and ZD30DDTi five-speed automatic rows as approved-scope but evidence-blocked configurations;
- prohibit implementation of an evidence-blocked row until primary Nissan ordering data confirms the gearbox code, ratios, converter and valid engine application;
- use the source-like narrow single-cab dropside flatbed with single rear wheels for all eight rows;
- use one representative light/unladen payload state per row and omit body, cab, wheelbase, bed-height and GVW duplicates;
- retain distinct mass, axle, final-drive and gearing calibration where a row represents a heavier 1.75/2.0-t chassis;
- use the initial 2007 Japanese calibration by default and create a later calibration only when primary data proves a mechanically distinct torque curve or ratio set;
- exclude Canter Guts, Ashok Leyland, Dongfeng, UD/Isuzu OEM badges and specialist body conversions;
- no additional F24 engine, transmission or drivetrain variant was requested by the owner.

## Approved configuration matrix

### Japanese Atlas F24 — 5 RWD configurations

| # | Engine | Transmission | Drivetrain / chassis policy | Status |
|---:|---|---|---|---|
| 1 | QR20DE 1.998L naturally aspirated petrol inline-four, source-era truck calibration | 5-speed conventional manual | RWD; one representative light-flatbed final drive, differential and approximately 1.5-t payload state | **approved** |
| 2 | QR20DE 1.998L petrol | 5-speed Aisin-family torque-converter automatic | RWD; one representative light-flatbed final drive, differential and approximately 1.5-t payload state | **approved scope / evidence blocked** |
| 3 | ZD30DDTi 2.953L common-rail turbo-diesel inline-four, initial F24 calibration | 5-speed conventional manual | RWD; one representative 1.5-t flatbed state | **approved** |
| 4 | ZD30DDTi 2.953L common-rail turbo-diesel | 5-speed torque-converter automatic | RWD; one representative 1.5-t flatbed state | **approved scope / evidence blocked** |
| 5 | ZD30DDTi 2.953L common-rail turbo-diesel | 6-speed conventional manual | RWD; one representative heavier 1.75/2.0-t gearing and axle state | **approved** |

### European Nissan Cabstar F24 — 3 RWD configurations

| # | Engine | Transmission | Drivetrain / chassis policy | Status |
|---:|---|---|---|---|
| 6 | YD25DDTi 2.5L common-rail turbo-diesel, approximately 110 PS | 5-speed conventional manual | RWD; one standard final drive and differential | **approved** |
| 7 | YD25DDTi 2.5L common-rail turbo-diesel, approximately 130 PS | 6-speed conventional manual | RWD; one standard final drive and differential | **approved** |
| 8 | ZD30DDTi 3.0L common-rail turbo-diesel, approximately 150 PS / 350-Nm class | 6-speed conventional manual | RWD; one standard final drive and differential | **approved** |

**Approved total: 5 Japanese RWD + 3 European RWD = 8 Nissan Atlas / Cabstar F24 configurations.**

## Explicitly excluded 4WD configuration

The previously researched ZD30DDTi plus five-speed-manual 4WD candidate is excluded. Model 17 will not receive a transfer case, driven front axle, front differential, front half-shafts, 4WD engagement state or 4WD-specific mass and steering calibration.

## Calibration-revision policy

The Japanese F24 received documented engine-output and transmission-ratio revisions in 2009 and further emissions/fuel-economy changes in 2010–2012. These revisions do not automatically create duplicate catalog rows.

- initial 2007 calibration is the strict source-era default;
- 2009/2010/2012 emissions, injection, exhaust and ratio changes remain metadata unless a revision changes performance or gearing enough to be mechanically distinct;
- a separate late calibration requires primary Nissan evidence for a different output curve or gearbox/final-drive set;
- Mitsubishi Fuso Canter Guts, Ashok Leyland Partner/Garuda, Dongfeng Captain and other OEM derivatives remain excluded.

## Chassis and transmission requirements

Every row requires a cab-over ladder frame, longitudinal engine, dry clutch or hydrodynamic converter, exact gearbox, prop shaft, live driven rear axle, leaf-spring rear suspension and source-body-correct mass, tyre, brake and drag calibration.

The five-speed automatic must be represented as a conventional torque-converter planetary automatic with converter multiplication, creep, progressive lock-up, hydraulic shift phases and kickdown. It may not reuse a manual or automated-manual model.

The six-speed manual is a separate gearset from the five-speed manual. Heavy-payload gearing may not be reproduced by applying only a speed cap.

## Engine and driveline audio architecture

The QR20DE requires a commercial-vehicle naturally aspirated petrol inline-four profile with a truck exhaust/intake system and lower-load delivery than a passenger-car calibration.

The ZD30DDTi requires a dedicated large-displacement common-rail commercial-diesel profile with four-cylinder cadence, injection transients, turbocharger, low-speed load response and engine-braking behaviour.

The YD25DDTi Cabstar rows require a separate 2.5L common-rail commercial-diesel family. They may share low-level four-cylinder diesel DSP utilities with Maxity, but badge/body-specific intake, exhaust and driveline layers must remain calibrated independently.

## Evidence still required before parameter commitment

Before implementation retain primary Nissan Japan and Nissan Europe documentation for:

- exact 2007 Japanese model codes and valid engine/transmission combinations;
- QR20DE truck output, torque curve, idle, rev limit and emissions calibration;
- ZD30DDTi initial and revised output/torque curves;
- five-speed manual, six-speed manual and automatic gearbox codes and all ratios;
- automatic converter stall ratio, lock-up map and shift behaviour;
- one standard final drive, differential and tyre size per approved row;
- source-body wheelbase, kerb mass, payload, axle loads, centre of gravity, steering, brakes and suspension;
- drag/frontal area and documented performance targets;
- direct GLB SHA-256, hierarchy, wheel centres, AABB and scale.

Secondary sources establish the platform, engine families, broad transmission architectures and market split, but they do not authorize guessed parameters for the evidence-blocked automatic rows.

## Owner decision recorded

The owner approved all eight researched RWD configurations, including all three European Cabstar rows, and excluded only the 4WD candidate.

Model 17 is **`approved`** with **8** configurations. Implementation remains blocked by the global all-model research gate. Research proceeds to model 18.
