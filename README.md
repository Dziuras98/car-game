# Car Game

Godot 4.7 prototype focused on car driving, short races, data-driven vehicle variants and procedurally generated tracks. Windows is the sole target platform; player input is provided through keyboard and gamepad actions.

The project is intentionally kept text-heavy and regression-tested so gameplay systems can be changed without silently breaking exported builds.

## Current baseline

The repository currently provides:

- free-drive and race modes with explicit mode validation and rollback on failed session startup;
- catalog-driven track, car model and car variant selection through typed resource arrays;
- Nissan 370Z-style 6MT and 7AT variants backed by `CarSpecs` resources;
- explicit AI eligibility on supported car variants and all-or-nothing opponent spawning;
- a modular `CharacterBody3D` vehicle runtime with powertrain, transmission, tire, four-point ground-contact and reset helpers;
- `TransmissionType` as the sole transmission-mode state;
- surface-dependent grip and a friction-circle longitudinal-force budget;
- generated track surfaces, collision, barriers, markers, checkpoints and stadium decoration;
- ordered checkpoint validation and continuous race-position progress;
- AI opponents that consume the typed generated-track contract;
- speedometer, tachometer, minimap, countdown, lap/position HUD, results and pause UI;
- Polish and English localization resources with explicit startup loading;
- keyboard and gamepad player input plus a separate external AI input channel;
- bounded procedural audio voices and skid-mark buffers;
- Windows production and packaged-test export presets;
- one complete project-verification entrypoint and automatically discovered regression tests with per-command timeouts and runtime-error detection.

The project remains a prototype. Structural correctness and test coverage take priority over adding more cars or tracks.

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

The active track is created before the selected car. A gameplay session is considered started only after the exact mode/track/variant IDs, player car and required race participants validate. A failed step clears partial runtime state and returns to the menu. Free drive enables input immediately; race mode starts the countdown only after the complete opponent set and lap tracking are ready.

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
- `resources/cars/nissan/370z/model.tres`
- `resources/cars/nissan/370z/variants/`
- `resources/cars/nissan/370z/specs/`
- `scripts/car/car_controller.gd`
- `scripts/car/car_drive_config_builder.gd`

`CarSpecs` is the authoritative tuning source. Runtime controllers consume a sanitized `CarDriveConfig`; game systems use the public `PlayerCarController` API instead of reading tuning fields directly. The base 370Z scene contains visual, collision and audio structure only and does not serialize tuning values.

`CarVariantDefinition.ai_eligible` is the sole declaration that a variant may be used by the current AI. The automatic 370Z is eligible; the manual variant remains player-selectable and is never used as an implicit opponent fallback.

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
- `scripts/race/generated_track.gd`
- `scripts/track/`

`TrackCatalog.default_track_id` is the sole default-track declaration. Generated geometry is rebuilt atomically and publishes a geometry revision so AI, minimap and lap tracking can refresh their cached data.

## Runtime architecture

`GameManager` coordinates menu state, active track, transactional session startup, spawning, camera/HUD binding and transitions between free drive and race. Detailed responsibilities are delegated to:

- `CarSelectionState`, `MenuOptionsBuilder` and `TrackSpawnController`;
- `CarSpawner`, `CarInstanceFactory` and participant spawn helpers;
- `RaceSessionController`, `RaceManager` and `LapTracker`;
- `PlayerCarController`, powertrain/chassis helpers and `CarInput`;
- generated-track builders and UI scene controllers.

Production coordinators do not expose test-simulation entry points. Integration tests use the dedicated `GameTestAdapter` and observable runtime state.

See `docs/architecture.md` for the current boundaries.

## Automated tests

The complete Windows verification entrypoint is:

```text
scripts/ci/verify_project.ps1
```

It performs:

1. localization catalog and UI-key validation;
2. static repository checks;
3. headless project import;
4. automatic discovery of standalone tests in `scripts/tests/` that extend `SceneTree`;
5. automatic discovery of scenes under `scenes/tests/`;
6. a separate timeout and diagnostic log for every command;
7. failure on Godot runtime-error output even when the process exits with code `0`.

The static checks also reject orphaned test scripts, production `_for_test` identifiers, completed-migration regressions, implicit mode/index/AI fallbacks, mutable GitHub Action tags and reintroduced architectural fallback paths. A runtime test must be one of:

- a standalone `SceneTree` test;
- a script referenced by a scene under `scenes/tests/`;
- an editor launcher;
- an explicitly allowed test helper.

The canonical end-to-end scene is:

```text
scenes/tests/full_program_smoke_test.tscn
```

It runs `scripts/tests/full_program_smoke_test.gd` and covers menu navigation, automatic and manual free drive, braking/reverse, steering, car switching, race setup, AI movement, results cleanup and post-race re-entry.

Run the complete suite locally:

```powershell
./scripts/ci/verify_project.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Use `scripts/ci/run_tests.ps1` directly only for focused test work that intentionally skips localization orchestration.

## Export validation

`.github/workflows/windows-tests.yml` runs on `windows-2025`, pins GitHub actions to immutable commit SHAs, verifies the SHA-512 checksums of the Godot editor and export-template archives, invokes the complete project verification and then exports/smoke-tests both Windows presets.

`scripts/ci/export_windows.ps1` creates and smoke-tests both the normal packaged startup and the packaged regression route. Successful workflow artifacts contain the executable, PCK and diagnostic logs.

See `docs/continuous_integration.md` and `docs/windows_export.md` for exact gates and artifact behavior.

## Documentation

- `docs/architecture.md` — subsystem ownership and dependency boundaries;
- `docs/car_catalog.md` — car catalog/model/variant/spec and AI-eligibility rules;
- `docs/vehicle_model.md` — current handling and powertrain model;
- `docs/roadmap.md` — completed remediation stages and separately deferred feature expansion;
- `docs/continuous_integration.md` — Windows CI and packaged validation;
- `docs/windows_export.md` — Windows export details.

## Change rules

1. Keep one architectural concern per commit where practical.
2. Add focused regression coverage with subsystem changes.
3. Preserve compatibility with the canonical full-program smoke test.
4. Keep detailed handling-tuning changes separate from structural refactors.
5. Update the relevant documentation when ownership or data flow changes.
6. Do not introduce an alternate fallback path when an explicit catalog or resource field already owns the decision.
7. Do not expose test-only suffixes or simulation entry points from production classes.
8. Preserve prepare-then-commit semantics for tracks, session startup and opponent sets.
