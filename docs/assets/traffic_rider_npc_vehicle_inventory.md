# Traffic Rider NPC vehicle inventory

## Source bundle

- title: **Traffic Rider NPC Vehicles**;
- uploader shown in embedded metadata: Mason (`ModelzRipper`);
- source: https://sketchfab.com/3d-models/traffic-rider-npc-vehicles-61f8508a366d41e3b3a40c4b54f7a03a;
- uploader-stated embedded license: CC BY-NC 4.0;
- project treatment: accepted provenance risk for a private, noncommercial project; see `THIRD_PARTY_NOTICES.md` and `docs/accepted_risks.md`.

The repository contains 20 individually extracted source GLBs. Their geometry is currently unscaled for real-world use: the dimensions in the source assets must not be treated as metres.

Before geometry or runtime integration begins, every model must pass the complete research and owner-approval gates defined in `docs/assets/traffic_rider_npc_vehicle_import_workflow.md`.

## Mandatory status progression

```text
source_only
→ researching
→ awaiting_owner_scope
→ approved
→ integrating
→ integrated
```

`awaiting_owner_scope` is mandatory. After researching all evidenced factory engine, transmission and drivetrain combinations, the complete matrix must be shown to the owner. Integration remains blocked until the owner confirms whether to import all variants or a subset and whether any expected variant is missing.

## Included models

| # | Source GLB | Intended identity | Class | Source triangles | Workflow status |
|---:|---|---|---|---:|---|
| 1 | `01_bmw_4_series_2014.glb` | BMW 4 Series Coupé F32 pre-LCI | passenger coupe | 1,780 | `awaiting_owner_scope` |
| 2 | `02_chevrolet_silverado_2014.glb` | Chevrolet Silverado 2014 | pickup | 2,232 | `source_only` |
| 3 | `03_renault_clio_2013.glb` | Renault Clio 2013 | passenger hatchback | 2,118 | `source_only` |
| 4 | `04_chevrolet_cruze_2011.glb` | Chevrolet Cruze 2011 | passenger sedan | 2,444 | `source_only` |
| 5 | `05_ford_e150_2012.glb` | Ford E-150 2012 | full-size van | 1,844 | `source_only` |
| 6 | `06_ford_excursion_2000.glb` | Ford Excursion 2000 | SUV | 2,180 | `source_only` |
| 7 | `07_ford_f150_limited_2013.glb` | Ford F-150 Limited 2013 | pickup | 1,758 | `source_only` |
| 8 | `08_ford_transit_connect_2011.glb` | Ford Transit Connect 2011 | compact van | 1,650 | `source_only` |
| 9 | `09_land_rover_freelander_2_2012.glb` | Land Rover Freelander 2 2012 | SUV | 2,130 | `source_only` |
| 10 | `10_volkswagen_golf_vii_2013.glb` | Volkswagen Golf VII 2013 | passenger hatchback | 1,982 | `source_only` |
| 11 | `11_kia_ceed_2012.glb` | Kia cee'd 2012 | passenger hatchback | 2,134 | `source_only` |
| 12 | `12_renault_maxity_2008.glb` | Renault Maxity 2008 | light box truck | 2,102 | `source_only` |
| 13 | `13_mazda_2_2011.glb` | Mazda 2 2011 | passenger hatchback | 1,770 | `source_only` |
| 14 | `14_mazda_3_2014.glb` | Mazda 3 2014 | passenger hatchback | 1,842 | `source_only` |
| 15 | `15_mercedes_benz_sprinter_2014.glb` | Mercedes-Benz Sprinter 2014 | full-size van | 1,536 | `source_only` |
| 16 | `16_mercedes_benz_unimog_u5023_2013.glb` | Mercedes-Benz Unimog U5023 2013 | utility vehicle | 2,032 | `source_only` |
| 17 | `17_nissan_atlas_2007.glb` | Nissan Atlas 2007 | light flatbed truck | 1,996 | `source_only` |
| 18 | `18_nissan_atleon_2004.glb` | Nissan Atleon 2004 | medium box truck | 2,076 | `source_only` |
| 20 | `20_skoda_octavia_combi_2013.glb` | Skoda Octavia Combi 2013 | passenger estate | 2,010 | `source_only` |
| 23 | `23_volkswagen_amarok_2010.glb` | Volkswagen Amarok 2010 | pickup | 2,684 | `source_only` |

Total committed source geometry: **40,300 triangles**.

## Active owner-scope gates

| Model | Research record | Candidate standard combinations | Blocking decision |
|---|---|---:|---|
| 01 — BMW 4 Series Coupé F32 pre-LCI | `docs/vehicles/traffic/bmw_4_series_2014.md` | 42 | all variants vs subset; regional/special/post-LCI scope; missing variants |

No implementation work may begin for an active row until the owner decision is recorded in its research document.

## Source topology

The included GLBs were extracted without geometry simplification. The normal source hierarchy contains three render meshes:

1. body;
2. paired front wheels;
3. paired rear wheels.

The paired wheel meshes are source data, not the final runtime contract. Integration must create four independent, hub-centred wheel nodes as defined in `traffic_rider_npc_vehicle_import_workflow.md`.

## Deliberately excluded large trucks

These models existed in the combined source bundle but were not added to the repository:

| Source index | Model | Reason |
|---:|---|---|
| 19 | Scania truck | large heavy truck excluded from scope |
| 21 | Generic articulated truck | articulated heavy truck excluded from scope |
| 22 | Generic rigid truck | large rigid truck excluded from scope |

## Pilot order after research approval

After each pilot completes the full Stage 0 research and receives explicit owner scope approval, the geometry/runtime workflow is validated on:

1. Volkswagen Golf VII 2013;
2. Chevrolet Silverado 2014;
3. Mercedes-Benz Sprinter 2014;
4. Nissan Atleon 2004.

The pilot designation never bypasses complete powertrain research, exact transmission architecture, current-physics calibration or engine-audio requirements.

Updating a row to `integrated` requires a model-specific record under `docs/vehicles/traffic/`, the approved variant catalog, corresponding scenes/resources and all automated tests defined by the workflow.
