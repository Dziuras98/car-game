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

`awaiting_owner_scope` is mandatory. After researching all evidenced factory engine, transmission and drivetrain combinations, the complete matrix must be shown to the owner. The individual model moves to `approved` only after the owner confirms the scope and whether anything is missing.

## Global research-before-implementation gate

Research and owner-scope approval proceed through all included models in ascending numeric order. **No Traffic Rider model may enter `integrating` until every included model has reached `approved`.** An individually approved model remains implementation-deferred while any later model is still `source_only`, `researching` or `awaiting_owner_scope`.

After model 23 receives scope approval, implementation begins in ascending numeric order and must follow the current-physics, exact-transmission, audio and validation requirements of the workflow.

## Included models

| # | Source GLB | Intended identity | Class | Source triangles | Workflow status |
|---:|---|---|---|---:|---|
| 1 | `01_bmw_4_series_2014.glb` | BMW 4 Series Coupé F32 pre-LCI | passenger coupe | 1,780 | `approved` |
| 2 | `02_chevrolet_silverado_2014.glb` | Chevrolet Silverado 1500 Crew Cab Standard Box RWD, K2XX pre-facelift | pickup | 2,232 | `approved` |
| 3 | `03_renault_clio_2013.glb` | Renault Clio IV X98 five-door hatchback, Phase 1 source with approved Phase 1/Phase 2 scope | passenger hatchback | 2,118 | `approved` |
| 4 | `04_chevrolet_cruze_2011.glb` | Chevrolet Cruze J300 North American LS sedan, pre-facelift source and approved global pre-facelift scope | passenger sedan | 2,444 | `approved` |
| 5 | `05_ford_e150_2012.glb` | Ford E-150 Commercial Cargo Van, regular length, merged 2008–2014 engine scope | full-size van | 1,844 | `approved` |
| 6 | `06_ford_excursion_2000.glb` | Ford Excursion 2000 pre-facelift XLT, drivetrain unresolved visually | SUV | 2,180 | `awaiting_owner_scope` |
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

## Approved scopes

| Model | Research record | Approved combinations | Scope |
|---|---|---:|---|
| 01 — BMW 4 Series Coupé F32 pre-LCI | `docs/vehicles/traffic/bmw_4_series_2014.md` | 44 | all 42 mechanically distinct standard combinations, including regional 418i/418d entries subject to final evidence, plus RWD 6MT and 8AT 435i ZHP; strict pre-LCI body; no mechanically duplicate catalog entries |
| 02 — Chevrolet Silverado 1500 K2XX pre-facelift | `docs/vehicles/traffic/chevrolet_silverado_2014.md` | 4 | all distinct pre-facelift engine/transmission combinations but RWD only: LV3+6L80, L83+6L80, L86+6L80 and L86+8L90; both 2014 and 2015; one verified standard axle ratio per row; gasoline only; no Z71, Max Trailering, SSV, 4WD or duplicate package/fuel entries |
| 03 — Renault Clio IV X98 hatchback | `docs/vehicles/traffic/renault_clio_2013.md` | 10 | standard non-R.S., non-GT hatchback scope across Phase 1, Phase 2 and Clio Génération; no GT, LPG, R.S., Estate or duplicate calibration rows |
| 04 — Chevrolet Cruze J300 sedan | `docs/vehicles/traffic/chevrolet_cruze_2011.md` | 20 | all researched pre-facelift Chevrolet-badged J300 sedan rows; no facelift-only, LPG, ethanol-state, Eco, hatchback, wagon or later-body entries |
| 05 — Ford E-150 Commercial Cargo Van | `docs/vehicles/traffic/ford_e150_2012.md` | 2 | regular-length cargo body only; 4.6L and 5.4L V8; 2008–2014 differences merged into each engine row; one verified standard axle ratio, open differential and gasoline only; no E85, CNG/LPG, Crew Van, Extended, Wagon, E-250/E-350 or package duplicates |

Models 01, 02, 03, 04 and 05 have passed their individual owner-scope gates, but implementation is deferred by the global research-before-implementation gate.

## Active owner-scope gates

| Model | Research record | Candidate configurations | Blocking decision |
|---|---|---:|---|
| 06 — Ford Excursion | `docs/vehicles/traffic/ford_excursion_2000.md` | 12 complete generation rows; 8 if 7.3L calibrations are merged; 6 for exact 2000 source year | source year vs full generation; all engines; 4x2/4x4; 2005 facelift; 7.3 calibration merging; trim derivatives; axle/differential policy; Mexico 2006; missing variants |

No implementation work may begin for any model while this or any later owner-scope gate remains unresolved. After model 06 is approved, research continues with model 07.

## Source topology

The included GLBs were extracted without geometry simplification. The normal source hierarchy contains three render meshes: body, paired front wheels and paired rear wheels. Integration must create four independent, hub-centred wheel nodes as defined in `traffic_rider_npc_vehicle_import_workflow.md`.

## Deliberately excluded large trucks

| Source index | Model | Reason |
|---:|---|---|
| 19 | Scania truck | large heavy truck excluded from scope |
| 21 | Generic articulated truck | articulated heavy truck excluded from scope |
| 22 | Generic rigid truck | large rigid truck excluded from scope |

## Research and later implementation order

`01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18 → 20 → 23`

Only after all 20 scopes are approved does implementation begin, again in ascending order. Updating a row to `integrated` requires its model-specific record, approved catalog, scenes/resources and automated validation.