# Track layout resources

Generated-track layout data is Resource-backed and admitted through typed validation before it can replace committed runtime geometry.

## Authoritative data path

```text
TrackCatalog
  -> TrackDefinition
    -> GeneratedTrack scene
      -> TrackLayoutResource
        -> TrackGenerationConfig
          -> TrackLayoutBuilder / TrackCheckpointBuilder
            -> TrackGeometryData / TrackCheckpointGate
              -> GeneratedTrack committed revision
```

The catalog currently references:

```text
resources/tracks/simple_oval_definition.tres
  -> resources/tracks/simple_oval.tres

resources/tracks/tor_poznan_definition.tres
  -> resources/tracks/tor_poznan.tres
```

`resources/tracks/catalog.tres` is the authoritative list and owns `default_track_id = simple_oval`.

## `TrackLayoutResource` ownership

A layout resource stores or references:

- stable track ID and display name;
- recommended lap-count metadata;
- closed-loop control points;
- samples per spline segment;
- base road width and optional lap-progress width profile;
- shoulder widths and optional progress profile;
- grass/runoff and barrier dimensions;
- optional barrier-distance and barrier-visibility profiles;
- optional racing-line offset profile;
- optional banking/crossfall profile;
- ordered checkpoint progress values;
- checkpoint gate depth, height and width margin;
- generic stadium/decoration settings;
- track-specific environment settings consumed by dedicated builders.

Runtime-safe values are copied into `TrackGenerationConfig`. Builders do not read mutable layout resources directly while generating committed geometry.

## Current tracks

### Simple oval

```text
resources/tracks/simple_oval.tres
scenes/tracks/simple_oval.tscn
```

The oval uses 18 control points and six samples per segment, producing a 108-point closed loop. It retains the generic curvature-driven width variation path: local horizontal curvature is converted through a bounded smoothstep response so corners widen while straights remain near the base width.

Its checkpoint progress values are `0.25`, `0.50` and `0.75`, producing three intermediate gates plus start/finish.

### Tor Poznań

```text
resources/tracks/tor_poznan.tres
scenes/tracks/tor_poznan.tscn
```

The production reconstruction currently uses:

- 240 source control points and 480 generated samples;
- a centerline calibrated to a 4083-metre lap;
- nominal 12-metre road width;
- progress-based shoulder, barrier, racing-line and banking profiles;
- twelve intermediate checkpoint gates plus start/finish;
- generated curbs and a dedicated pit/trackside environment;
- a drivable pit entry, pit lane and pit exit;
- pit buildings, control tower, gantry, grandstands, paddock and batched forest;
- a configured opening in the procedural pit-side barrier.

The reconstruction boundaries and accuracy claims are documented in `docs/tor_poznan_reconstruction.md`.

## Typed generation and profiles

`TrackLayoutBuilder.build(config)` consumes a `TrackGenerationConfig`. Control points and sampling density come from the referenced `TrackLayoutResource`; runtime-safe copies provide sanitized road, shoulder, barrier, racing-line, banking and decoration values.

Profile values are sampled by normalized lap progress. Loop profiles must be continuous at the `0.0`/`1.0` boundary. Validation rejects malformed progress/value arrays rather than silently falling back to unrelated layout defaults.

The builder can combine:

- a base road width;
- curvature-driven width variation;
- an explicit progress-based road-width profile;
- left/right shoulder profiles;
- barrier offset and visibility profiles;
- racing-line lateral offsets;
- banking/crossfall values.

The resulting center, tangent, right-vector, width and edge arrays are stored in `TrackGeometryData` and shared by render, collision, checkpoints, AI, minimap and lap projection.

## Geometry admission

`TrackGeometryData.validate()` is the final topology boundary before generated geometry can be committed. It rejects:

- missing or mismatched geometry arrays;
- non-finite values, degenerate center segments and collapsed or reversed road edges;
- invalid tangent/right-vector frames;
- curves whose sampled circumradius is too small for the local road half-width;
- self-intersections of the sampled center line;
- intersections between non-adjacent road-edge segments;
- non-adjacent center segments that do not preserve width-aware road clearance.

The clearance check uses both segments' maximum local half-widths plus a fixed safety margin. This prevents a spline from producing overlapping asphalt even when its center lines do not mathematically cross.

