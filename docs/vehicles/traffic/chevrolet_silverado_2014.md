# Chevrolet Silverado 1500 K2XX pre-facelift — research and owner-scope gate

- Model number in Traffic Rider bundle: **02**
- Source GLB: `02_chevrolet_silverado_2014.glb`
- Source SHA-256: `bce261f8703d7e03737cfd40ffa25a1546b76de84772f5b790ed7cc3b40ee465`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation for any Traffic Rider vehicle begins until the owner has approved the scope of every included model.

## Visual identity

The source mesh represents a **Chevrolet Silverado 1500 K2XX Crew Cab Standard Box, pre-facelift**. The texture atlas contains an `LTZ` grille badge and a `4x4` rear-bed decal, so the strict visual identity is **LTZ Crew Cab Standard Box 4WD**.

It is not:

- a Silverado 2500HD/3500HD;
- a Regular Cab or Double Cab;
- a Short Box or Long Box body;
- a 2016-and-later facelift body;
- a GMC Sierra.

The body proportions support the 153-inch-wheelbase Crew Cab Standard Box configuration. Exact wheel, suspension-package and appearance-package identity remain unresolved.

Identity confidence: **high for 1500/K2XX/Crew Cab/Standard Box/pre-facelift; high for LTZ and 4x4 texture identity; package details unresolved**.

## Reference dimensions

Primary Crew Cab Standard Box reference:

| Parameter | Reference |
|---|---:|
| Wheelbase | approximately 3.886 m / 153.0 in |
| Overall length | approximately 6.085 m / 239.6 in |
| Bed length | approximately 1.98 m / 6.5 ft |

The final visual scale must use wheelbase as the primary reference and cross-check overall length, width, height, tracks, ground clearance and tyre diameter against the exact approved configuration.

## Source inspection

| Item | Result |
|---|---|
| Source meshes | 3 |
| Body mesh | `AI_Chevy_High_Chevrolet_Silverado_2014_0` |
| Front wheel-pair mesh | `on_teker.001_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.001_wheel_0` |
| Body triangles | 1,512 |
| Front wheel-pair triangles | 360 |
| Rear wheel-pair triangles | 360 |
| Total triangles | 2,232 |
| Source AABB | approximately 3.264371 × 2.644866 × 8.329704 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 5.377249 source units |
| Approximate wheelbase-derived scale | 0.7227 for a 3.886 m real wheelbase |

The source GLB remains unchanged. A future derived visual will have to split both paired axle meshes into four independent hub-centred wheel nodes, but that work is explicitly deferred until every model scope is approved.

## Research boundary and deduplication

The baseline matrix covers **mechanically distinct engine/transmission/drivetrain combinations** available with the pre-facelift 2014–2015 Silverado 1500 K2XX body.

Rules:

- do not duplicate an identical powertrain because it appears in both model years or several trim levels;
- treat a different transmission behind the same engine as a separate variant;
- treat RWD and selectable 4WD as separate variants;
- do not treat a gasoline/E85 calibration as a second vehicle when it is the same flex-fuel vehicle operating on another approved fuel;
- do not create a separate vehicle for an appearance package;
- create a separate chassis configuration only when suspension, brakes, tyres, axle ratio, cooling, mass or other physical behaviour changes materially.

Evidence states:

- `strongly_supported`: consistent manufacturer-era specifications and multiple technical references;
- `provisional_package`: powertrain is established, but exact trim, axle-ratio or package availability still requires a retained GM order guide, trailering guide, homologation record or build-data source;
- `rejected/not_factory`: no evidence of a factory combination for this body and period.

## Engines

| Engine | Architecture | Factory output used as research anchor | Notes |
|---|---|---|---|
| LV3 4.3 L EcoTec3 | naturally aspirated 90-degree V6, pushrod, direct injection, VVT, AFM | 285 hp; 305 lb-ft / approximately 413 Nm | flex-fuel applications exist; dedicated V6 audio architecture required |
| L83 5.3 L EcoTec3 | naturally aspirated cross-plane V8, pushrod, direct injection, VVT, AFM | 355 hp; 383 lb-ft / approximately 519 Nm | gasoline/E85 states must not become duplicate vehicles |
| L86 6.2 L EcoTec3 | naturally aspirated cross-plane V8, pushrod, direct injection, VVT, AFM | 420 hp; 460 lb-ft / approximately 624 Nm | 2014 uses 6L80; 2015 uses 8L90 |

