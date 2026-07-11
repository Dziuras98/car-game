# Architecture baseline

This document defines the current subsystem boundaries of the Godot car-game prototype. Windows is the sole target platform. Player control uses the project input map through keyboard and gamepad bindings; AI uses a separate external input channel.

## Validation baseline

The required pull-request gates are:

- public-repository current-tree and complete-history safety validation;
- localization validation, headless import and automatically discovered regression tests on Windows;
- Windows production/test export, production-PCK content validation and packaged startup smoke tests.

`scripts/ci/verify_project.ps1` is the complete verification entrypoint. Static checks enforce ownership boundaries and completed migrations, while runtime tests own behavioral contracts. The canonical end-to-end scenario is `scenes/tests/full_program_smoke_test.tscn`.

## Runtime composition

The configured entry scene is `scenes/startup.tscn`. `StartupRouter` loads:

- `scenes/main.tscn` for normal startup;
- `scenes/tests/exported_build_smoke_test.tscn` only for the test-export feature and private smoke argument.

The normal main scene composes the active-track container, player spawn, camera, speedometer/tachometer, minimap, menu, pause/race UI and `GameManager`.

## High-level game flow

1. `GameManager` validates car and track catalogs, including explicit AI eligibility when opponents are enabled.
2. `TrackCatalog.default_track_id` resolves the initial track.
3. `TrackSpawnController` stages and commits the selected `GeneratedTrack`.
4. `MenuOptionsBuilder` creates typed car and track options from catalogs.
5. `MainMenu` emits `StringName` mode, track and variant IDs.
6. `GameSessionStartTransaction` validates exact IDs and resolves the catalog car index and `TrackDefinition`.
7. The transaction clears prior runtime state and asks `GameSessionState` to enter `STARTING`.
8. The transaction activates the selected track and configures detached `CarSpawner` / `RaceSessionController` objects.
9. `CarInstanceFactory` creates the exact selected variant and assigns `CarSpecs` before scene-tree entry.
10. The player car receives its requested global transform before capturing its reset origin.
11. Race opponent creation prepares the complete typed car/AI-driver set before committing any opponent.
12. `RaceSessionController` builds stable `RaceParticipant` records for the player and opponents.
13. Camera, speedometer and minimap bind after the player car exists.
14. Race mode starts only after the complete opponent and lap-tracking set is ready.
15. `GameSessionState` commits mode, track and variant IDs and transitions to `FREE_DRIVE` or `RACE` only after all runtime stages succeed.
16. Any failed stage invokes the same runtime-reset callback and returns the lifecycle to `MENU`.
17. Returning to the menu disposes cars, opponents, participant records, tracking, committed IDs, input state and race UI.

## Session and orchestration responsibilities

### `GameManager`

`scripts/game/game_manager.gd` is a scene coordinator. It owns:

- catalog and scene-contract validation;
- menu and pause wiring;
- active-track references;
- construction of runtime coordinators;
- camera/HUD/minimap target binding;
- public read-only lifecycle access.

It exposes `get_session_phase()` and re-emits `GameSessionState.phase_changed` as `session_phase_changed`. It must not duplicate session IDs, infer state from UI visibility or contain the detailed startup stage sequence.

### `GameModes` and `GameSessionState`

- `GameModes` owns the supported `StringName` mode identifiers.
- Mode, track and car-variant identifiers are `StringName` throughout menu, catalog, transaction and committed session state.
- `GameSessionState` owns `MENU`, `STARTING`, `FREE_DRIVE` and `RACE`.
- State-changing operations return `GameSessionState.Result`, distinguishing invalid phase, unsupported mode, empty track ID and empty variant ID.
- Rejected operations do not mutate committed state or emit phase transitions.

### `GameSessionStartTransaction`

`scripts/game/game_session_start_transaction.gd` owns selection validation, stage ordering, final commit and rollback. It uses explicit callbacks supplied by `GameManager`, allowing the transition contract to be tested without a complete main scene.

The transaction is prepare-then-commit: no active session IDs are committed until the track, runtime controllers, player and—when applicable—race participant set are complete.

### Selection and spawning

Key helpers:

