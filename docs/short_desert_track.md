# Krótki Tor Pustynny / Short Desert Track

## Runtime layout

The track is selectable in free drive and race modes. Its procedural layer supplies deterministic road collision, barriers, checkpoints and AI racing-line data.

- source road mesh analysed: 64,680 triangles;
- extracted closed centreline: approximately 219 source units;
- scale correction: `5.0`;
- resulting lap length: approximately 1.10 km;
- start line: project origin, forward along negative Z;
- generated road width: 18 m;
- checkpoints: 20%, 40%, 60% and 80%.

## Split visual model

The uploaded 72,406,464-byte GLB is divided by scene function rather than by arbitrary byte ranges. All six visual parts are stored directly in `assets/tracks/short_desert_track/`:

| File | Size | Contents |
| --- | ---: | --- |
| `track_surface.glb` | 13.3 MiB | road, lines, kerbs and terrain |
| `fences.glb` | 11.8 MiB | track fencing |
| `barriers.glb` | 6.7 MiB | banks and perimeter barriers |
| `buildings.glb` | 8.0 MiB | buildings, start and finish props |
| `vehicles.glb` | 2.3 MiB | source-scene vehicles |
| `vegetation.glb` | 1.5 MiB | trees and vegetation bases |

Every part preserves its source transforms and materials. `ShortDesertVisualLoader` applies one common transform to all six files: a five-times scale, 90-degree Y rotation and translation to the procedural start line. The loader tolerates missing parts, so the procedural track remains playable if a visual part is removed.

`assets/tracks/short_desert_track/split_manifest.json` records the source hash, expected output hashes, object counts and triangle counts. The split can be reproduced with:

```text
python tools/track_import/split_short_desert_track.py path/to/race_track_map.glb
```

The utility requires Python 3.10+ and `trimesh`.

## Collision policy

The imported GLBs are visual assets only. Gameplay collision continues to come from the project-authored procedural track pipeline. This avoids using the approximately 607,000-triangle source scene as concave runtime collision and keeps surface grip, checkpoint sequencing and AI navigation deterministic.
