# Chevrolet Silverado 1500 K2XX pre-facelift — research and approved scope

- Model number in Traffic Rider bundle: **02**
- Source GLB: `02_chevrolet_silverado_2014.glb`
- Source SHA-256: `bce261f8703d7e03737cfd40ffa25a1546b76de84772f5b790ed7cc3b40ee465`
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **4 mechanically distinct RWD combinations**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation for any Traffic Rider vehicle begins until the owner has approved the scope of every included model.

## Visual identity

The source mesh represents a **Chevrolet Silverado 1500 K2XX Crew Cab Standard Box, pre-facelift**. The texture atlas contains an `LTZ` grille badge and a `4x4` rear-bed decal, so the unmodified texture is visually closest to an **LTZ Crew Cab Standard Box 4WD**.

The approved catalog scope is RWD-only. Implementation must therefore create a non-destructive material/texture variant that removes the `4x4` decal. Trim badges must also be corrected when an approved engine was not factory-compatible with the depicted LTZ trim. The source GLB and its embedded textures remain unchanged.

It is not:

- a Silverado 2500HD/3500HD;
- a Regular Cab or Double Cab;
- a Short Box or Long Box body;
- a 2016-and-later facelift body;
- a GMC Sierra.

The body proportions support the 153-inch-wheelbase Crew Cab Standard Box configuration. Exact wheel and appearance-package identity remain unresolved.

Identity confidence: **high for 1500/K2XX/Crew Cab/Standard Box/pre-facelift; high for source LTZ/4x4 texture identity; approved runtime variants require corrected RWD materials**.

## Reference dimensions

Primary Crew Cab Standard Box reference:

| Parameter | Reference |
|---|---:|
| Wheelbase | approximately 3.886 m / 153.0 in |
| Overall length | approximately 6.085 m / 239.6 in |
| Bed length | approximately 1.98 m / 6.5 ft |

Final scale must use wheelbase as the primary reference and cross-check overall length, width, height, tracks, ground clearance and tyre diameter against the exact approved configuration.

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

The source GLB remains unchanged. A future derivative must split both paired axle meshes into four independent hub-centred wheel nodes, but this work is deferred until all model scopes are approved.

## Research boundary and deduplication

The researched base matrix contains **8 mechanically distinct engine/transmission/drivetrain combinations** for the pre-facelift 2014–2015 Silverado 1500 K2XX body. The owner approved the four RWD rows and rejected the four selectable-4WD counterparts.

Deduplication rules:

- do not duplicate an identical powertrain because it appears in both model years or several trim levels;
- treat a different transmission behind the same engine as a separate variant;
- retain only RWD for this model;
- use only the normal gasoline calibration;
- do not create E85/flex-fuel catalog duplicates or selectable fuel states;
- use one verified standard factory axle ratio per approved powertrain;
- do not create separate Z71, Max Trailering, Special Service Vehicle or appearance-package variants.

## Engines

| Engine | Architecture | Factory output used as research anchor | Approved fuel treatment |
|---|---|---:|---|
| LV3 4.3 L EcoTec3 | naturally aspirated 90-degree V6, pushrod, direct injection, VVT, AFM | 285 hp; 305 lb-ft / approximately 413 Nm | gasoline only |
| L83 5.3 L EcoTec3 | naturally aspirated cross-plane V8, pushrod, direct injection, VVT, AFM | 355 hp; 383 lb-ft / approximately 519 Nm | gasoline only |
| L86 6.2 L EcoTec3 | naturally aspirated cross-plane V8, pushrod, direct injection, VVT, AFM | 420 hp; 460 lb-ft / approximately 624 Nm | gasoline only |

No production manual, DCT, CVT or automated-manual transmission belongs in the approved matrix.

## Complete researched base matrix

| # | Model-year applicability | Engine | Transmission | Drivetrain | Owner decision |
|---:|---|---|---|---|---|
| 1 | 2014–2015 | LV3 4.3 V6 | Hydra-Matic 6L80 6AT, RPO MYC | RWD | **approved** |
| 2 | 2014–2015 | LV3 4.3 V6 | Hydra-Matic 6L80 6AT, RPO MYC | selectable part-time 4WD | rejected — RWD only |
| 3 | 2014–2015 | L83 5.3 V8 | Hydra-Matic 6L80 6AT, RPO MYC | RWD | **approved** |
| 4 | 2014–2015 | L83 5.3 V8 | Hydra-Matic 6L80 6AT, RPO MYC | selectable part-time 4WD | rejected — RWD only |
| 5 | 2014 | L86 6.2 V8 | Hydra-Matic 6L80 6AT, RPO MYC | RWD | **approved** |
| 6 | 2014 | L86 6.2 V8 | Hydra-Matic 6L80 6AT, RPO MYC | selectable part-time 4WD | rejected — RWD only |
| 7 | 2015 | L86 6.2 V8 | Hydra-Matic 8L90 8AT, RPO M5U | RWD | **approved** |
| 8 | 2015 | L86 6.2 V8 | Hydra-Matic 8L90 8AT, RPO M5U | selectable part-time 4WD | rejected — RWD only |

