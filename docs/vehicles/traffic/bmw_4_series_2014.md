# BMW 4 Series Coupé F32 pre-LCI — research and approved scope

- Model number in Traffic Rider bundle: **01**
- Source GLB: `01_bmw_4_series_2014.glb`
- Source SHA-256: `fab5af5379c45f780f2ccc608560b99cb441ebf0f66c06e8eef0cb7fcd28d510`
- Research date: 2026-07-15
- Owner approval date: 2026-07-15
- Workflow status: **`approved`**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Approved implementation scope: **44 mechanically distinct pre-LCI combinations**.

## Visual identity

The source mesh represents a **two-door BMW 4 Series Coupé F32, pre-LCI, non-M body**. It is not the F33 retractable-hardtop Convertible, the F36 five-door Gran Coupé or the widened F82 M4 body.

The exact trim line and bumper package are unresolved. The body proportions, lamps and front/rear design are consistent with the first-phase F32 sold before the exterior facelift introduced for 2017. The approved visual scope is therefore:

- F32 Coupé from launch through February 2017;
- include the March 2016 engine-family update because those powertrains were sold before the exterior LCI;
- exclude all post-LCI mechanical combinations from this visual;
- exclude F33, F36, F82/F83 and Alpina derivatives.

Identity confidence: **verified body code and phase; trim unresolved**.

## Reference dimensions

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

The launch xDrive specification is 1.377 m high, with 1.544/1.590 m tracks and 0.145 m ground clearance. Final visual scale must be calibrated primarily from the 2.810 m wheelbase and then cross-checked against the chosen drive configuration.

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

The source GLB remains unchanged. A derived visual will be required to split both axle meshes into four hub-centred wheel nodes.

## Research boundary and deduplication rule

The matrix covers mechanically distinct standard-production combinations applicable to the pre-LCI F32 Coupé across markets. A different engine generation under the same badge is a separate variant because its torque curve, controls, inertia, response and sound architecture differ materially.

The owner's instruction to avoid copies is recorded as the following catalog rule:

- do not create multiple catalog entries for a mechanically identical engine, transmission, drivetrain and calibration merely because it appeared in multiple markets, trims or model years;
- keep N20 versus B48, N47 versus B47 and N55 versus B58 as separate variants because they are different engine families, not copies;
- keep manual and automatic versions separate because the transmission architecture and performance differ;
- keep RWD and xDrive versions separate because mass, losses, traction and torque distribution differ.

Evidence states:

- `verified_factory`: direct BMW F32 press kit or technical sheet;
- `strongly_supported`: BMW F32 range data plus official later F32 mechanical specification;
- `provisional regional`: catalogued regional application for which an additional market-specific BMW order guide or homologation sheet is still required before implementation.

## Approved standard matrix

The transmission lists expand independently. For example, `RWD: 6MT, 8AT; xDrive: 6MT, 8AT` represents four separate variants.

