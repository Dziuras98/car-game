# Krótki Tor Pustynny / Short Desert Track

## Current integration stage

The first integration stage creates a fully selectable and race-capable procedural proxy derived from the uploaded `Race Track Map` GLB.

- source road mesh analysed: 64,680 triangles;
- source scene bounds: approximately 96.9 × 7.9 × 80.6 model units;
- extracted closed centreline: approximately 219 source units;
- applied scale correction: `5.0`;
- resulting lap length: approximately 1.10 km;
- start line aligned to the project convention: origin, forward along negative Z;
- generated road width: 18 m;
- checkpoints: 20%, 40%, 60% and 80%;
- supported modes: free drive and race.

The source model contains approximately 607,000 triangles and a 72 MB embedded GLB. The initial stage intentionally does not commit that full visual asset. Instead, the existing deterministic track-generation pipeline supplies road mesh, collision, barriers, checkpoints and AI racing-line data, while `DesertGeneratedTrack` replaces grass and roadside materials with sand surfaces.

## Follow-up work

A later visual pass can import an optimized version of the original scenery, with collision proxies separated from decorative geometry and large textures reduced or externalized. That pass should preserve the scale, origin, orientation and attribution established here.
