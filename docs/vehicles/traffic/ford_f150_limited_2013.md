# Ford F-150 Limited SuperCrew — research and owner-scope gate

- Model number in Traffic Rider bundle: **07**
- Source GLB: `07_ford_f150_limited_2013.glb`
- Source SHA-256: `3be44b7f8f563efc57d259e0a3902dc55b2b347a0b34b2b90f55d75f541f6587`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents a **2013 Ford F-150 Limited SuperCrew with the 5.5-ft Styleside box**, from the facelifted P415/twelfth-generation F-150.

Visible source evidence includes:

- four full-size SuperCrew doors;
- the short 5.5-ft Styleside box rather than the 6.5-ft box;
- `F-150` and `LIMITED` exterior markings;
- Limited-specific chrome three-bar grille treatment;
- HID-style headlamp treatment;
- body-colour bumper surfaces with bright trim;
- polished 22-inch Limited wheel appearance;
- white exterior paint and North American plate treatment.

The source is not a Regular Cab, SuperCab, 6.5-ft or 8-ft box, SVT Raptor, Harley-Davidson, Platinum, King Ranch, Lariat, FX4 or lower trim. The model does not visually prove 4x2 versus 4x4: no sufficiently reliable driveline or decal detail survives in the low-polygon source.

Identity confidence: **high for 2013 F-150 Limited SuperCrew 5.5-ft box; drivetrain unresolved visually**.

## Reference dimensions and source inspection

Official Limited/SuperCrew 5.5-ft-box dimensions:

| Parameter | Reference / source result |
|---|---:|
| Wheelbase | 144.5 in / 3.6703 m |
| Overall length | 231.9 in / 5.8903 m |
| Width excluding mirrors | approximately 79.2 in / 2.0117 m |
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

## Research boundary

The strict represented model is the **F-150 Limited**, offered in this P415 form for model years 2013 and 2014 as a SuperCrew with the 5.5-ft box. The Limited equipment group standardizes the engine, transmission, body, wheel/tyre package and sport-oriented chassis equipment much more tightly than the broad F-150 range.

Other F-150 trims and body configurations are not silently included merely because they share the cab or frame. Expanding the scope to XL, XLT, FX, Lariat, King Ranch, Platinum, SVT Raptor or other boxes/cabs would require a separate much larger engine, body, wheelbase and chassis matrix.

## Engine and transmission identity

The Limited uses one factory engine/transmission architecture:

- **3.5L EcoBoost V6**, first-generation direct-injected, twin-turbocharged and intercooled DOHC petrol engine;
- approximately **365 hp at 5,000 rpm**;
- approximately **420 lb-ft / 569 Nm at 2,500 rpm**;
- Ford longitudinal **six-speed planetary torque-converter automatic**, working identification **6R80**;
- regular unleaded gasoline calibration.

The exact 6R80 engineering suffix, converter, ratios and year-specific calibration must be retained from a Ford service or order-guide source before parameter commitment. A generic six-speed automatic is not sufficient.

No other factory engine, manual transmission, diesel, FFV engine or alternative gearbox belongs to the 2013–2014 Limited trim.

## Complete strict-Limited candidate matrix

Both 4x2 and 4x4 Limited configurations are evidenced by Ford's distinct fuel-tank listings and drivetrain specifications. The source itself does not resolve which one it depicts.

| # | Model-year coverage | Engine | Transmission | Drivetrain | Base axle policy | Evidence |
|---:|---|---|---|---|---|---|
| 1 | 2013–2014 Limited, merged unless owner requests year rows | 3.5L EcoBoost twin-turbo DI V6, 365 hp / 420 lb-ft | Ford 6R80-family 6-speed torque-converter automatic | 4x2 RWD | standard Limited axle ratio and electronic locking differential, exact 2013 confirmation pending | `verified_body_powertrain_drivetrain`; axle detail strongest for 2014 |
| 2 | 2013–2014 Limited, merged unless owner requests year rows | 3.5L EcoBoost twin-turbo DI V6, 365 hp / 420 lb-ft | Ford 6R80-family 6-speed torque-converter automatic | automatic/selectable 4x4 with two-speed transfer case | standard Limited axle ratio and electronic locking differential, exact 2013 confirmation pending | `verified_body_powertrain_drivetrain`; transfer-case code pending |

**Base candidate total: 2 engine/transmission/drivetrain rows.**

The 2013 and 2014 Limited retain the same core body, engine, transmission, wheelbase and drivetrain choices. Known interior colour, paint and equipment-detail changes do not justify duplicate mechanical catalog rows unless the owner explicitly requests separate model years.

## Axle-ratio and differential subdivisions

For 2014, Ford documents:

- **3.55 electronic-locking rear axle** as the standard Limited configuration;
- **3.73 electronic-locking rear axle** as an available alternative.

The 3.73 ratio materially changes wheel torque, engine speed, acceleration and towing response. Possible scope policies are:

1. use one verified standard 3.55 electronic-locking axle per drivetrain row, producing **2 configurations**;
2. represent both 3.55 and 3.73 electronic-locking axles for 4x2 and 4x4 where order evidence confirms availability, producing up to **4 configurations**.

