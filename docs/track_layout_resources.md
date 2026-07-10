# Track layout resources

Generated-track layout data is Resource-backed.

## Authoritative data path

```text
resources/tracks/simple_oval.tres
    -> TrackLayoutResource
    -> GeneratedTrack
    -> TrackLayoutBuilder / TrackCheckpointBuilder
    -> TrackGeometryData / TrackCheckpointGate
```

`TrackLayoutResource` stores:

- stable track ID and display name;
- recommended lap count metadata;
- closed-loop control points;
- samples per spline segment;
- road width and width variation;
- shoulder, grass and barrier dimensions;
- ordered checkpoint progress values;
- checkpoint gate depth, height and width margin;
- stadium-generation settings.

The current authoritative resource is:

```text
resources/tracks/simple_oval.tres
```

Both `scenes/tracks/simple_oval.tscn` and the helper `test_track.tscn` reference this resource instead of serializing their own generation parameters.

## Builder compatibility

`TrackLayoutBuilder.build(config)` keeps its Dictionary interface because the surface, collision, marker, barrier and decoration builders already share that configuration path. The dictionary contains a `track_layout` Resource. Optional width keys remain supported for focused tests, while control points and sampling density always come from the Resource.

The simple oval uses 18 control points and six samples per segment, producing the existing 108-point closed loop.

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

Completed laps are preserved. When the number of intermediate checkpoints remains unchanged, the current ordered checkpoint sequence is also preserved. When checkpoint topology changes, unfinished participants restart the partial sequence from checkpoint `1`; obsolete partial progress cannot authorize a finish crossing on the new topology.

Failed generation does not emit a revision and therefore leaves both the committed track and race state unchanged.

## Menu metadata

`MenuOptionsBuilder` builds track options from `TrackLayoutResource` metadata. The visible label, selected track ID and recommended lap metadata therefore come from the same source as generated geometry and checkpoint data.

## Regression coverage

```text
scenes/tests/track_layout_builder_test.tscn
scenes/tests/track_layout_resource_test.tscn
scenes/tests/lap_tracker_checkpoint_test.tscn
scenes/tests/lap_tracker_progress_test.tscn
scripts/tests/racing_line_projector_test.gd
```

Coverage includes Resource sequence rules, generated gate count, crossing direction, rejected cuts and duplicate finishes, sub-segment position ordering, bounded projection cost, continuity across adjacent non-local track sections, teleport reacquisition and active-session geometry rebuild reconciliation. All tests run in the required Windows CI suite.
