# Track layout resources

Generated-track layout data is Resource-backed.

## Authoritative data path

```text
resources/tracks/simple_oval.tres
    -> TrackLayoutResource
    -> GeneratedTrack
    -> TrackLayoutBuilder
    -> TrackGeometryData
```

`TrackLayoutResource` stores:

- stable track ID and display name;
- recommended lap count metadata;
- closed-loop control points;
- samples per spline segment;
- road width and width variation;
- shoulder, grass and barrier dimensions;
- stadium-generation settings.

The current authoritative resource is:

```text
resources/tracks/simple_oval.tres
```

Both `scenes/tracks/simple_oval.tscn` and the helper `test_track.tscn` reference this resource instead of serializing their own generation parameters.

## Builder compatibility

`TrackLayoutBuilder.build(config)` keeps its Dictionary interface because the surface, collision, marker, barrier and decoration builders already share that configuration path. The dictionary now contains a `track_layout` Resource. Optional width keys remain supported for focused tests, while control points and sampling density always come from the Resource.

The simple oval still uses 18 control points and six samples per segment, producing the existing 108-point closed loop.

## Menu metadata

`MenuOptionsBuilder` builds track options from `TrackLayoutResource` metadata. The visible label, selected track ID and recommended lap metadata therefore come from the same source as generated geometry.

## Regression coverage

```text
scenes/tests/track_layout_builder_test.tscn
scenes/tests/track_layout_resource_test.tscn
```

The resource test validates metadata, control-point count, generated sample count, road and shoulder dimensions, menu-option mapping and the scene-to-resource reference. Both tests run in the required Windows CI suite.
