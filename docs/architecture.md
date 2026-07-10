# Architecture baseline

This document describes the current architecture of the Godot car-game prototype and the boundaries that future changes should preserve.

## Validation baseline

The required Windows CI suite imports the project and runs:

```text
scripts/tests/car_controller_runtime_config_test.gd
scenes/tests/car_catalog_validation_test.tscn
scenes/tests/car_specs_runtime_reconfiguration_test.tscn
scenes/tests/car_powertrain_controller_test.tscn
scenes/tests/car_chassis_motion_test.tscn
scenes/tests/track_layout_builder_test.tscn
scenes/tests/track_layout_resource_test.tscn
scenes/tests/lap_tracker_checkpoint_test.tscn
scenes/tests/full_program_smoke_test.tscn
```

The full-program smoke test covers menu navigation, free drive, both 370Z variants, car switching, race countdown, AI movement, HUD/minimap binding, results and return-to-menu cleanup.

## Runtime composition

The main scene is:

```text
scenes/main.tscn
```

It composes:

- Resource-backed generated oval track;
- player spawn point;
- follow camera;
- lighting and environment;
- speedometer/tachometer;
- minimap;
- scene-driven menu and race UI;
- high-level game, free-drive and race coordination.

The root uses:

```text
scripts/game/game_manager.gd
```

## Module map

```text
scenes/
  main.tscn
  cars/
    370z.tscn
    370zat.tscn
    player_car.tscn
    test_car.tscn
  tests/
    car_catalog_validation_test.tscn
    car_chassis_motion_test.tscn
    car_powertrain_controller_test.tscn
    car_specs_runtime_reconfiguration_test.tscn
    track_layout_builder_test.tscn
    track_layout_resource_test.tscn
    lap_tracker_checkpoint_test.tscn
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
  tracks/
    simple_oval.tres

scripts/
  camera/
  car/
  game/
  race/
  tests/
  track/
  ui/
```

## High-level game flow

1. Godot loads `scenes/main.tscn`.
2. `GameManager` loads model/variant selection from `resources/cars/catalog.tres`.
3. Menu options are built for mode, track, model and variant.
4. `CarSpawner` and `RaceSessionController` are configured.
5. The selected variant is instantiated through `CarInstanceFactory`.
6. Variant `CarSpecs` is assigned before the car enters the scene tree.
7. Camera, speedometer and minimap bind to the active car.
8. Free drive enables input immediately and permits car switching.
9. Race mode spawns opponents, runs the countdown and locks switching.
10. `LapTracker` consumes ordered checkpoint crossings, updates participant progress and produces result ordering.

## Game and race responsibilities

### `GameManager`

`GameManager` is a coordinator. It owns:

- menu selection and state transitions;
- mode/track/model/variant selection;
- wiring the spawner, camera, HUD and minimap;
- starting free-drive or race sessions;
- returning to the menu.

It must not accumulate vehicle physics, detailed race rules or procedural UI layout code.

### Spawn helpers

```text
scripts/game/car_selection_state.gd
scripts/game/menu_options_builder.gd
scripts/game/car_spawner.gd
scripts/game/car_instance_factory.gd
scripts/game/player_car_spawn_controller.gd
scripts/game/opponent_spawn_layout.gd
scripts/game/opponent_paint_randomizer.gd
scripts/game/opponent_participant_spawner.gd
```

`CarInstanceFactory` requires every catalog variant and instantiated car scene to provide non-null `CarSpecs`. Opponent selection prefers variants whose specs enable automatic transmission. It does not mutate transmission fields on the controller.

### Race helpers

```text
scripts/game/race_session_controller.gd
scripts/race/race_manager.gd
scripts/race/lap_tracker.gd
scripts/race/ai_race_driver.gd
scripts/ui/race_hud.gd
```

`RaceSessionController` wires the spawner, race manager, lap tracker, HUD and minimap. `RaceManager` owns countdown/start/finish state. `LapTracker` owns ordered checkpoint validation, completed laps, nearest-line position sorting and finish order. `AiRaceDriver` only produces drive input.

An intermediate checkpoint sequence must be completed before a forward finish-line crossing can add a lap. Reverse and out-of-order crossings are rejected. Racing-line progress is not authoritative for lap completion.

## Car architecture

The car root type is:

```text
CharacterBody3D
```

The public controller is:

