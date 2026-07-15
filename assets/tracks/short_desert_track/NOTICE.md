# Short Desert Track source notice

The layout of **Krótki Tor Pustynny / Short Desert Track** is adapted from the following third-party Sketchfab model:

- title: `Race Track Map`;
- author/uploader: Mabaso_J (`pgs_jayb3e`);
- source: https://sketchfab.com/3d-models/race-track-map-c9f923f05b7443b6b55f0f2a19e0cb48;
- source publication date shown by Sketchfab: May 29, 2026;
- uploader-stated license: Creative Commons Attribution 4.0 International;
- license: https://creativecommons.org/licenses/by/4.0/.

The initial repository integration extracts and adapts the circuit centreline, scale and proportions from the supplied GLB. It uses project-authored procedural road, collision, checkpoint, barrier and desert-surface generation rather than redistributing the original 72 MB GLB.

Modifications include centreline extraction from the source road mesh, approximately five-times scale correction based on the source scene vehicles, rotation and translation to the project's start-line convention, control-point resampling, and procedural Godot runtime generation.

This notice and the corresponding entry in `THIRD_PARTY_NOTICES.md` must be preserved in redistributed copies containing this adapted track layout.
