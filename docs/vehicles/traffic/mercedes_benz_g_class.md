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

The paired axle meshes will eventually require left/right separation and hub-centred pivots, but no derived geometry may be committed while the all-model research and physics gates remain closed.

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
- whether Guard-specific glazing and body details are sufficiently represented by this generic visual;
- exact market represented by the texture.

## Candidate-version investigation result

All versions previously listed were checked against the long five-door W463 production range. Seven ordinary/AMG names are confirmed as genuine factory long-station-wagon applications in the represented visual period. The names expand to at least ten mechanically or protection-distinct configurations because the G 500 changed transmission, the G 55 AMG Kompressor had two factory calibrations, and the G 500 Guard existed in multiple protection classes.

The dates below describe the overlap with the visual period, not necessarily the complete lifetime of the sales designation.

| Configuration | Long-body type lead | Production overlap | Engine | Factory output | Transmission architecture | Body availability | Evidence state |
|---|---|---|---|---|---|---|---|
| G 270 CDI long | `463.323` | 2001/2002–2006 | OM612.965, 2685 cc inline-five common-rail turbodiesel | 115 kW / 156 PS; 400 Nm | five-speed torque-converter automatic, 722.6 family | long five-door confirmed; short also existed | `strongly_supported_factory` |
| G 400 CDI long | `463.333` | 2001–2006 | OM628.962, 3996 cc V8 common-rail biturbo diesel | 184 kW / 250 PS; 560 Nm | five-speed torque-converter automatic, 722.6 family | long five-door confirmed; short also existed | `strongly_supported_factory` |
| G 320 V6 long | `463.245` | 2000–2005 | M112.945, 3199 cc naturally aspirated petrol V6 | 158 kW / 215 PS; 300 Nm | five-speed torque-converter automatic, 722.6 family | long five-door confirmed; short/cabriolet derivatives also existed | `strongly_supported_factory` |
| G 500 long — five-speed phase | `463.248` | 2000–2006 transition pending exact date | M113.962, 4966 cc naturally aspirated petrol V8 | 218 kW / 296 PS; 456 Nm | five-speed torque-converter automatic, 722.6 family | long five-door confirmed; short/cabriolet derivatives also existed | `verified_identity`; exact gearbox changeover pending primary document |
| G 500 long — 7G phase | `463.248` | 2006/2007–2007 | same M113.962 5.0 V8 | same nominal output | seven-speed torque-converter automatic, 722.9 / 7G-TRONIC family | long five-door confirmed | `strongly_supported_factory`; exact start month/market pending |
| G 55 AMG long, naturally aspirated | `463.246` | 2001/2002–2004 | M113.982, 5439 cc naturally aspirated petrol V8 | 260 kW / 354 PS; approximately 525–530 Nm | AMG-calibrated five-speed torque-converter automatic, 722.6 family | long five-door confirmed; an earlier short version also existed | `strongly_supported_factory` |
| G 55 AMG Kompressor long — 476 PS | `463.270` | 2004–2006 | M113.993, 5439 cc supercharged petrol V8 | 350 kW / 476 PS; 700 Nm | AMG-calibrated five-speed torque-converter automatic, 722.6 family | long five-door only for this phase | `strongly_supported_factory` |
| G 55 AMG Kompressor long — 500 PS | `463.271` | late 2006/2007–2007 within visual scope | supercharged M113K 5.4 V8 | 368 kW / 500 PS; 700 Nm | AMG-calibrated five-speed torque-converter automatic, 722.6 family | long five-door only | `strongly_supported_factory` |
| G 320 CDI long | `463.341` | 2006–2007 within visual scope | OM642.970, 2987 cc V6 common-rail turbodiesel | 165 kW / 224 PS; 540 Nm | seven-speed torque-converter automatic, 722.9 / 7G-TRONIC family | long five-door confirmed; short/cabriolet derivatives also existed | `strongly_supported_factory` |
| G 500 Guard B4 | special-protection derivative of long G 500 | 2002–2007 | M113 5.0 V8 | base G 500 calibration | automatic; exact 722.6/722.9 changeover not yet proven for Guard | armoured long five-door only | `verified_factory_existence`; technical row incomplete |
| G 500 Guard B6 | special-protection derivative of long G 500 | 2001–2007 | M113 5.0 V8 | base G 500 calibration | automatic; exact gearbox/date pending | armoured long five-door only | `verified_factory_existence`; technical row incomplete |
| G 500 Guard B7 | special-protection derivative of long G 500 | 2002–2007 | M113 5.0 V8 | base G 500 calibration | automatic; exact gearbox/date pending | armoured long five-door only | `verified_factory_existence`; technical row incomplete |

## Per-version assessment

### G 270 CDI

