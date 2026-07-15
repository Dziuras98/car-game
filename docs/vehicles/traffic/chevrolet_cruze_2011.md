# Chevrolet Cruze J300 sedan — research and owner-scope gate

- Model number in Traffic Rider bundle: **04**
- Source GLB: `04_chevrolet_cruze_2011.glb`
- Source SHA-256: `ac6af7b6894a8bbe327f4250b16ab5176ad16743f7141afbe6c0efc9cd61f251`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source mesh represents a **Chevrolet Cruze J300 four-door sedan, North American pre-facelift exterior**. The texture atlas contains:

- Chevrolet bowties;
- an `LS` deck-lid badge;
- a North American/Michigan-style registration plate;
- the first-phase J300 front fascia and lamp design.

The strict visual identity is therefore a **2011-model-year North American Chevrolet Cruze LS sedan**. The body is not a Cruze hatchback, wagon, Holden Cruze, Daewoo Lacetti Premiere, the China-only D2SC/J400 successor or the international second-generation Cruze.

Identity confidence: **high for Chevrolet J300 sedan, North American pre-facelift and LS texture identity; exact wheel option unresolved**.

The wider research matrix below covers Chevrolet-badged J300 sedans across markets. Facelifted Chevrolet sedans may share the underlying body shell but require phase-correct bumpers, grille and lamps. Holden- and Daewoo-badged derivatives are not silently counted as Chevrolet duplicates.

## Reference dimensions

Representative J300 sedan values vary slightly by bumper and market:

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

## Research boundary and deduplication

The candidate matrix covers mechanically distinct Chevrolet-badged **J300 sedan** engine/transmission combinations across North America, Europe and selected regional markets. Hatchback and wagon bodies are excluded from this model because they require different render geometry, mass and aerodynamics.

Deduplication rules:

- do not duplicate identical mechanics because they appear in multiple trims, countries or model years;
- keep a different transmission behind the same engine as a separate row;
- keep materially different engine generations or calibrations separate;
- treat facelift appearance separately from powertrain identity;
- do not create separate gasoline/ethanol or gasoline/LPG catalog entries when the owner chooses a single multi-fuel vehicle with selectable fuel state;
- create a separate Eco or chassis-package configuration only when aero, mass, suspension, tyres, final drive or control calibration materially differs.

Evidence states:

- `verified_or_strongly_supported`: consistent period manufacturer data, official-era specifications and multiple technical references;
- `provisional_regional`: documented market occurrence, but exact Chevrolet order guide, homologation record or brochure must still be retained;
- `provisional_gearbox`: engine/transmission pairing is documented, but exact gearbox family/suffix is not yet sufficiently evidenced;
- `rejected/not_factory`: no factory evidence for the Chevrolet J300 sedan.

All candidate road variants are front-wheel drive. No production AWD or RWD Chevrolet Cruze J300 sedan belongs in this matrix.

## Complete candidate base matrix

The matrix contains **26 candidate engine/transmission rows** before optional Eco, emissions, chassis or fuel-state subdivisions.

### North America

| # | Application | Engine / output anchor | Transmission | Visual relationship | Evidence |
|---:|---|---|---|---|---|
| 1 | 2011–2015 LS-family sedan | LUW/LWE 1.8 naturally aspirated I4, approximately 138 hp / 169 Nm | conventional 6MT | **strict source LS visual match** | `verified_or_strongly_supported` |
| 2 | 2011–2015 LS-family sedan | LUW/LWE 1.8 naturally aspirated I4, approximately 138 hp / 169 Nm | Hydra-Matic 6T30 six-speed torque-converter automatic | **strict source LS visual match** | `verified_or_strongly_supported` |
| 3 | 2011–2016 Limited-era range | LUJ/LUV 1.4 turbo I4, approximately 138 hp / 200 Nm | conventional 6MT | North American body-compatible; non-LS material/trim correction required | `verified_or_strongly_supported` |
| 4 | 2011–2016 Limited-era range | LUJ/LUV 1.4 turbo I4, approximately 138 hp / 200 Nm | Hydra-Matic 6T40 six-speed torque-converter automatic | North American body-compatible; non-LS material/trim correction required | `verified_or_strongly_supported` |
| 5 | 2014–2015 North American Diesel | LUZ/Multijet 2.0 turbo-diesel I4, approximately 151 hp / 339–350 Nm | Aisin AF40-6 six-speed torque-converter automatic | body-compatible; Diesel/facelift-year trim derivative required | `verified_or_strongly_supported` |

### Europe and general export Chevrolet range

