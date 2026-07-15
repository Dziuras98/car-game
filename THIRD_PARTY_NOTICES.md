# Third-Party Names and Assets

This project is unofficial and is not sponsored, endorsed by or affiliated with BMW AG, Nissan Motor Co., Ltd., Fiat S.p.A./Stellantis, Ford Motor Company, Shelby American, Fabryka Samochodów Osobowych, Rover Group, PSA, Electronic Arts, Firemonkeys Studios or any other vehicle manufacturer, publisher, studio or asset author named below.

Names such as "BMW", "3 Series", "E46", "Nissan", "370Z", "Fiat", "Punto", "Ford", "Mustang", "Shelby", "G.T. 500", "FSO", "Polonez", "Caro", "Rover", "Pinto", "XUD", "Need for Speed", "Real Racing" and "Traffic Rider" are used descriptively. All product names, trademarks, logos and trade dress remain the property of their respective owners. The repository license and any third-party asset license described below do not grant trademark rights.

## Sketchfab BMW E46 visual model

The following third-party GLB is included under the uploader's stated **Creative Commons Attribution 4.0 International** license and is expressly excluded from the repository's root `LICENSE`.

### Low Poly Car - BMW E46 1998

- author: ROH3D (`roh3d`);
- source: https://sketchfab.com/3d-models/low-poly-car-bmw-e46-1998-d9bfd8126e754164b48ded833c017bbf;
- included GLB: `assets/third_party/sketchfab/bmw_e46_1998/low_poly_car_bmw_e46_1998.glb`;
- uploader-stated license: CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/;
- source publication date shown by Sketchfab: May 25, 2025;
- project use: shared detailed visual body for the non-M BMW E46 sedan variants.

The game adds Godot wrapper scenes, collision volumes, screen-visibility LOD, low-detail fallback geometry, drivetrain configuration and procedural audio. These integration changes do not transfer authorship of the underlying model. Redistributed copies or builds containing the GLB must credit ROH3D, link the source page and CC BY 4.0 license, and identify that the model was integrated and adapted for Godot runtime use.

## Sketchfab Nissan 370Z visual models

The following third-party GLB files are included under the uploader's stated **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International** license. They and their direct adaptations are expressly excluded from the repository's root `LICENSE`.

### 2013 Nissan 370Z

- author: Ddiaz Design (`ddiaz-design`);
- source: https://sketchfab.com/3d-models/2013-nissan-370z-11db2d5c2cd34c8b84e560b8090574e8;
- included untouched GLB: `assets/third_party/sketchfab/nissan_370z_2013/2013_nissan_370z.glb`;
- uploader-stated license: CC BY-NC-SA 4.0 — https://creativecommons.org/licenses/by-nc-sa/4.0/;
- uploader-stated provenance: "Based on a Need For Speed Mobile 3d model" with an external Vertex Warehouse credit.

### 2015 Nissan 370Z Nismo (Z34)

- author: Ddiaz Design (`ddiaz-design`);
- source: https://sketchfab.com/3d-models/2015-nissan-370z-nismo-z34-b66ac30ac64a4f1aa034fce37745abe3;
- included untouched GLB: `assets/third_party/sketchfab/nissan_370z_nismo_2015/2015_nissan_370z_nismo_z34.glb`;
- uploader-stated license: CC BY-NC-SA 4.0 — https://creativecommons.org/licenses/by-nc-sa/4.0/;
- uploader-stated provenance: "Based on a Real Racing 3 3d model" with an external archive credit.

### Project modifications

The Nissan GLB geometry and embedded textures are preserved as downloaded. The game applies technical integration changes in Godot wrapper scenes: a uniform `100` scale, a `180`-degree Y-axis rotation, vertical ground alignment and composition with independently authored collision, controller and procedural-audio nodes.

The canonical Nissan GLB files exist only at the paths listed above; duplicate source mirrors are not retained in the repository.

Redistributed copies or builds containing these assets must provide attribution to Ddiaz Design, link the relevant Sketchfab source and CC BY-NC-SA 4.0 license, identify the modifications, remain noncommercial and preserve ShareAlike for adapted model material. Detailed scope and attribution wording are recorded in `assets/third_party/sketchfab/README.md`.