No production manual, DCT, CVT or automated-manual transmission belongs in this matrix.

## Complete pre-facelift base matrix

The following matrix contains **8 mechanically distinct base combinations** before axle-ratio and materially different chassis-package subdivisions:

| # | Model-year applicability | Engine | Transmission | Drivetrain | Visual relationship | Evidence |
|---:|---|---|---|---|---|---|
| 1 | 2014–2015 | LV3 4.3 V6 | Hydra-Matic 6L80 6AT, RPO MYC | RWD | body-compatible; LTZ/4x4 badges would need material variants | strongly supported |
| 2 | 2014–2015 | LV3 4.3 V6 | Hydra-Matic 6L80 6AT, RPO MYC | selectable part-time 4WD | body-compatible; 4x4 badge compatible, LTZ badge not exact | strongly supported |
| 3 | 2014–2015 | L83 5.3 V8 | Hydra-Matic 6L80 6AT, RPO MYC | RWD | body-compatible; 4x4 badge would need removal | strongly supported |
| 4 | 2014–2015 | L83 5.3 V8 | Hydra-Matic 6L80 6AT, RPO MYC | selectable part-time 4WD | **strict LTZ 4x4 visual match** | strongly supported |
| 5 | 2014 | L86 6.2 V8 | Hydra-Matic 6L80 6AT, RPO MYC | RWD | body-compatible; 4x4 badge would need removal | strongly supported |
| 6 | 2014 | L86 6.2 V8 | Hydra-Matic 6L80 6AT, RPO MYC | selectable part-time 4WD | **strict LTZ 4x4 visual match** | strongly supported |
| 7 | 2015 | L86 6.2 V8 | Hydra-Matic 8L90 8AT, RPO M5U | RWD | body-compatible; 4x4 badge would need removal | strongly supported |
| 8 | 2015 | L86 6.2 V8 | Hydra-Matic 8L90 8AT, RPO M5U | selectable part-time 4WD | **strict LTZ 4x4 visual match** | strongly supported |

Summary:

- broad pre-facelift body-shell scope: **8 base combinations**;
- strict current-texture LTZ 4x4 scope: **3 base combinations**;
- exact axle-ratio and physical package subdivisions: pending owner policy and retained official package evidence.

## Transmission architecture

Both transmissions are conventional planetary torque-converter automatics, not automated manuals or dual-clutch transmissions.

### Hydra-Matic 6L80 / RPO MYC

Research ratios:

| Gear | Ratio |
|---|---:|
| Reverse | approximately 3.06 |
| 1 | approximately 4.03 |
| 2 | approximately 2.36 |
| 3 | approximately 1.53 |
| 4 | approximately 1.15 |
| 5 | approximately 0.85 |
| 6 | approximately 0.67 |

### Hydra-Matic 8L90 / RPO M5U

Research ratios:

| Gear | Ratio |
|---|---:|
| Reverse | approximately 3.82 |
| 1 | approximately 4.56 |
| 2 | approximately 2.97 |
| 3 | approximately 2.08 |
| 4 | approximately 1.69 |
| 5 | approximately 1.27 |
| 6 | 1.00 |
| 7 | approximately 0.85 |
| 8 | approximately 0.65 |

A later implementation must model the 6L80 and 8L90 independently, including converter multiplication/slip, creep, progressive lock-up, torque and inertia phases during shifts, kickdown, tow/haul scheduling and grade braking. A generic shift delay is not sufficient.

## Drivetrain and transfer-case identity

The 4WD rows are **selectable part-time 4WD**, not permanent AWD. Depending on trim/package, the real vehicle may use an electronically controlled two-speed transfer case with modes such as 2H, Auto, 4H and 4L. Exact transfer-case RPO and control availability must be verified for every approved trim/package before implementation.

A future 4WD model must therefore represent:

- disconnected or rear-drive operation where applicable;
- clutch-controlled Auto mode where fitted;
- locked high-range 4WD;
- low-range multiplication;
- operating restrictions and driveline wind-up behaviour;
- transfer-case inertia and losses.

It must not use a fixed AWD front-torque fraction as a substitute.

## Axle ratios and package subdivisions

