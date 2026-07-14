# Car Game

Godot 4.7 prototype focused on car driving, short races, data-driven vehicle variants and procedurally generated tracks. Windows is the sole target platform; player input is provided through keyboard and gamepad actions.

The project is intentionally text-heavy and regression-tested so gameplay systems can be changed without silently breaking exported builds.

## Current baseline

The repository currently provides:

- free-drive and race modes owned by the shared `GameModes` contract, with explicit validation and rollback on failed session startup;
- a blocking loading step between the final menu selection and gameplay, with monotonic progress reported by the staged startup pipeline;
- catalog-driven track, car model and car variant selection through typed resource arrays;
- four catalog models and fifteen playable variants:
  - Nissan 370Z Z34 — 6MT and 7AT;
  - Nissan 370Z NISMO Z34 V2 — 6MT and 7AT;
  - 1967 Shelby G.T. 500 — four-speed manual and C6 three-speed automatic;
  - 1995 Fiat Punto Type 176 — nine petrol, diesel, turbo and Selecta CVT variants;
- authoritative validation across `CarCatalog`, `CarModelDefinition`, `CarVariantDefinition` and `CarSpecs`;
- explicit AI eligibility on supported car variants and all-or-nothing opponent spawning;
- AI support for explicitly eligible manual, conventional automatic and CVT variants, including manual shift requests and reverse recovery;
- a modular `CharacterBody3D` vehicle runtime with powertrain, transmission, tire, four-point ground-contact and reset helpers;
- `CarSpecs.TransmissionType` as the sole transmission-mode state, including direct drive, manual, automatic and CVT modes;
- automatic throttle cut on manual upshifts and RPM-targeted throttle blips on manual downshifts;
- relational gearbox, automatic-transmission and CVT validation in addition to per-field tuning ranges;
- surface-dependent grip, lateral slip, longitudinal slip-ratio traction/braking limits and combined-slip effects;
- two catalog tracks: the generated simple oval and the calibrated Tor Poznań reconstruction;
- generated track surfaces, collision, variable width/banking profiles, barriers, markers, checkpoints and track-specific decoration;
- ordered checkpoint validation and continuous race-position progress;
- speedometer, tachometer, minimap, loading, countdown, lap/position HUD, active-car label, results and pause UI;
- random selection of a different catalog variant when switching cars in free drive;
- Polish and English localization resources with explicit startup loading;
- keyboard and gamepad player input plus a separate external AI input channel;
- model-specific procedural player audio, Nissan baked AI audio banks, bounded audio processing and skid-mark buffers;
- Windows production and packaged-test export presets;
- one complete project-verification entrypoint and automatically discovered regression tests with per-command timeouts plus runtime-error and unexpected-warning detection;
- current-tree and complete-history public-repository safety checks;
- SHA-pinned GitHub Actions, verified export-template archives and diagnostics-only pull-request artifacts.

The project remains a prototype. Structural correctness and test coverage take priority over uncontrolled feature expansion.

## Engine and startup

- Engine used by CI: Godot `4.7-stable`
- Renderer: Forward Plus
- Physics: Jolt Physics
- Project entry scene: `scenes/startup.tscn`
- Normal gameplay scene: `scenes/main.tscn`
- Global theme: `resources/ui/default_theme.tres`

`StartupRouter` sends normal launches to the gameplay scene and packaged smoke-test launches to the exported-build regression scene.

## Running the project

1. Clone the repository on Windows.
2. Open `project.godot` in Godot 4.7.
3. Run the project with `F6`/`F5` as appropriate.
4. Select mode, track, model and variant in the menu.
5. The menu enters a non-cancellable loading step while the selected session is validated and constructed.

The complete car and track catalogs are validated before menu construction. The active track is created before the selected car. A gameplay session is considered started only after the exact mode/track/variant IDs, player car and required race participants validate. A failed step clears partial runtime state and returns to the menu. Free drive enables input immediately after commit; race mode starts the countdown only after the complete opponent set and lap tracking are ready.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Accelerate | `W`, Arrow Up | Right trigger |
| Brake / reverse request | `S`, Arrow Down | Left trigger |
| Steer left / right | `A` / `D`, arrows | Left stick |
| Handbrake | Space | A / Cross |
| Reset car | `R` | X / Square |
| Rear-view camera | `C` | Right shoulder |
| Pause | Esc | Start / Options |
| Switch car | `T`, free-drive only | Back / View |
| Gear up / down | `E` / `Q` | Y / Triangle and B / Circle |

Input bindings are defined in `project.godot`. `CarInput` reads the standard action map for the player and keeps AI input on a separate typed channel. `scripts/tests/input_mapping_test.gd` requires every gameplay action to retain both a keyboard and a gamepad event.

