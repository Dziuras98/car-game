# Short Desert Track source notice

The visual assets and layout of **Krótki Tor Pustynny / Short Desert Track** are adapted from the following third-party Sketchfab model:

- title: `Race Track Map`;
- author/uploader: Mabaso_J (`pgs_jayb3e`);
- source: https://sketchfab.com/3d-models/race-track-map-c9f923f05b7443b6b55f0f2a19e0cb48;
- source publication date shown by Sketchfab: May 29, 2026;
- uploader-stated license: Creative Commons Attribution 4.0 International;
- license: https://creativecommons.org/licenses/by/4.0/.

The original 72 MB GLB is converted into six logical GLB scene groups under `models/`: track surfaces, fences, barriers, buildings, vehicles and vegetation. This split preserves source node transforms, materials and embedded textures while allowing every repository file to remain below 15 MiB. A manifest records source and output SHA-256 hashes.

Project modifications include safe duplicate-vertex cleanup, centreline extraction from the source road mesh, five-times scale correction, rotation and translation to the project's start-line convention, control-point resampling, and composition with project-authored collision, checkpoint and race systems. These changes do not transfer authorship of the underlying model.

Redistributed copies or builds containing the split GLB files must credit Mabaso_J, link the source page and CC BY 4.0 license, and identify that the asset was split, optimized and adapted for Godot runtime use. This notice and the corresponding entry in `THIRD_PARTY_NOTICES.md` must be preserved.