```text
scripts/car/car_controller.gd
class_name PlayerCarController
```

`PlayerCarController` is a thin runtime coordinator. It owns:

- one exported `car_specs` Resource;
- runtime state and helper instances;
- public telemetry/control methods;
- physics-frame orchestration;
- runtime specs reconfiguration;
- reset delegation.

### Authoritative data path

```text
CarVariantDefinition -> CarSpecs -> CarDriveConfig -> runtime controllers
```

There is no active legacy-export fallback. `CarDriveConfigBuilder` only copies a non-null `CarSpecs` into a sanitized runtime config.

The old tuning fields are not exported by `PlayerCarController`. A temporary `_set()` compatibility list ignores stale serialized keys in the large base 370Z scene. Those keys are not runtime data and should disappear when that scene is next resaved in Godot.

### Car helpers

```text
scripts/car/car_runtime_state.gd
scripts/car/car_drive_config.gd
scripts/car/car_drive_config_builder.gd
scripts/car/car_powertrain_controller.gd
scripts/car/car_chassis_controller.gd
scripts/car/car_reset_controller.gd
scripts/car/car_input.gd
scripts/car/manual_transmission_model.gd
scripts/car/automatic_transmission_model.gd
scripts/car/shift_timer_model.gd
scripts/car/drivetrain_model.gd
scripts/car/torque_converter_model.gd
scripts/car/engine_model.gd
scripts/car/resistance_model.gd
scripts/car/tire_model.gd
scripts/car/vehicle_motion_model.gd
scripts/car/skid_mark_emitter.gd
```

### Physics-frame pipeline

1. check reset input;
2. read player or external input;
3. store throttle/brake telemetry;
4. update transmission, RPM and longitudinal speed;
5. update grounded tire recovery and current-frame slip;
6. update steering using current-frame slip;
7. apply velocity, floor stick/gravity and `move_and_slide()`;
8. write collision-resolved horizontal velocity back to runtime state.

### Runtime reconfiguration

Changing `car_specs` rebuilds the runtime config, reconfigures powertrain/chassis helpers, clamps the gear, updates the existing skid emitter and synchronizes internal/public RPM. Motion state is preserved unless initialization explicitly requests a reset.

## Track architecture

The generated track entry point is:

```text
scripts/race/generated_track.gd
```

It delegates to:

```text
scripts/track/track_generated_content_root.gd
scripts/track/track_geometry_data.gd
scripts/track/track_layout_resource.gd
scripts/track/track_layout_builder.gd
scripts/track/track_surface_mesh_builder.gd
scripts/track/track_collision_builder.gd
scripts/track/track_marker_builder.gd
scripts/track/track_barrier_builder.gd
scripts/track/track_decoration_builder.gd
scripts/track/track_checkpoint_builder.gd
scripts/track/track_checkpoint_gate.gd
scripts/track/track_material_factory.gd
```

`resources/tracks/simple_oval.tres` is authoritative for control points, sampling, road dimensions, decoration settings and ordered checkpoint progress values.

`GeneratedTrack` builds finish/checkpoint `Area3D` gates from the sampled geometry and emits `checkpoint_crossed(car, checkpoint_index, is_forward)`. Gate direction is derived from the sampled track tangent and the car's world velocity.

The public `get_racing_line_points()` method supplies AI, minimap and race-position sorting. It does not complete laps.

Focused tests freeze the 108-point geometry, Resource mapping, generated gate count, crossing direction and ordered lap-validation contract.

## UI architecture

Major layouts are scene-driven:

```text
scenes/ui/main_menu.tscn
scenes/ui/countdown_overlay.tscn
scenes/ui/lap_position_hud.tscn
scenes/ui/results_screen.tscn
scenes/ui/mobile_drive_controls.tscn
scenes/ui/speedometer.tscn
scenes/ui/minimap.tscn
```

Scripts update values, visibility and signals. Runtime-generated menu buttons and result rows remain script-driven because their content depends on catalog/session data.

## Change rules

- Commit helper tests with subsystem changes.
- Update relevant documentation in the same change.
- Publish each completed stage to `master` as one atomic commit so CI runs are not cancelled by later commits.
- Do not mix architecture cleanup with detailed handling tuning or new vehicle imports.
- Add new cars through catalog/model/variant/spec Resources rather than controller overrides.
- Do not add major modes or tracks until the performance pass is complete.
