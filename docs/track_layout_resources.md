# Track layout resources

Generated-track layout data is Resource-backed and admitted through typed validation before it can replace committed runtime geometry.

## Authoritative data path

```text
resources/tracks/simple_oval.tres
    -> TrackLayoutResource
    -> TrackGenerationConfig
    -> TrackLayoutBuilder / TrackCheckpointBuilder
    -> TrackGeometryData / TrackCheckpointGate
    -> GeneratedTrack committed revision
```

`TrackLayoutResource` stores:

- stable track ID and display name;
- recommended lap count metadata;
- closed-loop control points;
- samples per spline segment;
- road width and curvature-driven width variation;
- shoulder, grass and barrier dimensions;
- ordered checkpoint progress values;
- checkpoint gate depth, height and width margin;
- stadium-generation settings.

The current authoritative resource is:

```text
resources/tracks/simple_oval.tres
```

Both `scenes/tracks/simple_oval.tscn` and the helper `test_track.tscn` reference this resource instead of serializing their own generation parameters.

## Typed generation and width profile

`TrackLayoutBuilder.build(config)` consumes a `TrackGenerationConfig`. Control points and sampling density come from the referenced `TrackLayoutResource`; runtime-safe copies provide sanitized road, shoulder and decoration values.

The simple oval uses 18 control points and six samples per segment, producing a 108-point closed loop.

Road width is not tied to fixed lap-progress locations. For each sampled point, the builder calculates local horizontal curvature from the incoming and outgoing segments. `width_variation` then widens curved sections through a bounded smoothstep response while straight sections retain the configured base width. The same algorithm therefore applies to additional track layouts without oval-specific constants.

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

Generation is transactional. A failed validation does not replace the currently committed geometry, does not publish a new geometry revision and does not disturb consumers using the last valid track.

## Checkpoint sequence

The simple oval defines checkpoint progress values at `0.25`, `0.50` and `0.75`. `TrackCheckpointBuilder` maps them onto sampled center-line points and creates four `Area3D` gates:

```text
0 = finish line
1 = checkpoint at 25%
2 = checkpoint at 50%
3 = checkpoint at 75%
```

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

A successful `GeneratedTrack` rebuild publishes a new geometry revision. `LapTracker` then discards projection continuity and globally reprojects each valid participant against the newly committed loop.

Completed laps are preserved. Every committed geometry revision resets unfinished checkpoint sequences before projection is reacquired, preventing partial progress from an obsolete geometry from authorizing a finish crossing.

Failed generation does not emit a revision and therefore leaves both the committed track and race state unchanged.

## Menu metadata

`MenuOptionsBuilder` builds track options from `TrackLayoutResource` metadata. The visible label, selected track ID and recommended lap metadata therefore come from the same source as generated geometry and checkpoint data.

## Regression coverage

```text
scenes/tests/track_layout_builder_test.tscn
scenes/tests/track_layout_resource_test.tscn
scenes/tests/lap_tracker_checkpoint_test.tscn
scenes/tests/lap_tracker_progress_test.tscn
scripts/tests/track_geometry_topology_validation_test.gd
scripts/tests/racing_line_projector_test.gd
```

Coverage includes Resource sequence rules, curvature-driven width generation, minimum curve radius, center/edge self-intersection rejection, width-aware non-adjacent clearance, generated gate count, crossing direction, rejected cuts and duplicate finishes, sub-segment position ordering, bounded projection cost, continuity across adjacent non-local track sections, teleport reacquisition and active-session geometry rebuild reconciliation. All tests run in the required Windows CI suite.
