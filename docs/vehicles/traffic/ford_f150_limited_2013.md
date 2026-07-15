# Ford F-150 P415 SuperCrew 5.5-ft box — research and owner-scope gate

- Model number in Traffic Rider bundle: **07**
- Source GLB: `07_ford_f150_limited_2013.glb`
- Source SHA-256: `3be44b7f8f563efc57d259e0a3902dc55b2b347a0b34b2b90f55d75f541f6587`
- Research date: 2026-07-15
- Scope expansion date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The committed source represents a **2013 Ford F-150 Limited SuperCrew with the 5.5-ft Styleside box**, from the facelifted P415/twelfth-generation F-150.

Visible source evidence includes:

- four full-size SuperCrew doors;
- the short 5.5-ft Styleside box rather than the 6.5-ft or 8-ft box;
- `F-150` and `LIMITED` exterior markings;
- Limited-specific chrome three-bar grille treatment;
- HID-style headlamps;
- body-colour bumper surfaces with bright trim;
- polished 22-inch Limited wheel appearance;
- white exterior paint and North American plate treatment.

The source does not visually prove 4x2 versus 4x4. The owner has nevertheless fixed the **3.5L EcoBoost scope to 4x2 only**.

Identity confidence: **high for the 2013 Limited SuperCrew 5.5-ft source; high for the shared P415 SuperCrew/short-box body proportions; period-correct 2009–2012 front and trim derivatives require separate visual work**.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Wheelbase | 144.5 in / 3.6703 m |
| Overall length | 231.9 in / 5.8903 m |
| Width excluding mirrors | approximately 78.9 in for 2009–2011 and 79.2 in for 2012–2014 |
| Box floor length | 67.0 in / 1.7018 m |
| Cargo-box volume | approximately 55.4 cu ft |
| Source meshes | 3 |
| Body mesh | `AI_Ford_F150_High_Ford_F150_Limited_2013_0` |
| Front wheel-pair mesh | `on_teker.006_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.006_wheel_0` |
| Body triangles | 1,182 |
| Front wheel-pair triangles | 288 |
| Rear wheel-pair triangles | 288 |
| Total triangles | 1,758 |
| Source scene AABB | approximately 3.492298 × 2.698670 × 8.420832 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 5.362779 source units |
| Approximate wheelbase-derived scale | 0.684403 |

The 3.6703 m wheelbase is the primary scale reference. Length, width, height, tracks, ground clearance, wheel diameter, tyre sidewall and box dimensions require independent cross-checks.

The committed GLB remains unchanged. Wheel separation, collision, catalog, physics, transmission and audio work remain blocked by the global research gate.

## Expanded research boundary

The owner expanded research from the strict 2013–2014 Limited trim to the complete **2009–2014 P415 model-year generation**, while retaining the source-compatible **SuperCrew cab and 5.5-ft Styleside box** as the body boundary.

The expansion does not silently add Regular Cab, SuperCab, 6.5-ft or 8-ft boxes, Flareside, SVT Raptor wide body or chassis-cab derivatives. Trim names are evidence for engine and equipment availability, not automatic duplicate catalog vehicles.

The generation has two major powertrain periods:

1. **2009–2010:** 4.6L 2V, 4.6L 3V and 5.4L 3V FFV V8 engines; the base 4.6L 2V uses a four-speed automatic while the other engines use a six-speed automatic.
2. **2011–2014:** 3.7L V6 FFV, 5.0L V8 FFV, 3.5L EcoBoost V6 and 6.2L V8; all use the six-speed automatic architecture.

The 3.5L EcoBoost was not a 2009–2010 factory engine. Its expanded model-year coverage therefore begins in 2011.

## Powertrain architecture by period

### 2009–2010