| Badge / engine revision | Pre-LCI period | Output / torque | Factory combinations | Evidence | Count |
|---|---|---|---|---|---:|
| 418i — B38B15 turbo I3 | 03/2016–02/2017 | 100 kW / 136 PS; 220 Nm | RWD: 6MT, 8AT | provisional regional, approved subject to final document verification | 2 |
| 420i — N20B20 turbo I4 | 11/2013–02/2016 | 135 kW / 184 PS; 270 Nm | RWD: 6MT, 8AT; xDrive: 6MT, 8AT | verified / strongly supported | 4 |
| 420i — B48B20 turbo I4 | 03/2016–02/2017 | 135 kW / 184 PS; 290 Nm | RWD: 6MT, 8AT; xDrive: 6MT, 8AT | verified / strongly supported | 4 |
| 428i — N20B20 turbo I4 | 07/2013–02/2016 | 180 kW / 245 PS; 350 Nm | RWD: 6MT, 8AT; xDrive: 8AT | verified_factory | 3 |
| 430i — B48B20 turbo I4 | 03/2016–02/2017 | 185 kW / 252 PS; 350 Nm | RWD: 6MT, 8AT; xDrive: 8AT | verified / strongly supported | 3 |
| 435i — N55B30 turbo I6 | 07/2013–02/2016 | 225 kW / 306 PS; 400 Nm | RWD: 6MT, 8AT; xDrive: 8AT | verified_factory | 3 |
| 440i — B58B30 turbo I6 | 03/2016–02/2017 | 240 kW / 326 PS; 450 Nm | RWD: 6MT, 8AT; xDrive: 6MT, 8AT | verified / strongly supported | 4 |
| 418d — N47D20 turbo I4 | approximately 03/2014–02/2015 | 105 kW / 143 PS; 300 Nm | RWD: 6MT, 8AT | strongly supported regional, approved subject to final document verification | 2 |
| 418d — B47D20 turbo I4 | 03/2015–02/2017 | 110 kW / 150 PS; 320 Nm | RWD: 6MT, 8AT | strongly supported regional, approved subject to final document verification | 2 |
| 420d — N47D20 turbo I4 | 07/2013–02/2015 | 135 kW / 184 PS; 380 Nm | RWD: 6MT, 8AT; xDrive: 6MT, 8AT | verified / strongly supported | 4 |
| 420d — B47D20 turbo I4 | 03/2015–02/2017 | 140 kW / 190 PS; 400 Nm | RWD: 6MT, 8AT; xDrive: 6MT, 8AT | verified / strongly supported | 4 |
| 425d — N47D20 twin-turbo I4 | approximately 03/2014–02/2016 | 160 kW / 218 PS; 450 Nm | RWD: 6MT, 8AT | strongly supported | 2 |
| 425d — B47D20 twin-turbo I4 | 03/2016–02/2017 | 165 kW / 224 PS; 450 Nm | RWD: 6MT, 8AT | strongly supported | 2 |
| 430d — N57D30 turbo I6 | 11/2013–02/2017 | 190 kW / 258 PS; 560 Nm | RWD: 8AT; xDrive: 8AT | verified / strongly supported | 2 |
| 435d — N57D30 twin-turbo I6 | 11/2013–02/2017 | 230 kW / 313 PS; 630 Nm | xDrive: 8AT | verified_factory | 1 |
| **Standard total** |  |  | **23 petrol + 19 diesel** |  | **42** |

All 8AT entries are conventional planetary **ZF 8HP-family torque-converter automatics**. They are not automated manuals or DCTs.

## Approved special variant

| Variant | Period / market | Output / torque | Factory combinations | Evidence | Count |
|---|---|---|---|---|---:|
| 435i ZHP Coupé Edition — N55B30 with BMW M Performance Power Kit | MY2016, United States, 100-car edition | 335 hp; 430 Nm with 6MT; 450 Nm with 8AT | RWD: 6MT, 8AT | BMW of North America release details reproduced by BMWBLOG | 2 |

The ZHP is mechanically separate from the standard 435i because it uses a different engine calibration, intake, exhaust, limited-slip differential and performance package. It is not treated as a duplicate.

**Approved total: 42 standard + 2 ZHP = 44 combinations.**

BMW M Performance Power Kits sold separately for ordinary cars remain excluded as standalone catalog variants; only the factory-defined ZHP edition is included.

## Excluded derivatives

- BMW M4 F82/F83: widened body, S55 engine and M-specific chassis;
- Alpina B4/D4: separate manufacturer derivatives;
- F33 Convertible and F36 Gran Coupé variants;
- post-LCI 2017–2020 combinations;
- dealer/accessory tunes and ordinary M Performance Power Kit installations outside the approved ZHP edition.

## Transmission implementation assessment

The current `master` supports a generic automatic shift request model and a basic torque-converter multiplier, but does not model all required F32/ZF 8HP behaviour. Approved automatic variants will require an architecture-specific extension supporting at minimum:

- speed-ratio-dependent converter multiplication and slip;
- creep and launch behaviour;
- progressive, gear-dependent lock-up clutch control;
- skip shifts and kickdown strategy;
- torque and inertia phases during shifts instead of a generic full torque cut;
- mode-dependent shift schedules;
- distinct 8HP generations and torque-capacity families when required;
- exact reverse and final-drive ratios.

