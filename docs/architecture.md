# Architecture baseline

This document defines the current subsystem boundaries of the Godot car-game prototype. It describes the code that is expected to remain stable while new cars, tracks and race features are added.

## Validation baseline

The required pull-request gates are:

- Windows localization validation, headless import and regression tests;
- Windows production/test export and packaged startup smoke tests;
- Android debug APK export, integrity and manifest validation.

`scripts/ci/verify_project.ps1` is the single complete Windows verification entrypoint. It validates localization and then delegates test execution to `scripts/ci/run_tests.ps1`, which discovers tests automatically instead of maintaining a handwritten list:

- standalone scripts under `scripts/tests/` must extend `SceneTree`;
- all scenes under `scenes/tests/` are executed, except explicit packaged-only fixtures;
- each command receives an independent timeout and log;
- Godot runtime-error output fails the command even when its exit code is zero;
- static checks reject architectural fallback paths, completed-migration regressions, production test-only identifiers, mutable GitHub Action tags and orphaned test scripts.

The canonical end-to-end test is `scenes/tests/full_program_smoke_test.tscn`, which runs `scripts/tests/full_program_smoke_test.gd`.

## Runtime composition

The configured project entry scene is:

```text
scenes/startup.tscn
```

`StartupRouter` selects:

- `scenes/main.tscn` for a normal launch;
- `scenes/tests/exported_build_smoke_test.tscn` for the packaged smoke-test argument.

The normal main scene composes:

- track container and generated active track;
- player spawn point;
- follow camera;
- speedometer/tachometer and minimap;
- menu, pause and race UI;
- lighting/environment;
- the high-level game coordinator.

## High-level game flow

1. `GameManager` validates the car and track catalogs, including the existence of an explicit AI-eligible variant when opponents are enabled.
2. `TrackCatalog.default_track_id` resolves the initial track.
3. `TrackSpawnController` instantiates and validates the selected `TrackDefinition` before committing it as `TrackContainer/ActiveTrack`.
4. Menu options are built from catalog data.
5. The user selects an explicitly supported mode, track, model and variant.
6. `GameManager` validates the exact IDs and configures a staged `CarSpawner` / `RaceSessionController` pair for the selected track.
7. `CarInstanceFactory` instantiates the exact selected variant and assigns its `CarSpecs` before scene-tree entry; invalid indices are rejected rather than clamped.
8. Car spawners assign the requested global transform and then capture it as the reset origin.
9. Race opponent creation prepares the complete requested set of typed car/AI-driver pairs before any participant is committed to the scene.
10. Camera, speedometer and minimap bind only after the player car exists.
11. Free drive enables input immediately; race mode commits only after all opponents and lap tracking are ready, then starts the countdown.
12. `LapTracker` consumes ordered checkpoint crossings and continuous racing-line progress.
13. Any failed session-start step clears partial runtime state and returns to the main menu.
14. Returning to the menu disposes cars, opponents, input state and race UI.

## Game and race responsibilities

### `GameManager`

`scripts/game/game_manager.gd` is a coordinator. It owns:

- selected mode, track and car variant IDs;
- menu wiring and high-level transitions;
- active-track activation;
- transactional session startup and rollback;
- camera/HUD/minimap binding;
- free-drive and race session entry/cleanup;
- pause and mobile-control lifecycle.

It must not accumulate vehicle physics, procedural track construction, detailed lap rules, low-level UI layout logic or test-simulation facades.

### Selection and spawning

Key helpers:

```text
scripts/game/car_selection_state.gd
scripts/game/menu_options_builder.gd
scripts/game/track_spawn_controller.gd
scripts/game/car_spawner.gd
scripts/game/car_instance_factory.gd
scripts/game/player_car_spawn_controller.gd
scripts/game/opponent_participant_spawner.gd
```

Rules:

- catalog IDs are authoritative;
- car and track catalog arrays are statically typed;
- `TrackCatalog.default_track_id` is the only default-track mechanism;
- every car variant supplies a scene and `CarSpecs`;
- `CarSpecs` is assigned before a car enters the tree;
- player-car indices outside the configured catalog range are rejected rather than corrected;
- spawn transforms are applied before `capture_current_transform_as_start()` records the reset origin;
- opponents use only variants with explicit `ai_eligible = true` and a supported automatic-transmission contract;
- opponent drivers are configured through typed references before entering the scene tree;
- the requested opponent count is all-or-nothing: incomplete sets are discarded before scene commit;
- an opponent session seed of `-1` randomizes the session, while a non-negative seed reproduces variants, paint and driver profiles;
- missing or invalid content fails validation rather than selecting an implicit fallback.

### Race subsystem

```text
scripts/game/race_session_controller.gd
scripts/race/race_manager.gd
scripts/race/lap_tracker.gd
scripts/race/participant_race_state.gd
scripts/race/ai_race_driver.gd
scripts/race/ai_driver_profile.gd
scripts/race/opponent_ai_profile_factory.gd
scripts/ui/race_hud.gd
```

Responsibilities:

- `RaceSessionController` validates and wires participants, track signals, HUD and lifecycle, and reports whether startup committed successfully;
- `RaceManager` owns IDLE/COUNTDOWN/RUNNING/FINISHED state and input locks;
- `LapTracker` owns ordered checkpoint state, lap completion, continuous progress, positions and finish order;
- `AiRaceDriver` consumes typed `PlayerCarController`, committed `GeneratedTrack` and validated `AiDriverProfile` contracts and only produces drive input;
- `OpponentAiProfileFactory` derives per-opponent speed profiles from the session seed and opponent index without depending on unrelated random draws.

