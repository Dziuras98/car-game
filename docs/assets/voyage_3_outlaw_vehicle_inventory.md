# Voyage 3: Outlaw vehicle inventory

## Source bundle

- title: **Voyage 3: Outlaw Playable & NPC Vehicles**;
- Sketchfab uploader: Mason (`ModelzRipper`);
- source: https://sketchfab.com/3d-models/voyage-3-outlaw-playable-npc-vehicles-ec3bd1d415a0471aad47d07e93a448ff;
- uploader-stated license: CC BY-NC 4.0;
- original combined GLB: `voyage_3_outlaw_playable__npc_vehicles.glb`;
- original combined SHA-256: `54f50e5b0d7f038c02548254ccba4c86e435130d5018bf7c40578b9c0aa4f3d0`;
- exact retained-source contract: `docs/assets/voyage_3_outlaw_source_upload.md`;
- workflow: `docs/assets/voyage_3_outlaw_vehicle_import_workflow.md`.

## Provenance limitation

The uploader states that many models were made by `reliable_3d` on TurboSquid and explicitly states that the uploader is not the creator and does not hold rights to those models. The uploader-stated CC BY-NC metadata is retained for traceability, but it is not proof of a complete upstream rights chain.

## Retained and excluded scope

- retained vehicle identities: **18**;
- retained source geometry after upload: **19,845 triangles**;
- retained UAZ: higher-detail UAZ Hunter Police, 4,638 triangles;
- retained Gazelle: **van only**;
- excluded: lower-detail UAZ Hunter Police duplicate;
- excluded: GAZ Gazelle flatbed.

## Mandatory status progression

`source_only → researching → awaiting_owner_scope → approved → integrating → integrated`

All 18 retained vehicles remain `source_only`. The verified GLB upload, complete all-model research gate and PR #118 physics gate all remain blocking.

## Included vehicles

| # | Expected source GLB | Uploader-label identity | Class | Triangles | Research record | Status |
|---:|---|---|---|---:|---|---|
| 1 | `01_mercedes_benz_g_class.glb` | Mercedes-Benz G-Class | SUV | 676 | `docs/vehicles/traffic/mercedes_benz_g_class.md` | `source_only` |
| 2 | `02_bmw_m3_e92.glb` | BMW M3 E92 | passenger coupe | 478 | `docs/vehicles/traffic/bmw_m3_e92.md` | `source_only` |
| 3 | `03_mitsubishi_lancer_evolution.glb` | Mitsubishi Lancer Evolution | performance sedan | 494 | `docs/vehicles/traffic/mitsubishi_lancer_evolution.md` | `source_only` |
| 4 | `04_liaz_bus.glb` | LiAZ bus | city bus | 600 | `docs/vehicles/traffic/liaz_bus.md` | `source_only` |
| 5 | `05_lada_2104.glb` | Lada / VAZ-2104 | passenger estate | 513 | `docs/vehicles/traffic/lada_2104.md` | `source_only` |
| 6 | `06_lada_2112.glb` | Lada / VAZ-2112 | passenger hatchback | 539 | `docs/vehicles/traffic/lada_2112.md` | `source_only` |
| 7 | `07_uaz_hunter_police.glb` | UAZ Hunter Police | police SUV | 4,638 | `docs/vehicles/traffic/uaz_hunter_police.md` | `source_only` |
| 8 | `08_mercedes_benz_s_class_s600.glb` | Mercedes-Benz S-Class S600 | luxury sedan | 2,252 | `docs/vehicles/traffic/mercedes_benz_s_class_s600.md` | `source_only` |
| 9 | `09_lada_niva.glb` | Lada Niva | compact SUV | 584 | `docs/vehicles/traffic/lada_niva.md` | `source_only` |
| 10 | `10_kamaz_military.glb` | KamAZ military truck | heavy utility truck | 2,612 | `docs/vehicles/traffic/kamaz_military.md` | `source_only` |
| 11 | `11_honda_jazz_saw.glb` | Honda Jazz “Saw” | passenger hatchback | 2,230 | `docs/vehicles/traffic/honda_jazz_saw.md` | `source_only` |
| 12 | `12_lada_kalina.glb` | Lada Kalina | passenger car | 482 | `docs/vehicles/traffic/lada_kalina.md` | `source_only` |
| 13 | `13_lada_granta.glb` | Lada Granta | passenger car | 614 | `docs/vehicles/traffic/lada_granta.md` | `source_only` |
| 14 | `14_gaz_gazelle_van.glb` | GAZ Gazelle van | light commercial van | 422 | `docs/vehicles/traffic/gaz_gazelle_van.md` | `source_only` |
| 15 | `15_vaz_1111_oka.glb` | VAZ-1111 Oka | city car | 360 | `docs/vehicles/traffic/vaz_1111_oka.md` | `source_only` |
| 16 | `16_lada_2107.glb` | Lada / VAZ-2107 | passenger sedan | 713 | `docs/vehicles/traffic/lada_2107.md` | `source_only` |
| 17 | `17_lada_2115_samara.glb` | Lada / VAZ-2115 Samara | passenger sedan | 512 | `docs/vehicles/traffic/lada_2115_samara.md` | `source_only` |
| 18 | `18_gaz_volga_rust.glb` | GAZ Volga — rust visual | passenger sedan | 1,126 | `docs/vehicles/traffic/gaz_volga_rust.md` | `source_only` |

## Research and implementation order

`01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18`

The uploader labels are provisional. Generation, body, facelift, model year and complete factory powertrain scope must be verified before the owner-scope gate.
