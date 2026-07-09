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
    car_input.gd
    manual_transmission_model.gd
    automatic_transmission_model.gd
    shift_timer_model.gd
    drivetrain_model.gd
    engine_audio.gd
    engine_model.gd
    resistance_model.gd
    skid_mark_emitter.gd
    tire_squeal_audio.gd
    torque_converter_model.gd
  game/
    game_manager.gd
    car_spawner.gd
  race/
    ai_race_driver.gd
    generated_track.gd
    lap_tracker.gd
    race_manager.gd
  ui/
    countdown_overlay.gd
    lap_position_hud.gd
    main_menu.gd
    minimap.gd
    race_hud.gd
    results_screen.gd
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
12. `RaceHud` delegates countdown, lap/position and results UI to specialized helpers.

## Car architecture

Current car root type: `CharacterBody3D`.

Current main controller: `scripts/car/car_controller.gd`.

Responsibilities currently inside the controller:

- forward/reverse speed model;
- applying selected gears;
- steering model;
- lateral slip approximation;
- handbrake behavior;
- tire slip intensity output;
- reset-to-start behavior;
- movement through `move_and_slide()`.

Player/external drive input is handled by `scripts/car/car_input.gd`.

Manual gear-up/gear-down requests are handled by `scripts/car/manual_transmission_model.gd`.

Automatic gear-selection decisions are handled by `scripts/car/automatic_transmission_model.gd`.

Shift-timer update and delay selection are handled by `scripts/car/shift_timer_model.gd`.

Engine RPM, torque curve and rev limiter multiplier are handled by `scripts/car/engine_model.gd`.

Gear-ratio lookup, wheel-coupled RPM, wheel-force and drive-acceleration helper calculations are handled by `scripts/car/drivetrain_model.gd`.

Torque converter RPM coupling and torque multiplication are handled by `scripts/car/torque_converter_model.gd`.

Aerodynamic drag and rolling resistance are handled by `scripts/car/resistance_model.gd`.

Skid mark visual effects are handled by `scripts/car/skid_mark_emitter.gd`.

This is acceptable for a prototype but the controller should still be split further before drivetrain and tire behavior are expanded.

### Target car architecture

Recommended direction:

```text
scripts/car/
  player_car_controller.gd      # thin coordinator for movement and public API
  car_input.gd                  # player/external input abstraction
  manual_transmission_model.gd  # manual gear input helper
  automatic_transmission_model.gd # automatic gear selection
  shift_timer_model.gd          # shift-timer update and delay selection
  drivetrain_model.gd           # gearbox, wheel force
  torque_converter_model.gd     # automatic torque converter helper
  engine_model.gd               # RPM, torque curve, limiter
  resistance_model.gd           # drag and rolling resistance
  tire_model.gd                 # lateral grip, slip, handbrake, tire state
  skid_mark_emitter.gd          # skid mark visual effect
  car_specs.gd                  # Resource with tunable car data
  engine_audio.gd
  tire_squeal_audio.gd
```

The next substantial car refactor should continue vehicle-controller cleanup, because gear application, tire behavior and movement are still coupled to the controller.

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
scripts/game/car_spawner.gd       # player car, opponent and AI-driver instantiation
scripts/race/race_manager.gd      # countdown, input lock, race start/finish state
scripts/race/lap_tracker.gd       # participant registration, laps, progress, results
scripts/ui/race_hud.gd            # UI facade used by GameManager
scripts/ui/countdown_overlay.gd   # countdown overlay construction and visibility
scripts/ui/lap_position_hud.gd    # lap and race-position display
scripts/ui/results_screen.gd      # results list and return-to-menu button
```

This is now a better split than the original monolithic coordinator. Remaining cleanup should focus on converting procedural UI helpers into scenes and reducing `car_controller.gd`.

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
- `RaceHud` is a facade over procedural countdown, lap/position and results helpers;
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
| `car_controller.gd` is still large | High | Gear application, tires and movement are still coupled |
| Lap tracking is heuristic | Medium | Uses racing-line progress rather than physical checkpoints |
| Track generator mixes data and scenery | Medium | Adding more tracks will duplicate or complicate logic |
| Procedural audio may scale poorly with many cars | Medium | Each active car can generate audio samples |
| UI is partly procedural | Medium | Harder to style, animate and maintain |
| Car/track lists are hardcoded | Medium | Adding content requires script and scene edits |

## Preferred next refactor

After local validation of the current race/menu/UI split, continue with one of these:

1. Convert procedural UI helpers into scene-driven UI.
2. Extract tire model logic from `car_controller.gd` in small, behavior-preserving changes.
3. Keep `docs/vehicle_model.md` updated before and after vehicle-model changes.

Do not change car handling while race/menu/UI refactors remain untested locally.
