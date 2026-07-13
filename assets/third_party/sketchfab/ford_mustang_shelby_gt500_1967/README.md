# 1967 Shelby G.T. 500 source asset

## Source

- Original model: https://sketchfab.com/3d-models/1967-ford-mustang-shelby-cobra-gt500-e310cc7537bf4d1aa644a2c233a5fec6
- Current repository file: `res://1967_ford_mustang_shelby_cobra_gt500.glb`
- Runtime wrapper: `res://scenes/cars/mustang_shelby_gt500_1967_visuals.tscn`
- Integration state: player-runtime visual contract complete

The GLB remains in the repository root because it was uploaded there directly. Relocation into this directory must update every Godot path in the same commit.

## Verified import data

The headless Godot hierarchy inspection established:

- 71 render meshes;
- source unit conversion: 100×;
- corrected project transform: X and Z axes inverted, Y preserved;
- measured rendered bounds after conversion: approximately 1.7936 × 1.3534 × 4.8189 m;
- measured wheelbase from tyre centres: approximately 2.7437 m;
- four separately addressable tyre, wheel and brake-rotor groups;
- separately addressable front brake calipers.

`MustangShelbyGT5001967VisualController` binds all four detailed wheel assemblies explicitly. The front calipers follow steering without spinning; rear brake hardware remains fixed. The wrapper also supplies the standard screen-visibility LOD policy and a four-wheel low-detail fallback.

## Remaining asset work

1. Record the exact Sketchfab licence and author attribution from the original downloaded package metadata.
2. Verify transparency, normals, imported textures and shadow behaviour under representative gameplay lighting.
3. Relocate the GLB into this directory in an atomic path-update commit.
4. Remove geometry only after profiling proves that it has no visible contribution and the 71-mesh regression is intentionally updated.
