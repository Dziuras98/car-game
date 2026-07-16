# Voyage 3: Outlaw verified source upload contract

## Purpose

The branch records 18 retained GLBs. They were extracted from the combined Sketchfab scene by removing only the lineup translation and preserving local hierarchy, geometry, materials, embedded textures and local transforms.

The GitHub connector used to create this draft cannot transfer local binary files. Therefore the GLBs are the only intentionally pending part of the initial draft. They must be copied from the prepared package and committed without modification before research begins.

## Required files and hashes

| # | Required root-level file | Identity | Triangles | SHA-256 |
|---:|---|---|---:|---|
| 1 | `01_mercedes_benz_g_class.glb` | Mercedes-Benz G-Class | 676 | `5f3b43e8e5dfbef5c15ec24e11721086e23c396a7f6c416710d58fe5606d0225` |
| 2 | `02_bmw_m3_e92.glb` | BMW M3 E92 | 478 | `b449e4eb0ee6897e58639654d8ea5e36255267b34ac3ce61e91aacd1d96054b3` |
| 3 | `03_mitsubishi_lancer_evolution.glb` | Mitsubishi Lancer Evolution | 494 | `e3214624957429b308f5b0094944b7de3de2aed2ed6b88c59a16fa492eb22e02` |
| 4 | `04_liaz_bus.glb` | LiAZ bus | 600 | `e185be0e40f1dc370315ac5098a920217c9e7a31e1ce16d86754b52d41c535dd` |
| 5 | `05_lada_2104.glb` | Lada / VAZ-2104 | 513 | `e2c7050851328bc234b94b33914c4647197d66a5c2a87752789d0503e96758dc` |
| 6 | `06_lada_2112.glb` | Lada / VAZ-2112 | 539 | `257814961f25230b373989e648b6009d843ff09f422e76ae4d53100fb6d17d74` |
| 7 | `07_uaz_hunter_police.glb` | UAZ Hunter Police, retained high-detail model | 4,638 | `1ccafea5d4edbccba20cdda8223c329785e307f46a0a4a3a14f259e959ead45f` |
| 8 | `08_mercedes_benz_s_class_s600.glb` | Mercedes-Benz S-Class S600 | 2,252 | `bd821fac459d4153a55fd9e33e3d3ad3fcfcedd053fb82c2fc07a853cb648184` |
| 9 | `09_lada_niva.glb` | Lada Niva | 584 | `0a8b47187665720bfa7e8c56f1ce3960aa71d4943035c4696349172a5413a56a` |
| 10 | `10_kamaz_military.glb` | KamAZ military truck | 2,612 | `a08609e721b46566e3fe6f14912ef1ee958e2d29333cb342a2af0d1fc91f2d9b` |
| 11 | `11_honda_jazz_saw.glb` | Honda Jazz “Saw” | 2,230 | `7a0f9dc9a388c84594d7b3d344bda8ac3b854c1bff11de13b7c70e4e848f7285` |
| 12 | `12_lada_kalina.glb` | Lada Kalina | 482 | `c00c1d487834dcaeed5f499130f59a67c7aa8d19859f1437d58abd3108e7cccd` |
| 13 | `13_lada_granta.glb` | Lada Granta | 614 | `37e6c1f23ad2757757b76f4dbc96bb739f6c23244784ce76de6bc25781bc5d2e` |
| 14 | `14_gaz_gazelle_van.glb` | GAZ Gazelle van | 422 | `c61069879edf46f1bf17ec832c1b1adf572510ff75c7bc3baf45311ca79f893c` |
| 15 | `15_vaz_1111_oka.glb` | VAZ-1111 Oka | 360 | `0d43e355c952d92dab8478ea5f911a7995f712c20d3cacd32860ef412cb5c113` |
| 16 | `16_lada_2107.glb` | Lada / VAZ-2107 | 713 | `9c65f023e5f920b8e9c8d881d9879740b374a58a84882771ce138c77413f5ea8` |
| 17 | `17_lada_2115_samara.glb` | Lada / VAZ-2115 Samara | 512 | `694e4a5f7b7301c02cd617ab58c1b31d2e13c5f98e05beb492b1b0478c5aa656` |
| 18 | `18_gaz_volga_rust.glb` | GAZ Volga — rust visual | 1,126 | `227826a1573fc93682193e78139d6d37ffadf02ef01a36fc83a2bb02ad9f036d` |

Total retained geometry: **19,845 triangles**.

## Explicit exclusions

- lower-detail UAZ Hunter Police source: 640 triangles, SHA-256 `7351aef4cb3ab2a081a8d6d2c481a0ccd6ca4c9efbb37ffd7f5bcdf9a9ef6d17`;
- GAZ Gazelle flatbed source: 606 triangles, SHA-256 `afc4628e07aa7006a5d11a8aff17bd100092c2f9899678cc874a4cc87f745fb7`.

Only the Gazelle van is allowed in this branch. The flatbed must not be added under another filename.

## Verification

After copying the GLBs, verify every SHA-256 and run a Godot headless import. The source-upload commit must not modify workflow status, begin geometry processing or create runtime vehicle resources.
