# Mercedes-Benz G-Class W463 long station wagon — research in progress

Workflow status: **`researching`**

- order: 01
- source: `01_mercedes_benz_g_class.glb`
- uploader label: Mercedes-Benz G-Class
- represented class: body-on-frame luxury SUV / off-road vehicle
- source triangles: 676

## Verified source contract

The branch file is byte-identical to the prepared extracted source.

- file size: 1,356,064 bytes;
- SHA-256: `5f3b43e8e5dfbef5c15ec24e11721086e23c396a7f6c416710d58fe5606d0225`;
- Git blob SHA-1: `1868eaadc613f4dbc2e83e89464322860be33610`;
- source metadata title: `Mercedes G-Class`;
- source generator: Sketchfab 17.8.0;
- animations: 0;
- skins: 0.

## Source geometry inspection

The GLB contains one body mesh and two paired-wheel meshes.

| Node | Geometry | Vertices | Triangles | Purpose |
|---|---|---:|---:|---|
| `Object_4` | `Object_0` | 615 | 404 | body |
| `Object_6` | `Object_1` | 148 | 136 | front wheel pair |
| `Object_8` | `Object_2` | 148 | 136 | rear wheel pair |

- scene bounds: `(-1.177522, -0.010401, -2.494948)` to `(1.156676, 2.083489, 2.181052)`;
- source extents: `2.334198 × 2.093890 × 4.676000`;
- source axes: `+Y` up, vehicle length along `Z`;
- paired-wheel centres: approximately `Z +1.422253` and `Z -1.627929`;
- source axle-centre separation: approximately `3.050182` source units;
- one PBR material: `gelik`;
- two embedded 1024 × 512 PNG textures: base colour and specular;
- `KHR_materials_specular` is used;
- no source animation or skeleton can provide runtime wheel motion.

The paired axle meshes will eventually require left/right separation and hub-centred pivots, but no derived geometry may be committed while the all-model research gate remains closed.

## Represented identity assessment

### Strongly supported

The embedded texture depicts:

- a first-generation Mercedes-Benz G-Class W463;
- the long-wheelbase five-door station-wagon body;
- post-2002-style exterior mirrors with integrated indicator treatment;
- a front-fender badge visibly reading `5.0 V8`;
- a non-AMG body without the characteristic G 55 AMG side-exit exhaust and AMG exterior treatment.

The directly represented production variant is therefore a **Mercedes-Benz G 500 long station wagon with the naturally aspirated M113 5.0-litre V8**, within the 2002–2007 visual period. The simplified mesh cannot establish one exact model year.

### Still unresolved visually

- whether the texture corresponds to the 2002–2006 exterior or the early-2007 update;
- whether the wheels and `5.0 V8` fender badge are factory, regional or aftermarket details;
- exact market represented by the texture;
- whether AMG-specific exhaust, wheel and badge differences should receive a derived visual or be documented as an approximation.

## Owner scope directions recorded during research

The owner has already made two explicit scope decisions for this model:

1. **Exclude every G 500 Guard derivative.** B4, B6 and B7 protection variants are outside the requested scope and require no further research or implementation.
2. **Include the original G 63 AMG V12 special-order model.** Its lack of a public catalogue does not exclude it; incomplete technical values must remain evidence-blocked rather than guessed.

These directions amend the research matrix but do not bypass the mandatory final `awaiting_owner_scope` gate for the complete model.

## Researched configuration matrix

The current requested scope contains **10 mechanically distinct configurations**.

| Candidate ID | Configuration | Body/type lead | Production overlap | Engine | Factory output | Transmission/driveline | Evidence state |
|---|---|---|---|---|---|---|---|
| `w463_g270cdi_7226` | G 270 CDI long | `463.323` | 2001/2002–2006 | OM612.965, 2685 cc inline-five common-rail turbodiesel | 115 kW / 156 PS; 400 Nm | five-speed torque-converter automatic, 722.6 family; permanent 4WD | `strongly_supported_factory` |
| `w463_g400cdi_7226` | G 400 CDI long | `463.333` | 2001–2006 | OM628.962, 3996 cc V8 common-rail biturbo diesel | 184 kW / 250 PS; 560 Nm | five-speed torque-converter automatic, 722.6 family; permanent 4WD | `strongly_supported_factory` |
| `w463_g320_m112_7226` | G 320 V6 long | `463.245` | 2000–2005 | M112.945, 3199 cc naturally aspirated petrol V6 | 158 kW / 215 PS; 300 Nm | five-speed torque-converter automatic, 722.6 family; permanent 4WD | `strongly_supported_factory` |
| `w463_g500_m113_7226` | G 500 long — five-speed phase | `463.248` | 2000–changeover pending | M113.962, 4966 cc naturally aspirated petrol V8 | 218 kW / 296 PS; 456 Nm | five-speed torque-converter automatic, 722.6 family; permanent 4WD | `verified_identity`; exact phase boundary pending |
| `w463_g500_m113_7229` | G 500 long — 7G phase | `463.248` | changeover pending–2007 | M113.962, 4966 cc naturally aspirated petrol V8 | 218 kW / 296 PS; 456 Nm | seven-speed torque-converter automatic, 722.9 / 7G-TRONIC; permanent 4WD | `strongly_supported_factory`; exact start month/market pending |
| `w463_g55_m113_na_7226` | G 55 AMG long, naturally aspirated | `463.246` | 2001/2002–2004 | M113.982, 5439 cc naturally aspirated petrol V8 | 260 kW / 354 PS; 525–530 Nm conflict open | AMG-calibrated five-speed torque-converter automatic, 722.6 family; permanent 4WD | `strongly_supported_factory` |
| `w463_g55k_476_7226` | G 55 AMG Kompressor long — 476 PS | `463.270` | 2004–2006 | M113.993, 5439 cc supercharged petrol V8 | 350 kW / 476 PS; 700 Nm | AMG-calibrated five-speed torque-converter automatic, 722.6 family; permanent 4WD | `strongly_supported_factory` |
| `w463_g55k_500_7226` | G 55 AMG Kompressor long — 500 PS | `463.271` | late 2006/2007–2007 | supercharged M113K 5.4 V8 | 368 kW / 500 PS; 700 Nm | AMG-calibrated five-speed torque-converter automatic, 722.6 family; permanent 4WD | `strongly_supported_factory` |
| `w463_g320cdi_7229` | G 320 CDI long | `463.341` | 2006–2007 within visual scope | OM642.970, 2987 cc V6 common-rail turbodiesel | 165 kW / 224 PS; 540 Nm | seven-speed torque-converter automatic, 722.9 / 7G-TRONIC; permanent 4WD | `strongly_supported_factory` |
| `w463_g63_v12_m137` | G 63 AMG V12 long, factory special order | individual AMG special-order vehicle; public type lead unresolved | delivered 2001; generally recorded as 2002 model, approximately 2001–2003 programme | M137 E63 / M137.980, 6258 cc naturally aspirated 60-degree petrol V12 | 326 kW / 444 PS at 5500 rpm; 620 Nm at 4400 rpm | five-speed torque-converter automatic; exact 722.6 subtype evidence-blocked; permanent 4WD | `strongly_supported_factory_special_order` |

