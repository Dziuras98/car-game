# Nissan Atleon 2004 pre-facelift box truck — research and approved scope

- Model number in Traffic Rider bundle: **18**
- Source GLB: `18_nissan_atleon_2004.glb`
- Source Git blob SHA-1: `680e31baa11e5d7abf8d13b95b2638eb3db32e69`
- Source SHA-256: **pending direct binary hash capture before integration**
- Research date: 2026-07-15
- Owner decision date: 2026-07-16
- Workflow status: **`approved`**
- Approved implementation scope: **4 pre-facelift Nissan Atleon RWD configurations**
- Physics baseline inspected during research: `master` after merge commit `a22eb5ee8776ae3e4aa294de9de8fc57af69609a`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity and body policy

The source represents a **pre-facelift Nissan Atleon from approximately model year 2004**, using the 2000–2006 cab rather than the 2006 Cabstar-F24-style facelift. The committed inventory identifies it as a medium box truck.

The approved source-body anchor is:

- forward-control standard-width single cab;
- pre-2006 grille, lamps and bumper treatment;
- enclosed rectangular cargo box behind the cab;
- rear double-door commercial body;
- rear-wheel-drive road stance;
- dual rear wheels appropriate to the medium-duty chassis family;
- no flatbed, tipper, crew cab, fire body, military module, crane or specialist conversion.

The owner approved the same source-like single-cab box body for every retained engine row. Each row must nevertheless receive an engine-appropriate chassis, GVW, mass, axle, wheelbase, tyre, brake and final-drive calibration rather than sharing one artificial physical configuration.

The filename and source date fit the Barcelona-built Atleon range introduced in 2000. The represented chassis is not the lighter Cabstar/Atlas F24 and not the facelift Atleon produced from 2006 with ZD30 and Cummins common-rail engines.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Production/body phase | Atleon 2000–2006, pre-facelift |
| Factory GVW family | approximately 3.5–8.0 t depending on chassis |
| Factory body availability | chassis-cab, flatbed and box body |
| Source class | medium box truck |
| Source triangles | 2,076 |
| Source Git blob SHA-1 | `680e31baa11e5d7abf8d13b95b2638eb3db32e69` |
| Source topology | body and axle-wheel assemblies; exact nodes, rear-tyre count and bounds pending direct binary inspection |
| Source wheelbase and scale | pending direct hub-centre measurement and body-dimension cross-check |

The committed GLB remains unchanged. Before integration, direct binary inspection must record SHA-256, scene hierarchy, AABB, front axis, hub centres, tyre count and wheelbase-derived scale. If the rear axle mesh contains four physical tyres, all four rear contacts must be retained and explicitly bound.

## Approved research boundary

The approved scope covers the **2000–2006 Nissan Atleon pre-facelift range**, concentrating on the 2004 source year. It excludes:

- earlier Ebro/Nissan L/M and ECO-T bodies;
- 2006–2013 facelift Atleon ZD30 150-PS and Cummins 185-PS rows;
- the later Nissan NT500 successor;
- lighter Cabstar/Atlas/Maxity models;
- non-factory engine conversions.

Four pre-facelift engine calibrations are retained:

- Atleon 110 — BD30Ti 2.953L turbo-diesel inline-four, 81 kW / 110 PS at approximately 3,500 rpm and 262 Nm at approximately 2,100 rpm;
- Atleon 140 — B4.40Ti 3.989L turbo-diesel inline-four, 102 kW / 139–140 PS at approximately 2,600 rpm and 425 Nm at approximately 1,300 rpm;
- Atleon 165 — B6.60TiL 5.985L turbo-diesel inline-six, 119 kW / 162–165 PS at approximately 2,600 rpm and 459 Nm at approximately 1,500 rpm;
- Atleon 210 — B6.60TiH 5.985L turbo-diesel inline-six, 154 kW / 209–210 PS at approximately 2,600 rpm and 647 Nm at approximately 1,300 rpm.

All are longitudinal front-engine commercial diesels driving a live rear axle in the standard road range. No factory automatic application has been evidenced for the approved 2004 scope.

## Owner-directed scope rules

- retain all four pre-facelift RWD engine rows: Atleon 110, 140, 165 and 210;
- keep exact gearbox codes, ratio tables, clutch capacities and engine-to-chassis pairings evidence-blocked until primary Nissan documentation confirms them;
- prohibit final implementation of a row whose valid gearbox and chassis application cannot be confirmed;
- use the source-like pre-facelift single-cab box body for every row;
- use one representative unladen/light-payload state per engine row;
- assign engine-appropriate GVW, mass, axle, tyre, brake, wheelbase and final-drive calibration rather than one shared truck mass;
- retain dual rear wheels when direct source inspection confirms four physical rear tyres;
- omit body, cab, wheelbase, box-length, roof-height, payload, GVW and final-drive-option duplicates;
- keep the unresolved 4WD branch excluded unless primary documentation identifies a complete valid 2000–2006 combination;
- exclude all 2006–2013 facelift ZD30 and Cummins rows;
- exclude flatbed, tipper, crew-cab, municipal, fire, military, recovery and other specialist bodies;
- no additional pre-facelift engine, transmission or drivetrain row was requested by the owner.

## Approved configuration matrix