## Data ownership

### Cars

```text
CarCatalog
  -> Array[CarModelDefinition]
    -> Array[CarVariantDefinition]
      -> CarSpecs
        -> CarDriveConfig
          -> runtime controllers
```

Important paths:

- `resources/cars/catalog.tres`
- `resources/cars/nissan/370z/`
- `resources/cars/nissan/370z_nismo/`
- `resources/cars/ford/mustang_shelby_gt500_1967/`
- `resources/cars/fiat/punto_176_1995/`
- `scripts/car/car_controller.gd`
- `scripts/car/car_drive_config_builder.gd`
- `scripts/car/car_powertrain_controller.gd`
- `scripts/car/tire_model.gd`

`CarCatalog.validate()` is the authoritative content boundary. It enforces globally unique model/variant IDs and delegates model, variant and specification validation. `CarSpecs` is the authoritative tuning source. Runtime controllers consume a sanitized `CarDriveConfig`; game systems use the public `PlayerCarController` API instead of reading tuning fields directly.

`CarVariantDefinition.ai_eligible` is the sole declaration that a variant may be used by the current AI. An eligible variant must provide a valid AI scene and a geared transmission supported by the runtime. Manual opponents use one-shot external shift requests, RPM hysteresis and explicit neutral/reverse transitions during recovery. Conventional automatics and CVTs manage their own direction and ratio/gear state.

### Tracks

```text
TrackCatalog
  -> default_track_id
  -> Array[TrackDefinition]
    -> GeneratedTrack scene
      -> TrackLayoutResource
        -> TrackGenerationConfig
          -> typed builder pipeline
```

Important paths:

- `resources/tracks/catalog.tres`
- `resources/tracks/simple_oval_definition.tres`
- `resources/tracks/simple_oval.tres`
- `resources/tracks/tor_poznan_definition.tres`
- `resources/tracks/tor_poznan.tres`
- `scripts/race/generated_track.gd`
- `scripts/track/`

`TrackCatalog.default_track_id` is the sole default-track declaration. Generated geometry is rebuilt atomically and publishes a geometry revision so AI, minimap and lap tracking can refresh their cached data. The Tor Poznań resource additionally uses progress-based width, shoulder, barrier, racing-line and banking profiles plus a dedicated pit/trackside environment configuration.

## Runtime architecture

`GameManager` coordinates menu state, loading progress, active track, transactional session startup, spawning, camera/HUD binding and transitions between free drive and race. Detailed responsibilities are delegated to:

- `GameModes`, `GameSessionState`, `GameSessionStartTransaction`, `CarSelectionState`, `MenuOptionsBuilder` and `TrackSpawnController`;
- `CarSpawner`, `CarInstanceFactory` and participant spawn helpers;
- `RaceSessionController`, `RaceManager` and `LapTracker`;
- `PlayerCarController`, powertrain/chassis helpers and `CarInput`;
- generated-track builders and UI scene controllers.

Production coordinators do not expose test-simulation entry points. Integration tests use the dedicated `GameTestAdapter` and observable runtime state.

See `docs/architecture.md` for the current boundaries.

## Vehicle model

The game uses a deterministic arcade vehicle model rather than rigid-body wheels. Each simulation substep:

1. samples four typed ground probes;
2. recovers lateral speed and calculates lateral slip;
3. updates the selected transmission, clutch/converter/CVT state and engine RPM;
4. converts requested drive, service-brake, reverse and handbrake acceleration into tire-limited longitudinal acceleration;
5. records signed longitudinal slip ratio and combines lateral/longitudinal slip for steering, effects and audio;
6. applies steering, suspension/gravity and collision-resolved movement.

Longitudinal capacity is based on the configured tire coefficient, gravity, surface grip, active-contact fraction and remaining friction-circle capacity after lateral use. Requests beyond peak grip enter a configurable sliding region instead of producing unlimited acceleration or braking.

See `docs/vehicle_model.md` for the complete model and limitations.

## Engine audio

Audio backends are selected by scene rather than inferred from catalog position:

- Nissan player scenes use live `ProfiledEngineAudioSynthesizer` generation;
- Nissan AI scenes use committed baked coast/load WAV banks through `BakedEngineAudioPlayer`;
- the Shelby player scenes use the dedicated live cross-plane Ford FE synthesizer and are not currently AI-eligible;
- Fiat Punto player and AI variants share live variant scenes using the dedicated four-cylinder petrol/diesel/turbo synthesizer.

The existing production audio benchmark represents the Nissan race fixture (`1` live player voice plus `3` baked AI voices); it is not a universal assertion that every AI-capable car uses baked audio.

