# Architecture baseline

This document describes the current architecture of the Godot car game prototype and the intended direction for cleanup.

It is not a final architecture. It is a baseline snapshot intended to guide incremental refactoring.

## Current composition

The current main scene is `scenes/main.tscn`.

At runtime, it composes:

- generated track scene;
- car spawn point;
- directional light;
- camera with follow script;
- world environment;
- speedometer HUD;
- minimap;
- main menu;
- high-level game/free-drive/race logic attached to the root node.

The root node currently uses `scripts/game/game_manager.gd`.

## Current module map

```text
scenes/
  main.tscn
  cars/
    370z.tscn
    370zat.tscn
    player_car.tscn
    test_car.tscn
  tracks/
    simple_oval.tscn
    test_track.tscn
  ui/
    main_menu.tscn
    minimap.tscn
    speedometer.tscn

scripts/
  camera/
    follow_camera.gd
  car/
    car_controller.gd
    engine_audio.gd
    tire_squeal_audio.gd
  game/
    game_manager.gd
    car_spawner.gd
  race/
    ai_race_driver.gd
    generated_track.gd
    lap_tracker.gd
    race_manager.gd
  ui/
    main_menu.gd
    minimap.gd
    race_hud.gd
    speedometer.gd
    tachometer_gauge.gd
```

## Core runtime flow

Current flow:

1. Godot loads `scenes/main.tscn`.
2. The root node runs `scripts/game/game_manager.gd`.
3. The main menu is shown.
4. The player selects mode, track and car.
5. `GameManager` receives the menu signal.
6. `CarSpawner` instantiates the selected car at `CarSpawn`.
7. Camera, speedometer and minimap are pointed at the active car.
8. In free-drive mode, player input is enabled immediately.
9. In race mode, `CarSpawner` creates opponents and AI drivers.
10. `RaceManager` runs the countdown and unlocks player/AI input after `START`.
11. `LapTracker` updates lap/progress/position logic each physics tick.
12. `RaceHud` shows countdown, lap/position and results UI.

## Car architecture

Current car root type: `CharacterBody3D`.

Current main controller: `scripts/car/car_controller.gd`.

Responsibilities currently inside the controller:

- player input;
- external input for AI;
- forward/reverse speed model;
- manual and automatic transmission logic;
- torque converter approximation;
- engine RPM model;
- engine torque curve approximation;
- rev limiter;
- aerodynamic drag;
- rolling resistance;
- steering model;
- lateral slip approximation;
- handbrake behavior;
- tire slip intensity output;
- skid mark spawning;
- reset-to-start behavior;
- movement through `move_and_slide()`.

This is acceptable for a prototype but should not keep growing.

### Target car architecture

Recommended direction:

```text
scripts/car/
  player_car_controller.gd      # thin coordinator for movement and public API
  car_input.gd                  # player/external input abstraction
  drivetrain_model.gd           # engine, gearbox, torque converter, wheel force
  tire_model.gd                 # lateral grip, slip, handbrake, tire state
  skid_mark_emitter.gd          # skid mark visual effect
  car_specs.gd                  # Resource with tunable car data
  engine_audio.gd
  tire_squeal_audio.gd
```

The first extraction should be `skid_mark_emitter.gd`, because it is the least coupled part of the current controller.

The second extraction should be drivetrain logic, because engine and transmission tuning will keep expanding.

## Race/game architecture

Current high-level coordinator: `scripts/game/game_manager.gd`.

Current responsibilities of `GameManager`:

- receiving menu selection;
- storing selected mode and track IDs;
- delegating player/opponent spawn to `CarSpawner`;
- wiring camera, speedometer and minimap targets;
- starting free-drive or race mode;
- delegating race lifecycle to `RaceManager`;
- delegating lap/progress/result-order logic to `LapTracker`;
- delegating countdown/lap/results UI to `RaceHud`;
- return-to-menu flow.

Specialized helpers:

```text
scripts/game/car_spawner.gd      # player car, opponent and AI-driver instantiation
scripts/race/race_manager.gd     # countdown, input lock, race start/finish state
scripts/race/lap_tracker.gd      # participant registration, laps, progress, results
scripts/ui/race_hud.gd           # procedural countdown, lap and results UI
```

This is now a better split than the original monolithic coordinator. Remaining cleanup should focus on converting procedural UI into scenes and reducing `car_controller.gd`.

## Track architecture

Current track generator: `scripts/race/generated_track.gd`.

Current responsibilities:

- stores hardcoded control points;
- samples Catmull-Rom points;
- exposes `get_racing_line_points()`;
- generates grass;
- generates road shoulders;
- generates asphalt mesh;
- generates trimesh collisions;
- generates finish line visuals;
- generates edge markers;
- generates barriers;
- optionally generates stadium scenery.

This is effective for fast prototyping but should later be split into track data and visual generation.

### Target track architecture

```text
resources/tracks/
  simple_oval.tres              # TrackLayoutResource

scripts/race/
  track_layout_resource.gd      # control points, width, racing line, metadata
  generated_track.gd            # builds drivable surface from layout
  track_decoration_builder.gd   # barriers, stadium, lights, scenery
```

## UI architecture

Current UI approach is mixed:

- `speedometer.tscn` is a proper scene with a small binding script;
- `main_menu.gd` builds menu UI procedurally;
- `race_hud.gd` builds countdown, lap UI and results UI procedurally;
- `minimap.gd` draws the map and participants manually.

Target direction:

```text
scenes/ui/
  main_menu.tscn
  race_hud.tscn
  countdown_overlay.tscn
  results_screen.tscn
  speedometer.tscn
  minimap.tscn
```

UI layout should be scene-driven. Scripts should update labels, visibility and signals, not construct the whole visual hierarchy unless there is a specific reason.

## Data architecture

Current data is mostly stored in exported variables on scenes and scripts.

This is acceptable now, but it will become awkward when adding more cars and tracks.

Recommended future data model:

```text
resources/cars/
  370z_manual.tres
  370z_automatic.tres

resources/tracks/
  simple_oval.tres

resources/game_modes/
  free_drive.tres
  race.tres
```

Use Resources for reusable car, track and mode definitions. Scenes should instantiate visuals and behavior; Resources should carry tunable data.

## Refactoring rules

1. Do not change car handling while refactoring race/menu structure.
2. Do not add new cars while extracting car systems.
3. Keep UI extraction separate from race logic extraction.
4. Keep procedural track changes separate from car physics changes.
5. After each change, manually test free drive and race mode in Godot.

## Current technical risks

| Risk | Severity | Reason |
|---|---:|---|
| `car_controller.gd` is growing into a monolith | High | Input, drivetrain, tires, VFX and movement are coupled |
| Lap tracking is heuristic | Medium | Uses racing-line progress rather than physical checkpoints |
| Track generator mixes data and scenery | Medium | Adding more tracks will duplicate or complicate logic |
| Procedural audio may scale poorly with many cars | Medium | Each active car can generate audio samples |
| UI is partly procedural | Medium | Harder to style, animate and maintain |
| Car/track lists are hardcoded | Medium | Adding content requires script and scene edits |

## Preferred next refactor

After local validation of the current race/menu split, continue with one of these:

1. Convert `RaceHud` into scene-driven UI.
2. Extract skid mark visual effects from `car_controller.gd`.
3. Add `docs/vehicle_model.md` before changing drivetrain or tire behavior.

Do not change car handling while race/menu/UI refactors remain untested locally.