**Approved total: 4 RWD combinations.**

The L86 + 6L80 and L86 + 8L90 rows remain separate because the transmission architecture, ratios, shift behaviour, inertia and model-year applicability differ materially.

## Approved catalog rows

1. Silverado 1500 Crew Cab Standard Box RWD — LV3 4.3 V6 — 6L80 — 2014–2015.
2. Silverado 1500 Crew Cab Standard Box RWD — L83 5.3 V8 — 6L80 — 2014–2015.
3. Silverado 1500 Crew Cab Standard Box RWD — L86 6.2 V8 — 6L80 — 2014.
4. Silverado 1500 Crew Cab Standard Box RWD — L86 6.2 V8 — 8L90 — 2015.

## Transmission architecture

Both approved transmissions are conventional planetary torque-converter automatics, not automated manuals or dual-clutch transmissions.

### Hydra-Matic 6L80 / RPO MYC

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

A later implementation must model the 6L80 and 8L90 independently, including converter multiplication/slip, creep, progressive lock-up, torque and inertia phases during shifts, kickdown, normal road shift scheduling and grade braking. Tow/haul-specific tuning is outside the approved catalog scope.

## Final-drive policy

Each approved row receives exactly one **standard factory axle ratio**. Max Trailering and optional axle ratios are excluded.

The exact standard ratio must be verified from retained official Chevrolet order-guide or build-data evidence for the exact engine, transmission, RWD, Crew Cab and Standard Box combination. No provisional 3.08/3.23/3.42/3.73 value may be committed merely because it was available elsewhere in the range.

## Excluded configurations

The following are explicitly outside the approved scope:

- all selectable-4WD configurations and transfer-case modes;
- Z71;
- Max Trailering;
- Special Service Vehicle;
- optional axle-ratio variants;
- E85 calibration or selectable fuel-state variants;
- duplicate trim or appearance-package entries;
- 2016-and-later facelift models.

## Performance and physics requirements

For each approved row, later implementation research and calibration must retain:

- sampled full-load gasoline torque curve and AFM transition behaviour;
- exact transmission and standard axle ratio;
- converter and lock-up control;
- exact kerb mass and axle load for Crew Cab Standard Box RWD;
- tyre dimensions and rolling radius;
- aerodynamic drag and frontal area;
- unloaded acceleration and maximum-speed targets;
- braking performance;
- validation against the current `master` physics baseline at implementation time.

No performance value may be matched with false torque, wrong mass, wrong final drive or an arbitrary speed/acceleration cap.

## Engine-audio architecture assessment

| Engine family | Required treatment |
|---|---|
| LV3 | dedicated 90-degree even-fire pushrod V6 pulse, collector, direct-injection, valvetrain and AFM-transition model |
| L83 | Gen V 5.3 L cross-plane pushrod V8 model with its own firing/collector, intake, exhaust, AFM and load layers |
| L86 | Gen V 6.2 L cross-plane pushrod V8; it may share low-level V8 architecture utilities with L83 but requires a distinct combustion, intake/exhaust, inertia and calibration profile |

The LV3 must not be produced by pitch-shifting an inline-six or unrelated V6. L83 and L86 must not be reduced to one generic V8 waveform.

## Evidence retained and unresolved implementation research

Before implementation, retain primary documentation for:

- official 2014 and 2015 Chevrolet order guides;
- the standard axle ratio of each approved RWD powertrain;
- exact tyre, mass, drag, braking and performance values;
- exact gasoline torque curves and AFM control behaviour;
- exact trim/material corrections required for the LV3 and RWD variants.

These evidence gaps do not reopen the approved catalog scope. They block final parameter commitment if unresolved.

## Owner decision recorded

The owner decided:

1. Start from the complete eight-row base matrix, but retain **only RWD**, producing four approved combinations.
2. Include model years 2014 and 2015 and preserve L86 + 6L80 separately from L86 + 8L90.
3. Use only one verified **standard axle ratio** per approved powertrain.
4. Exclude Z71, Max Trailering and Special Service Vehicle variants.
5. Use only the default gasoline calibration; exclude E85 duplicates and fuel-state variants.
6. Missing expected variants: **none identified by the owner**.

The individual owner-scope gate is satisfied. Model 02 is **`approved`**, but implementation remains blocked by the global all-model research gate. Research proceeds to model 03.
