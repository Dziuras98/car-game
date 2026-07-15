# Ford F-150 P415 SuperCrew 5.5-ft box — research and approved scope

- Model number in Traffic Rider bundle: **07**
- Source GLB: `07_ford_f150_limited_2013.glb`
- Source SHA-256: `3be44b7f8f563efc57d259e0a3902dc55b2b347a0b34b2b90f55d75f541f6587`
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **7 mechanically consolidated 4x2 engine configurations**
- Model-year coverage: **2009–2014 P415, identical mechanical years merged**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity and owner-directed common appearance

The committed source represents a **2013 Ford F-150 Limited SuperCrew with the 5.5-ft Styleside box**. It has four full-size doors, the 144.5-in wheelbase, the short 67-in box, Limited grille and badges, HID-style lamps, body-colour/bright bumpers and polished 22-in wheels.

The owner expanded the mechanical scope to the complete 2009–2014 P415 generation but deliberately fixed every approved row to the **same source-like 2013 Limited exterior and chassis presentation**:

- SuperCrew cab and 5.5-ft Styleside box only;
- source 2013 Limited front, lamps, bumpers, badges and materials for every row;
- 22-in polished wheels with P275/45R22 tyres for every row;
- Limited-style sport-tuned shock calibration for every row;
- one common visual/equipment version rather than separate XL, XLT, FX, Lariat, King Ranch, Platinum, Harley-Davidson, Limited or Raptor derivatives.

This is an explicit owner-directed visual and running-gear homogenization. It is not a claim that every 2009–2012 engine was sold from the factory with 2013 Limited trim, HID lamps, 22-in tyres or the Limited shock package. The catalog must retain each engine's real model-year availability while using the common source presentation.

Excluded bodies are Regular Cab, SuperCab, 6.5-ft and 8-ft boxes, Flareside, SVT Raptor wide body and chassis-cab derivatives.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Wheelbase | 144.5 in / 3.6703 m |
| Overall length | 231.9 in / 5.8903 m |
| Box floor length | 67.0 in / 1.7018 m |
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

The source GLB remains unchanged. Four independent wheels, collision, catalog, physics, transmission and audio remain deferred by the global research gate.

## Owner-directed scope rules

- include every evidenced engine family compatible with the P415 SuperCrew 5.5-ft body boundary;
- use **4x2 rear-wheel drive only** for every engine;
- merge model years where engine, output, transmission and drivetrain architecture are mechanically equivalent;
- use one verified factory-standard axle ratio and one verified standard differential state per row;
- do not create optional axle-ratio, open/locking or limited-slip duplicates;
- simulate gasoline only, including FFV engines; do not create E85 states or rows;
- preserve one common source-like 2013 Limited appearance;
- use the 22-in P275/45R22 package and sport-tuned shocks on every approved row;
- no additional expected variant is missing according to the owner.

## Approved configuration matrix

| # | Model-year application | Engine / gasoline calibration | Transmission | Drivetrain and axle policy | Status |
|---:|---|---|---|---|---|
| 1 | 2009–2010 | 4.6L Modular SOHC 2-valve naturally aspirated cross-plane V8, 248 hp / 294 lb-ft | Ford 4R75E-family 4-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and standard differential | **approved** |
| 2 | 2009–2010 | 4.6L Modular SOHC 3-valve naturally aspirated cross-plane V8, 292 hp / 320 lb-ft | Ford 6R80-family 6-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and standard differential | **approved** |
| 3 | 2009–2010 | 5.4L Triton Modular SOHC 3-valve naturally aspirated cross-plane V8 FFV hardware, gasoline-only output approximately 310 hp / 365 lb-ft | Ford 6R80-family 6-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and standard differential | **approved** |
| 4 | 2011–2014 | 3.7L Duratec Ti-VCT DOHC naturally aspirated V6 FFV hardware, gasoline-only, 302 hp / 278 lb-ft | Ford 6R80-family 6-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and standard differential | **approved** |
| 5 | 2011–2014 | 5.0L Coyote Ti-VCT DOHC naturally aspirated cross-plane V8 FFV hardware, gasoline-only, 360 hp / 380 lb-ft | Ford 6R80-family 6-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and standard differential | **approved** |
| 6 | 2011–2014 | 3.5L EcoBoost DOHC twin-turbo direct-injected V6, 365 hp / 420 lb-ft | Ford 6R80-family 6-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and standard differential | **approved** |
| 7 | 2011–2014 | 6.2L Boss SOHC naturally aspirated V8, 411 hp / 434 lb-ft on the documented gasoline grade | Ford 6R80-family 6-speed planetary torque-converter automatic | 4x2 RWD; one verified standard axle ratio and standard differential | **approved** |

