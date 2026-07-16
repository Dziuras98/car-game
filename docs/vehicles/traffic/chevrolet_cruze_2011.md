# Chevrolet Cruze J300 sedan — research and approved scope

- Model number in Traffic Rider bundle: **04**
- Source GLB: `04_chevrolet_cruze_2011.glb`
- Source SHA-256: `ac6af7b6894a8bbe327f4250b16ab5176ad16743f7141afbe6c0efc9cd61f251`
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **20 mechanically distinct pre-facelift Chevrolet-badged J300 sedan configurations**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source mesh represents a **Chevrolet Cruze J300 four-door sedan, North American pre-facelift exterior**. The texture atlas contains:

- Chevrolet bowties;
- an `LS` deck-lid badge;
- a North American/Michigan-style registration plate;
- the first-phase J300 front fascia and lamp design.

The strict visual identity is therefore a **2011-model-year North American Chevrolet Cruze LS sedan**. It is not a Cruze hatchback, wagon, Holden Cruze, Daewoo Lacetti Premiere, China D2SC/J400 successor or international second-generation Cruze.

Identity confidence: **high for Chevrolet J300 sedan, North American pre-facelift and LS texture identity; exact wheel option unresolved**.

The approved scope remains strictly within the **pre-facelift Chevrolet-badged J300 sedan body phase** represented by the source. Regional versions may require market-correct badges, registration recesses, reflectors, grille materials or trim, but no facelift-only bumper, lamp or grille derivative is approved.

## Reference dimensions

Representative pre-facelift J300 sedan values:

| Parameter | Reference |
|---|---:|
| Wheelbase | 2.685 m |
| Overall length | approximately 4.597–4.603 m |
| Width excluding mirrors | approximately 1.788 m |
| Height | approximately 1.477 m |

Final visual scale must use the 2.685 m wheelbase as the primary reference and cross-check length, width, height, tracks, ground clearance and the exact wheel/tyre package.

## Source inspection

| Item | Result |
|---|---|
| Source meshes | 3 |
| Body mesh | `AI_Cruze_High_Chevrolet_Cruze_2011_0` |
| Front wheel-pair mesh | `on_teker.003_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.003_wheel_0` |
| Body triangles | 1,724 |
| Front wheel-pair triangles | 360 |
| Rear wheel-pair triangles | 360 |
| Total triangles | 2,444 |
| Source scene AABB | approximately 2.840597 × 2.135179 × 6.618588 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 3.973514 source units |
| Approximate wheelbase-derived scale | 0.675724 for a 2.685 m real wheelbase |

The source GLB remains unchanged. A future derivative must split each paired axle mesh into independent, hub-centred left and right wheel nodes. That work remains blocked by the global research gate.

## Owner-directed scope rules

- include every researched engine/transmission row that belongs to the pre-facelift Chevrolet-badged J300 sedan phase;
- exclude combinations available only with facelift bodywork;
- include the China-market 1.6 turbo 6MT;
- include every researched pre-facelift 1.7/2.0 diesel combination, including the North American LUZ diesel;
- include South American 1.8 flex-fuel manual and automatic rows, but calibrate them for **gasoline only**;
- do not add ethanol as a selectable fuel state or duplicate vehicle;
- exclude every petrol/LPG or bi-fuel row;
- exclude North American Eco package subdivisions;
- include provisional regional and gearbox rows immediately in the fixed scope, while requiring exact primary documentation before final parameter commitment;
- all approved variants are FWD;
- hatchback, wagon, Holden, Daewoo and later-generation bodies remain excluded.

## Approved engine and powertrain matrix

The original 26-row research matrix reduces to **20 approved pre-facelift rows** after removing five facelift-only rows and the LPG row.

### North America

| # | Original candidate | Application | Engine / output anchor | Transmission | Status |
|---:|---:|---|---|---|---|
| 1 | 1 | 2011–2015 LS-family sedan, pre-facelift application | LUW/LWE 1.8 naturally aspirated I4, approximately 138 hp / 169 Nm | conventional 6MT | **approved**; strict LS source match |
| 2 | 2 | 2011–2015 LS-family sedan, pre-facelift application | LUW/LWE 1.8 naturally aspirated I4, approximately 138 hp / 169 Nm | Hydra-Matic 6T30 six-speed torque-converter automatic | **approved**; strict LS source match |
| 3 | 3 | 2011–2014 pre-facelift 1.4 turbo range | LUJ/LUV 1.4 turbo I4, approximately 138 hp / 200 Nm | conventional 6MT | **approved** |
| 4 | 4 | 2011–2014 pre-facelift 1.4 turbo range | LUJ/LUV 1.4 turbo I4, approximately 138 hp / 200 Nm | Hydra-Matic 6T40 six-speed torque-converter automatic | **approved** |
| 5 | 5 | 2014 North American Diesel, pre-facelift | LUZ/Multijet 2.0 turbo-diesel I4, approximately 151 hp / 339–350 Nm | Aisin AF40-6 six-speed torque-converter automatic | **approved** |

