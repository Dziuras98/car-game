# Land Rover Freelander 2 / LR2 L359 — research and owner-scope gate

- Model number in Traffic Rider bundle: **09**
- Source GLB: `09_land_rover_freelander_2_2012.glb`
- Source SHA-256: `ba2cd619b59ff52a0e44ff48e17ea5fc91f89d59cdb4012597dc3b2628a20191`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents a **North American 2012 Land Rover LR2 HSE**, equivalent to the Land Rover Freelander 2 L359, using the first facelift / middle visual phase.

Visible source evidence includes:

- `LR2` and `HSE` rear badging;
- North American rear plate treatment;
- five-door L359 body and high HSE equipment presentation;
- first-facelift grille, bumper, headlamp and tail-lamp treatment used before the 2013-model-year second update;
- blue paint, front fog lamps, side fender vents and HSE-style alloy wheels.

The source is not the original 2007–2010 exterior and not the later 2013–2014 second-facelift exterior with revised lighting and interior presentation.

Identity confidence: **high for 2012 LR2 HSE and the middle visual phase**.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Wheelbase | approximately 2,660 mm / 2.660 m |
| Overall length | approximately 4,500 mm / 4.500 m |
| Width excluding mirrors | approximately 1,910 mm / 1.910 m |
| Height | approximately 1,740 mm / 1.740 m |
| Source meshes | 3 |
| Body mesh | `AI_Freelander_High_LR_Freelander_LR2_2012_0` |
| Front wheel-pair mesh | `on_teker.008_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.009_wheel_0` |
| Body triangles | 1,410 |
| Front wheel-pair triangles | 360 |
| Rear wheel-pair triangles | 360 |
| Total triangles | 2,130 |
| Source scene AABB | approximately 3.062419 × 2.439575 × 6.475932 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 3.877631 source units |
| Approximate wheelbase-derived scale | 0.685986 |

The 2.660-m wheelbase is the primary scale reference. Length, width, height, tracks, ground clearance, tyre radius and bumper limits require independent cross-checks.

The committed GLB remains unchanged. Four independent wheels, collision, catalog, physics, transmission and audio work remain blocked by the global research gate.

## Research boundary

The complete candidate scope covers the **second-generation Freelander 2 / LR2 L359**, produced from late 2006 through 2014 and sold under the LR2 name in North America.

Three visual phases require separate consideration:

1. **2007–2010 original exterior**;
2. **2011–2012 first facelift / middle phase**, represented by the source;
3. **2013–2014 second facelift**, with revised grille, lamps, interior and the Si4 petrol replacement for the 3.2 i6.

The five-door monocoque body and 2.660-m wheelbase remain common, but bumpers, lamps, trim, wheels and detailed mass/equipment change by phase and market.

## Complete mechanically consolidated candidate matrix

The table separates engine calibration, transmission architecture and FWD/AWD layout. Model-year control-system revisions such as stop/start and Haldex generation are recorded as metadata unless the owner requests separate rows.

| # | Model-year application | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|---|
| 1 | 2007–2010 | 2.2L TD4 common-rail turbo-diesel inline-four, approximately 160 PS / 400 Nm | six-speed conventional manual transaxle, working identification Getrag/Ford M66-family | on-demand AWD with front transaxle, PTU, prop shaft and Haldex rear coupling | `verified_family`; exact gearbox suffix and year changeovers pending |
| 2 | 2007–2010 | 2.2L TD4 common-rail turbo-diesel inline-four, approximately 160 PS / 400 Nm | Aisin AWF21 / TF-80SC-family six-speed planetary torque-converter automatic | on-demand AWD with Haldex coupling | `verified_family` |
| 3 | 2007–2012 | Volvo SI6 3.2L naturally aspirated transverse inline-six petrol, approximately 233 PS / 317 Nm; North American rating approximately 230 hp | Aisin AWF21 / TF-80SC-family six-speed planetary torque-converter automatic | on-demand AWD with Haldex coupling | `verified`; strict source-engine family |
| 4 | 2011–2014 | 2.2L eD4 turbo-diesel inline-four, 150 PS / approximately 400 Nm | six-speed conventional manual transaxle with stop/start | **front-wheel drive only**, no PTU, rear prop shaft or Haldex unit | `verified_layout_family` |
| 5 | 2011–2014 | 2.2L TD4 turbo-diesel inline-four, 150 PS / approximately 420 Nm | six-speed conventional manual transaxle | on-demand AWD with Haldex coupling | `verified_family` |
| 6 | 2011–2014 | 2.2L TD4 turbo-diesel inline-four, 150 PS / approximately 420 Nm | Aisin AWF21 / TF-80SC-family six-speed planetary torque-converter automatic | on-demand AWD with Haldex coupling | `verified_family` |
| 7 | 2011–2014 | 2.2L SD4 turbo-diesel inline-four, 190 PS / approximately 420–430 Nm | Aisin AWF21 / TF-80SC-family six-speed planetary torque-converter automatic | on-demand AWD with Haldex coupling | `verified_family` |
| 8 | 2013–2014 | 2.0L Si4 direct-injected turbocharged petrol inline-four, approximately 240–241 PS / 340 Nm | Aisin AWF21 / TF-80SC-family six-speed planetary torque-converter automatic | on-demand AWD with Haldex coupling | `verified_family`; replaces the 3.2 i6 in the late visual phase |

**Mechanically consolidated candidate total: 8 rows.**

A strict source-year North American LR2 HSE scope would contain only row 3: **3.2 i6 + six-speed automatic + AWD**. Keeping all engines but merging manual and automatic TD4 rows would be mechanically inaccurate because the clutch/manual and torque-converter automatic are distinct architectures.