```text
scripts/game/game_modes.gd
scripts/game/game_session_state.gd
scripts/game/game_session_start_transaction.gd
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
- invalid content and indices are rejected rather than clamped or replaced with the first item;
- every car receives its variant `CarSpecs` before entering the tree;
- spawn transforms are applied before reset-origin capture;
- opponents use only explicitly AI-eligible supported variants;
- opponent count is all-or-nothing;
- a seed of `-1` randomizes the session, while non-negative seeds reproduce participant setup;
- free-drive switching may update only the committed variant ID.

## Race subsystem

```text
scripts/game/race_session_controller.gd
scripts/race/race_participant.gd
scripts/race/race_manager.gd
scripts/race/lap_tracker.gd
scripts/race/participant_race_state.gd
scripts/race/ai_race_driver.gd
scripts/race/ai_driver_profile.gd
scripts/race/opponent_ai_profile_factory.gd
scripts/ui/race_hud.gd
```

Responsibilities:

- `RaceParticipant` owns stable participant ID, player/opponent kind, car reference, ordinal and display label; labels never depend on `Node.name` parsing;
- `RaceSessionController` wires typed participants, track, lap tracking, minimap, HUD and race state;
- `RaceSessionController._reset_runtime_state()` is the shared cleanup path for failed startup and normal return;
- `RaceManager` owns IDLE/COUNTDOWN/RUNNING/FINISHED state and input locks;
- `LapTracker` owns checkpoint order, laps, progress, positions and finish order;
- `AiRaceDriver` produces external drive inputs from typed car, track and profile references.

Checkpoint crossings are authoritative for lap completion. Racing-line projection is used only for ordering between gates.

## Vehicle architecture

The car root is a `CharacterBody3D` controlled by `PlayerCarController`.

### Authoritative data path

```text
CarCatalog
  -> CarModelDefinition
    -> CarVariantDefinition
      -> CarSpecs
        -> CarDriveConfig
          -> runtime controllers
```

`CarSpecs.transmission_type` is the only transmission-mode source. The visual car scene contains visual, collision and audio structure but no tuning overrides.

### Runtime pipeline

1. sample player or external input;
2. snapshot input telemetry;
3. cast four cached suspension probes;
4. aggregate contact count, normal sum, grip sum and spring-support sum without temporary per-frame arrays;
5. recover lateral speed and calculate slip;
6. update transmission, clutch, engine RPM and longitudinal speed using bounded substeps;
7. update steering while contact exists;
8. apply bounded gravity and suspension support;
9. call `move_and_slide()`;
10. write collision-resolved velocity back to local runtime state.

Probe positions are rebuilt only when `CarDriveConfig` changes. Spring support is an explicit sum of active probe contributions; tests cover exactly one, two, three and four contacts. Contact normals and grip are averaged over active probes.

Generated track surfaces use the typed `TrackSurfaceBody` contract for grip. Surface grip and friction-circle coupling affect drive, braking, lateral recovery and handbrake behavior in the same physics frame.

## Track architecture

```text
TrackCatalog
  -> TrackDefinition
    -> GeneratedTrack
      -> TrackLayoutResource
        -> TrackGenerationConfig
        -> TrackGeometryData
        -> TrackGeneratedMeshes
```

`GeneratedTrack` builds into detached staged content and swaps it only after geometry, surfaces and checkpoint gates validate. Failed rebuilds preserve the prior committed track. Geometry revisions refresh AI, minimap and lap-tracking caches.

Render and collision geometry share generated meshes. Asphalt, shoulder and grass collision bodies are typed `TrackSurfaceBody` instances. Repeated markers, barriers and stadium elements use bounded `MultiMesh` groups.

## UI, input and localization

Major layouts are scene-driven. Catalog/session-dependent menu buttons and result rows are generated at runtime. All controls use the global theme. Localization catalogs are loaded before normal main-scene routing; startup terminates with a non-zero exit when catalog initialization fails.

`GameInputActions` owns action identifiers. `project.godot` owns keyboard/gamepad bindings and deadzones. Player actions and external AI input remain separate channels.

## Export architecture

`export_presets.cfg` contains exactly two Windows Desktop presets:

- `Windows Desktop` for production;
- `Windows Test` for packaged regressions.

The production PCK is inspected after export. CI fails when test scenes/scripts, CI scripts or documentation are packaged, or when required production paths are absent.

## Change rules

- Keep catalog/resource ownership explicit; do not add implicit fallback selection.
- Keep `GameManager` and `PlayerCarController` as coordinators.
- Keep detailed startup sequencing in `GameSessionStartTransaction`.
- Preserve prepare-then-commit semantics for tracks, sessions and opponent sets.
- Keep lifecycle phase and committed IDs solely in `GameSessionState`.
- Use typed lifecycle results rather than boolean-only transition failures.
- Use `RaceParticipant` for identity and labels; never parse participant semantics from node names.
- Use one race-runtime cleanup implementation for rollback and menu return.
- Keep ground-contact probes cached and contact aggregation allocation-free.
- Add focused regression coverage with each subsystem change.
- Preserve the canonical full-program smoke flow and complete Windows verification.