- **4.6L Modular SOHC 2-valve naturally aspirated cross-plane V8:** 248 hp / 294 lb-ft; longitudinal four-speed planetary torque-converter automatic, working identification 4R75E.
- **4.6L Modular SOHC 3-valve naturally aspirated cross-plane V8:** 292 hp / 320 lb-ft; longitudinal six-speed planetary torque-converter automatic, working identification 6R80/6R80E family.
- **5.4L Triton Modular SOHC 3-valve naturally aspirated cross-plane V8 FFV:** approximately 310 hp / 365 lb-ft on gasoline and up to 320 hp / 390 lb-ft on E85; same six-speed automatic family.

The 4.6L 2V is evidenced in the SuperCrew short-box as 4x2 but not as SuperCrew 4x4. The 4.6L 3V and 5.4L appear in both 4x2 and 4x4 SuperCrew applications.

### 2011–2014

- **3.7L Duratec Ti-VCT DOHC naturally aspirated V6 FFV:** 302 hp / 278 lb-ft; six-speed automatic; source-body SuperCrew 5.5-ft application is evidenced as 4x2.
- **5.0L Coyote Ti-VCT DOHC naturally aspirated cross-plane V8 FFV:** 360 hp / 380 lb-ft; six-speed automatic; 4x2 and 4x4 SuperCrew applications.
- **3.5L EcoBoost DOHC twin-turbocharged direct-injected V6:** 365 hp / 420 lb-ft; six-speed automatic; factory 4x2 and 4x4 existed, but the owner has fixed this project scope to **4x2 only with one standard axle ratio**.
- **6.2L Boss SOHC naturally aspirated V8:** 411 hp / 434 lb-ft on the documented premium-fuel rating; six-speed automatic; 4x2 and 4x4 SuperCrew applications from 2011 onward.

The six-speed working identification is 6R80-family. Exact engineering suffixes, converters and calibration changes by year and engine require Ford service/order-guide evidence before parameters are committed.

## Mechanically consolidated candidate matrix

This matrix merges model years where the same engine, transmission, body and drivetrain architecture continue. It does not yet merge visually different 2009–2012 and 2013–2014 front treatments.

| # | Model-year coverage | Engine / fuel hardware | Transmission | Drivetrain | Axle policy | Decision state |
|---:|---|---|---|---|---|---|
| 1 | 2009–2010 | 4.6L Modular 2V V8, 248 hp / 294 lb-ft | 4R75E-family 4-speed torque-converter automatic | 4x2 RWD | unresolved owner policy; one standard ratio recommended | candidate |
| 2 | 2009–2010 | 4.6L Modular 3V V8, 292 hp / 320 lb-ft | 6R80-family 6-speed torque-converter automatic | 4x2 RWD | unresolved owner policy | candidate |
| 3 | 2009–2010 | 4.6L Modular 3V V8, 292 hp / 320 lb-ft | 6R80-family 6-speed torque-converter automatic | 4x4 | unresolved owner policy | candidate |
| 4 | 2009–2010 | 5.4L Triton 3V V8 FFV | 6R80-family 6-speed torque-converter automatic | 4x2 RWD | unresolved owner policy | candidate |
| 5 | 2009–2010 | 5.4L Triton 3V V8 FFV | 6R80-family 6-speed torque-converter automatic | 4x4 | unresolved owner policy | candidate |
| 6 | 2011–2014 | 3.7L Duratec Ti-VCT V6 FFV, 302 hp / 278 lb-ft | 6R80-family 6-speed torque-converter automatic | 4x2 RWD | unresolved owner policy | candidate |
| 7 | 2011–2014 | 5.0L Coyote V8 FFV, 360 hp / 380 lb-ft | 6R80-family 6-speed torque-converter automatic | 4x2 RWD | unresolved owner policy | candidate |
| 8 | 2011–2014 | 5.0L Coyote V8 FFV, 360 hp / 380 lb-ft | 6R80-family 6-speed torque-converter automatic | 4x4 | unresolved owner policy | candidate |
| 9 | 2011–2014 | 3.5L EcoBoost twin-turbo DI V6, 365 hp / 420 lb-ft | 6R80-family 6-speed torque-converter automatic | **4x2 RWD only** | **one verified standard ratio only; owner-fixed** | partially approved |
| 10 | 2011–2014 | 6.2L Boss V8, 411 hp / 434 lb-ft | 6R80-family 6-speed torque-converter automatic | 4x2 RWD | unresolved owner policy | candidate |
| 11 | 2011–2014 | 6.2L Boss V8, 411 hp / 434 lb-ft | 6R80-family 6-speed torque-converter automatic | 4x4 | unresolved owner policy | candidate |