See `docs/baked_engine_audio.md` and the model-specific car documents for the current contracts.

## Automated tests

The complete Windows verification entrypoint is:

```text
scripts/ci/verify_project.ps1
```

It performs:

1. current-tree and complete-history public-repository safety validation;
2. localization catalog and UI-key validation;
3. static repository checks;
4. headless project import;
5. automatic discovery of standalone tests in `scripts/tests/` that extend `SceneTree`;
6. automatic discovery of scenes under `scenes/tests/`;
7. a separate timeout and diagnostic log for every command;
8. failure on Godot runtime errors and non-allowlisted warnings even when the process exits with code `0`.

Expected warnings from deliberate negative-path tests are allowlisted by exact test path and anchored message pattern. Resource fallbacks, invalid UIDs, unexpected importer warnings, `ObjectDB` leaks and other new warnings fail verification.

The canonical end-to-end scene is:

```text
scenes/tests/full_program_smoke_test.tscn
```

It runs `scripts/tests/full_program_smoke_test.gd` and covers menu/back navigation, the loading transition, Nissan automatic and manual free drive, braking/reverse, steering, random car switching, Nissan race setup, AI movement, results cleanup and post-race re-entry. CVT, Fiat and Shelby contracts are covered by focused automatically discovered tests rather than this single end-to-end fixture.

Run the complete suite locally:

```powershell
./scripts/ci/verify_project.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Use `scripts/ci/run_tests.ps1` directly only for focused test work that intentionally skips repository-safety and localization orchestration.

## Export validation

`.github/workflows/windows-tests.yml` runs on `windows-2025`, pins GitHub actions to immutable commit SHAs, verifies the SHA-512 checksums of the Godot editor and export-template archives, invokes the complete project verification and then exports/smoke-tests both Windows presets.

The export-template cache stores the original archive, which is verified on every use before extraction. Pull-request runs upload test logs plus production/test-build startup logs; executable/PCK artifacts are published only by trusted push or manually dispatched runs.

`scripts/ci/export_windows.ps1` creates and smoke-tests both the normal packaged startup and the packaged regression route.

See `docs/continuous_integration.md` and `docs/windows_export.md` for exact gates and artifact behavior.

## Repository policy

- `LICENSE` preserves all rights unless a later license explicitly grants reuse rights.
- `SECURITY.md` defines private vulnerability reporting and secret-response rules.
- `THIRD_PARTY_NOTICES.md` records trademark, license and asset-provenance status, including unresolved provenance records that block redistribution assumptions.
- `.github/dependabot.yml` proposes updates for pinned GitHub Actions.

## Documentation

- `docs/architecture.md` — subsystem ownership and dependency boundaries;
- `docs/car_catalog.md` — catalog/model/variant/spec rules and current catalog content;
- `docs/vehicle_model.md` — current handling, transmission and tire model;
- `docs/performance.md` — current operation-count, visual-LOD and backend-specific performance contracts;
- `docs/track_layout_resources.md` — catalog-backed layout, profile and generated-geometry contracts;
- `docs/baked_engine_audio.md` — scene-specific live/baked audio backends and baking workflow;
- `docs/audio/vq37vhr_procedural_model.md` — Nissan VQ37VHR procedural model;
- `docs/cars/nissan_370z_nismo_2016.md` — Nissan 370Z/NISMO content and sources;
- `docs/cars/ford_mustang_shelby_gt500_1967.md` — Shelby content and calibration;
- `docs/cars/fiat_punto_1995.md` — Fiat Punto variants, CVT and synthesis;
- `docs/tor_poznan_reconstruction.md` — Tor Poznań geometry and environment reconstruction;
- `docs/runtime_safety_contracts.md` — transactional runtime safety contracts;
- `docs/accepted_risks.md` — explicitly accepted project risks;
- `docs/roadmap.md` — completed platform stages and remaining feature work;
- `docs/continuous_integration.md` — Windows CI, repository-safety and artifact behavior;
- `docs/windows_export.md` — Windows export details.

## Change rules

1. Keep one architectural concern per commit where practical.
2. Add focused regression coverage with subsystem changes.
3. Preserve compatibility with the canonical full-program smoke test.
4. Keep detailed handling-tuning changes separate from structural refactors.
5. Update the relevant documentation when ownership, content, data flow or runtime behavior changes.
6. Do not introduce an alternate fallback path when an explicit catalog or resource field already owns the decision.
7. Do not expose test-only suffixes or simulation entry points from production classes.
8. Preserve prepare-then-commit semantics for tracks, session startup, runtime specs and opponent sets.
9. Treat any catalog validation error as a startup-blocking configuration error.