### Europe and general export Chevrolet range

| # | Original candidate | Application | Engine / output anchor | Transmission | Status |
|---:|---:|---|---|---|---|
| 6 | 9 | launch-era Europe/export | F16D4-family 1.6 naturally aspirated I4, approximately 113–117 PS / 153 Nm | conventional 5MT | **approved** |
| 7 | 10 | launch-era regional export | F16D4-family 1.6 naturally aspirated I4, approximately 113–117 PS / 153 Nm | six-speed torque-converter automatic; exact family pending | **approved provisional** |
| 8 | 11 | 2011-and-later pre-facelift Europe | updated 1.6 naturally aspirated I4, approximately 124 PS / 154–155 Nm | conventional 6MT | **approved** |
| 9 | 12 | 2011-and-later pre-facelift regional range | updated 1.6 naturally aspirated I4, approximately 124 PS / 154–155 Nm | six-speed torque-converter automatic; exact family pending | **approved provisional** |
| 10 | 13 | launch-era Europe/export | F18D4-family 1.8 naturally aspirated I4, approximately 140–143 PS / 176 Nm | conventional 5MT | **approved** |
| 11 | 14 | pre-facelift regional Chevrolet range where documented | F18D4-family 1.8 naturally aspirated I4, approximately 140–143 PS / 176 Nm | conventional 6MT; exact suffix pending | **approved provisional** |
| 12 | 15 | pre-facelift Europe/export | F18D4-family 1.8 naturally aspirated I4, approximately 140–143 PS / 176 Nm | GM 6T30/6T40-family six-speed torque-converter automatic; exact suffix pending | **approved provisional** |
| 13 | 18 | early European range | VM Motori/RA420 2.0 VCDi turbo-diesel I4, approximately 125 PS / 300 Nm | conventional 5MT | **approved** |
| 14 | 19 | launch-era Europe | VM Motori/RA420 2.0 VCDi turbo-diesel I4, approximately 150 PS / 320 Nm | conventional 5MT | **approved** |
| 15 | 20 | launch-era Europe/export | VM Motori/RA420 2.0 VCDi turbo-diesel I4, approximately 150 PS / 320 Nm | GM 6T45-family six-speed torque-converter automatic | **approved** |
| 16 | 21 | 2011-and-later pre-facelift Europe | Family Z/LLW 2.0 VCDi turbo-diesel I4, approximately 163–166 PS / 360 Nm | conventional 6MT; exact M32/F40 suffix pending | **approved provisional** |
| 17 | 22 | 2011-and-later pre-facelift Europe/export | Family Z/LLW 2.0 VCDi turbo-diesel I4, approximately 163 PS / 360 Nm | GM 6T45-family six-speed torque-converter automatic | **approved** |

### Regional Chevrolet derivatives

| # | Original candidate | Application | Engine / output anchor | Transmission | Status |
|---:|---:|---|---|---|---|
| 18 | 23 | China J300, from late 2011, pre-facelift body | 1.6 turbo I4, approximately 184 PS / 235 Nm | conventional 6MT | **approved**; China-market trim/material correction required |
| 19 | 24 | Brazil/South America, pre-facelift sedan | 1.8 flex-fuel naturally aspirated I4, gasoline calibration approximately 140 hp | conventional 6MT | **approved, gasoline only** |
| 20 | 25 | Brazil/South America, pre-facelift sedan | 1.8 flex-fuel naturally aspirated I4, gasoline calibration approximately 140 hp | six-speed torque-converter automatic; exact suffix pending | **approved provisional, gasoline only** |

**Approved total: 20 mechanically distinct pre-facelift Chevrolet J300 sedan configurations.**

## Explicit exclusions

The following candidate rows or subdivisions are outside the approved scope:

- original row 6: late/facelift-era European 1.4 naturally aspirated 5MT;
- original rows 7–8: facelift-era European A14NET 1.4 turbo 6MT/6AT;
- original rows 16–17: facelift-era A17DTS 1.7 VCDi 110/130 6MT;
- original row 26: petrol/LPG bi-fuel;
- all North American Eco manual/automatic package subdivisions;
- every post-facelift North American, European or regional appearance derivative;
- ethanol calibration or selectable ethanol state for South American 1.8 flex-fuel rows;
- hatchback, wagon, Holden Cruze and Daewoo Lacetti Premiere derivatives;
- China D2SC/J400, international second generation and every later Cruze body;
- AWD and RWD.

