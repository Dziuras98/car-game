# Traffic Rider NPC vehicle inventory

## Source bundle

- title: **Traffic Rider NPC Vehicles**;
- uploader shown in embedded metadata: Mason (`ModelzRipper`);
- source: https://sketchfab.com/3d-models/traffic-rider-npc-vehicles-61f8508a366d41e3b3a40c4b54f7a03a;
- uploader-stated embedded license: CC BY-NC 4.0;
- project treatment: accepted provenance risk for a private, noncommercial project; see `THIRD_PARTY_NOTICES.md` and `docs/accepted_risks.md`.

The repository contains 20 individually extracted source GLBs. Their geometry is unscaled source geometry and must not be interpreted as metres. Sources are relocated individually into canonical third-party paths when their numbered implementation begins.

## Mandatory status progression

```text
source_only
→ researching
→ awaiting_owner_scope
→ approved
→ integrating
→ integrated
```

`awaiting_owner_scope` is mandatory. Research and owner-scope approval are complete for all 20 included models.

## Global implementation gates

The global research gate is satisfied: every included model has reached `approved`.

The physics dependency is also satisfied. PR #118, **Rework per-wheel vehicle physics and recalibrate DPI v3**, was merged into `master` as commit `3743f5e95391b63a97e81b95050984b8240b7f30`. PR #107 is synchronized directly onto that commit and uses it as the initial implementation baseline.

The reviewed baseline includes authoritative per-wheel contact, load, longitudinal/lateral slip and force state; wheel/drivetrain inertia; differentials; AWD torque distribution interfaces; two-pass load transfer; braking/ABS/traction control; steering/yaw; vector drag; transmission interfaces; and DPI v3.

Model 01 may therefore enter `integrating`. Stage 7 calibration still requires re-synchronization and complete regression tests before parameters are finalized.

## Included models

| # | Source GLB | Intended identity | Class | Source triangles | Workflow status |
|---:|---|---|---|---:|---|
| 1 | `assets/third_party/sketchfab/traffic_rider_npc_vehicles/bmw_4_series_f32/source/01_bmw_4_series_2014.glb` | BMW 4 Series Coupé F32 pre-LCI | passenger coupe | 1,780 | `integrating` |
| 2 | `02_chevrolet_silverado_2014.glb` | Chevrolet Silverado 1500 Crew Cab Standard Box RWD, K2XX pre-facelift | pickup | 2,232 | `approved` |
| 3 | `03_renault_clio_2013.glb` | Renault Clio IV X98 five-door hatchback, Phase 1 source with approved Phase 1/Phase 2 scope | passenger hatchback | 2,118 | `approved` |
| 4 | `04_chevrolet_cruze_2011.glb` | Chevrolet Cruze J300 North American LS sedan, pre-facelift source and approved global pre-facelift scope | passenger sedan | 2,444 | `approved` |
| 5 | `05_ford_e150_2012.glb` | Ford E-150 Commercial Cargo Van, regular length, merged 2008–2014 engine scope | full-size van | 1,844 | `approved` |
| 6 | `06_ford_excursion_2000.glb` | Ford Excursion 2000 pre-facelift XLT, approved 4x2 engine scope | SUV | 2,180 | `approved` |
| 7 | `07_ford_f150_limited_2013.glb` | Ford F-150 Limited 2013 source with approved 2009–2014 P415 SuperCrew 5.5-ft 4x2 engine scope | pickup | 1,758 | `approved` |
| 8 | `08_ford_transit_connect_2011.glb` | Ford Transit Connect XLT Premium Wagon 2011 with approved complete first-generation powertrain scope | compact van | 1,650 | `approved` |
| 9 | `09_land_rover_freelander_2_2012.glb` | Land Rover LR2 HSE 2012 with approved complete Freelander 2 L359 powertrain scope | SUV | 2,130 | `approved` |
| 10 | `10_volkswagen_golf_vii_2013.glb` | Volkswagen Golf VII five-door source with approved standard TSI/TDI and e-Golf scope | passenger hatchback | 1,982 | `approved` |
| 11 | `11_kia_ceed_2012.glb` | Kia cee'd JD five-door European pre-facelift standard EcoDynamics-style source with approved complete powertrain scope | passenger hatchback | 2,134 | `approved` |
| 12 | `12_renault_maxity_2008.glb` | Renault Maxity original-body single-cab short-wheelbase box truck with approved complete six-powertrain scope | light box truck | 2,102 | `approved` |
| 13 | `13_mazda_2_2011.glb` | North American 2011 Mazda2 Sport five-door facelift source with approved complete global powertrain scope | passenger hatchback | 1,770 | `approved` |
| 14 | `14_mazda_3_2014.glb` | North American 2014 Mazda3 BM five-door high-grade 2.5-style source with approved global BM/BN/BY scope | passenger hatchback | 1,842 | `approved` |
| 15 | `15_mercedes_benz_sprinter_2014.glb` | Mercedes-Benz Sprinter W906 facelift long-wheelbase high-roof windowed single-rear-wheel van with approved RWD-only scope | full-size van | 1,536 | `approved` |
| 16 | `16_mercedes_benz_unimog_u5023_2013.glb` | Mercedes-Benz Unimog U5023 single-cab dropside source with approved U4023/U5023 mechanical scope | utility vehicle | 2,032 | `approved` |
| 17 | `17_nissan_atlas_2007.glb` | Nissan Atlas / Cabstar F24 2007 narrow single-cab flatbed source with approved RWD scope | light flatbed truck | 1,996 | `approved` |
| 18 | `18_nissan_atleon_2004.glb` | Nissan Atleon 2004 pre-facelift single-cab box truck with approved four-engine RWD scope | medium box truck | 2,076 | `approved` |
| 20 | `20_skoda_octavia_combi_2013.glb` | Škoda Octavia III type 5E Combi 2013 standard pre-facelift source with approved non-Scout scope | passenger estate | 2,010 | `approved` |
| 23 | `23_volkswagen_amarok_2010.glb` | Volkswagen Amarok I type 2H original Double Cab source with approved full-generation scope | pickup | 2,684 | `approved` |