Factory axle ratio depends on engine, transmission, drive, towing package and model year. Research references indicate families around 3.08, 3.23, 3.42 and 3.73 for relevant K2XX configurations; the 2015 L86/8L90 combination is commonly associated with 3.23 and a 3.42 Max Trailering configuration.

This submatrix remains **provisional pending retained official order-guide/trailering-guide confirmation**. Exact combinations must not be guessed during implementation.

Two catalog policies are possible:

1. each verified factory axle ratio and materially different Max Trailering configuration becomes a separate playable variant; or
2. axle ratio/package becomes an explicit selectable configuration under one base engine/transmission/drivetrain entry.

Either policy must preserve the real final drive, mass, tyres, cooling, suspension and tow/haul behaviour and must not collapse them into one compromise calibration.

## Materially different packages

Potentially relevant packages include Z71, Max Trailering and the 2015 Special Service Vehicle package. They should not create duplicates solely for badges or appearance. They may require separate physical configurations when evidence confirms changes to suspension, tyres, brakes, cooling, electrical load, mass, axle ratio, speed limiter or duty-cycle behaviour.

High Country, Rally and other appearance/trim variants should remain material or trim variants unless their mechanical specification differs.

## Performance and physics requirements

For each approved physical configuration, later research and calibration must retain:

- sampled full-load torque curve and AFM transition behaviour;
- exact transmission and axle ratios;
- converter and lock-up control;
- exact kerb mass and axle load for cab/bed/drive/package;
- tyre dimensions and rolling radius;
- aerodynamic drag and frontal area;
- selectable-4WD and low-range behaviour;
- unloaded acceleration and maximum-speed targets;
- braking performance;
- tow/haul shift scheduling, grade braking and representative loaded behaviour;
- validation against the current `master` physics baseline at implementation time.

No performance value may be matched with false torque, wrong mass, wrong final drive or an arbitrary speed/acceleration cap.

## Engine-audio architecture assessment

| Engine family | Required treatment |
|---|---|
| LV3 | dedicated 90-degree even-fire pushrod V6 pulse, collector, direct-injection, valvetrain and AFM-transition model |
| L83 | Gen V 5.3 L cross-plane pushrod V8 model with its own firing/collector, intake, exhaust, AFM and load layers |
| L86 | Gen V 6.2 L cross-plane pushrod V8; it may share low-level V8 architecture utilities with L83 but requires a distinct combustion, intake/exhaust, inertia and calibration profile |

The LV3 must not be produced by pitch-shifting an inline-six or unrelated V6. L83 and L86 must not be reduced to one generic V8 recording or waveform. Flexible-fuel operation may alter a profile state, but must not create a duplicate vehicle entry.

## Evidence retained and unresolved work

The broad engine/transmission changeover and base drivetrain matrix are strongly supported by manufacturer-era specifications and technical transmission references. Before implementation, the following must be strengthened with retained primary documentation:

- official 2014 and 2015 Chevrolet order guides;
- official trailering guides and axle-ratio/package tables;
- exact transfer-case RPO by trim and package;
- exact tyre, mass, drag, braking and performance values for every approved physical configuration;
- exact flex-fuel output and control distinctions;
- exact Special Service Vehicle, Z71 and Max Trailering mechanical deltas.

Implementation remains blocked both by the owner-scope decision below and by the global all-model research gate.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Use only the **3 strict current-texture LTZ 4x4 combinations**, or approve all **8 pre-facelift Crew Cab Standard Box base combinations** with later badge/material variants for RWD, lower trims and the LV3?
2. Include both model years 2014 and 2015, preserving the mechanically distinct L86 + 6L80 and L86 + 8L90 combinations?
3. Should every verified factory axle ratio and materially different Max Trailering configuration be a separate playable catalog entry, or an explicit selectable configuration under its base powertrain?
4. Include materially different Z71, Max Trailering and Special Service Vehicle chassis configurations when they change real physics, while avoiding duplicate entries for unchanged powertrains?
5. Treat gasoline and E85 output as fuel states of one flexible-fuel variant rather than duplicate vehicles?
6. Is any expected engine, transmission, drivetrain, axle/package or pre-facelift model-year variant missing from this matrix?

No implementation begins after this individual decision. Research continues through the remaining models in ascending order, and implementation starts only after the owner has approved the scope of every included model.