# Third-party source models

This directory is a staging area for original third-party model downloads. It is intentionally excluded from Godot imports by the adjacent `.gdignore` file.

Keep downloaded source files unmodified here. Optimized runtime assets belong under `assets/cars/` only after geometry, materials, licensing and provenance have been reviewed.

## Upload locations

- Standard 370Z: `sketchfab/nissan_370z_2013/2013_nissan_370z_original.glb`
- 370Z NISMO: `sketchfab/nissan_370z_nismo_2015/2015_nissan_370z_nismo_z34_original.glb`

For every downloaded model, retain:

- the original GLB without edits;
- the source page URL;
- author attribution;
- the exact license name and version;
- a copy of any license or attribution text supplied with the download;
- notes describing later modifications.

Do not assume that the repository's main license applies to files in this directory. Every third-party asset retains its own license.

GitHub rejects individual files larger than 100 MB. Use Git LFS before committing a larger model or texture file.