**Mechanically consolidated candidate total: 11 rows.**

If the owner applies 4x2-only and one-standard-axle policies to every engine, the scope reduces to **7 rows**. If only the 3.5L EcoBoost family is ultimately retained across 2011–2014, the scope reduces to **1 mechanically merged row**, subject to the visual-phase decision below.

## Owner-fixed 3.5L EcoBoost policy

For every approved 2011–2014 3.5L EcoBoost application:

- use 4x2 rear-wheel drive only;
- exclude the transfer case, front driveshaft, front differential and driven half-shafts;
- use one verified factory-standard rear-axle ratio for the selected year/trim calibration;
- do not create optional axle-ratio duplicates;
- do not create a 4x4 duplicate.

The standard axle is not uniform across every possible trim. The 2012 generic 4x2 EcoBoost towing table documents a 3.15 application, while the 2014 Limited equipment list documents a standard **3.55 electronic-locking differential**. Therefore a selected trim/year calibration must determine the exact ratio and differential state; one ratio must not be guessed for the entire 2011–2014 range.

## Visual phases and trim problem

- **2009–2012:** original P415 front treatment. The 2011–2012 3.5L EcoBoost existed in SuperCrew 5.5-ft bodies, but not in the 2013-style Limited appearance represented by the source. Including these years requires a period-correct grille, lamps, bumpers, wheels and badges.
- **2013–2014:** refreshed front treatment. The source is the 2013 Limited visual anchor. Limited uses the 3.5L EcoBoost, 22-inch P275/45R22 tyres, sport-tuned shocks and a standard 3.55 electronic-locking rear axle.

The project must not label a 2011 or 2012 truck as Limited while reusing the 2013 source materials unchanged. A non-Limited earlier trim derivative must be selected if those years become approved catalog content.

## Axle and differential questions for the other engines

Factory towing and equipment tables show multiple ratios including 3.15, 3.31, 3.55, 3.73, 4.10 and trim/package-specific locking or limited-slip states. These options materially affect acceleration, engine speed, towing and differential behaviour.

The owner has fixed the 3.5L EcoBoost to one standard ratio. The remaining engines still require a policy:

1. one verified standard axle and differential state per engine/drivetrain row; or
2. separate factory axle-ratio rows, which would substantially increase the catalog.

The first policy is recommended for consistency with models 02, 05 and 06.

## Fuel subdivisions

- 4.6L 2V and 4.6L 3V are gasoline engines.
- 5.4L 3V, 3.7L and 5.0L are FFV-capable.
- 3.5L EcoBoost and 6.2L are gasoline engines in this generation.

The FFV engines can be represented as gasoline-only hardware/calibration states, selectable gasoline/E85 states, or duplicate fuel rows. Duplicate rows are not recommended because the same engine hardware underlies the fuel choice. The 5.4L published peak output changes with E85 and therefore cannot silently use the E85 rating while simulating gasoline.

## Chassis and physics architecture

All approved rows require:

- fully boxed ladder frame;
- longitudinal front engine;
- independent double-wishbone/coil-over front suspension;
- solid rear drive axle on leaf springs;
- four-wheel disc brakes with ABS;
- AdvanceTrac with Roll Stability Control;
- SuperCrew 5.5-ft-box mass and load distribution;
- drivetrain-specific mass, ride height and losses;
- year-, trim-, wheel- and tyre-correct steering and damping calibration.

