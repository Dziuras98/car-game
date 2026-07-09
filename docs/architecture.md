# Architecture baseline

This document describes the current architecture of the Godot car game prototype and the intended direction for cleanup.

It is not a final architecture. It is a validated baseline snapshot intended to guide incremental refactoring.

## Validation status

The current baseline has been manually validated in Godot Android Editor and with the extended full-program smoke test.

Validated areas:

- project opens without parse errors;
- main menu flow works;
- free-drive mode works;
- race mode works;
- AI opponents move after countdown;
- player input lock/unlock works during race flow;
- `switch-car` is allowed only in free-drive mode;
- automatic transmission car can accelerate, brake and reverse;
- manual transmission car can shift through forward, neutral and reverse states;
- mobile touch controls work on Android;
- engine and tire audio work on Android;
- results screen and return-to-menu cleanup work;
- post-race free-drive reentry works.

The current regression gate is `scenes/tests/full_program_smoke_test.tscn`, optionally launched through `scripts/tests/run_full_program_smoke_test.gd`.

The mobile-controls scene refactor has been reported as passing the full-program smoke test. The later `VehicleMotionModel` extraction is behavior-preserving by design, but still requires the same smoke test after checkout.

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
- high-level game/free-drive/race logic attached to the root node;
- temporary Android mobile driving overlay instantiated by `GameManager` from `scenes/ui/mobile_drive_controls.tscn`.

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
    tire_model.gd
    tire_squeal_audio.gd
    torque_converter_model.gd
    vehicle_motion_model.gd
  game/
    game_manager.gd
    car_spawner.gd
  race/
    ai_race_driver.gd
    generated_track.gd
    lap_tracker.gd
    race_manager.gd
  tests/
    full_program_smoke_test.gd
    game_test_adapter.gd
    run_full_program_smoke_test.gd
  ui/
    countdown_overlay.gd
    lap_position_hud.gd
    main_menu.gd
    mobile_drive_controls.gd
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
3. `GameManager` instantiates the temporary mobile drive controls scene.
4. The main menu is shown.
5. The player selects mode, track and car.
6. `GameManager` receives the menu signal.
7. `CarSpawner` instantiates the selected car at `CarSpawn`.
8. Camera, speedometer and minimap are pointed at the active car.
9. In free-drive mode, player input is enabled immediately and car switching is allowed.
10. In race mode, car switching is blocked.
11. In race mode, `CarSpawner` creates opponents and AI drivers.
12. `RaceManager` runs the countdown and unlocks player/AI input after `START`.
13. `LapTracker` updates lap/progress/position logic each physics tick.
14. `RaceHud` delegates countdown, lap/position and results UI to specialized helpers.

## Car architecture

Current car root type: `CharacterBody3D`.

Current main controller: `scripts/car/car_controller.gd`.

Responsibilities currently inside the controller:

- forward/reverse speed model;
- applying selected gears;
- steering model;
- grounding behavior;
- reset-to-start behavior;
- skid-mark dispatch;
- movement through `move_and_slide()`.

Specialized car helpers:

```text
scripts/car/car_input.gd                    # player/external input abstraction
scripts/car/manual_transmission_model.gd    # manual gear-up/gear-down requests
scripts/car/automatic_transmission_model.gd # automatic gear-selection decisions
scripts/car/shift_timer_model.gd            # shift timer update and delay selection
scripts/car/engine_model.gd                 # RPM, torque curve and limiter
scripts/car/drivetrain_model.gd             # gear ratios, wheel RPM, wheel force and drive acceleration
scripts/car/torque_converter_model.gd       # automatic RPM coupling and torque multiplication
scripts/car/resistance_model.gd             # drag and rolling resistance
scripts/car/tire_model.gd                   # lateral grip recovery and tire slip intensity
scripts/car/vehicle_motion_model.gd         # local/global velocity projection helpers
scripts/car/skid_mark_emitter.gd            # skid mark visual effect
```

This is acceptable for a prototype and has passed the current regression test before the latest vehicle-motion extraction. The controller should still be split further before drivetrain and tire behavior are expanded.

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
  vehicle_motion_model.gd       # local/global velocity projection helpers
  skid_mark_emitter.gd          # skid mark visual effect
  car_specs.gd                  # Resource with tunable car data
  engine_audio.gd
  tire_squeal_audio.gd
```

`vehicle_motion_model.gd` now exists and is intentionally narrow. It only converts between local forward/lateral speed and global horizontal velocity using the car transform. It does not apply gravity, grounding, steering or `move_and_slide()`.

## Race/game architecture

Current high-level coordinator: `scripts/game/game_manager.gd`.

Current responsibilities of `GameManager`:

- receiving menu selection;
- storing selected mode and track IDs;
- delegating player/opponent spawn to `CarSpawner`;
- wiring camera, speedometer and minimap targets;
- instantiating the temporary mobile drive controls scene;
- starting free-drive or race mode;
- allowing car switching only in free-drive mode;
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
scripts/ui/countdown_overlay.gd   # countdown overlay scene binding and visibility
scripts/ui/lap_position_hud.gd    # lap and race-position display
scripts/ui/results_screen.gd      # results list and return-to-menu button
scripts/ui/mobile_drive_controls.gd # temporary Android touch-driving overlay binding
```

