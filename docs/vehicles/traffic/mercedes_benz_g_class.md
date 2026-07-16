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
- the long-wheelbase five-door station-wagon body, with two side doors and three side-window sections per side;
- post-2002-style exterior mirrors with integrated indicator treatment;
- a front-fender badge visibly reading `5.0 V8`;
- a non-AMG body without the characteristic G 55 AMG side-exit exhaust and AMG-specific exterior treatment.

The most probable represented production variant is therefore a **Mercedes-Benz G 500 long station wagon with the naturally aspirated M113 5.0-litre V8**, within the 2002–2007 visual period. The mesh is too simplified to assign one exact model year from geometry alone.

### Still unresolved

- exact model year and market represented by the texture;
- whether the texture corresponds to the 2002–2006 exterior or the early-2007 update;
- whether the wheels and `5.0 V8` fender badge are factory, regional or aftermarket details;
- exact transmission changeover date and markets for the M113 G 500;
- whether the owner wants only the directly represented G 500 or every mechanically distinct long-station-wagon powertrain sharing the evidenced visual phase.

## Research scope under investigation

The complete matrix is not yet ready for owner approval. The following are candidate rows that must be verified against manufacturer brochures, price lists, press material, homologation records and transmission documentation before they can be accepted as factory combinations for the represented long station wagon.

| Candidate model | Candidate engine architecture | Candidate transmission architecture | Current evidence state |
|---|---|---|---|
| G 270 CDI | OM612 2.7-litre inline-five turbodiesel | five-speed torque-converter automatic | `discovery_only` |
| G 400 CDI | OM628 4.0-litre V8 biturbo diesel | five-speed torque-converter automatic | `discovery_only` |
| G 320 | M112 3.2-litre naturally aspirated V6 petrol | five-speed torque-converter automatic | `discovery_only` |
| G 500 | M113 5.0-litre naturally aspirated V8 petrol | five-speed automatic and possible later seven-speed transition to verify by market/date | `strongly_supported_identity`; mechanical details pending primary evidence |
| G 55 AMG | M113 5.4-litre naturally aspirated V8 petrol | AMG-calibrated five-speed torque-converter automatic | `discovery_only` |
| G 55 AMG Kompressor | supercharged M113K 5.4-litre V8 petrol, multiple factory calibrations | AMG-calibrated five-speed torque-converter automatic | `discovery_only` |
| G 320 CDI | OM642 3.0-litre V6 turbodiesel | seven-speed torque-converter automatic | `discovery_only` |
| G 500 Guard | protected long-wheelbase derivative with G 500 powertrain | transmission and protection class to verify separately | `specialist_variant_pending_scope` |

`discovery_only` rows are search leads, not approved technical data. No power, torque, ratio, mass, performance or production-date value may be implemented from this table.

## Primary-evidence queue

Research is now collecting and reconciling:

1. Mercedes-Benz brochures and price lists for the 2002–2008 W463 long station wagon;
2. the archived Daimler press kit **The new generation Mercedes-Benz G-Class: Forever young**;
3. official engine and transmission documentation for M113/M113K, M112, OM612, OM628 and OM642 applications;
4. market-specific homologation/type-approval records for exact engine–gearbox combinations;
5. official dimensions, kerb/gross masses, tyres, final drives and performance figures;
6. evidence separating ordinary long station wagons from AMG and Guard derivatives.

Secondary databases may be used only to locate primary documents or identify conflicts. They are not sufficient for final matrix approval.

## Mandatory owner-scope gate

The owner-scope question is **not open yet**. It will be asked only after the complete evidenced factory matrix is assembled, transmission architectures and regional/model-year restrictions are resolved, and all uncertain rows are explicitly identified.

## Implementation block

No geometry processing or implementation may begin before all 18 records are approved and PR #118 or an accepted merged successor supplies the final physics baseline.