## Drivetrain architecture

### eD4 front-wheel drive

The eD4 is the only production two-wheel-drive L359 powertrain. It removes the AWD power-transfer unit, prop shaft, Haldex coupling and driven rear differential/shafts. It also omits Terrain Response and Hill Descent Control functionality associated with the AWD models. It requires its own mass, inertia, traction, torque-steer and rear-axle calibration.

### AWD models

All other candidate rows use a front-biased on-demand AWD architecture with:

- transverse engine and transaxle;
- front differential and half-shafts;
- power-transfer unit;
- longitudinal prop shaft;
- electronically controlled Haldex rear coupling;
- rear final drive and half-shafts;
- Terrain Response and stability-control coordination where fitted.

Early vehicles use an earlier Haldex control generation; model-year 2009 onward uses a revised generation. The exact coupling hardware, control map and final-drive ratios must follow the selected year rather than being represented as a generic fixed 50:50 system.

## Transmission architecture assessment

### Six-speed manual

Manual diesel rows require a driver-operated dry clutch and a real six-speed transaxle. Required data include exact forward and reverse ratios, final drive, clutch capacity and inertia, synchronizer behaviour, launch, engine braking and stop/start integration where applicable.

### AWF21 / TF-80SC six-speed automatic

The 3.2 i6, automatic TD4, SD4 and Si4 rows use a transverse six-speed planetary automatic with a hydrodynamic torque converter. It requires converter multiplication and slip, creep, progressive lock-up, exact forward and reverse ratios, torque and inertia shift phases, multi-gear kickdown, grade/load scheduling, thermal protection and AWD-coupling coordination.

The automatic must not be represented by a dual-clutch, CVT or generic six-speed timing model.

## Engine and driveline audio architecture

| Engine | Required treatment |
|---|---|
| 2.2 TD4 early 160 | four-cylinder common-rail diesel combustion, turbo and emissions layers appropriate to the early calibration |
| 2.2 eD4 / TD4 150 | later Euro-emissions diesel architecture with calibration-specific boost, injection, stop/start and load response |
| 2.2 SD4 190 | higher-output diesel turbo and combustion response; not only a louder TD4 |
| 3.2 SI6 | dedicated naturally aspirated transverse inline-six firing cadence, intake resonance and exhaust grouping |
| 2.0 Si4 | dedicated direct-injected turbo petrol inline-four with compressor, turbine, wastegate/bypass and boosted induction response |

The SI6 cannot be synthesized by pitch-shifting a V6, and the Si4 cannot reuse a naturally aspirated four-cylinder waveform with added turbo noise.

## Visual and trim policy candidates

- **Original 2007–2010 phase:** requires a correct earlier grille, bumper, lamps and wheel/trim derivative.
- **Source 2011–2012 phase:** exact visual anchor is North American LR2 HSE.
- **Late 2013–2014 phase:** requires revised grille, lamps, interior details and late wheel/trim treatment.
- S, GS/SE, HSE, HST, Dynamic and market package names should not automatically duplicate identical mechanics.

Possible scope policies are:

1. preserve only the source-like 2011–2012 LR2 HSE appearance for all approved powertrains;
2. create period-correct visual derivatives for all three phases;
3. restrict mechanics to the exact source phase and market.

## Final drive, differential and emissions subdivisions

Factory final-drive ratios, Haldex control generations, tyre sizes and differential details vary by engine, transmission, drivetrain and model year. Possible catalog policies are:

1. one verified standard final drive and standard differential/coupling state per approved row;
2. separate gearing or coupling-generation rows where materially different.

Diesel DPF, catalyst, EGR, stop/start and Euro-standard changes may be retained as selected-year metadata or represented as separate rows. Duplicate emissions-state rows are not recommended unless the hardware materially changes performance and the owner requests them.

## Evidence still required before parameter commitment

Before implementation retain primary Land Rover workshop, order-guide or technical evidence for:

- exact model-year start/end dates and market restrictions for each engine;
- exact manual gearbox code, ratios, clutch and final drive;
- AWF21/TF-80SC ratios, converter and engine-specific calibration;
- Haldex generation, coupling limits, rear final drive and control maps by year;
- one standard final-drive ratio and differential/coupling state per approved row;
- selected-year DPF, catalyst, EGR and stop/start hardware;
- exact kerb mass, axle loads, tyres, brakes, drag and performance targets;
- source HSE wheel and tyre size.

These evidence gates prevent guessed parameters but do not block the owner from selecting catalog scope.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Keep only the exact **2011–2012 LR2 HSE source phase**, or cover the complete 2007–2014 L359 generation?
2. Include all eight engine/transmission/drivetrain rows?
3. Include the front-wheel-drive eD4 as well as AWD models?
4. Preserve manual and automatic TD4 configurations as separate rows?
5. Preserve only the source-like 2011–2012 HSE exterior, or create correct original and 2013–2014 visual derivatives?
6. Use one representative HSE-style trim without duplicating S/SE/HST/Dynamic packages?
7. Store Haldex generation, stop/start and emissions revisions as selected-year metadata, or create separate rows?
8. Use one verified standard final drive and one standard differential/coupling state per approved row?
9. Exclude LPG or other non-core conversions?
10. Is any expected engine, transmission, drivetrain, visual phase or market variant missing?

No implementation begins after this individual decision. Research proceeds to model 10 only after the owner fixes model 09 scope, and implementation begins only after every included model has reached `approved`.