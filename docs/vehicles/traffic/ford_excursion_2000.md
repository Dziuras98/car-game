# Ford Excursion — research and owner-scope gate

- Model number in Traffic Rider bundle: **06**
- Source GLB: `06_ford_excursion_2000.glb`
- Source SHA-256: `7e6909692533a21392cb7bdfa03f52db5fe58da59fba6ea5727a76070d91baf7`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents a **Ford Excursion first generation, 2000-model-year pre-facelift body, XLT exterior treatment**.

Evidence visible in the texture and mesh:

- original 2000–2004 egg-crate grille and Super Duty-derived front clip;
- black paint with XLT-style lower cladding;
- chrome steel-wheel treatment associated with XLT;
- rectangular rear trim badge above the `EXCURSION` nameplate consistent with XLT;
- original rear tri-panel door and vertical E-Series-derived lamps;
- full roof rack and running boards.

The source is not the 2005 front facelift. Exact 4x2 versus 4x4 identity is unresolved: ride-height and wheel-hub cues are too coarse to treat either drivetrain as visually proven.

Identity confidence: **high for 2000 Excursion and pre-facelift body; medium-high for XLT; drivetrain unresolved**.

## Reference dimensions

| Parameter | Reference |
|---|---:|
| Overall length | 226.7 in / 5.758 m |
| Wheelbase | 137.1 in / 3.48234 m |
| Width | 80.0 in for 2000–2001; approximately 79.9 in later |
| Height | approximately 77.2–77.4 in 4x2; 80.2–80.4 in 4x4 |
| Maximum cargo volume | 146.4 cu ft |

Final scale must use the 3.48234 m wheelbase as the primary reference and separately validate length, width, height, tracks, ground clearance, bumpers and tyre size.

## Source inspection

| Item | Result |
|---|---|
| Source meshes | 3 |
| Body mesh | `AI_Ford_Excursion_High_Ford_Excursion_2000_Black_0` |
| Front wheel-pair mesh | `on_teker.005_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.005_wheel_0` |
| Body triangles | 1,460 |
| Front wheel-pair triangles | 360 |
| Rear wheel-pair triangles | 360 |
| Total triangles | 2,180 |
| Source scene AABB | approximately 3.459776 × 2.915746 × 8.266416 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 5.098955 source units |
| Approximate wheelbase-derived scale | 0.682952 |

The source GLB remains unchanged. Wheel separation, collision, catalog, physics, transmission and audio are deferred by the global research gate.

## Research boundary

The complete candidate matrix covers the U.S./Canadian **2000–2005 Ford Excursion generation**. A short Mexico-only 2006 continuation is recorded as provisional regional scope and requires retained Ford Mexico documentation before inclusion.

Trim packages do not automatically duplicate powertrains. XLT, Limited, Eddie Bauer, XLS/fleet and special appearance packages become separate entries only if the owner requests visual/interior derivatives with materially different mass or equipment.

All factory Excursions use an automatic transmission. No factory manual row is evidenced.

## Complete candidate powertrain matrix

The matrix separates 4x2 and 4x4 because they use materially different front suspension and driveline architecture. It also separates documented 7.3L diesel output revisions.

| # | Model-year application | Engine / calibration | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|---|
| 1 | 2000–2005 | 5.4L Triton Modular SOHC 2-valve naturally aspirated V8, 255 hp / 350 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | 4x2 RWD | `verified` |
| 2 | 2000–2005 | 5.4L Triton Modular SOHC 2-valve naturally aspirated V8, 255 hp / 350 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | part-time 4x4 | `verified` |
| 3 | 2000–2005 | 6.8L Triton Modular SOHC 2-valve naturally aspirated V10, 310 hp / 425 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | 4x2 RWD | `verified` |
| 4 | 2000–2005 | 6.8L Triton Modular SOHC 2-valve naturally aspirated V10, 310 hp / 425 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | part-time 4x4 | `verified` |
| 5 | 2000 | 7.3L Power Stroke/Navistar T444E turbo-diesel V8, 235 hp / 500 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | 4x2 RWD | `verified` |
| 6 | 2000 | 7.3L Power Stroke/Navistar T444E turbo-diesel V8, 235 hp / 500 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | part-time 4x4 | `verified` |
| 7 | 2001 | 7.3L Power Stroke/Navistar T444E turbo-diesel V8, 250 hp / 505 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | 4x2 RWD | `verified` |
| 8 | 2001 | 7.3L Power Stroke/Navistar T444E turbo-diesel V8, 250 hp / 505 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | part-time 4x4 | `verified` |
| 9 | 2002–early 2003 | 7.3L Power Stroke/Navistar T444E turbo-diesel V8, 250 hp / 525 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | 4x2 RWD | `verified`; exact 2003 changeover date pending |
| 10 | 2002–early 2003 | 7.3L Power Stroke/Navistar T444E turbo-diesel V8, 250 hp / 525 lb-ft | Ford 4R100 4-speed planetary torque-converter automatic | part-time 4x4 | `verified`; exact 2003 changeover date pending |
| 11 | late 2003–2005 | 6.0L Power Stroke/Navistar VT365 turbo-diesel V8, 325 hp / 560 lb-ft | Ford TorqShift 5R110W 5-speed planetary torque-converter automatic | 4x2 RWD | `verified`; exact 2003 introduction date pending |
| 12 | late 2003–2005 | 6.0L Power Stroke/Navistar VT365 turbo-diesel V8, 325 hp / 560 lb-ft | Ford TorqShift 5R110W 5-speed planetary torque-converter automatic | part-time 4x4 | `verified`; exact 2003 introduction date pending |