The exact ZF gearbox family/suffix and exact six-speed manual code must be verified per approved variant. Family-level assumptions such as 8HP45, 8HP50 or 8HP70 may not be committed as exact codes without corroborating evidence.

The current xDrive implementation uses a fixed front torque fraction. Approved xDrive variants require a review of dynamic transfer-clutch behaviour and speed/slip-dependent torque distribution.

## Physics and performance requirements

Each approved combination must receive its own:

- sampled full-load torque curve;
- exact forward, reverse and final-drive ratios;
- exact DIN/EU mass for engine, drive and gearbox;
- tyre size and rolling radius;
- drag coefficient and frontal area;
- axle load and centre-of-mass estimate;
- drivetrain efficiency and rotating inertia;
- converter/clutch and shift behaviour;
- documented acceleration, in-gear, standing-distance and top-speed targets;
- braking and tire-force calibration against current `master` physics.

BMW launch data gives representative validation targets of 5.9/5.8 s to 100 km/h for the 428i RWD manual/automatic, 5.4/5.1 s for the 435i RWD manual/automatic, 5.8 s for the 428i xDrive automatic and 4.9 s for the 435i xDrive automatic. These are validation targets, not direct tuning parameters.

Before integration is completed, the branch must be synchronized with current `master`. Every affected F32 variant must be retested and recalibrated after relevant shared-physics changes.

## Engine-audio architecture assessment

| Engine family | Required treatment |
|---|---|
| B38 | turbo inline-three; dedicated three-cylinder firing and collector model |
| N20 | first-generation BMW turbo inline-four profile |
| B48 | modular turbo inline-four, distinct from N20 |
| N55 | modern turbo inline-six with dedicated intake, exhaust and turbo transients; separate standard and ZHP calibrations |
| B58 | modular turbo inline-six, distinct from N55 and naturally aspirated BMW I6 models |
| N47 | common-rail turbo-diesel inline-four |
| B47 | later modular diesel inline-four with distinct combustion and mechanical layers |
| N57 | turbo/twin-turbo diesel inline-six with aspiration-specific layers |

Unrelated cylinder layouts may not be pitch-shifted or equalized into these sounds. Shared DSP utilities are allowed, but architecture-defining pulse cadence, collector grouping, induction, turbo and mechanical layers must be independently derived.

## Primary sources retained for implementation

- BMW Group, *The new BMW 4 Series Coupe*, 15 June 2013: https://www.press.bmwgroup.com/global/article/detail/T0142634EN/the-new-bmw-4-series-coupe
- BMW Group launch technical PDF: https://www.press.bmwgroup.com/global/article/attachment/T0142634EN/256334
- BMW Group, *BMW model update measures for autumn 2013*, 19 September 2013: https://www.press.bmwgroup.com/global/article/detail/T0145791EN/bmw-model-update-measures-for-autumn-2013
- BMW Group, *The new BMW 4 Series*, January 2017: https://www.press.bmwgroup.com/global/article/detail/T0266807EN/the-new-bmw-4-series
- BMW Group technical specifications PDF, January 2017: https://www.press.bmwgroup.com/global/article/attachment/T0266807EN/394469
- BMWBLOG reproduction of BMW of North America 435i ZHP release details, 20 May 2015: https://www.bmwblog.com/2015/05/20/bmw-unveils-the-special-edition-bmw-435i-zhp-coupe/

Regional entries still require an additional market-specific BMW order guide, price list, homologation sheet or parts-catalog record before their exact implementation values are finalized. Approval means they are in scope; it does not permit guessing missing technical data.

## Owner decision recorded

The owner answered on 2026-07-15:

1. Import all standard combinations: **yes**.
2. Include regional/provisional 418i and 418d combinations: **yes**, subject to final documentary verification.
3. Avoid copies: **yes**. Mechanically identical duplicates across markets/years are collapsed, while different engine generations and transmission/drivetrain combinations remain separate.
4. Include the US 435i ZHP Coupé: **yes**, both 6MT and 8AT versions.
5. Visual scope: **strictly pre-LCI**.
6. Missing expected variants: **none identified by the owner**.

The owner-scope gate is satisfied. The model may proceed from `approved` to `integrating`; model 02 remains blocked until model 01 completes according to the ascending-number workflow.