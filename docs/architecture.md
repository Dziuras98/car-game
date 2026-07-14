# Architecture baseline

This document defines the current subsystem boundaries of the Godot car-game prototype. Windows is the sole target platform. Player control uses the project input map through keyboard and gamepad bindings; AI uses a separate external input channel.

## Validation baseline

The required pull-request gates are:

- public-repository current-tree and complete-history safety validation;
- localization validation, headless import and automatically discovered regression tests on Windows;
- Windows production/test export, production-PCK content validation and packaged startup smoke tests.

`scripts/ci/verify_project.ps1` is the complete verification entrypoint. Static checks enforce ownership boundaries and completed migrations, while runtime tests own behavioral contracts. The canonical end-to-end scenario is `scenes/tests/full_program_smoke_test.tscn`.

## Current content composition

The authoritative catalogs currently expose:

- four car models and fifteen playable variants:
  - Nissan 370Z — 6MT and 7AT;
  - Nissan 370Z NISMO — 6MT and 7AT;
  - 1967 Shelby G.T. 500 — four-speed manual and C6 automatic;
  - 1995 Fiat Punto Type 176 — nine manual/CVT petrol and diesel variants;
- two tracks:
  - the generated simple oval;
  - the calibrated Tor Poznań reconstruction.

The catalog resources, not this list, remain authoritative. Documentation must be updated when catalog content changes.

## Runtime composition

The configured entry scene is `scenes/startup.tscn`. `StartupRouter` loads:

- `scenes/main.tscn` for normal startup;
- `scenes/tests/exported_build_smoke_test.tscn` only for the test-export feature and private smoke argument.

The normal main scene composes the active-track container, player spawn, camera, speedometer/tachometer, minimap, menu/loading UI, pause/race UI and `GameManager`.

## High-level game flow

1. `GameManager` validates car and track catalogs, race counts, spacing values and explicit AI eligibility.
2. `TrackCatalog.default_track_id` resolves the initial track.
3. `TrackSpawnController` stages and commits the selected `GeneratedTrack`.
4. `MenuOptionsBuilder` creates typed car and track options from catalogs.
5. `MainMenu` emits `StringName` mode, track and variant IDs after entering a blocking loading step and yielding frames so the loading UI is visible.
6. `GameSessionStartTransaction` validates exact IDs and resolves the catalog car index and `TrackDefinition`.
7. The transaction asks `GameSessionState` to enter `STARTING`. Rejection preserves the complete currently active runtime and committed session state.
8. Only after lifecycle admission succeeds does the transaction clear prior runtime objects and stage the selected track.
9. The transaction reports monotonic loading progress while it validates selection, prepares the track, creates the runtime controllers, spawns the player, prepares race participants and commits the session.
10. The transaction configures detached `CarSpawner` / `RaceSessionController` objects against the staged track.
11. `CarInstanceFactory` creates the exact selected variant and assigns validated `CarSpecs` before scene-tree entry.
12. The player car receives its requested global transform before capturing its reset origin.
13. Race opponent creation prepares the complete typed car/AI-driver set before committing any opponent; failed preparation restores the random-number-generator state.
14. `RaceSessionController` builds stable `RaceParticipant` records for the player and opponents.
15. Camera, speedometer, active-car label and minimap bind after the player car exists.
16. Race mode starts only after the complete opponent and lap-tracking set is ready.
17. The staged track is committed provisionally; same-ID definition replacement remains reversible until session commit succeeds.
18. `GameSessionState` commits mode, track and variant IDs and transitions to `FREE_DRIVE` or `RACE` only after all runtime stages succeed.
19. The track commit is finalized and runtime geometry rebuilds are locked for the active session.
20. Successful startup completes and hides the loading step. Any failed stage invokes the same runtime-reset callback, rolls back the track transaction, resets the menu and returns the lifecycle to `MENU`.
21. Returning to the menu disposes cars, opponents, participant records, tracking, committed IDs, input state and race UI, then releases the track-rebuild lock.

## Session and orchestration responsibilities

### `GameManager`

`scripts/game/game_manager.gd` is a scene coordinator. It owns:

- catalog and scene-contract validation;
- menu, loading-progress and pause wiring;
- active-track references;
- construction of runtime coordinators;
- camera/HUD/minimap target binding;
- public read-only lifecycle access;
- the single fatal-initialization path and the race-runtime fault boundary.

It exposes `get_session_phase()` and re-emits `GameSessionState.phase_changed` as `session_phase_changed`. It must not duplicate session IDs, infer state from UI visibility or contain the detailed startup stage sequence. Initialization failures atomically stop processing, clear partial runtime, disable interactive UI and display a blocking localized error. Packaged regression builds also exit non-zero.