## G 63 AMG V12 evidence assessment

The G 63 AMG V12 is admitted to the matrix as a genuine AMG factory special-order configuration, not as a normal catalogue row.

Vehicle-level evidence includes a documented 2002 G 63 AMG V12 with chassis `WDCYR48F62X127865`, ordered through Gargash Mercedes-Benz in Dubai and delivered on 10 October 2001. RM Sotheby's describes it as one of approximately five examples, equipped with a hand-built naturally aspirated 6.3-litre V12, a five-speed automatic transmission and four-wheel drive.

Corroborated mechanical data for the M137 E63 AMG application:

- engine family/code: M137 E63 / M137.980;
- displacement: 6258 cc;
- layout: naturally aspirated 60-degree V12;
- output: 326 kW / 444 PS at 5500 rpm;
- torque: 620 Nm at 4400 rpm;
- documented G-Class performance lead: 0–100 km/h approximately 6.5 s;
- documented governed top-speed lead: approximately 210 km/h;
- production quantity: approximately five, not treated as an exact factory-certified count.

Open items remain the exact transmission suffix and ratios, axle/final-drive data, kerb and gross mass, tyre specification, brakes, suspension calibration and full torque curve. Those values remain `evidence_blocked`.

This row requires a dedicated naturally aspirated V12 audio architecture. It may not reuse a V8 profile or transform an unrelated engine waveform through pitch/EQ.

## Excluded Guard scope

`G 500 Guard B4`, `G 500 Guard B6` and `G 500 Guard B7` are `rejected_by_owner_scope`.

They must not be researched further, counted as candidate configurations, exposed in the catalog or approximated using ordinary G 500 mass/collision data unless the owner explicitly reopens that decision.

## Shared drivetrain architecture

All included configurations use permanent four-wheel drive, a two-range transfer case and three selectable differential locks. Exact transfer-case ratios, axle ratios, differential-control logic and market-specific tyre packages still require primary technical documentation before implementation.

The driveline implementation must follow the complete-torque-path contract from PR #107. A generic AWD percentage is not an acceptable substitute for the transfer case, range and three locking differentials.

## Evidence record

Primary-source targets:

- archived Daimler press kit, **The new generation Mercedes-Benz G-Class: Forever young**;
- period Mercedes-Benz brochures, price lists, operator documentation and homologation records;
- official engine and transmission documentation for M112, M113/M113K, M137, OM612, OM628, OM642, 722.6 and 722.9.

Factory-special-order corroboration for G 63 AMG V12:

- RM Sotheby's, **2002 Mercedes-Benz G 63 AMG V12**, chassis `WDCYR48F62X127865`;
- AUTO BILD, **Diese Mercedes G-Klasse gibt es nur fünf Mal**, documenting the M137, 6258 cc, 444 PS, 0–100 km/h and programme history;
- independently corroborated M137 E63 technical application tables.

Secondary tables are not sufficient authority for exact ratios or implementation values. Conflicts in production dates, quoted torque and long-body performance remain open until reconciled against manufacturer or homologation material.

## Remaining work before owner-scope gate

1. establish the exact G 500 722.6 → 722.9 changeover by market and production month;
2. confirm exact transmission subtypes, gear ratios, reverse ratios and final drives for every row;
3. collect factory long-body kerb/gross masses, axle loads, tyres, brakes, drag and performance data;
4. resolve 525 Nm versus 530 Nm documentation for the naturally aspirated G 55 AMG;
5. complete G 63 AMG V12 transmission, mass, tyre, brake, suspension and full-curve evidence while preserving evidence blocks where primary material does not exist;
6. separate ordinary mechanical variants from non-mechanical limited editions such as Classic 25/Limited Edition and Grand Edition;
7. assign final structured-data records and prove transmission and audio backend decisions.

## Mandatory owner-scope gate

The final owner-scope question is **not open yet**. The Guard exclusion and G 63 AMG V12 inclusion are already binding interim directions, but the remaining exact technical work must be completed before the full ten-configuration matrix can move to `awaiting_owner_scope`.

## Implementation block

No geometry processing or implementation may begin before all 18 model records are approved. PR #118 is merged, but the branch must be synchronized with then-current `master`, the current physics baseline recorded and the full suite passed before model 01 enters `integrating`.