| # | Application | Engine / output anchor | Transmission | Evidence |
|---:|---|---|---|---|
| 6 | late European range | 1.4 naturally aspirated I4, approximately 100 PS / 130 Nm | conventional 5MT | `verified_or_strongly_supported` |
| 7 | facelift-era Europe | A14NET-family 1.4 turbo I4, approximately 140 PS / 200 Nm | conventional 6MT | `verified_or_strongly_supported` |
| 8 | facelift-era Europe | A14NET-family 1.4 turbo I4, approximately 140 PS / 200 Nm | GM 6T40-family six-speed torque-converter automatic | `verified_or_strongly_supported` |
| 9 | launch-era Europe/export | F16D4-family 1.6 naturally aspirated I4, approximately 113–117 PS / 153 Nm | conventional 5MT | `verified_or_strongly_supported` |
| 10 | launch-era regional export | F16D4-family 1.6 naturally aspirated I4, approximately 113–117 PS / 153 Nm | six-speed torque-converter automatic; exact family pending | `provisional_regional`, `provisional_gearbox` |
| 11 | 2011-and-later Europe | updated 1.6 naturally aspirated I4, approximately 124 PS / 154–155 Nm | conventional 6MT | `verified_or_strongly_supported` |
| 12 | 2011-and-later regional range | updated 1.6 naturally aspirated I4, approximately 124 PS / 154–155 Nm | six-speed torque-converter automatic; exact family pending | `provisional_regional`, `provisional_gearbox` |
| 13 | launch-era Europe/export | F18D4-family 1.8 naturally aspirated I4, approximately 140–143 PS / 176 Nm | conventional 5MT | `verified_or_strongly_supported` |
| 14 | later regional Chevrolet range | F18D4-family 1.8 naturally aspirated I4, approximately 140–143 PS / 176 Nm | conventional 6MT | `provisional_regional`; exact start date and gearbox suffix pending |
| 15 | Europe/export | F18D4-family 1.8 naturally aspirated I4, approximately 140–143 PS / 176 Nm | GM 6T30/6T40-family six-speed torque-converter automatic; exact application suffix pending | `verified_or_strongly_supported`, `provisional_gearbox` |
| 16 | facelift-era Europe | A17DTS/1.7 VCDi turbo-diesel I4, approximately 110 PS / 280 Nm | conventional 6MT | `verified_or_strongly_supported` |
| 17 | facelift-era Europe | A17DTS/1.7 VCDi turbo-diesel I4, approximately 130 PS / 300 Nm | conventional 6MT | `verified_or_strongly_supported` |
| 18 | early European range | VM Motori/RA420 2.0 VCDi turbo-diesel I4, approximately 125 PS / 300 Nm | conventional 5MT | `verified_or_strongly_supported` |
| 19 | launch-era Europe | VM Motori/RA420 2.0 VCDi turbo-diesel I4, approximately 150 PS / 320 Nm | conventional 5MT | `verified_or_strongly_supported` |
| 20 | launch-era Europe/export | VM Motori/RA420 2.0 VCDi turbo-diesel I4, approximately 150 PS / 320 Nm | GM 6T45-family six-speed torque-converter automatic | `verified_or_strongly_supported` |
| 21 | 2011-and-later Europe | Family Z/LLW 2.0 VCDi turbo-diesel I4, approximately 163–166 PS / 360 Nm | conventional 6MT; exact M32/F40 application suffix pending | `verified_or_strongly_supported`, `provisional_gearbox` |
| 22 | 2011-and-later Europe/export | Family Z/LLW 2.0 VCDi turbo-diesel I4, approximately 163 PS / 360 Nm | GM 6T45-family six-speed torque-converter automatic | `verified_or_strongly_supported` |

### Regional Chevrolet derivatives

| # | Application | Engine / output anchor | Transmission | Evidence |
|---:|---|---|---|---|
| 23 | China J300, from late 2011 | 1.6 turbo I4, approximately 184 PS / 235 Nm | conventional 6MT | `verified_or_strongly_supported`; Chinese Chevrolet fascia/material validation required |
| 24 | Brazil/South America | 1.8 flex-fuel naturally aspirated I4, approximately 140 hp gasoline / 144 hp ethanol | conventional 6MT | `verified_or_strongly_supported`; fuel-state and local calibration evidence required |
| 25 | Brazil/South America | 1.8 flex-fuel naturally aspirated I4, approximately 140 hp gasoline / 144 hp ethanol | six-speed torque-converter automatic | `verified_or_strongly_supported`; exact automatic suffix pending |
| 26 | selected European Chevrolet/BRC-approved application | 1.6 or 1.8 naturally aspirated petrol/LPG bi-fuel; exact approved engine application unresolved | conventional 5MT | `provisional_regional`; exact factory/dealer-approved status must be resolved before inclusion |

### Candidate totals

- broad Chevrolet-badged J300 sedan scope: **26 base rows**;
- strict unmodified North American LS source-texture scope: **2 rows**;
- every facelift, trim and regional row needs phase- and market-correct material treatment;
- candidate count may increase only if the owner requests physically distinct Eco/package configurations and evidence confirms their mechanical differences.

## Body phases and regional visual policy

The source is a North American/global pre-facelift sedan. The following require separate visual decisions:

- global/European facelift front and rear trim;
- North American 2015 facelift details;
- market-specific grilles, lamps, reflectors, registration recesses and badges;
- China-market J300 trim;
- North American Diesel and Eco appearance details.

The 2014 China D2SC/J400 successor and second-generation Cruze are different bodies and remain excluded.