Confirmed as applicable. It replaced the preceding G 300 Turbodiesel and was offered in both short and long W463 station wagons. The long vehicle is mechanically distinct because mass and performance differ from the short body. It requires an inline-five diesel audio architecture and a five-speed converter automatic.

### G 400 CDI

Confirmed as applicable. This is the V8 biturbo-diesel version, not a diesel calibration of the G 500. It requires its own V8-diesel combustion/audio model, a five-speed converter automatic, and materially different mass/torque calibration.

### G 320 petrol

Confirmed as applicable through 2005. The candidate is the later M112 V6 version, not the earlier M104 inline-six G 320. The source visual period overlaps only the M112-powered configuration.

### G 500

Confirmed and directly represented by the texture. It must be split by transmission phase once the exact factory changeover is established. A 722.6 and a 722.9 vehicle cannot be collapsed into one configuration because ratios, inertia, shift behaviour and performance differ.

### G 55 AMG naturally aspirated

Confirmed as applicable through 2004. It is a 5.4-litre M113 AMG engine, not the 5.0-litre G 500 engine and not the later supercharged unit. AMG exterior differences mean this configuration would share the simplified body only as an explicitly documented visual approximation.

### G 55 AMG Kompressor

Confirmed as applicable in two calibrations inside the represented period:

1. 350 kW / 476 PS from 2004 to the 2006 update;
2. 368 kW / 500 PS from the late-2006/2007 update.

The later 373 kW / 507 PS calibration belongs to the later 2008+ phase and is currently outside this visual scope.

### G 320 CDI

Confirmed as the 2006 replacement for both the G 270 CDI and G 400 CDI in the civilian W463 range. It introduces both a V6 diesel architecture and 7G-TRONIC, so it cannot reuse either earlier diesel configuration.

### G 500 Guard

Confirmed as a factory long-body special-protection derivative during the period, but it is not yet implementation-ready. B4, B6 and B7 protection levels must remain separate until factory masses, payloads, tyres, brakes, suspension changes, glazing/body differences and exact transmission applicability are documented. A normal G 500 mass or collision volume may not be reused.

## Additional omitted factory lead

Research also found a very-low-volume **G 63 AMG V12** from approximately 2001–2003. It was not in the original candidate list. Its factory/AMG production status, exact count, chassis coding and applicability to the owner-directed scope require a separate evidence review before it can be added to the matrix. It is not silently included or rejected here.

## Shared drivetrain architecture

All confirmed civilian variants use permanent four-wheel drive, a two-range transfer case and three selectable differential locks. Exact transfer-case ratios, axle ratios, differential-control logic and market-specific tyre packages still require primary technical documentation before implementation.

## Evidence reviewed

Primary-source target:

- archived Daimler press kit, **The new generation Mercedes-Benz G-Class: Forever young**: `https://web.archive.org/web/20160304002619/http://media.daimler.com/dcmedia/0-921-614254-1-1489395-1-0-0-0-0-1-11701-1549054-0-1-0-0-0-0-0.html`;
- period Mercedes-Benz brochures, price lists, operator documentation and Guard material remain the required authority for exact gearbox suffixes, dates, masses and ratios.

Corroborating technical leads used to identify conflicts and type numbers:

- Mercedes-Benz G-Class historical model tables and production summaries;
- period W463 type-code tables for `463.245`, `463.248`, `463.246`, `463.270`, `463.271`, `463.323`, `463.333` and `463.341`;
- period model-history references distinguishing the 2001, 2004, 2006 and 2007 updates.

Secondary tables are not treated as sufficient authority for final ratios or implementation values. Conflicts in production dates, quoted torque and long-body performance remain open until reconciled against factory documents.

## Remaining work before owner-scope gate

1. establish the exact G 500 722.6 → 722.9 changeover by market and production month;
2. confirm exact transmission subtypes, gear ratios, reverse ratios and final drives for every row;
3. collect factory long-body kerb/gross masses, axle loads, tyres and performance data;
4. complete Guard B4/B6/B7 mass, chassis, brake, suspension, tyre and gearbox records;
5. resolve 525 Nm versus 530 Nm documentation for the naturally aspirated G 55 AMG;
6. decide from evidence whether the G 63 AMG V12 was a catalogue factory variant, AMG special order or conversion outside the intended matrix;
7. separate ordinary mechanical variants from non-mechanical limited editions such as Classic 25/Limited Edition and Grand Edition.

## Mandatory owner-scope gate

The owner-scope question is **not open yet**. All originally listed versions have been checked for existence and long-body applicability, but exact technical rows remain incomplete in the areas listed above.

## Implementation block

No geometry processing or implementation may begin before all 18 records are approved and PR #118 or an accepted merged successor supplies the final physics baseline.
