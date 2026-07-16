# BMW 4 Series Coupé F32 pre-LCI — research and integration record

- Model number in Traffic Rider bundle: **01**
- Canonical source GLB: `assets/third_party/sketchfab/traffic_rider_npc_vehicles/bmw_4_series_f32/source/01_bmw_4_series_2014.glb`
- Source SHA-256: `fab5af5379c45f780f2ccc608560b99cb441ebf0f66c06e8eef0cb7fcd28d510`
- Research date: 2026-07-15
- Owner approval date: 2026-07-15
- Integration start date: 2026-07-16
- Workflow status: **`integrating`**
- Authoritative physics baseline: `master` at `3743f5e95391b63a97e81b95050984b8240b7f30` — merged PR #118, per-wheel vehicle physics and DPI v3
- Approved implementation scope: **44 mechanically distinct pre-LCI combinations**

## Current integration state

Completed in the first implementation tranche:

- synchronized PR #107 directly onto the merged PR #118 baseline;
- relocated the unchanged source GLB from the repository root to its canonical third-party path without retaining a duplicate;
- created `TrafficVehicleVisualDefinition` as a reusable, validated visual-integration resource;
- created `resources/traffic/vehicles/bmw_4_series_f32.tres` with verified dimensions, source hash and scale evidence;
- created `scenes/traffic/vehicles/bmw_4_series_f32_visuals.tscn` with canonical `+Y` up / `-Z` front conversion and wheelbase-derived uniform scale;
- added automated contracts for the canonical path, source immutability metadata, scale, baseline and explicit incomplete-derivative state.

Not yet complete:

- split paired front and rear wheel meshes into four independent hub-centred wheel meshes;
- centre the derivative between axle centres and ground it from tyre contact points;
- record final visibility AABB, wheel centres and rolling radius from the processed derivative;
- create playable and AI scenes;
- implement the 44 exact powertrain rows, ZF 8HP behaviour, xDrive coupling, engine audio and performance calibration;
- add the model to the playable catalog only after every exposed variant has complete evidence-backed data.

`processed_visual_ready` remains `false`. The source wrapper is an inspection and scale/orientation stage, not a runtime-ready vehicle visual. No powertrain, mass, gearing, tire, audio or performance value has been guessed.

## Visual identity

The source mesh represents a **two-door BMW 4 Series Coupé F32, pre-LCI, non-M body**. It is not the F33 retractable-hardtop Convertible, the F36 five-door Gran Coupé or the widened F82 M4 body.

The exact trim line and bumper package are unresolved. The body proportions, lamps and front/rear design are consistent with the first-phase F32 sold before the exterior facelift introduced for 2017. Approved visual scope:

- F32 Coupé from launch through February 2017;
- include the March 2016 engine-family update because those powertrains were sold before the exterior LCI;
- exclude all post-LCI mechanical combinations from this visual;
- exclude F33, F36, F82/F83 and Alpina derivatives.

Identity confidence: **verified body code and phase; trim unresolved**.

## Reference dimensions and scale

Primary pre-LCI RWD reference:

| Parameter | Reference |
|---|---:|
| Length | 4.638 m |
| Width excluding mirrors | 1.825 m |
| Height | 1.362 m |
| Wheelbase | 2.810 m |
| Front track | 1.545 m |
| Rear track | 1.594 m |
| Ground clearance | 0.130 m |

The launch xDrive specification is 1.377 m high, with 1.544/1.590 m tracks and 0.145 m ground clearance. Final visual calibration uses the RWD body reference; xDrive differences belong in physical variant data.

Measured source wheelbase: approximately **4.0489 source units**. The committed wrapper scale is therefore:

```text
2.810 / 4.0489 = 0.6940156586
```

The wrapper uses `0.6940157` and a 180-degree Y rotation. Source front is `+Z`; project front is local `-Z`.

## Source inspection

| Item | Result |
|---|---|
| Source meshes | 3 |
| Body mesh | `AI_Bmw4_High_BMW_4_Series_2014_0` |
| Front wheel-pair mesh | `on_teker_wheel_0` |
| Rear wheel-pair mesh | `arka_teker_wheel_0` |
| Body triangles | 1,132 |
| Front wheel-pair triangles | 324 |
| Rear wheel-pair triangles | 324 |
| Total triangles | 1,780 |
| Source AABB | approximately 2.896693 × 1.971918 × 6.661146 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 4.0489 source units |

The source GLB remains byte-identical. A derived visual is mandatory because both axle meshes contain paired wheels. It must preserve materials, UVs, normals and source triangles while producing `Body`, `WheelFrontLeft`, `WheelFrontRight`, `WheelRearLeft` and `WheelRearRight` with hub-centred pivots.