Generation is transactional. Builders create detached staged content. A failed validation does not replace the currently committed geometry, publish a geometry revision or disturb consumers using the last valid track.

## Generated surfaces and environment

Asphalt, shoulder and grass geometry share their generated render/collision source and use typed `TrackSurfaceBody` collision bodies with explicit grip multipliers.

Repeated edge markers, barriers, curbs, forest elements and generic stadium objects use bounded `MultiMesh` groups where applicable. Track-specific environment builders may add pit lanes, buildings, grandstands or exclusions, but those objects remain part of the staged generated-content transaction.

Collision surfaces used as vehicle ground support must satisfy the typed `TrackSurfaceBody` contract. Decorative or barrier bodies cannot become suspension support accidentally.

## Checkpoint sequence

`TrackCheckpointBuilder` maps ordered progress values onto sampled center-line points and creates `Area3D` gates. Gate `0` is start/finish; subsequent gates follow the resource order.

Each gate is aligned to the local track tangent. A crossing is forward only when the car's world velocity has a positive component along that tangent.

`LapTracker` starts by expecting checkpoint `1`. It advances only through the ordered sequence and arms the finish line after the last checkpoint. A lap is completed only by a forward crossing of gate `0` after the complete sequence.

Reverse crossings, skipped checkpoints, duplicate finish crossings and finish crossings after a track cut are rejected. Racing-line projection remains available only for race-position sorting and never authorizes lap completion.

## Continuous progress projection

`RacingLineProjector` performs one global acquisition when a participant is registered. Normal updates search a dynamic, wrapped window around the participant's previous racing-line segment instead of scanning the complete sampled loop.

This preserves topological continuity on hairpins, parallel straights and other places where a spatially closer segment may be much farther around the lap. The search falls back to a global acquisition when:

- no previous projection exists;
- the stored segment index is no longer valid;
- participant displacement indicates a teleport or reset;
- the local window cannot reacquire the racing line within its bounded distance;
- committed track geometry is rebuilt.

The local window expands with participant displacement but remains capped. Its normal per-participant cost therefore does not grow with the total number of racing-line samples.

## Geometry rebuild policy

A successful `GeneratedTrack` rebuild publishes a new geometry revision. AI, minimap and lap tracking replace their geometry-dependent caches.

`LapTracker` discards projection continuity and globally reprojects each valid participant against the newly committed loop. Completed laps are preserved. Every committed geometry revision resets unfinished checkpoint sequences before projection is reacquired, preventing partial progress from obsolete geometry from authorizing a finish crossing.

Repeated rebuild requests are deferred and coalesced. A generation signature prevents unchanged layout/configuration requests from rebuilding meshes and collision.

During an active gameplay session, generated-track mutation is locked. Layout-change requests are coalesced and deferred until the session releases the lock. Failed generation does not emit a revision and leaves both committed track and race state unchanged.

## Menu metadata

`MenuOptionsBuilder` builds track options from `TrackDefinition`/layout metadata. The visible label, selected track ID and recommended lap metadata therefore come from the same catalog-backed source as the generated scene and checkpoint data.

There is no first-entry fallback. `TrackCatalog.default_track_id` is the only default-track declaration, and invalid catalog/definition/layout combinations block startup.

## Regression coverage

Relevant coverage includes:

```text
scenes/tests/track_layout_builder_test.tscn
scenes/tests/track_layout_resource_test.tscn
scenes/tests/lap_tracker_checkpoint_test.tscn
scenes/tests/lap_tracker_progress_test.tscn
scripts/tests/track_geometry_topology_validation_test.gd
scripts/tests/racing_line_projector_test.gd
scripts/tests/track_selection_runtime_test.gd
scripts/tests/tor_poznan_layout_test.gd
scripts/tests/tor_poznan_environment_test.gd
```

Coverage includes:

- resource sequence and loop-profile continuity rules;
- curvature-driven and progress-based geometry values;
- minimum curve radius, center/edge self-intersection rejection and width-aware clearance;
- generated gate count and crossing direction;
- rejected cuts and duplicate finishes;
- sub-segment position ordering and bounded projection cost;
- continuity across adjacent non-local track sections and teleport reacquisition;
- atomic rebuilds, generation revision propagation and active-session rebuild locking;
- Tor Poznań length, width, orientation, checkpoint, pit/environment, batched forest/curb and barrier-opening contracts.

All tests run in the required Windows CI suite.