**Approved total: 7 mechanically consolidated Ford F-150 P415 SuperCrew 5.5-ft 4x2 configurations.**

## Explicit exclusions

- every 4x4 row, transfer case, front driveshaft, front differential and driven front half-shaft;
- separate model-year rows where mechanics are equivalent;
- selectable E85 and separate E85 rows;
- optional 3.15, 3.31, 3.55, 3.73, 4.10 or other axle-ratio duplicates;
- separate open, limited-slip or electronic-locking differential rows;
- period-correct 2009–2012 front, trim and wheel derivatives;
- smaller factory wheel/tyre packages and non-Limited shock calibrations;
- all alternative cab, box and wide-body configurations;
- manual transmissions, diesel engines and gaseous-fuel conversions.

## Chassis and physics architecture

Every approved row must use:

- a fully boxed ladder frame;
- longitudinal front engine and rear-wheel drive;
- independent double-wishbone/coil-over front suspension;
- solid rear drive axle on leaf springs;
- no transfer case or driven front axle;
- four-wheel disc brakes with ABS;
- AdvanceTrac with Roll Stability Control where correct for the selected year;
- the SuperCrew 5.5-ft-body mass distribution;
- engine- and year-correct kerb mass, axle loads and centre of gravity;
- the owner-selected 22-in P275/45R22 tyres and sport-tuned shock calibration.

The large wheel package and common Limited suspension may change acceleration, ride and tyre response relative to the original lower-trim donor combinations. Validation must use the approved configuration itself rather than falsely matching a smaller-wheel factory test by changing engine torque or mass.

## Transmission architecture assessment

### 4R75E-family four-speed

The 4.6L 2V row requires a distinct longitudinal four-speed planetary automatic with hydrodynamic converter multiplication and slip, creep, progressive lock-up, four exact forward ratios, reverse, torque and inertia shift phases, kickdown, load/grade scheduling and thermal protection.

### 6R80-family six-speed

The remaining six rows use the longitudinal six-speed planetary automatic family. Each engine needs its correct converter, shift schedule, lock-up behaviour, torque coordination and thermal calibration. The EcoBoost row additionally requires boost-aware torque management during launch and shifts.

The 4R75E and 6R80 may not share a generic ratio set or differ only by disabling two gears.

## Engine-audio architecture assessment

| Engine | Required treatment |
|---|---|
| 4.6L 2V / 4.6L 3V / 5.4L 3V | displacement- and valvetrain-specific Ford Modular cross-plane V8 layers |
| 3.7L V6 | naturally aspirated V6 cadence with Ti-VCT transient response |
| 5.0L Coyote V8 | DOHC Ti-VCT cross-plane V8, distinct from the older Modular 2V/3V engines |
| 3.5L EcoBoost | dedicated direct-injected twin-turbo V6 with compressor, turbine, wastegate/bypass and intercooler response |
| 6.2L Boss V8 | large-displacement SOHC V8 with its own intake, exhaust and load character |

No row may be created only by pitch-shifting a different cylinder layout or engine family.

## Evidence still required before parameter commitment

Before implementation retain exact Ford order-guide or service evidence for:

- 4R75E and 6R80 engineering suffixes, ratios, converters and year/engine calibration;
- one factory-standard axle ratio and differential state for each approved row;
- exact gasoline output for the 5.4L FFV row without using its E85 rating;
- kerb mass, axle loads and centre of gravity for each engine/year combination;
- tyre characteristics for the common P275/45R22 package;
- aerodynamic, braking and documented performance targets.

These gaps do not reopen the seven-row approved catalog scope and do not authorize guessed hardware.

## Owner decision recorded

The owner decided:

1. Include all seven researched engine families.
2. Restrict every engine to 4x2 rear-wheel drive.
3. Use one standard axle ratio and one standard differential state per row.
4. Simulate FFV engines on gasoline only.
5. Preserve the same source-like 2013 Limited body and exterior for every row.
6. Use one visual/equipment version rather than trim duplicates.
7. Merge years with identical mechanics.
8. Use the 22-in P275/45R22 wheels and sport-tuned shocks everywhere.
9. Missing expected variants: **none identified by the owner**.

Model 07 is **`approved`** with **7** configurations. Implementation remains blocked by the global all-model research gate. Research proceeds to model 08.