## Research boundary and deduplication

The matrix covers mechanically distinct standard-production combinations applicable to the pre-LCI F32 Coupé across markets. Different engine generations under the same badge remain separate because torque curves, controls, inertia, response and sound architecture differ materially.

- do not create duplicate catalog entries for a mechanically identical engine, transmission, drivetrain and calibration merely because it appeared in multiple markets, trims or model years;
- keep N20 versus B48, N47 versus B47 and N55 versus B58 separate;
- keep manual and automatic versions separate;
- keep RWD and xDrive versions separate.

Evidence states:

- `verified_factory`: direct BMW F32 press kit or technical sheet;
- `strongly_supported`: BMW F32 range data plus official later F32 mechanical specification;
- `provisional regional`: additional market-specific BMW documentation is still required before exact runtime parameters may be committed.

## Approved standard matrix

The transmission lists expand independently. `RWD: 6MT, 8AT; xDrive: 6MT, 8AT` represents four variants.

| Badge / engine revision | Pre-LCI period | Output / torque | Factory combinations | Evidence | Count |
|---|---|---|---|---|---:|
| 418i — B38B15 turbo I3 | 03/2016–02/2017 | 100 kW / 136 PS; 220 Nm | RWD: 6MT, 8AT | provisional regional | 2 |
| 420i — N20B20 turbo I4 | 11/2013–02/2016 | 135 kW / 184 PS; 270 Nm | RWD: 6MT, 8AT; xDrive: 6MT, 8AT | verified / strongly supported | 4 |
| 420i — B48B20 turbo I4 | 03/2016–02/2017 | 135 kW / 184 PS; 290 Nm | RWD: 6MT, 8AT; xDrive: 6MT, 8AT | verified / strongly supported | 4 |
| 428i — N20B20 turbo I4 | 07/2013–02/2016 | 180 kW / 245 PS; 350 Nm | RWD: 6MT, 8AT; xDrive: 8AT | verified_factory | 3 |
| 430i — B48B20 turbo I4 | 03/2016–02/2017 | 185 kW / 252 PS; 350 Nm | RWD: 6MT, 8AT; xDrive: 8AT | verified / strongly supported | 3 |
| 435i — N55B30 turbo I6 | 07/2013–02/2016 | 225 kW / 306 PS; 400 Nm | RWD: 6MT, 8AT; xDrive: 8AT | verified_factory | 3 |
| 440i — B58B30 turbo I6 | 03/2016–02/2017 | 240 kW / 326 PS; 450 Nm | RWD: 6MT, 8AT; xDrive: 6MT, 8AT | verified / strongly supported | 4 |
| 418d — N47D20 turbo I4 | approximately 03/2014–02/2015 | 105 kW / 143 PS; 300 Nm | RWD: 6MT, 8AT | provisional regional | 2 |
| 418d — B47D20 turbo I4 | 03/2015–02/2017 | 110 kW / 150 PS; 320 Nm | RWD: 6MT, 8AT | strongly supported regional | 2 |
| 420d — N47D20 turbo I4 | 07/2013–02/2015 | 135 kW / 184 PS; 380 Nm | RWD: 6MT, 8AT; xDrive: 6MT, 8AT | verified / strongly supported | 4 |
| 420d — B47D20 turbo I4 | 03/2015–02/2017 | 140 kW / 190 PS; 400 Nm | RWD: 6MT, 8AT; xDrive: 6MT, 8AT | verified / strongly supported | 4 |
| 425d — N47D20 twin-turbo I4 | approximately 03/2014–02/2016 | 160 kW / 218 PS; 450 Nm | RWD: 6MT, 8AT | strongly supported | 2 |
| 425d — B47D20 twin-turbo I4 | 03/2016–02/2017 | 165 kW / 224 PS; 450 Nm | RWD: 6MT, 8AT | strongly supported | 2 |
| 430d — N57D30 turbo I6 | 11/2013–02/2017 | 190 kW / 258 PS; 560 Nm | RWD: 8AT; xDrive: 8AT | verified / strongly supported | 2 |
| 435d — N57D30 twin-turbo I6 | 11/2013–02/2017 | 230 kW / 313 PS; 630 Nm | xDrive: 8AT | verified_factory | 1 |
| **Standard total** |  |  | **23 petrol + 19 diesel** |  | **42** |

All 8AT entries are conventional planetary **ZF 8HP-family torque-converter automatics**.

## Approved special variant

