# 1967 Ford Mustang Shelby GT500 source asset

## Source

- Original model: https://sketchfab.com/3d-models/1967-ford-mustang-shelby-cobra-gt500-e310cc7537bf4d1aa644a2c233a5fec6
- Current repository file: `res://1967_ford_mustang_shelby_cobra_gt500.glb`
- Integration state: visual foundation only

The binary GLB remains in the repository root during this phase because it was uploaded there directly. The visual wrapper references that path explicitly. A later asset-cleanup change should relocate the binary into this directory and update the wrapper in the same commit.

## Required follow-up before gameplay integration

1. Record the exact Sketchfab license and author attribution from the downloaded package metadata.
2. Inspect and document the imported node hierarchy, especially all four wheel, tyre, rim, brake-disc and caliper assemblies.
3. Measure the imported bounds and establish the authoritative scale, forward axis, origin and ground offset.
4. Verify materials, transparency, normals, texture import settings and shadow behaviour in Godot.
5. Remove decorative or hidden geometry that has no visible contribution in the game camera.
6. Create explicit model-specific wheel bindings before attaching `CarVisualController`.

Do not add this car to `resources/cars/catalog.tres` until the visual bindings, collision scene and at least one complete `CarSpecs`/variant pair are valid.
