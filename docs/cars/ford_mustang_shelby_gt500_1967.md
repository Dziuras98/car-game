# Ford Mustang Shelby GT500 (1967)

## Phase scope

This change establishes the visual and file-layout foundation for the 1967 Shelby GT500. It does not create a playable catalog variant and does not define engine, gearbox, suspension, tyre or audio tuning.

The source model was uploaded as:

```text
res://1967_ford_mustang_shelby_cobra_gt500.glb
```

Original source:

https://sketchfab.com/3d-models/1967-ford-mustang-shelby-cobra-gt500-e310cc7537bf4d1aa644a2c233a5fec6

## Added visual structure

```text
scenes/cars/
  mustang_shelby_gt500_1967_visuals.tscn
  mustang_shelby_gt500_1967_low_detail_visuals.tscn
scenes/dev/
  mustang_shelby_gt500_1967_visual_preview.tscn
scripts/dev/
  car_model_visual_preview.gd
```

The detailed wrapper isolates source-model alignment under `ModelAlignment`. Scale, orientation and ground alignment can therefore be corrected without modifying the imported GLB.

The low-detail scene provides a deliberately inexpensive silhouette and exposes the standard wheel node names expected by `CarVisualController`:

- `WheelFrontLeft`;
- `WheelFrontRight`;
- `WheelRearLeft`;
- `WheelRearRight`.

Its geometry is an initial visual approximation, not an authoritative dimensional model.

## Preview workflow

Open and run:

```text
res://scenes/dev/mustang_shelby_gt500_1967_visual_preview.tscn
```

The preview script collects all imported `MeshInstance3D` bounds, frames the model automatically and places the ground plane under the lowest visual point. This makes scale and orientation defects visible even when the GLB imports at an unexpected unit scale.

## Deliberate exclusions

The following are intentionally deferred:

1. relocating the binary GLB from the repository root;
2. exact source scale, forward-axis and ground-offset correction;
3. imported material and texture cleanup;
4. explicit detailed-wheel bindings;
5. player and AI scenes;
6. collision volumes;
7. catalog model and variant resources;
8. authoritative mechanical specifications and torque curve;
9. engine audio profile and synthesis calibration;
10. catalog, runtime and visual regression tests.

The car must not be added to `resources/cars/catalog.tres` before at least one complete variant passes catalog validation.

## Next visual phase

The next change should inspect the imported scene tree in Godot and record exact node paths for each wheel assembly. A model-specific `CarVisualController` subclass should then bind four logical wheels explicitly, with front steering-only brake components separated from rotating tyre/rim/disc components. After that, the detailed and low-detail roots can be connected to the standard screen-visibility LOD policy.
