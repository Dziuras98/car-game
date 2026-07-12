# Sketchfab vehicle models

The two GLB files below are third-party visual assets. They are not covered by the repository's root `LICENSE`.

| Asset | Author | Original source | Runtime path |
|---|---|---|---|
| 2013 Nissan 370Z | Ddiaz Design (`ddiaz-design`) | https://sketchfab.com/3d-models/2013-nissan-370z-11db2d5c2cd34c8b84e560b8090574e8 | `nissan_370z_2013/2013_nissan_370z.glb` |
| 2015 Nissan 370Z Nismo (Z34) | Ddiaz Design (`ddiaz-design`) | https://sketchfab.com/3d-models/2015-nissan-370z-nismo-z34-b66ac30ac64a4f1aa034fce37745abe3 | `nissan_370z_nismo_2015/2015_nissan_370z_nismo_z34.glb` |

## Asset license

The Sketchfab API identifies both downloads as licensed under **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)**:

https://creativecommons.org/licenses/by-nc-sa/4.0/

Subject to the rights actually held by the licensor, this permits copying and adapting the assets only for noncommercial purposes. Attribution, a license reference and an indication of modifications are required. Adapted material must be offered under CC BY-NC-SA 4.0 or a compatible license, and no additional legal or technological restrictions may be applied to the licensed material.

This license applies to the listed GLB files and to copyrightable project contributions that directly adapt those files. It does not relicense the game's source code, data, audio, user interface, track assets or other independently authored material.

The project must not sell, rent, sublicense, monetize with advertising, place behind paid access, use for sponsorship or otherwise use these models primarily for commercial advantage or monetary compensation without separate permission covering that use.

## Changes made for this project

The downloaded GLB payloads are preserved without geometry or texture edits. Godot wrapper scenes apply only technical placement changes:

- uniform source scale of `100`;
- rotation of `180` degrees around the Y axis so the vehicle faces the project's `-Z` forward direction;
- a vertical translation to place the tyres on the gameplay ground plane;
- integration with independently authored collision, controller and procedural-audio nodes.

The GLB files in this directory are the untouched downloaded payloads and are used directly by Godot. Keeping one canonical copy avoids repository duplication; all project-specific placement and integration remains in wrapper scenes.

## Required attribution for redistributed builds

A redistributed build containing either model must retain, in a reasonably accessible credits or notices location:

- the model title;
- `Ddiaz Design` as author;
- the corresponding Sketchfab source URL;
- `CC BY-NC-SA 4.0` and the license URL;
- the project modifications listed above;
- the provenance warning below.

## Provenance warning

The uploader's own descriptions state that the standard 370Z is "Based on a Need For Speed Mobile 3d model" and that the NISMO model is "Based on a Real Racing 3 3d model". No written permission from the upstream game publishers or original asset rights holders is present in this repository.

A Creative Commons license grants only rights that the licensor has authority to grant. Consequently, the CC BY-NC-SA label does not independently establish that Ddiaz Design can license all underlying geometry, textures, logos or trade dress. Inclusion in this noncommercial prototype is not a representation of complete upstream rights clearance. Obtain written permission or replace these assets before any release where verified redistribution rights are required.

Nissan names, badges and vehicle trade dress are not licensed by CC BY-NC-SA 4.0 and remain subject to the rights of their respective owners. This project is unofficial and is not sponsored, endorsed by or affiliated with Nissan, Electronic Arts, Firemonkeys Studios or their affiliates.