Total committed source geometry: **40,300 triangles**.

## Approved scopes

| Model | Research record | Approved combinations | Scope |
|---|---|---:|---|
| 01 — BMW 4 Series Coupé F32 pre-LCI | `docs/vehicles/traffic/bmw_4_series_2014.md` | 44 | all 42 mechanically distinct standard combinations, including regional 418i/418d entries subject to final evidence, plus RWD 6MT and 8AT 435i ZHP; strict pre-LCI body; no mechanically duplicate catalog entries |
| 02 — Chevrolet Silverado 1500 K2XX pre-facelift | `docs/vehicles/traffic/chevrolet_silverado_2014.md` | 4 | all distinct pre-facelift engine/transmission combinations but RWD only: LV3+6L80, L83+6L80, L86+6L80 and L86+8L90 |
| 03 — Renault Clio IV X98 hatchback | `docs/vehicles/traffic/renault_clio_2013.md` | 10 | standard non-R.S., non-GT hatchback scope across Phase 1, Phase 2 and Clio Génération |
| 04 — Chevrolet Cruze J300 sedan | `docs/vehicles/traffic/chevrolet_cruze_2011.md` | 20 | all researched pre-facelift Chevrolet-badged J300 sedan rows |
| 05 — Ford E-150 Commercial Cargo Van | `docs/vehicles/traffic/ford_e150_2012.md` | 2 | regular-length cargo body; 4.6L and 5.4L V8 |
| 06 — Ford Excursion pre-facelift XLT 4x2 | `docs/vehicles/traffic/ford_excursion_2000.md` | 5 | 4x2 5.4 V8, 6.8 V10, 7.3 early, 7.3 late and 6.0 Power Stroke |
| 07 — Ford F-150 P415 SuperCrew 5.5-ft 4x2 | `docs/vehicles/traffic/ford_f150_limited_2013.md` | 7 | all researched engine families, consolidated across 2009–2014, 4x2 only |
| 08 — Ford Transit Connect first generation | `docs/vehicles/traffic/ford_transit_connect_2011.md` | 6 | all researched combustion families plus Azure Dynamics Electric |
| 09 — Land Rover Freelander 2 / LR2 L359 | `docs/vehicles/traffic/land_rover_freelander_2_2012.md` | 8 | eD4 FWD and seven Haldex AWD rows |
| 10 — Volkswagen Golf VII five-door hatchback | `docs/vehicles/traffic/volkswagen_golf_vii_2013.md` | 38 | 22 standard TSI, 14 ordinary TDI and two e-Golf generations |
| 11 — Kia cee'd JD five-door hatchback | `docs/vehicles/traffic/kia_ceed_2012.md` | 15 | eight petrol and seven diesel rows |
| 12 — Renault Maxity F24 original body | `docs/vehicles/traffic/renault_maxity_2008.md` | 6 | five diesel calibrations plus Maxity Electric |
| 13 — Mazda2 / Demio DE five-door hatchback | `docs/vehicles/traffic/mazda_2_2011.md` | 16 | complete global powertrain scope including EV |
| 14 — Mazda3 BM / BN / BY | `docs/vehicles/traffic/mazda_3_2014.md` | 19 | petrol, diesel, AWD and hybrid rows |
| 15 — Mercedes-Benz Sprinter W906 facelift RWD | `docs/vehicles/traffic/mercedes_benz_sprinter_2014.md` | 17 | OM651, OM642, M271 and factory NGT RWD rows |
| 16 — Mercedes-Benz Unimog U4023 / U5023 | `docs/vehicles/traffic/mercedes_benz_unimog_u5023_2013.md` | 2 | both mechanically distinct 437.4 chassis rows |
| 17 — Nissan Atlas / Cabstar F24 | `docs/vehicles/traffic/nissan_atlas_2007.md` | 8 | five Japanese Atlas RWD and three European Cabstar RWD rows |
| 18 — Nissan Atleon 2004 pre-facelift | `docs/vehicles/traffic/nissan_atleon_2004.md` | 4 | BD30Ti, B4.40Ti and two B6.60Ti calibrations |
| 20 — Škoda Octavia III Combi pre-facelift | `docs/vehicles/traffic/skoda_octavia_combi_2013.md` | 35 | standard FWD, ordinary 4×4 and RS Combi; Scout excluded |
| 23 — Volkswagen Amarok I full generation | `docs/vehicles/traffic/volkswagen_amarok_2010.md` | 19 | original/updated four-cylinder, regional petrol and V6 rows with distinct drivetrains |

