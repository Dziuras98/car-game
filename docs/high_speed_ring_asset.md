# High Speed Ring asset import

## Source analysis

The downloaded Sketchfab GLB is 68,264,572 bytes and contains 127 mesh nodes,
100 materials, 108 embedded PNG textures, 209,125 vertices and 192,344
triangles. Its imported scene bounds are approximately 3,985 × 364 × 3,985
units. Most node and material names are automatically generated, so a semantic
split into road, terrain and props cannot be made reliably from metadata alone.

## Split strategy

`tools/track_import/split_high_speed_ring.py` groups mesh nodes by their material
set and applies deterministic first-fit-decreasing bin packing. It copies only
the accessor ranges and texture buffer views required by each output scene.
This avoids carrying the source model's large shared geometry buffers into every
part.

The generated files are `part_001.glb` through `part_017.glb`. Every part is
below 5 MiB; actual sizes range from about 3.3 to 4.3 MiB. The manifest records
hashes, source nodes, material names and geometry counts.

Rebuild with:

```text
python tools/track_import/split_high_speed_ring.py path/to/high_speed_ring.glb
```

The splitter uses only the Python standard library.

## Validation

The generated parts were loaded independently with `trimesh`. Combined results
match the source exactly:

- mesh nodes: 127 / 127;
- vertices: 209,125 / 209,125;
- triangles: 192,344 / 192,344;
- combined scene bounds: unchanged.

## Runtime status

`HighSpeedRingVisualLoader` loads all available fragments at their source
transform. The asset is visual-only at this stage. A playable track still needs
a project-authored collision surface, start grid, checkpoints, racing line and
AI navigation data; the imported render meshes should not be used directly as
high-poly concave gameplay collision.