A 4x4 configuration must use its real transfer case and front driveline. A 4x2 configuration must not be implemented as a disabled 4x4.

## Transmission architecture assessment

### 4R75E-family four-speed

The 2009–2010 4.6L 2V row requires a distinct four-speed planetary automatic with a hydrodynamic converter, exact four forward ratios, reverse, creep, lock-up, kickdown, load scheduling and thermal behaviour.

### 6R80-family six-speed

Every other candidate row uses the longitudinal six-speed planetary automatic family. It requires exact ratios, engine-specific converter and lock-up behaviour, torque and inertia shift phases, multi-gear kickdown, tow/haul or grade scheduling, boost coordination for EcoBoost and transfer-case coordination for 4x4.

The four-speed and six-speed units must not share a generic ratio set or only differ by the number of enabled gears.

## Engine-audio architecture assessment

| Engine | Required treatment |
|---|---|
| 4.6L 2V / 4.6L 3V / 5.4L 3V | displacement- and valvetrain-specific Ford Modular cross-plane V8 layers |
| 3.7L V6 | naturally aspirated V6 cadence and Ti-VCT transient response |
| 5.0L Coyote V8 | DOHC Ti-VCT cross-plane V8, distinct from the older Modular 2V/3V engines |
| 3.5L EcoBoost | dedicated direct-injected twin-turbo V6 with turbo, compressor, wastegate/bypass and intercooler response |
| 6.2L Boss V8 | large-displacement SOHC V8 with its own firing, intake and exhaust architecture |

None of these may be produced only by pitch-shifting another cylinder layout or displacement.

## Evidence retained and unresolved work

Ford 2010, 2012, 2013 and 2014 brochures and technical tables establish the body dimensions, engine outputs, transmission counts, SuperCrew availability, drivetrain subdivisions, EcoBoost introduction period, axle choices and Limited package data used above. Before implementation retain exact Ford order-guide/service evidence for:

- 2009 and 2011 order restrictions and exact model-year changeovers;
- 4R75E and 6R80 engineering suffixes, ratios and converters;
- one standard axle ratio and differential state for each approved row;
- exact trim/body availability where brochure tables aggregate cabs;
- kerb mass, axle loads, tyres, drag, brakes and performance targets;
- 4x4 transfer-case codes and behaviour if any non-EcoBoost 4x4 rows are approved.

These gaps block parameter commitment but do not justify guessed hardware.

## Owner scope decision — remaining questions

Status remains **`awaiting_owner_scope`**. The following decisions are already fixed: generation research covers 2009–2014; body remains SuperCrew with the 5.5-ft box; 3.5L EcoBoost is 4x2 only with one standard axle ratio.

Please decide:

1. Include all seven engine families represented in the 11-row matrix, or retain only selected engines?
2. For every engine other than 3.5L EcoBoost, include both evidenced 4x2 and 4x4 rows, or use 4x2 only?
3. Apply one verified standard axle ratio and standard differential state to every remaining row, matching the fixed EcoBoost policy?
4. Simulate the 5.4L, 3.7L and 5.0L FFV engines on gasoline only, or provide selectable E85 states?
5. Include a correct 2009–2012 front/trim derivative, or keep only the 2013–2014 refreshed appearance?
6. If 2009–2012 is included, use one period-correct non-Limited high-series appearance without trim duplicates?
7. Merge mechanically identical model years into the period rows shown above, or create separate year entries?
8. Preserve the source Limited 22-inch P275/45R22 wheel/tyre and sport-shock package only for the 2013–2014 Limited row rather than forcing it onto earlier/non-Limited engines?
9. Is any expected P415 SuperCrew 5.5-ft engine, transmission, drivetrain, fuel, axle or visual-phase variant missing?

No implementation begins after this partial decision. Research proceeds to model 08 only after the owner fixes the remaining model 07 scope, and implementation begins only after every included model has reached `approved`.