This is now a validated split compared to the original monolithic coordinator. Remaining cleanup should focus on reducing `car_controller.gd`, splitting `generated_track.gd`, improving test/diagnostic APIs, and avoiding new feature work without running the regression test.

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
  checkpoint_builder.gd         # physical checkpoint and lap-validation volumes
```

## UI architecture

Current UI approach is mostly scene-driven for the main race/menu surfaces:

- `main_menu.tscn` owns the static main menu layout; `main_menu.gd` controls menu state, labels, signals and dynamic option-button creation;
- `countdown_overlay.tscn` owns the countdown overlay layout; `countdown_overlay.gd` updates text and visibility;
- `lap_position_hud.tscn` owns the lap/position HUD layout; `lap_position_hud.gd` updates lap and position values;
- `results_screen.tscn` owns the results screen layout; `results_screen.gd` updates visibility, return-to-menu signaling and dynamic result rows;
- `mobile_drive_controls.tscn` owns the temporary Android touch overlay layout; `mobile_drive_controls.gd` binds scene buttons to input actions;
- `speedometer.tscn` owns the speedometer/tachometer layout; `speedometer.gd` binds it to the active car;
- `minimap.gd` still draws the map and participants manually.

Target direction:

```text
scenes/ui/
  main_menu.tscn
  race_hud.tscn
  countdown_overlay.tscn
  results_screen.tscn
  mobile_drive_controls.tscn
  speedometer.tscn
  minimap.tscn
```

UI layout should be scene-driven. Scripts should update labels, visibility and signals, not construct the whole visual hierarchy unless there is a specific reason.

The current exception is runtime-driven repeated content: main-menu option buttons are still created from the current menu step and car catalog data, and results rows are still created from the race result list. That dynamic construction belongs in scripts until those controls need reusable item scenes.

## Test architecture

Current automated runtime test:

```text
scenes/tests/full_program_smoke_test.tscn
scripts/tests/full_program_smoke_test.gd
scripts/tests/game_test_adapter.gd
scripts/tests/run_full_program_smoke_test.gd
```

The test is an extended full-program smoke/regression test. It instantiates `scenes/main.tscn`, presses visible menu buttons, simulates input through `Input.action_press()` / `Input.action_release()`, verifies free-drive automatic/manual behavior, verifies race setup, checks `switch-car` blocking in race mode, waits through a longer AI race soak segment, simulates player finish and verifies return-to-menu cleanup.

`GameTestAdapter` centralizes smoke-test access to the current car, opponent list, configured opponent count, selected mode/track, node visibility, visible menu/results buttons, return-to-menu flow and simulated player finish. The test runner should use the adapter instead of directly reading `GameManager` fields.

Current limitation: `GameTestAdapter` still knows selected `GameManager` internals. This is acceptable for the current prototype because the coupling is centralized, but a future production-facing diagnostic API on `GameManager` would be cleaner.

## Data architecture

Current data is mostly stored in exported variables on scenes and scripts.

This is acceptable now, but it will become awkward when adding more cars and tracks.

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

Cars are cataloged through `CarCatalog -> CarModelDefinition -> CarVariantDefinition -> CarSpecs`.

Recommended future track and mode data model:

```text
resources/tracks/
  simple_oval.tres

resources/game_modes/
  free_drive.tres
  race.tres
```

Use Resources for reusable car, track and mode definitions. Scenes should instantiate visuals and behavior; Resources should carry tunable data.

## Refactoring rules

1. Keep one architectural concern per change.
2. Run `scenes/tests/full_program_smoke_test.tscn` after every gameplay, race, UI or input change.
3. Keep car handling changes separate from race/menu/UI refactors.
4. Do not add new cars while extracting car systems.
5. Keep UI extraction separate from race logic extraction.
6. Keep procedural track changes separate from car physics changes.
7. Keep `docs/vehicle_model.md` updated before and after vehicle-model changes.

## Current technical risks

| Risk | Severity | Reason |
|---|---:|---|
| `car_controller.gd` is still large | High | Gear application, steering, grounding and movement are still coupled, although local/global velocity projection has been extracted |
| Track generator mixes data and scenery | Medium/High | Adding more tracks will duplicate or complicate logic |
| Lap tracking is heuristic | Medium/High | Uses racing-line progress rather than physical checkpoints |
| `GameTestAdapter` knows selected `GameManager` internals | Medium | Better than spreading private access through tests, but a public diagnostic API would be cleaner |
| Runtime-created UI rows/buttons are still script-built | Low/Medium | Main layouts are scene-driven, but menu options and results rows still depend on runtime data |
| Mobile controls are still temporary test UI | Low/Medium | The layout is scene-driven now, but it is still not final configurable input UI |
| Procedural audio may scale poorly with many cars | Medium | Each active car can generate audio samples |
| Car/track lists are hardcoded | Medium | Adding content requires script and scene edits |

## Preferred next refactor

After the UI scene-driven baseline, continue in this order:

1. Split `scripts/race/generated_track.gd` into track data, surface generation and decoration responsibilities.
2. Continue reducing `scripts/car/car_controller.gd` without changing driving feel.
3. Add a cleaner test/diagnostic API so `GameTestAdapter` reads less `GameManager` internal state directly.
4. Replace lap-tracking heuristics with checkpoint-based validation when adding more tracks.

Do not continue deeper vehicle movement refactors without running the extended smoke test immediately after each step.