### Rights-chain limitation

Creative Commons licenses grant only rights the licensor has authority to grant. The uploader's statements that these models are based on assets from commercial games create an unresolved upstream-rights risk. This repository contains no written authorization from the original game publishers or asset rights holders and makes no representation that all geometry, textures, logos or trade dress are fully cleared for redistribution.

The project owner has directed their inclusion in this noncommercial prototype with this warning. Noncommercial use alone does not resolve a missing upstream license.

### Accepted project decision

The owner has explicitly accepted this known Nissan limitation for the current private/noncommercial prototype because no suitable replacement assets are available and there is no commercialization plan. The decision, audit treatment and mandatory review triggers are recorded in `docs/accepted_risks.md`.

This accepted-risk record does not claim full rights clearance. It means ordinary technical audits should not report the unchanged Nissan provenance limitation as a new remediation item unless a documented review trigger occurs.

## Additional Sketchfab models with incomplete or restrictive repository provenance

The repository also contains external GLB assets whose source pages are documented in model-specific integration notes, but which are not covered by the BMW or Nissan Creative Commons statements above.

These entries are **not** recorded as accepted risks in `docs/accepted_risks.md`.

### 1967 Ford Mustang Shelby G.T. 500

- included GLB: `1967_ford_mustang_shelby_cobra_gt500.glb`;
- source page: https://sketchfab.com/3d-models/1967-ford-mustang-shelby-cobra-gt500-e310cc7537bf4d1aa644a2c233a5fec6;
- integration record: `docs/cars/ford_mustang_shelby_gt500_1967.md`;
- author: not recorded in the repository;
- license: not recorded in the repository;
- current use: source visual model for the playable 1967 Shelby G.T. 500 scenes.

### 1995 Fiat Punto GT / Type 176

- included GLB: `free_1995_fiat_punto_gt.glb`;
- source page: https://sketchfab.com/3d-models/free-1995-fiat-punto-gt-48db6facb4b64e99b60f36b8c01185e1;
- integration record: `docs/cars/fiat_punto_1995.md`;
- author: not recorded in the repository;
- license: not recorded in the repository;
- current use: source visual model shared by the playable and AI-eligible Fiat Punto Type 176 variants.

### 1993 FSO Polonez Caro MR'93

- included GLB: `1993_fso_polonez_caro_mr93_lp_new.glb`;
- source page: https://sketchfab.com/3d-models/1993-fso-polonez-caro-mr93-lp-new-f67c26c7db354b10b203c7e2f157467d;
- author/uploader: Krzysztof Stolorz (`KrStolorz`);
- displayed source license: Sketchfab **Free Standard**, not Creative Commons;
- integration records: `docs/cars/fso_polonez_caro_mr93_runtime.md` and `docs/cars/fso_polonez_caro_mr93_asset_notice.md`;
- current use: detailed visual body shared by seven playable and AI-eligible Polonez Caro MR'93 variants.

Sketchfab's standard terms restrict standalone or extractable redistribution. The raw Polonez GLB is therefore not treated as cleared for public source or binary redistribution. The project needs separate written permission covering redistribution, another applicable license, or replacement/removal of the asset. Its technical integration does not broaden the underlying rights.

### Distribution status of incomplete or restrictive records

Until the repository records an applicable license, written permission or an explicit accepted-risk decision covering each asset and its intended distribution:

- no contributor should describe these models as rights-cleared, freely reusable or covered by the repository's root `LICENSE`;
- no public binary/source redistribution should assume permission to include these files;
- no commercialization or external distribution decision should rely on the fact that the assets were downloadable from Sketchfab;
- the assets should be relocated into a clearly identified third-party asset directory only together with complete path updates and a verified provenance record;
- removal or replacement remains the safe option if acceptable permission cannot be demonstrated and no accepted-risk exception applies.

This section records documentation and rights-verification gaps. It does not infer license terms from a model title, page availability or the word "free" in a filename.

## Sketchfab Traffic Rider NPC vehicle bundle

The repository contains 20 individually extracted non-heavy vehicle GLBs from a combined asset identified by embedded metadata as **Traffic Rider NPC Vehicles**.