## Visual and regional material policy

The pre-facelift body shape remains mandatory for all approved rows. The source texture is specifically North American LS, so non-LS and non-North-American rows require non-destructive material variants for applicable:

- deck-lid and grille badges;
- registration-plate recess and plate style;
- side markers and reflectors;
- grille inserts and chrome treatment;
- diesel, LT/LTZ or regional trim markings;
- wheel and tyre package.

These changes must not alter the committed source GLB. A facelift bumper, grille or lamp set must not be introduced under this approved model scope.

## Transmission architecture assessment

### Conventional manuals

The approved range uses multiple five- and six-speed manual transaxle families. Exact D16/D20/M32/F40 or other family/suffix assignments, ratios, reverse ratio, final drive, clutch capacity and rotating inertia must be verified per row. `5MT` or `6MT` is not sufficient implementation data.

### GM 6T30, 6T40 and 6T45

These are conventional planetary torque-converter automatics but require distinct models and calibration data:

- 6T30 for lower-torque petrol applications;
- 6T40 for 1.4 turbo and applicable regional petrol rows;
- 6T45 for higher-torque diesel applications.

### Aisin AF40-6

The North American LUZ diesel uses an Aisin six-speed planetary torque-converter automatic. It remains separate from the GM 6T family.

Every approved automatic later requires converter multiplication/slip, creep, progressive lock-up, torque and inertia shift phases, kickdown, grade logic, thermal protection and architecture-specific shift schedules.

## Performance and physics requirements

For every approved row, later parameter research must establish:

- sampled full-load torque curve and transient behaviour;
- exact transmission and final-drive ratios;
- clutch or converter/lock-up behaviour;
- kerb mass and axle loads for exact market and trim;
- tyre dimensions and rolling radius;
- drag coefficient and frontal area;
- braking, steering and suspension targets;
- documented acceleration, in-gear and maximum-speed targets;
- validation against current `master` physics.

Performance may not be matched with false torque, wrong mass, incorrect transmission family or an arbitrary hidden cap.

## Engine-audio architecture assessment

| Engine family | Required treatment |
|---|---|
| LUW/LWE and F16D4/F18D4 naturally aspirated petrol I4 | family- and displacement-specific port-injected inline-four combustion, intake, exhaust and valvetrain layers |
| LUJ/LUV 1.4 turbo | small-turbo inline-four model with distinct boost, induction and load transients |
| China 1.6 turbo | separate higher-output turbo-I4 calibration and induction/exhaust profile |
| early RA420 2.0 VCDi | VM Motori-derived diesel combustion, mechanical and turbo layers |
| later Family Z/LLW 2.0 VCDi | separate later diesel architecture/calibration profile |
| LUZ/Multijet 2.0 diesel | separate Fiat/GM Multijet-derived diesel profile |
| South American 1.8 flex-fuel | gasoline combustion state only; ethanol state excluded |

Unrelated inline-four families must not collapse into one generic waveform merely because they share cylinder count.

## Evidence still required before parameter commitment

Before implementation, retain or strengthen primary documentation for:

- North American 2011–2014 order guides and specifications;
- European Chevrolet brochures and price lists for the pre-facelift phase;
- China J300 1.6 turbo homologation/order material;
- South American 1.8 gasoline-state output and transmission data;
- exact manual and automatic gearbox suffixes, ratios and final drives;
- exact mass, tyre, drag, braking and performance values for every approved configuration.

Provisional rows are approved for catalog scope immediately. Missing exact documentation blocks final parameter commitment; it does not authorize guessed hardware or ratios.

## Owner decision recorded

The owner decided:

1. Include all researched rows compatible with the source model's pre-facelift J300 sedan body phase.
2. Exclude every facelift-only version and use only the body version corresponding to the source model.
3. Include the China-market 1.6 turbo 6MT.
4. Include all applicable diesels, including the North American LUZ diesel.
5. Include South American 1.8 flex-fuel manual and automatic, but retain only the gasoline calibration.
6. Exclude LPG/bi-fuel.
7. Exclude Eco package configurations.
8. Include provisional regional and gearbox rows immediately, while preserving their evidence requirements.
9. Missing expected variants: **none identified by the owner**.

The individual owner-scope gate is satisfied. Model 04 is **`approved`** with **20** configurations, but implementation remains blocked by the global all-model research gate. Research proceeds to model 05.