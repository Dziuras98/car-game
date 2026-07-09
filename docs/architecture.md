# Architecture baseline

This document describes the current architecture of the Godot car game prototype and the intended cleanup direction.

It is not a final architecture. It is a baseline snapshot for incremental refactoring. When responsibilities move between scripts, update this document in the same change.

## Validation status

The project has an extended full-program smoke test at:

```text
scenes/tests/full_program_smoke_test.tscn
```

The smoke test can also be launched through:

```text
scripts/tests/run_full_program_smoke_test.gd
```

Current documented smoke-test coverage includes:

- project/main scene instantiation;
- main menu flow and back navigation;
- free-drive automatic flow;
- free-drive manual flow;
- car switching in free drive;
- `switch-car` blocked in race mode;
- race countdown and input lock/unlock;
- AI opponents moving after countdown;
- speedometer/minimap visibility;
- result screen after simulated finish;
- return-to-menu cleanup;
- post-race free-drive reentry.

This documentation cleanup did not intentionally change runtime code. It does not replace a local Godot smoke-test run after future code changes.

## Current composition

The current main scene is:

```text
scenes/main.tscn
```

At runtime, it composes:

- generated oval track scene;
- player car spawn point;
- directional light;
- follow camera;
- world environment;
- speedometer/tachometer HUD;
- minimap;
- main menu;
- high-level game/free-drive/race flow on the root node;
- temporary Android mobile driving overlay instantiated by `GameManager`.

The root node currently uses:

```text
scripts/game/game_manager.gd
```

## Current module map

```text
scenes/
  main.tscn
  cars/
    370z.tscn
    370zat.tscn
    player_car.tscn
    test_car.tscn
  tests/
    full_program_smoke_test.tscn
  tracks/
    simple_oval.tscn
    test_track.tscn
  ui/
    countdown_overlay.tscn
    lap_position_hud.tscn
    main_menu.tscn
    minimap.tscn
    mobile_drive_controls.tscn
    results_screen.tscn
    speedometer.tscn

resources/
  cars/
    catalog.tres
    nissan/370z/
      model.tres
      specs/
        370z_6mt_specs.tres
        370z_7at_specs.tres
      variants/
        370z_6mt.tres
        370z_7at.tres

scripts/
  camera/
    follow_camera.gd
  car/
    automatic_transmission_model.gd
    car_catalog.gd
    car_chassis_controller.gd
    car_controller.gd
    car_drive_config.gd
    car_drive_config_builder.gd
    car_input.gd
    car_model_definition.gd
    car_powertrain_controller.gd
    car_reset_controller.gd
    car_runtime_state.gd
    car_specs.gd
    car_variant_definition.gd
    drivetrain_model.gd
    engine_audio.gd
    engine_model.gd
    manual_transmission_model.gd
    resistance_model.gd
    shift_timer_model.gd
    skid_mark_emitter.gd
    tire_model.gd
    tire_squeal_audio.gd
    torque_converter_model.gd
    vehicle_motion_model.gd
  game/
    car_instance_factory.gd
    car_selection_state.gd
    car_spawner.gd
    game_manager.gd
    menu_options_builder.gd
    opponent_paint_randomizer.gd
    opponent_participant_spawner.gd
    opponent_spawn_layout.gd
    player_car_spawn_controller.gd
    race_session_controller.gd
  race/
    ai_race_driver.gd
    generated_track.gd
    lap_tracker.gd
    race_manager.gd
  track/
    track_barrier_builder.gd
    track_collision_builder.gd
    track_decoration_builder.gd
    track_generated_content_root.gd
    track_geometry_data.gd
    track_layout_builder.gd
    track_marker_builder.gd
    track_material_factory.gd
    track_surface_mesh_builder.gd
  tests/
    car_controller_runtime_config_test.gd
    full_program_smoke_test.gd
    game_test_adapter.gd
    run_full_program_smoke_test.gd
  ui/
    countdown_overlay.gd
    lap_position_hud.gd
    main_menu.gd
    minimap.gd
    mobile_drive_controls.gd
    race_hud.gd
    results_screen.gd
    speedometer.gd
    tachometer_gauge.gd
```

## Core runtime flow

Current flow:

1. Godot loads `scenes/main.tscn`.
2. The root node runs `scripts/game/game_manager.gd`.
3. `GameManager` builds car-selection state from `resources/cars/catalog.tres`, with scene-list fallback from `available_cars`.
4. `GameManager` configures the menu with track options and car model/variant options.
5. `GameManager` configures `CarSpawner` and `RaceSessionController`.
6. `GameManager` instantiates the temporary mobile drive controls scene.
7. The main menu is shown.
8. The player selects mode, track, model and variant.
9. `GameManager` receives the menu signal.
10. `CarSpawner` instantiates the selected car at `CarSpawn`.
11. Camera, speedometer and minimap are pointed at the active car.
12. In free-drive mode, player input is enabled immediately and car switching is allowed.
13. In race mode, car switching is blocked.
14. In race mode, `RaceSessionController` asks `CarSpawner` to create opponents and AI drivers.
15. `RaceManager` runs the countdown and unlocks player/AI input after `START`.
16. `LapTracker` updates lap/progress/position logic each physics tick during the race.
17. `RaceHud` delegates countdown, lap/position and results UI to specialized UI scripts.

## Game/menu architecture

Current high-level coordinator:

```text
scripts/game/game_manager.gd
```

Current responsibilities of `GameManager`:

- receiving menu selection;
- storing selected mode, track and car variant IDs;
- configuring menu options;
- configuring car-selection state;
- delegating player/opponent spawn to `CarSpawner`;
- wiring camera, speedometer and minimap targets;
- instantiating the temporary mobile drive controls scene;
- starting free-drive or race mode;
- allowing car switching only in free-drive mode;
- delegating race lifecycle to `RaceSessionController`;
- return-to-menu flow.

Specialized helpers:

```text
scripts/game/car_selection_state.gd        # available scene/variant selection state
scripts/game/menu_options_builder.gd       # menu dictionaries from catalog/track options
scripts/game/car_spawner.gd                # spawn facade
scripts/game/car_instance_factory.gd       # instantiate car scenes and apply variant specs
scripts/game/player_car_spawn_controller.gd # current player-car lifecycle
scripts/game/opponent_spawn_layout.gd      # opponent spawn transforms/lane offsets
scripts/game/opponent_paint_randomizer.gd  # opponent paint variation
scripts/game/opponent_participant_spawner.gd # opponent car and AI driver creation
scripts/game/race_session_controller.gd    # race-session facade
```

Target direction:

- keep `GameManager` as a coordinator;
- do not add new car physics, race rules or UI construction directly to `GameManager`;
- move future mode-specific state into explicit session/mode controllers;
- keep the menu consuming prepared option data instead of reading catalog Resources directly.

## Race architecture

Current race facade:

```text
scripts/game/race_session_controller.gd
```

Specialized race helpers:

```text
scripts/race/race_manager.gd   # countdown, input lock, race start/finish state
scripts/race/lap_tracker.gd    # participant registration, laps, progress, result order
scripts/race/ai_race_driver.gd # prototype racing-line follower
scripts/ui/race_hud.gd         # UI facade used by RaceSessionController/GameManager
```

Current limitations:

- `LapTracker` uses nearest racing-line progress and index wrapping to count laps.
- This is acceptable for the current simple oval but not robust against shortcuts, reversing across the line or complex track layouts.
- Checkpoint validation should replace lap-counting heuristics before multiple tracks or serious race rules are added.

Target direction:

```text
scripts/race/
  checkpoint.gd
  checkpoint_sequence.gd
  lap_tracker.gd              # validates checkpoint order, keeps progress sorting
scripts/track/
  checkpoint_builder.gd       # generated checkpoint/final-line volumes
```

## Car architecture

Current car root type:

```text
CharacterBody3D
```

Current public controller:

```text
scripts/car/car_controller.gd
class_name PlayerCarController
```

`PlayerCarController` is now a runtime coordinator. It keeps the scene-compatible export fields, `car_specs`, input helper ownership, skid-mark emitter ownership, public telemetry/control API, `_physics_process()` orchestration, runtime reconfiguration and reset delegation.

Current per-physics-frame pipeline:

1. reset check through `CarInput`;
2. input read;
3. runtime input snapshot;
4. powertrain update;
5. steering update;
6. tire/slip update and skid-mark dispatch;
7. velocity/gravity application through `move_and_slide()`.

Specialized car helpers:

```text
scripts/car/car_runtime_state.gd          # speed/RPM/gear/input/start-transform state
scripts/car/car_drive_config.gd           # sanitized runtime copy of drive tuning
scripts/car/car_drive_config_builder.gd   # CarSpecs or legacy export -> CarDriveConfig
scripts/car/car_powertrain_controller.gd  # transmission, engine, torque, resistance, forward speed
scripts/car/car_chassis_controller.gd     # steering, tire slip, skid dispatch, gravity, move_and_slide
scripts/car/car_reset_controller.gd       # reset-to-start behavior
scripts/car/car_input.gd                  # player/external input abstraction
scripts/car/manual_transmission_model.gd  # manual gear input helper
scripts/car/automatic_transmission_model.gd # automatic gear selection
scripts/car/shift_timer_model.gd          # shift-timer update and delay selection
scripts/car/drivetrain_model.gd           # gearbox, wheel RPM, wheel force
scripts/car/torque_converter_model.gd     # automatic torque converter helper
scripts/car/engine_model.gd               # RPM, torque curve, limiter
scripts/car/resistance_model.gd           # drag and rolling resistance
scripts/car/tire_model.gd                 # lateral grip and slip intensity
scripts/car/vehicle_motion_model.gd       # local/global velocity projection
scripts/car/skid_mark_emitter.gd          # skid mark visual effect
scripts/car/engine_audio.gd
scripts/car/tire_squeal_audio.gd
```

Current data source:

- Preferred path: `CarVariantDefinition -> CarSpecs -> CarDriveConfig`.
- Fallback path: legacy exported tuning fields on `PlayerCarController -> CarDriveConfig` when `car_specs == null`.

Current cleanup direction:

- keep `PlayerCarController` thin;
- do not change driving feel during architecture cleanup;
- add unit/helper tests before deeper physics changes;
- remove legacy exported tuning only after all scenes and variants rely on `CarSpecs`;
- split `CarSpecs` into sub-resources only after the current Resource-backed path is validated.

## Track architecture

Current generated track entry point:

```text
scripts/race/generated_track.gd
```

`generated_track.gd` is now a thin orchestrator. It owns exported track parameters, rebuild triggers, builder instances, the last-built `TrackGeometryData`, and the public `get_racing_line_points()` method.

Specialized track builders:

```text
scripts/track/track_generated_content_root.gd # stable GeneratedContent node and generated-child cleanup
scripts/track/track_geometry_data.gd          # generated geometry data container
scripts/track/track_layout_builder.gd         # control points, Catmull-Rom sampling, widths, edges, racing line
scripts/track/track_surface_mesh_builder.gd   # grass, roadside and asphalt mesh/body creation
scripts/track/track_collision_builder.gd      # grass, roadside and asphalt collisions
scripts/track/track_marker_builder.gd         # finish line and edge markers
scripts/track/track_barrier_builder.gd        # barrier visuals
scripts/track/track_decoration_builder.gd     # optional stadium/scenery/lights
scripts/track/track_material_factory.gd       # generated materials
```

Current limitations:

- track layout control points are still hardcoded inside `TrackLayoutBuilder`;
- track options are still hardcoded in `MenuOptionsBuilder`;
- no physical checkpoint sequence exists yet;
- barrier visuals are generated, but strong gameplay collision consequences are not a finished system.

Target direction:

```text
resources/tracks/
  simple_oval.tres              # TrackLayoutResource

scripts/track/
  track_layout_resource.gd      # control points, width, racing line, metadata
  checkpoint_builder.gd         # physical checkpoint and lap-validation volumes
```

## UI architecture

Current UI approach is mostly scene-driven:

- `main_menu.tscn` owns the static main menu layout; `main_menu.gd` controls menu state, labels, signals and dynamic option-button creation;
- `countdown_overlay.tscn` owns the countdown overlay layout; `countdown_overlay.gd` updates text and visibility;
- `lap_position_hud.tscn` owns the lap/position HUD layout; `lap_position_hud.gd` updates lap and position values;
- `results_screen.tscn` owns the results screen layout; `results_screen.gd` updates visibility, return-to-menu signaling and dynamic result rows;
- `mobile_drive_controls.tscn` owns the temporary Android touch overlay layout; `mobile_drive_controls.gd` binds scene buttons to input actions;
- `speedometer.tscn` owns the speedometer/tachometer layout; `speedometer.gd` binds it to the active car;
- `minimap.gd` still draws the map and participants manually.

Runtime-created UI remains acceptable for repeated data-driven content:

- main-menu option buttons depend on current mode/track/model/variant data;
- result rows depend on the race result list.

Target direction:

- keep layout in scenes;
- keep scripts focused on values, visibility, signals and data-driven repeated items;
- introduce reusable option/result row scenes only when dynamic rows become complex.

## Test architecture

Current automated runtime tests:

```text
scenes/tests/full_program_smoke_test.tscn
scripts/tests/full_program_smoke_test.gd
scripts/tests/game_test_adapter.gd
scripts/tests/run_full_program_smoke_test.gd
scripts/tests/car_controller_runtime_config_test.gd
```

`full_program_smoke_test.gd` is a broad regression test. It instantiates `scenes/main.tscn`, navigates visible menu buttons, simulates input through `Input.action_press()` / `Input.action_release()`, verifies free-drive automatic/manual behavior, verifies race setup, checks `switch-car` blocking in race mode, waits through an AI race soak segment, simulates player finish and verifies return-to-menu cleanup.

`GameTestAdapter` centralizes smoke-test access to game state. It is acceptable for the prototype, but a production-facing diagnostic API on `GameManager` would be cleaner than test-specific accessors.

`car_controller_runtime_config_test.gd` covers runtime config construction, geared-transmission checks, runtime-state reset and basic manual/automatic gear text formatting.

Target direction:

- keep the smoke test as the broad regression gate;
- add smaller helper tests for `TrackLayoutBuilder`, `CarDriveConfigBuilder`, `CarPowertrainController` and lap/checkpoint logic;
- avoid using smoke tests as the only guard for detailed math behavior.

## Data architecture

Current car data model:

```text
resources/cars/
  catalog.tres
  nissan/
    370z/
      model.tres
      specs/
        370z_6mt_specs.tres
        370z_7at_specs.tres
      variants/
        370z_6mt.tres
        370z_7at.tres
```

Cars are cataloged through:

```text
CarCatalog -> CarModelDefinition -> CarVariantDefinition -> CarSpecs
```

Recommended future data model:

```text
resources/tracks/
  simple_oval.tres

resources/game_modes/
  free_drive.tres
  race.tres
```

Use Resources for reusable car, track and mode definitions. Scenes should instantiate visuals and behavior; Resources should carry tunable data.

## Current technical risks

| Risk | Severity | Reason |
|---|---:|---|
| `GameManager` remains a broad coordinator | Medium | Acceptable now, but it should not absorb new gameplay systems |
| Lap tracking is heuristic | High | Nearest racing-line progress is not robust for complex tracks or shortcuts |
| Track layout data is hardcoded | Medium/High | Adding tracks still requires code edits |
| `CarSpecs`, `CarDriveConfig` and legacy exports duplicate tuning fields | Medium | New tuning fields must be copied through several paths until legacy exports are removed |
| Runtime `car_specs` reconfiguration needs more focused tests | Medium | Existing smoke tests are broad; edge cases need smaller tests |
| `GameTestAdapter` knows selected `GameManager` internals | Medium | Better than scattered test coupling, but a cleaner diagnostic API would be preferable |
| Runtime-created UI rows/buttons are still script-built | Low/Medium | Acceptable for data-driven repeated items, but may need item scenes later |
| Mobile controls are still temporary test UI | Low/Medium | Scene-driven now, but not final configurable input UI |
| Procedural audio may scale poorly with many cars | Medium | Each active car can generate audio samples |

## Preferred next refactor order

1. Add focused helper tests for current car runtime/config behavior.
2. Fix small runtime config edge cases, such as keeping skid-mark emitter configuration in sync when `car_specs` changes at runtime.
3. Add focused helper tests for track layout/builder behavior.
4. Move track layout data toward a Resource-backed representation.
5. Replace lap-counting heuristics with checkpoint-based validation.
6. Add new cars or imported car models only after the current architecture and tests are stable.

## Refactoring rules

1. Keep one architectural concern per change.
2. Run `scenes/tests/full_program_smoke_test.tscn` after every gameplay, race, UI, input, vehicle or track-generation change.
3. Keep car handling/tuning changes separate from architecture changes.
4. Keep generated-track changes separate from car physics changes.
5. Keep UI extraction separate from race logic extraction.
6. Keep `docs/vehicle_model.md` updated before and after vehicle-model changes.
7. Keep `README.md`, this file and `docs/roadmap.md` aligned after each responsibility-moving refactor.