- uploader shown in embedded metadata: Mason (`ModelzRipper`);
- source page: https://sketchfab.com/3d-models/traffic-rider-npc-vehicles-61f8508a366d41e3b3a40c4b54f7a03a;
- uploader-stated embedded license: CC BY-NC 4.0 — https://creativecommons.org/licenses/by-nc/4.0/;
- included files and model inventory: `docs/assets/traffic_rider_npc_vehicle_inventory.md`;
- integration procedure: `docs/assets/traffic_rider_npc_vehicle_import_workflow.md`;
- intended project use: NPC traffic vehicles in the private, noncommercial prototype;
- excluded source models: Scania heavy truck, generic articulated truck and generic rigid truck.

The source GLBs and any direct geometry derivatives are expressly excluded from the repository's root `LICENSE`. Attribution to Mason / `ModelzRipper`, the Sketchfab source page and the uploader-stated CC BY-NC 4.0 terms must remain with redistributed project copies containing these files.

### Rights-chain limitation

The bundle title and content identify the models as originating from the commercial game *Traffic Rider*. The repository contains no evidence that the uploader owns the upstream game assets or was authorized by the relevant upstream rights holder to license or redistribute them.

The uploader-stated Creative Commons metadata is recorded for traceability but is not treated as proof of a complete upstream rights chain. Noncommercial use does not by itself resolve that limitation. This project does not represent the assets as rights-cleared, project-authored or freely reusable by downstream parties.

### Accepted project decision

The owner has explicitly directed the project to retain and integrate the 20 committed source GLBs for the current personal, private-purpose and noncommercial prototype while preserving this warning and attribution. The owner accepts the unresolved upstream provenance risk for that scope.

The exact accepted scope, audit treatment and review triggers are recorded in `docs/accepted_risks.md`. Inclusion in this repository records the owner's risk decision; it does not grant additional rights to the project or downstream users.

## AssettoWorld Suzuka circuit assets

The Suzuka circuit package and the converted Godot assets derived from it are third-party materials sourced from AssettoWorld. They are not original project assets and are expressly excluded from the repository's root `LICENSE`.

- asset: Suzuka circuit for Assetto Corsa;
- source page: https://www.assettoworld.com/track/suzuka;
- supplied archive: `ac_suzuka_v.1.0.rar`;
- source platform named by the project owner: AssettoWorld;
- permission basis: the project owner reports that AssettoWorld's operators stated that files supplied through their site may be used, modified and redistributed for any noncommercial purpose;
- permitted project use: noncommercial modification, format conversion, integration and redistribution;
- prohibited use: commercial use, monetized distribution, paid access, advertising-supported distribution, sponsorship use and commercial licensing;
- attribution: redistributed copies must identify AssettoWorld as the source and link the source page above;
- license boundary: the assets are provided under this source-specific noncommercial permission statement, not under CC BY, CC BY-SA or the repository's root license.

The conversion to glTF/PNG, collision grouping, racing-line extraction and Godot integration do not transfer authorship of the underlying geometry, textures or source track data to this project. Project-authored scripts and configuration remain separately governed by the repository license, while the imported and converted track content remains subject to the AssettoWorld noncommercial restriction.

The permission record and required notice wording are documented in `docs/suzuka_asset_permission.md`. Any downstream copy containing the Suzuka assets must preserve that file or an equivalent notice.

## Contribution policy

Before committing any additional external model, texture, sound, font, logo or other asset, this file must record:

- the asset name and repository path;
- its author or rights holder;
- the original source;
- the applicable license or written permission;
- required attribution;
- any restrictions on modification, redistribution or commercial use;
- known provenance limitations or unresolved rights-chain concerns.

Contributors must not describe an external asset as rights-cleared unless the repository contains a demonstrable license or permission covering the submitted material. Unverified provenance must be disclosed explicitly rather than inferred from a download label.

When an asset with incomplete provenance is intentionally retained, the owner must separately decide whether to remove it, complete the license record or add a dated accepted-risk entry with explicit scope and review triggers. One asset's accepted-risk decision never applies automatically to another asset.