### `GameModes` and `GameSessionState`

- `GameModes` owns the supported `StringName` mode identifiers.
- Mode, track and car-variant identifiers are `StringName` throughout menu, catalog, transaction and committed session state.
- `GameSessionState` owns `MENU`, `STARTING`, `FREE_DRIVE` and `RACE`.
- State-changing operations return `GameSessionState.Result`, distinguishing invalid phase, unsupported mode, empty track ID and empty variant ID.
- Rejected operations do not mutate committed state or emit phase transitions.

### `GameSessionStartTransaction`

`scripts/game/game_session_start_transaction.gd` owns selection validation, lifecycle admission, stage ordering, progress reporting, final commit and rollback. It uses explicit callbacks supplied by `GameManager`, allowing the transition contract to be tested without a complete main scene.

The transaction is prepare-then-commit: no active session IDs are committed until the track, runtime controllers, player and—when applicable—race participant set are complete. Runtime cleanup occurs only after `begin_start()` admits the transaction, so a rejected start cannot destroy an active session.

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
- invalid content, counts and indices are rejected rather than clamped or replaced with the first item;
- every car receives its variant `CarSpecs` before entering the tree;
- spawn transforms are applied before reset-origin capture;
- opponents use only explicitly AI-eligible supported variants;
- opponent count is all-or-nothing;
- failed opponent preparation restores RNG state so retrying a seeded request is deterministic;
- a seed of `-1` randomizes the session, while non-negative seeds reproduce participant setup;
- free-drive switching selects a uniformly random different catalog variant when possible and may update only the committed variant ID;
- the driving HUD reads the committed active variant label instead of inferring it from a scene name.

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
- `RaceSessionController` exposes read-only telemetry instead of mutable `LapTracker` or `RaceManager` references;
- `RaceSessionController._reset_runtime_state()` is the shared cleanup path for failed startup, runtime faults and normal return;
- `RaceManager` owns IDLE/COUNTDOWN/RUNNING/FINISHED state and input locks;
- `LapTracker` owns checkpoint order, laps, progress, positions and finish order;
- unknown cars return explicit absent telemetry (`0` or `-1`) rather than plausible first-place values;
- every committed geometry revision resets unfinished checkpoint sequences before projection is reacquired;
- `AiRaceDriver` produces external drive inputs from typed car, track and profile references;
- manual AI variants additionally receive one-shot shift-up/shift-down requests with RPM hysteresis and explicit forward/neutral/reverse recovery sequencing;
- conventional automatics and CVTs manage their own forward/reverse and ratio/gear state from the external throttle/brake channel;
- an AI or lap-tracking contract failure applies controlled braking, emits one runtime fault and returns the complete session to the menu boundary.

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

`CarSpecs.transmission_type` is the only transmission-mode source. Its current values are direct drive, manual, conventional automatic and CVT. The visual car scene contains visual, collision and audio structure; variant wrapper scenes may embed the same authoritative `CarSpecs` resource referenced by their catalog variant, but must not contain divergent tuning overrides.

Runtime `CarSpecs` replacement is transactional. `try_apply_car_specs()` validates and builds the candidate `CarDriveConfig` before replacing the committed resource or reconfiguring controllers. Invalid replacement preserves the prior configuration, motion state and active physics processing.

### Runtime pipeline

For every bounded simulation substep:

1. use the outer-frame player or external input snapshot, consuming one-shot gear requests only once;
2. cast four cached suspension probes;
3. accept only `TrackSurfaceBody` colliders on the dedicated `ground_probe_collision_mask` and reject normals below `minimum_ground_normal_dot`;
4. aggregate contact count, normal sum, grip sum and spring-support sum without temporary per-frame arrays;
5. recover lateral speed and calculate lateral slip intensity;
6. update manual/automatic/CVT state, clutch or converter coupling, engine RPM and requested longitudinal force;
7. limit drive, reverse, service-brake and handbrake acceleration through the longitudinal tire model and record signed longitudinal slip ratio/intensity;
8. combine lateral and longitudinal slip for steering authority, skid marks and tire audio;
9. update steering while valid ground contact exists;
10. apply bounded gravity and suspension support;
11. call `move_and_slide()`;
12. write collision-resolved velocity back to local runtime state before the next substep.

Probe positions are rebuilt only when `CarDriveConfig` changes. Spring support is an explicit sum of active probe contributions; tests cover exactly one, two, three and four contacts. Contact normals and grip are averaged over active probes. Barriers, other cars and untyped collision bodies cannot become suspension support.