| # | Model / engine | Transmission | Drivetrain and chassis policy | Status |
|---:|---|---|---|---|
| 1 | Atleon 110, BD30Ti 2.953L turbo-diesel inline-four, 81 kW / 110 PS, 262 Nm | conventional dry-clutch manual; provisionally five-speed, exact gearbox code and ratios pending primary data | RWD; one representative light 3.5-t-class box-body final drive, axle and dual-rear-wheel state | **approved scope / transmission and chassis evidence blocked** |
| 2 | Atleon 140, B4.40Ti 3.989L turbo-diesel inline-four, 102 kW / 139–140 PS, 425 Nm | conventional dry-clutch manual; provisionally five-speed, exact gearbox code and ratios pending primary data | RWD; one representative medium chassis, final drive, axle and dual-rear-wheel state | **approved scope / transmission and chassis evidence blocked** |
| 3 | Atleon 165, B6.60TiL 5.985L turbo-diesel inline-six, 119 kW / 162–165 PS, 459 Nm | conventional dry-clutch manual; provisionally six-speed, exact gearbox code and ratios pending primary data | RWD; one representative heavier medium chassis, final drive, axle and dual-rear-wheel state | **approved scope / transmission and chassis evidence blocked** |
| 4 | Atleon 210, B6.60TiH 5.985L turbo-diesel inline-six, 154 kW / 209–210 PS, 647 Nm | conventional dry-clutch manual; provisionally six-speed, exact gearbox code and ratios pending primary data | RWD; one representative highest-GVW pre-facelift chassis, final drive, axle and dual-rear-wheel state | **approved scope / transmission and chassis evidence blocked** |

**Approved total: 4 pre-facelift Nissan Atleon RWD configurations.**

The provisional five-/six-speed split is retained only as a research hypothesis. It may not become final catalog data until primary Nissan material confirms each gearbox code, ratio set and chassis application.

## Explicitly excluded 4WD branch

Secondary historical summaries mention Atleon four-wheel-drive production, but current evidence does not identify a reliable pre-facelift 2004 engine, gearbox, transfer case and chassis combination.

The 4WD branch is excluded from model 18. It may be reconsidered only if primary Nissan ordering or service data proves:

- the exact 2000–2006 model code;
- engine and gearbox pairing;
- transfer-case type and ratios;
- engagement/full-time state;
- front axle and differential hardware;
- GVW, tyre, brake and steering restrictions.

A generic traction multiplier or an invented combination is prohibited.

## Chassis and transmission requirements

Each retained row requires:

- cab-over ladder frame;
- longitudinal front engine;
- driver-operated dry clutch;
- exact stepped manual gearbox and reverse ratio;
- prop shaft and live driven rear axle;
- leaf-sprung rear suspension and chassis-appropriate front suspension;
- hydraulic/pneumatic brake behaviour appropriate to GVW;
- box-body mass, centre of gravity, crosswind and drag calibration;
- physically represented dual rear tyres where present.

Different engine/chassis gearing may not be approximated with arbitrary speed caps.

## Engine and driveline audio architecture

Three distinct combustion/audio families are required:

1. **BD30Ti 3.0 inline-four** — small commercial direct-injection turbo-diesel with relatively high governed speed and lighter exhaust/turbo system.
2. **B4.40Ti 4.0 inline-four** — large-bore, low-speed four-cylinder commercial diesel with strong second-order cadence, heavier combustion events and lower-speed torque peak.
3. **B6.60TiL/H 6.0 inline-six** — low-speed inline-six commercial diesel with even 120-degree firing cadence, separate low- and high-output injection/turbo calibrations and substantially heavier driveline loading.

The 4.0 four-cylinder and 6.0 inline-six may not be produced by pitch-shifting the BD30 profile. The 165- and 210-PS six-cylinder rows may share a first-principles inline-six architecture but require different boost, injection, governor, exhaust and load-response calibration.

Additional layers are required for gearbox whine, prop shaft, live axle, dual rear tyres, cargo-box resonance, engine braking and high-GVW load transients.

## Evidence still required before parameter commitment

Before implementation retain primary Nissan Motor Ibérica brochures, price lists, workshop manuals, homologation data or body-builder documentation for:

- exact 2004 model codes and engine-to-GVW/body restrictions;
- full-load torque curves, idle, governor and engine-brake behaviour for BD30Ti, B4.40Ti and B6.60TiL/H;
- gearbox manufacturer/code, gear count, all forward/reverse ratios and clutch capacity for every row;
- one standard final drive and differential per row;
- wheelbases, cab/body dimensions, kerb mass, payload, axle ratings and centre of gravity;
- tyre sizes, dual-rear-wheel spacing, steering and brake hardware;
- drag/frontal area and documented gradeability, top-speed, acceleration and braking targets;
- direct GLB SHA-256, hierarchy, wheel centres, rear-tyre count, AABB and scale.

The four engine/output rows are approved, but current evidence remains insufficient to commit exact transmission or chassis parameters.

## Owner decision recorded

The owner approved all four researched pre-facelift RWD engine rows. The unresolved 4WD branch, facelift engines and alternate bodies remain excluded.

Model 18 is **`approved`** with **4** configurations. Implementation remains blocked by the global all-model research gate. Research proceeds to model 20.