## Eco and package subdivisions

North American Cruze Eco variants are not badge-only changes. Documented differences include active grille shutters, underbody aero panels, reduced mass, lower/sport suspension and distinct wheel/tyre choices. Manual and automatic Eco configurations may also use different gearing or final-drive calibration.

Two policies are possible:

1. create separate Eco physical configurations for every verified manual/automatic combination whose mass, aero, suspension, tyres or gearing differs;
2. exclude Eco packages and keep only standard physical configurations for the base 1.4T manual and automatic rows.

Appearance-only LT, LTZ and regional trim packages must not create catalog duplicates.

## Transmission architecture assessment

### Conventional manuals

The range uses multiple five- and six-speed manual transaxle families. Exact D16/D20/M32/F40 or other family/suffix assignments, ratios, reverse ratio, final drive, clutch capacity and rotating inertia must be verified per approved row. Marketing descriptions such as `5MT` or `6MT` are not sufficient implementation data.

### GM 6T30, 6T40 and 6T45

These are conventional planetary torque-converter automatics but are not interchangeable generic calibrations:

- 6T30 applications require their own converter, ratio and shift data;
- 6T40 applications have different torque capacity and calibration;
- 6T45 diesel applications require diesel-specific converter, lock-up and shift scheduling.

### Aisin AF40-6

The North American LUZ diesel uses an Aisin six-speed planetary torque-converter automatic. It must remain distinct from the GM 6T family.

Every approved automatic later requires speed-ratio-dependent converter multiplication/slip, creep, progressive lock-up, torque and inertia shift phases, kickdown, grade logic, thermal protection and architecture-specific shift schedules.

## Performance and physics requirements

For every approved row, later parameter research must establish:

- sampled full-load torque curve and transient behaviour;
- exact transmission and final-drive ratios;
- clutch or converter/lock-up behaviour;
- kerb mass and axle loads for exact market, phase and package;
- tyre dimensions and rolling radius;
- drag coefficient and frontal area;
- braking, steering and suspension targets;
- documented acceleration, in-gear and maximum-speed targets;
- Eco aero/mass/suspension differences when approved;
- validation against current `master` physics.

Performance may not be matched with false torque, wrong mass, incorrect transmission family or an arbitrary hidden cap.

## Engine-audio architecture assessment

| Engine family | Required treatment |
|---|---|
| naturally aspirated 1.4/1.6/1.8 petrol I4 | family- and displacement-specific port-injected inline-four combustion, intake, exhaust and valvetrain layers |
| 1.4 turbo petrol | small-turbo inline-four model with distinct boost, induction and load transients |
| China 1.6 turbo petrol | separate higher-output turbo-I4 calibration and induction/exhaust profile |
| 1.7 VCDi | common-rail turbo-diesel inline-four profile distinct from both 2.0 diesel families |
| early RA420 2.0 VCDi | VM Motori-derived diesel combustion, mechanical and turbo layers |
| later Family Z/LLW 2.0 VCDi | separate later diesel architecture/calibration profile |
| LUZ/Multijet 2.0 diesel | separate Fiat/GM Multijet-derived diesel profile |
| South American flex fuel | gasoline/ethanol combustion state only if approved; not a pitch/EQ-only duplicate |
| LPG | dedicated combustion/transient state only if approved |

Unrelated inline-four families must not collapse into one generic waveform merely because they share cylinder count.

## Evidence retained and unresolved work

Before implementation, retain or strengthen primary documentation for:

- North American 2011–2016 order guides, specifications and Eco package data;
- European Chevrolet brochures and price lists by phase;
- China J300 1.6 turbo homologation/order material;
- South American 1.8 flex-fuel output and transmission data;
- exact LPG approval status and engine application;
- exact manual and automatic gearbox suffixes, ratios and final drives;
- exact mass, tyre, drag, braking and performance values for every approved physical configuration.

These evidence gaps may block parameter commitment. They do not justify guessing a factory combination.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Approve only the **2 strict North American LS combinations**, or all/selected rows from the **26-row global Chevrolet J300 sedan matrix**?
2. Include both pre-facelift and facelift Chevrolet J300 sedans, with mandatory phase-correct visual derivatives?
3. Include the China-market 1.6 turbo 6MT row?
4. Include all 1.7 and 2.0 diesel rows, including the North American LUZ diesel?
5. Include the South American 1.8 flex-fuel manual and automatic; if included, treat gasoline and ethanol as states of one vehicle rather than duplicate catalog rows?
6. Include or exclude the provisional petrol/LPG row?
7. Create separate North American Eco manual/automatic physical configurations when verified aero, mass, suspension, tyre or gearing differences exist, or exclude Eco packages?
8. Include provisional regional/gearbox rows only after exact primary documentation confirms the pairing and hardware?
9. Is any expected engine, transmission, fuel, package, market or model-year variant missing from this matrix?

No implementation begins after this individual decision. Research continues to model 05 only after the owner fixes the Cruze scope, and implementation starts only after every included model has reached `approved`.
