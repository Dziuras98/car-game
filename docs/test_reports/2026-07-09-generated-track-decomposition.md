# Generated Track Decomposition - 2026-07-09

## Scope

Refactored the generated track implementation into smaller responsibility-focused builder classes while preserving the generated track shape, dimensions, public API, node names, materials, and gameplay behavior.

## Main monolith before refactor

- `scripts/race/generated_track.gd`

## New classes

- `TrackGeneratedContentRoot` (`scripts/track/track_generated_content_root.gd`): owns the stable `GeneratedContent` container and clears only generated children.
- `TrackGeometryData` (`scripts/track/track_geometry_data.gd`): typed geometry data container for center points, edges, shoulder edges, racing line, forward/right vectors, half widths, and center.
- `TrackLayoutBuilder` (`scripts/track/track_layout_builder.gd`): builds the Catmull-Rom sampled track layout, width variation, edges, shoulder edges, direction vectors, and racing line data without creating nodes.
- `TrackSurfaceMeshBuilder` (`scripts/track/track_surface_mesh_builder.gd`): builds grass, roadside terrain, and asphalt mesh/body nodes.
- `TrackCollisionBuilder` (`scripts/track/track_collision_builder.gd`): builds the grass box collision and trimesh collisions for roadside terrain and asphalt.
- `TrackMarkerBuilder` (`scripts/track/track_marker_builder.gd`): builds the finish line and edge markers.
- `TrackBarrierBuilder` (`scripts/track/track_barrier_builder.gd`): builds the visual barrier segments.
- `TrackDecorationBuilder` (`scripts/track/track_decoration_builder.gd`): builds optional stadium walls, arrows, stands, spectators, roof sections, and lights.
- `TrackMaterialFactory` (`scripts/track/track_material_factory.gd`): creates the same track, marker, barrier, and stadium materials as the old monolith.

## What remains in the main track script

- Existing exported track parameters and setter rebuild flow.
- Public `get_racing_line_points()` compatibility.
- Builder instance ownership.
- `_build_track_generation_config()`.
- Rebuild orchestration: config, layout, clear `GeneratedContent`, surfaces, collisions, markers, barriers, decorations.
- Last-built `TrackGeometryData` storage for public racing-line access.

## What moved out of the main track script

- Catmull-Rom sampling and width/edge data calculation.
- Grass, shoulder, and asphalt mesh creation.
- Grass, shoulder, and asphalt collision creation.
- Finish line and marker mesh creation.
- Barrier mesh creation.
- Stadium, wall arrow, light, spectator, and grandstand creation.
- Material creation for all generated track visuals.
- Generated child cleanup implementation.

## GeneratedContent behavior

`GeneratedContent` was introduced as a stable generated-content container. Rebuilds call `TrackGeneratedContentRoot.clear(self)`, which removes only children under `GeneratedContent` and does not touch manually added children on the track node.

All generated runtime content now goes under `GeneratedContent`, preserving gameplay while preventing rebuilds from deleting hand-authored track children.

## Public API compatibility

The track still exposes the same exported parameter names and the same public `get_racing_line_points()` method. The method still returns `Array[Vector3]` for compatibility with `Minimap`, `AI`, and `LapTracker` `has_method/call("get_racing_line_points")` usage.

`get_racing_line_points()` now returns `_geometry.racing_line_points` converted back to `Array[Vector3]`. The racing line remains the same sampled Catmull-Rom center line as before.

## Explicit non-changes

This refactor did not change:

- car physics,
- tuning,
- cars or car resources,
- AI or `ai_race_driver.gd`,
- `LapTracker`,
- `RaceManager`,
- `RaceSessionController`,
- `GameManager`,
- `CarSpawner`,
- menu flow,
- UI scenes,
- smoke test.

## Validation

- Smoke test command:
  - `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --path . --scene res://scenes/tests/full_program_smoke_test.tscn`
- Smoke test result:
  - `[SMOKE] Extended full program smoke test passed: 79 checks`
- `git diff --check`:
  - Passed with no output.

The full smoke test covered menu navigation, free drive, minimap visibility, automatic/manual car flows, race mode, moving AI opponents, results screen display after finish, return to menu, and post-race free-drive reentry.

## .gd.uid notes

Godot created `.gd.uid` files for the new `scripts/track/*.gd` builder scripts during import/validation. These are kept with the new scripts.

During validation Godot also recreated missing `.gd.uid` files for some existing `scripts/game` scripts. Those unrelated generated files were removed from the worktree because they are outside this refactor scope.

## Left for later

- Track generation parameters remain in the main script rather than a `Resource`, as requested.
- Stadium, arrows, and lights are grouped under `TrackDecorationBuilder` instead of further splitting into `TrackStadiumBuilder`, `TrackArrowBuilder`, or `TrackLightBuilder`; the current split keeps the refactor controlled while removing the decoration responsibilities from the main script.
- Barrier visuals remain in `TrackBarrierBuilder`. The previous implementation did not create barrier collision shapes, so no new barrier collision behavior was introduced.
