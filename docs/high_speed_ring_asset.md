# High Speed Ring asset import

## Runtime integration

High Speed Ring is selectable in free drive and race modes. The committed GLB fragments remain visual-only; deterministic gameplay geometry is generated through the existing track pipeline.

The source asphalt mask and banking were analysed directly from the downloaded model. The resulting runtime layout contains:

- 84 source-derived control points;
- an approximately 4.03 km generated lap;
- a start line at the project origin, leaving along positive X;
- a source-derived road-width profile ranging from approximately 15 to 28 m;
- a source-derived banking profile constrained to the generated-track contract of ±20 degrees;
- checkpoints at 20%, 40%, 60% and 80% of lap progress;
- procedural road collision, shoulders, barriers and AI racing-line data.

The 3D model already uses the project scale and orientation. `HighSpeedRingVisualLoader` therefore preserves the source transform and applies only a 0.03 m vertical separation to prevent the imported render road from z-fighting with the procedural collision surface.

## Source analysis

The downloaded Sketchfab GLB is 68,264,572 bytes and contains 127 mesh nodes, 100 materials, 108 embedded PNG textures, 209,125 vertices and 192,344 triangles. Its imported scene bounds are approximately 3,985 × 364 × 3,985 units.

Most node and material names are automatically generated, so a semantic split into road, terrain and props cannot be made reliably from metadata alone.

## Split strategy

`tools/track_import/split_high_speed_ring.py` groups mesh nodes by their material set and applies deterministic first-fit-decreasing bin packing. It copies only the accessor ranges and texture buffer views required by each output scene. This avoids carrying the source model's large shared geometry buffers into every part.

The generated files are `part_001.glb` through `part_017.glb`. Every part is below 5 MiB; actual sizes range from about 3.3 to 4.3 MiB. `assets/tracks/high_speed_ring/split_manifest.json` records hashes, source nodes, material names and geometry counts.

Rebuild with:

```text
python tools/track_import/split_high_speed_ring.py path/to/high_speed_ring.glb
```

The splitter uses only the Python standard library.

## Validation and collision policy

The generated parts were loaded independently with `trimesh`. Combined results match the source exactly:

- mesh nodes: 127 / 127;
- vertices: 209,125 / 209,125;
- triangles: 192,344 / 192,344;
- combined scene bounds: unchanged.

The imported GLBs must not be used directly as high-poly concave gameplay collision. Runtime collision, barriers, checkpoints and AI navigation are authored by the deterministic generated-track layer so grip, racing logic and packaged behaviour remain stable.