All 20 models have passed their individual owner-scope gates. Combined approved scope: **285 mechanically consolidated configurations**.

## Current implementation progress

| Item | State |
|---|---|
| Physics baseline | `3743f5e95391b63a97e81b95050984b8240b7f30` recorded; dependency resolved |
| Model 01 source | moved unchanged to canonical third-party path; root duplicate removed |
| Model 01 scale/orientation | wheelbase-derived scale `0.6940157`; source `+Z` converted to project `-Z` |
| Model 01 visual definition | created and validated as incomplete until wheel separation is complete |
| Model 01 processed derivative | pending four independent hub-centred wheel meshes |
| Model 01 powertrain catalog | pending exact evidence-backed data; no guessed variants exposed |
| Next model | model 02 remains queued until model 01 reaches `integrated` |

## Source topology

The normal source hierarchy contains body, paired front wheels and paired rear wheels. Integration must create four independent hub-centred wheel nodes. Dual-rear-wheel source models must represent and bind every physical rear tyre explicitly.

## Deliberately excluded large trucks

| Source index | Model | Reason |
|---:|---|---|
| 19 | Scania truck | large heavy truck excluded from scope |
| 21 | Generic articulated truck | articulated heavy truck excluded from scope |
| 22 | Generic rigid truck | large rigid truck excluded from scope |

## Implementation order

`01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18 → 20 → 23`

Updating a row to `integrated` requires its model-specific record, exact approved catalog, scenes/resources, architecture-correct transmission and audio, current-physics calibration and automated validation.