Generated track surfaces use the typed `TrackSurfaceBody` contract for grip. Surface grip and active-contact fraction affect lateral recovery and longitudinal capacity in the same physics frame. Lateral tire use reduces the remaining longitudinal capacity through a friction-circle approximation; acceleration or braking demand beyond peak capacity generates longitudinal slip and transitions toward the configured sliding-grip multiplier.

Manual forward-gear changes include built-in throttle assistance: upshifts cut throttle during the shift delay, while downshifts request enough throttle to approach the wheel-coupled target RPM. The current input model does not expose an analog clutch pedal.

`PlayerCarController.get_telemetry_snapshot()` exposes an immutable `CarTelemetrySnapshot` for UI and regression assertions. Consumers do not receive mutable `CarRuntimeState` ownership.

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

`GeneratedTrack` builds into detached staged content and swaps it only after geometry, surfaces and checkpoint gates validate. `TrackGeometryData.validate()` verifies array consistency, finite values, non-degenerate segments, positive loop length, usable vectors, widths and edge orientation. Failed rebuilds preserve the prior committed track.

`get_racing_line_points()` returns only the last committed geometry and has no generation side effects. Geometry revisions refresh AI, minimap and lap-tracking caches. Layout changes requested during an active session are coalesced and deferred until the session releases the runtime rebuild lock.

Render and collision geometry share generated meshes. Asphalt, shoulder and grass collision bodies are typed `TrackSurfaceBody` instances. Repeated markers, barriers and stadium/trackside elements use bounded `MultiMesh` groups.

Track layouts may provide lap-progress profiles for road width, shoulder width, barrier distance/visibility, racing-line offset and banking. Tor Poznań uses these profiles together with calibrated traced geometry and dedicated pit, paddock, building, gantry, grandstand, curb and forest configuration.

## UI, input and localization

Major layouts are scene-driven. Catalog/session-dependent menu buttons and result rows are generated at runtime. The final selection transitions to a blocking loading panel; cancel/back input is consumed until startup succeeds or rolls back. The driving HUD displays the active catalog variant and refreshes after free-drive car switching. All controls use the global theme.

Localization catalogs are loaded before normal main-scene routing; startup terminates with a non-zero exit when catalog initialization fails.

`GameInputActions` owns action identifiers. `project.godot` owns keyboard/gamepad bindings and deadzones. Player actions and external AI input remain separate channels.

## Engine-audio architecture

Audio backend choice is explicit in each car scene:

- Nissan player scenes use full live profiled synthesis;
- Nissan AI scenes use committed baked coast/load WAV banks;
- Shelby player scenes use the dedicated live cross-plane V8 synthesizer and are not currently AI-eligible;
- Fiat Punto player and AI variants currently share live variant scenes using the dedicated four-cylinder petrol/diesel/turbo synthesizer.

The current fleet benchmark models the Nissan production race fixture: one live player synthesizer and three baked AI players. It must not be interpreted as a catalog-wide rule that every AI scene uses baked audio.

## Export architecture

`export_presets.cfg` contains exactly two Windows Desktop presets:

- `Windows Desktop` for production;
- `Windows Test` for packaged regressions.

The production PCK is inspected after export. CI fails when test scenes/scripts, CI scripts or documentation are packaged, or when required production paths are absent.

`scripts/ci/export_windows.ps1` temporarily injects source-derived Windows metadata into both presets. Tagged builds use the semantic tag; other builds include the short commit SHA. Numeric file versions include the workflow run number. The committed preset file is restored in a `finally` block after success or failure.

## Change rules

- Keep catalog/resource ownership explicit; do not add implicit fallback selection.
- Keep `GameManager` and `PlayerCarController` as coordinators.
- Keep detailed startup sequencing and progress reporting in `GameSessionStartTransaction`.
- Preserve prepare-then-commit semantics for tracks, sessions, runtime specs and opponent sets.
- Keep lifecycle phase and committed IDs solely in `GameSessionState`.
- Use typed lifecycle results rather than boolean-only transition failures.
- Use `RaceParticipant` for identity and labels; never parse participant semantics from node names.
- Use one race-runtime cleanup implementation for rollback, runtime faults and menu return.
- Keep ground-contact probes cached, typed and allocation-free.
- Keep lateral and longitudinal slip state explicit; do not bypass tire capacity with direct drive/brake speed changes.
- Freeze generated-track mutation while a gameplay session is active.
- Add focused regression coverage with each subsystem change.
- Preserve the canonical full-program smoke flow and complete Windows verification.