Checkpoint crossings, not nearest-line progress, are authoritative for lap completion. Progress is used for position ordering between gates. Disabling or removing an AI driver neutralizes its external input so stale throttle, braking or steering cannot remain active.

## Car architecture

The car root is a `CharacterBody3D` controlled by `PlayerCarController`.

### Authoritative data path

```text
CarCatalog
  -> Array[CarModelDefinition]
    -> Array[CarVariantDefinition]
      -> CarSpecs
        -> CarDriveConfig
          -> runtime controllers
```

`CarSpecs` is the persistent tuning resource. `CarDriveConfigBuilder` validates it and creates a sanitized runtime copy. `CarSpecs.transmission_type` is the sole transmission-mode state. There are no legacy boolean transmission selectors and no controller-export fallback.

The base car scene contains visual, collision and audio structure only. It does not serialize tuning fields, and `PlayerCarController` does not intercept unknown properties.

### Runtime helpers

```text
scripts/car/car_runtime_state.gd
scripts/car/car_drive_config.gd
scripts/car/car_drive_config_builder.gd
scripts/car/car_powertrain_controller.gd
scripts/car/car_chassis_controller.gd
scripts/car/car_reset_controller.gd
scripts/car/car_input.gd
scripts/car/engine_model.gd
scripts/car/drivetrain_model.gd
scripts/car/resistance_model.gd
scripts/car/tire_model.gd
scripts/car/ground_contact_model.gd
scripts/car/automatic_transmission_model.gd
scripts/car/manual_transmission_model.gd
scripts/car/torque_converter_model.gd
scripts/car/skid_mark_emitter.gd
```

### Physics-frame pipeline

1. process reset requests;
2. read player, AI or touch input;
3. snapshot throttle/brake telemetry;
4. cast four suspension/ground-contact probes within configured suspension reach;
5. average contact normal and current surface grip, then calculate support;
6. recover lateral speed and calculate current-frame slip;
7. update transmission, clutch, coupled engine RPM and longitudinal speed using bounded substeps and current-frame tire state;
8. update steering only while tire contact exists;
9. apply gravity and suspension support;
10. call `move_and_slide()`;
11. write collision-resolved horizontal velocity back to runtime state.

Surface grip and the friction-circle factor affect drive and braking in the same physics frame in which the surface is sampled. Tire-generated drive, brake, handbrake and steering forces require active ground contact. An airborne engine may free-rev, while only aerodynamic drag and gravity continue to affect chassis motion.

A manual or automatic gear change starts the configured shift timer. Geared wheel torque is blocked until that timer completes. Engine RPM blends between free-rev and wheel-driven coupling according to transmission and clutch state.

### Runtime reconfiguration

Changing `car_specs` rebuilds `CarDriveConfig`, reconfigures controllers, clamps the active gear, preserves motion where requested, refreshes skid-mark settings and synchronizes RPM into the new valid range.

## Track architecture

### Persistent data

```text
TrackCatalog
  -> default_track_id
  -> Array[TrackDefinition]
    -> PackedScene
      -> GeneratedTrack
        -> TrackLayoutResource
```

- `TrackCatalog` owns selection and the explicit default ID;
- `TrackDefinition` owns display/runtime metadata and the track scene;
- `TrackLayoutResource` owns control points, sampling, width, checkpoints and decoration parameters.

### Typed generation pipeline

```text
TrackLayoutResource
  -> TrackGenerationConfig
  -> TrackLayoutBuilder
  -> TrackGeometryData
  -> TrackGeneratedMeshes
  -> surface/collision/marker/barrier/checkpoint/decoration builders
```

`GeneratedTrack` builds into a detached generated-content root and swaps it atomically only after geometry, surfaces and checkpoint gates validate. Failed rebuilds preserve the last committed generated subtree. Geometry revision notifications invalidate cached data in AI, minimap and lap tracking.

Render/collision meshes share generated geometry. Surfaces publish grip metadata. Repeated boxes such as edge markers, barriers and stadium elements are grouped in bounded `MultiMesh` batches.

## UI and input architecture

Major layouts are scene-driven:

```text
scenes/ui/main_menu.tscn
scenes/ui/pause_menu.tscn
scenes/ui/countdown_overlay.tscn
scenes/ui/lap_position_hud.tscn
scenes/ui/results_screen.tscn
scenes/ui/mobile_drive_controls.tscn
scenes/ui/speedometer.tscn
scenes/ui/minimap.tscn
```

Dynamic menu buttons and result rows remain runtime-generated because their content is catalog/session dependent.

All controls use the global theme from `resources/ui/default_theme.tres`. Localization catalogs are loaded before normal main-scene routing.

`CarInput` keeps player, external AI and touch channels separate. Mobile controls call the active car's touch API; they do not mutate global input actions.

## Audio and effects

Procedural engine and tire audio use bounded voice budgets and listener-distance gates. Skid marks use a bounded reusable buffer and continue aging even when their source car loses tire contact. These systems must remain safe when several AI cars exist simultaneously.

## Change rules

- Keep catalog/resource ownership explicit; do not add implicit first-entry, clamped-index or mode fallbacks.
- Keep `GameManager` and `PlayerCarController` as coordinators.
- Preserve prepare-then-commit semantics for tracks, gameplay sessions and opponent sets.
- Do not add test-only suffixes or simulation entry points to production classes.
- Add focused tests with each subsystem change.
- Ensure every test script is discoverable, scene-referenced or an explicitly allowed helper.
- Preserve the canonical full-program smoke flow.
- Keep architecture changes separate from detailed handling tuning.
- Update documentation when responsibilities, data ownership or CI behavior changes.
