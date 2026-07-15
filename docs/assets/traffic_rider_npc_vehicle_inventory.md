# Traffic Rider NPC vehicle inventory

## Source bundle

- title: **Traffic Rider NPC Vehicles**;
- uploader shown in embedded metadata: Mason (`ModelzRipper`);
- source: https://sketchfab.com/3d-models/traffic-rider-npc-vehicles-61f8508a366d41e3b3a40c4b54f7a03a;
- uploader-stated embedded license: CC BY-NC 4.0;
- project treatment: accepted provenance risk for a private, noncommercial project; see `THIRD_PARTY_NOTICES.md` and `docs/accepted_risks.md`.

The repository contains 20 individually extracted source GLBs. Their geometry is currently unscaled for real-world use: the dimensions below are source-space measurements and must not be treated as metres.

## Included models

| # | Source GLB | Intended identity | Class | Source triangles | Workflow status |
|---:|---|---|---|---:|---|
| 1 | `01_bmw_4_series_2014.glb` | BMW 4 Series 2014 | passenger coupe | 1,780 | source committed |
| 2 | `02_chevrolet_silverado_2014.glb` | Chevrolet Silverado 2014 | pickup | 2,232 | pilot candidate |
| 3 | `03_renault_clio_2013.glb` | Renault Clio 2013 | passenger hatchback | 2,118 | source committed |
| 4 | `04_chevrolet_cruze_2011.glb` | Chevrolet Cruze 2011 | passenger sedan | 2,444 | source committed |
| 5 | `05_ford_e150_2012.glb` | Ford E-150 2012 | full-size van | 1,844 | source committed |
| 6 | `06_ford_excursion_2000.glb` | Ford Excursion 2000 | SUV | 2,180 | source committed |
| 7 | `07_ford_f150_limited_2013.glb` | Ford F-150 Limited 2013 | pickup | 1,758 | source committed |
| 8 | `08_ford_transit_connect_2011.glb` | Ford Transit Connect 2011 | compact van | 1,650 | source committed |
| 9 | `09_land_rover_freelander_2_2012.glb` | Land Rover Freelander 2 2012 | SUV | 2,130 | source committed |
| 10 | `10_volkswagen_golf_vii_2013.glb` | Volkswagen Golf VII 2013 | passenger hatchback | 1,982 | pilot candidate |
| 11 | `11_kia_ceed_2012.glb` | Kia cee'd 2012 | passenger hatchback | 2,134 | source committed |
| 12 | `12_renault_maxity_2008.glb` | Renault Maxity 2008 | light box truck | 2,102 | source committed |
| 13 | `13_mazda_2_2011.glb` | Mazda 2 2011 | passenger hatchback | 1,770 | source committed |
| 14 | `14_mazda_3_2014.glb` | Mazda 3 2014 | passenger hatchback | 1,842 | source committed |
| 15 | `15_mercedes_benz_sprinter_2014.glb` | Mercedes-Benz Sprinter 2014 | full-size van | 1,536 | pilot candidate |
| 16 | `16_mercedes_benz_unimog_u5023_2013.glb` | Mercedes-Benz Unimog U5023 2013 | utility vehicle | 2,032 | source committed |
| 17 | `17_nissan_atlas_2007.glb` | Nissan Atlas 2007 | light flatbed truck | 1,996 | source committed |
| 18 | `18_nissan_atleon_2004.glb` | Nissan Atleon 2004 | medium box truck | 2,076 | pilot candidate |
| 20 | `20_skoda_octavia_combi_2013.glb` | Skoda Octavia Combi 2013 | passenger estate | 2,010 | source committed |
| 23 | `23_volkswagen_amarok_2010.glb` | Volkswagen Amarok 2010 | pickup | 2,684 | source committed |

Total committed source geometry: **40,300 triangles**.

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

## Status meanings

- `source committed`: the extracted source GLB exists, but no real-world calibration or runtime traffic integration is complete;
- `pilot candidate`: selected to validate the shared workflow for a geometry class;
- `integrated`: allowed only after every mandatory workflow and regression check passes.

Updating a row to `integrated` requires a model-specific record under `docs/vehicles/traffic/` and the corresponding scene, traffic resource and automated test.