The differential is already a physical electronic-locking unit in the documented Limited specification. It should not be replaced by a permanently open differential or a generic traction-control-only approximation.

Exact 2013 standard and optional axle availability requires a retained 2013 Ford order guide before final parameter commitment. The catalog scope may either defer that detail or use the verified 2014 Limited policy for a merged 2013–2014 row only after evidence supports the merge.

## Drivetrain and chassis subdivisions

### 4x2

The 4x2 Limited is rear-wheel drive. It has no transfer case, front driveshaft or driven front differential/half-shafts and uses the lower 4x2 ride-height and mass calibration.

### 4x4

The 4x4 Limited requires Ford's two-speed automatic/selectable four-wheel-drive architecture with transfer case, front driveshaft, front differential and half-shafts. It needs distinct mass, ride height, rotating inertia, driveline losses, transfer-case modes and traction behaviour.

The two drivetrains must not be represented as a visual flag over one shared physical driveline.

### Shared Limited chassis equipment

Later implementation must preserve:

- fully boxed ladder frame;
- independent double-wishbone/coil-over front suspension;
- solid rear drive axle on leaf springs;
- Limited sport-tuned shock calibration;
- electric power-assisted steering;
- four-wheel vented disc brakes with ABS;
- AdvanceTrac with Roll Stability Control;
- 22-inch polished wheels with the documented P275/45R22 tyre package;
- SuperCrew and 5.5-ft-box mass and load distribution.

A generic passenger-car suspension, generic pickup mass or smaller wheel/tyre package is not acceptable.

## Visual and package policy

The source is specifically Limited. The following are part of the represented physical/visual package and should normally be retained rather than optionalized:

- Limited grille, badges and box-side lettering;
- HID headlamps;
- body-colour/bright bumper treatment;
- 22-inch polished wheels and corresponding tyres;
- Limited cabin/equipment mass allowance;
- sport-tuned shocks.

Paint colours, 2013 Brick Red versus 2014 Marina Blue interior themes, navigation/audio options, bed accessories and appearance-only dealer accessories should not create duplicate vehicles.

## Transmission architecture assessment

The 6R80 is a longitudinal six-speed planetary automatic with a hydrodynamic torque converter and lock-up clutch. It requires:

- speed-ratio-dependent converter multiplication and slip;
- creep and brake-hold behaviour;
- progressive lock-up and unlock;
- six exact forward ratios and reverse;
- torque and inertia phases during shifts;
- multi-gear kickdown;
- adaptive load, grade and towing schedules;
- engine-torque coordination during boost and shifts;
- thermal protection;
- transfer-case mode coordination for 4x4.

It must not be represented as a DCT, automated manual or generic six-speed with arbitrary delays.

## Engine-audio architecture assessment

The 3.5L EcoBoost requires a dedicated twin-turbo V6 architecture with:

- correct V6 firing cadence and crank/firing order;
- direct-injection mechanical layer;
- twin-turbo spool, compressor and wastegate/bypass behaviour;
- intercooler and boosted induction response;
- load-dependent exhaust and turbine filtering;
- start, idle, boost onset, converter-loaded acceleration, shifts, overrun, limiter and shutdown.

It must not be synthesized by pitch-shifting a naturally aspirated V6 or applying turbo noise over a four-cylinder waveform.

## Evidence retained and unresolved work

Ford's 2013 and 2014 F-150 brochures establish the Limited body, SuperCrew/5.5-ft-box dimensions, exclusive 3.5L EcoBoost powertrain, 4x2 and 4x4 availability, 22-inch wheel/tyre package, HID lighting, chassis equipment and 2014 axle options.

Before implementation retain exact primary Ford service/order-guide evidence for:

- the 6R80 code/suffix, ratios, converter and calibration;
- the 4x4 transfer-case code, ratios and control modes;
- exact 2013 standard and optional axle ratios;
- exact kerb mass and axle loads for 4x2 and 4x4;
- drag, tyre characteristics, braking and documented performance targets;
- year-specific shock, stability-control and driveline calibration.

These gaps block parameter commitment but do not authorize guessed hardware.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Keep the scope strictly to the **2013–2014 F-150 Limited SuperCrew 5.5-ft box**, or expand it to other P415 F-150 trims, engines, cabs and boxes?
2. Include both the 4x2 and 4x4 Limited drivetrains, or only one?
3. Merge 2013 and 2014 into the same drivetrain rows, or create separate year entries despite identical core mechanics?
4. Use only the standard **3.55 electronic-locking axle**, or create separate 3.55 and 3.73 configurations wherever Ford ordering evidence confirms them?
5. Preserve only the Limited appearance and avoid XL/XLT/FX/Lariat/King Ranch/Platinum/Raptor visual derivatives?
6. Keep the Limited 22-inch P275/45R22 wheel/tyre package and sport-tuned shocks mandatory for every approved row?
7. Keep gasoline as the only fuel state, with no FFV/E85 or gaseous-fuel subdivisions?
8. Is any expected Limited engine, transmission, drivetrain, axle, body, model-year or package variant missing?

No implementation begins after this individual decision. Research proceeds to model 08 only after the owner fixes model 07 scope, and implementation begins only after every included model has reached `approved`.