| Variant | Period / market | Output / torque | Factory combinations | Evidence | Count |
|---|---|---|---|---|---:|
| 435i ZHP Coupé Edition — N55B30 with BMW M Performance Power Kit | MY2016, United States, 100-car edition | 335 hp; 430 Nm with 6MT; 450 Nm with 8AT | RWD: 6MT, 8AT | BMW of North America release details reproduced by BMWBLOG | 2 |

The ZHP is mechanically separate from the standard 435i because it uses a different engine calibration, intake, exhaust, limited-slip differential and performance package.

**Approved total: 42 standard + 2 ZHP = 44 combinations.**

## Excluded derivatives

- BMW M4 F82/F83;
- Alpina B4/D4;
- F33 Convertible and F36 Gran Coupé;
- post-LCI 2017–2020 combinations;
- accessory tunes outside the factory-defined ZHP edition.

## Transmission and drivetrain implementation requirements

Exact gearbox family/suffix, ratios, reverse ratio and final drive must be verified per row. Family-level assumptions such as 8HP45, 8HP50 or 8HP70 may not be presented as exact codes without corroboration.

The 8HP implementation must support speed-ratio-dependent converter multiplication and slip, creep, progressive gear-dependent lock-up, skip shifts, kickdown, torque and inertia shift phases, mode-dependent schedules and exact ratio sets. A shortened generic automatic shift delay is not an acceptable substitute.

xDrive requires review against the PR #118 per-wheel differential and wheel-torque interfaces. A fixed front torque fraction is not sufficient as a final model of transfer-clutch behaviour.

## Physics and performance requirements

Each combination requires its own sampled torque curve, exact gearing, DIN/EU mass, tyre size, drag, frontal area, axle load, centre of mass, losses, inertia, converter/clutch behaviour and sourced performance targets. Calibration must use per-wheel contact/load/slip, combined tire force, differential, rotational inertia, braking, steering/yaw, vector drag and DPI v3 interfaces from baseline `3743f5e95391b63a97e81b95050984b8240b7f30`.

Representative BMW launch targets include 5.9/5.8 s to 100 km/h for the 428i RWD manual/automatic, 5.4/5.1 s for the 435i RWD manual/automatic, 5.8 s for the 428i xDrive automatic and 4.9 s for the 435i xDrive automatic. These are validation targets, not tuning parameters.

## Engine-audio architecture

| Engine family | Required treatment |
|---|---|
| B38 | dedicated turbo inline-three firing and collector model |
| N20 | first-generation BMW turbo inline-four profile |
| B48 | modular turbo inline-four distinct from N20 |
| N55 | turbo inline-six with dedicated intake, exhaust and turbo transients; standard and ZHP calibrations |
| B58 | modular turbo inline-six distinct from N55 and naturally aspirated BMW I6 models |
| N47 | common-rail turbo-diesel inline-four |
| B47 | later modular diesel inline-four with distinct combustion and mechanical layers |
| N57 | turbo/twin-turbo diesel inline-six with aspiration-specific layers |

Unrelated cylinder layouts may not be pitch-shifted or equalized into these sounds.

## Primary sources retained for implementation

- BMW Group, *The new BMW 4 Series Coupe*, 15 June 2013: https://www.press.bmwgroup.com/global/article/detail/T0142634EN/the-new-bmw-4-series-coupe
- BMW Group launch technical PDF: https://www.press.bmwgroup.com/global/article/attachment/T0142634EN/256334
- BMW Group, *BMW model update measures for autumn 2013*, 19 September 2013: https://www.press.bmwgroup.com/global/article/detail/T0145791EN/bmw-model-update-measures-for-autumn-2013
- BMW Group, *The new BMW 4 Series*, January 2017: https://www.press.bmwgroup.com/global/article/detail/T0266807EN/the-new-bmw-4-series
- BMW Group technical specifications PDF, January 2017: https://www.press.bmwgroup.com/global/article/attachment/T0266807EN/394469
- BMWBLOG reproduction of BMW of North America 435i ZHP release details, 20 May 2015: https://www.bmwblog.com/2015/05/20/bmw-unveils-the-special-edition-bmw-435i-zhp-coupe/

Regional entries still require market-specific BMW documentation before exact runtime values are finalized.

## Owner decision recorded

The owner answered on 2026-07-15:

1. Import all standard combinations: **yes**.
2. Include regional/provisional 418i and 418d combinations: **yes**, subject to final documentary verification.
3. Avoid copies: **yes**.
4. Include the US 435i ZHP Coupé: **yes**, both 6MT and 8AT.
5. Visual scope: **strictly pre-LCI**.
6. Missing expected variants: **none identified by the owner**.

The owner-scope gate and PR #118 dependency are satisfied. Model 01 is now `integrating`; model 02 remains queued behind it in the ascending implementation order.