**Candidate total: 12 engine/calibration/transmission/drivetrain rows.**

If the three 7.3L output revisions are merged into one engine row per drivetrain, the generation scope reduces to **8 rows**. If only the exact 2000 source year is retained, the scope is **6 rows**.

## Drivetrain and chassis subdivisions

### 4x2

The 4x2 Excursion is rear-wheel drive and uses Ford Twin-I-Beam front suspension with coil springs. It has a lower ride height and no transfer case or driven front axle.

### 4x4

The 4x4 Excursion uses a selectable part-time four-wheel-drive system, transfer case, front driveshaft and solid front drive axle with leaf springs. It requires distinct mass, ride height, steering, unsprung mass, axle inertia, traction and transfer-case behaviour.

The two drivetrains must never be represented as a visual toggle over one shared passenger-car chassis.

## Axle and differential policy candidates

Ford documentation records 3.73, 4.10 and 4.30 rear-axle applications depending on engine, year and towing configuration, with limited-slip availability.

Possible catalog policies:

1. one verified standard axle ratio and standard differential per approved powertrain/drivetrain row;
2. separate axle-ratio rows where the gearing materially changes performance;
3. additional open/limited-slip subdivisions.

Fleet speed limiters, towing packages and payload equipment should not create catalog duplicates unless explicitly requested.

## Visual phases and trims

- **2000–2004 pre-facelift:** compatible with the source body; year and trim may require material, wheel, cladding and lamp corrections.
- **2005 facelift:** revised Super Duty-style grille/front treatment requires a separate accurate front visual derivative.
- **XLT:** closest source trim and chrome steel-wheel treatment.
- **Limited:** different cladding, wheels, seating and equipment.
- **Eddie Bauer:** introduced later with Arizona Beige exterior accents and distinct interior.
- **XLS/fleet and XLT Value/Premium:** package/trim derivatives; not automatically distinct mechanical rows.

## Transmission architecture assessment

### 4R100

The 5.4L, 6.8L and 7.3L rows use the longitudinal 4R100 four-speed planetary automatic with torque converter. Engine-specific converters and shift schedules must remain distinct. Required behaviour includes converter multiplication/slip, creep, lock-up, four exact forward ratios, reverse, torque/inertia shift phases, kickdown, grade/tow scheduling and thermal protection.

### TorqShift 5R110W

The 6.0L diesel uses the five-speed TorqShift 5R110W. It is not a renamed 4R100 and requires its own ratios, converter, adaptive shift logic, tow/haul behaviour, lock-up strategy and thermal model.

## Engine-audio architecture assessment

| Engine | Required treatment |
|---|---|
| 5.4L Triton V8 | naturally aspirated cross-plane Modular V8, displacement/load-specific intake and exhaust |
| 6.8L Triton V10 | dedicated even-fire V10 cadence and collector model; not a V8 pitch transformation |
| 7.3L Power Stroke | HEUI-injected Navistar diesel V8 with fixed-geometry turbo, mechanical/injection and turbo layers |
| 6.0L Power Stroke | separate common-rail-era HEUI diesel profile with variable-geometry turbo and different transient/combustion behaviour |

The two Power Stroke families must not share one generic diesel waveform.

## Evidence retained and unresolved work

Primary Ford brochures for 2000, 2001, 2002, 2003 and 2005 establish dimensions, engines, outputs, 4x2/4x4 availability, trim phases and transmission architecture. Before implementation retain exact Ford order-guide/service evidence for:

- 2003 7.3L-to-6.0L production split;
- exact transmission ratios, converter and calibration by engine/year;
- transfer-case model and ratios;
- standard/optional axle ratios and differential codes;
- mass, axle loads and centre of gravity by powertrain/drivetrain/trim;
- tyres, drag, brakes and documented performance;
- Mexico-only 2006 continuation if included.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Keep only the exact **2000 pre-facelift source year**, or cover the complete 2000–2005 U.S./Canadian generation?
2. Include all 5.4 V8, 6.8 V10, 7.3 diesel and 6.0 diesel engine families?
3. Include both 4x2 and 4x4 for every approved engine/calibration?
4. If the full generation is approved, include the visually distinct 2005 facelift with a correct derivative?
5. Keep the 2000, 2001 and 2002–2003 7.3L output revisions as separate rows, or merge them into one 7.3L row per drivetrain?
6. Preserve only the source-like XLT appearance, or add Limited, Eddie Bauer and XLS/fleet visual/interior derivatives without duplicating identical mechanics?
7. Use one verified standard axle ratio per row, or create separate 3.73/4.10/4.30 configurations where factory-available?
8. Use only the standard differential state, or create separate open and limited-slip configurations?
9. Exclude the provisional Mexico-only 2006 continuation, or include it after primary Ford Mexico documentation is retained?
10. Is any expected engine, drivetrain, transmission, trim, axle or model-year variant missing?

No implementation begins after this individual decision. Research proceeds to model 07 only after the owner fixes model 06 scope, and implementation begins only after every included model has reached `approved`.