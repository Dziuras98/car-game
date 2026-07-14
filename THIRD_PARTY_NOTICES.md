# Third-Party Names and Assets

This project is unofficial and is not sponsored, endorsed by or affiliated with Nissan Motor Co., Ltd., Fiat S.p.A./Stellantis, Ford Motor Company, Shelby American, Electronic Arts, Firemonkeys Studios or any other vehicle manufacturer, publisher, studio or asset author named below.

Names such as "Nissan", "370Z", "Fiat", "Punto", "Ford", "Mustang", "Shelby", "G.T. 500", "Need for Speed" and "Real Racing" are used descriptively. All product names, trademarks, logos and trade dress remain the property of their respective owners. The repository license and any third-party asset license described below do not grant trademark rights.

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

## Additional Sketchfab models with incomplete repository provenance records

The repository also contains two external GLB assets whose source pages are documented in model-specific integration notes, but whose author attribution and license terms are not currently recorded in this repository.

These entries are **not** covered by the Nissan CC BY-NC-SA statement above and are **not** recorded as accepted risks in `docs/accepted_risks.md`.

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

### Distribution status of incomplete records

Until the repository records the uploader/author, exact license, required attribution and any provenance limitations for each asset:

- no contributor should describe either model as rights-cleared, freely reusable or covered by the repository's root `LICENSE`;
- no public binary/source redistribution should assume permission to include these files;
- no commercialization or external distribution decision should rely on the fact that the assets were downloadable from Sketchfab;
- the assets should be relocated into a clearly identified third-party asset directory only together with complete path updates and a verified provenance record;
- removal or replacement remains the safe option if acceptable permission cannot be demonstrated.

This section records a documentation and rights-verification gap. It does not infer license terms from a model title, page availability or the word "free" in a filename.

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