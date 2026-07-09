# Car Game

Godot 4 prototype focused on car driving, simple racing flow, procedural track geometry, HUD, minimap, AI opponents and car-specific drivetrain tuning.

This document describes the current repository baseline so future Codex tasks and manual Godot testing start from the same structure.

## Current status

The project currently contains:

- a Godot 4 project configured for a 3D driving game;
- a main scene that composes the generated track, player spawn point, camera, HUD, minimap, menu and high-level game flow;
- a Nissan 370Z-inspired prototype car scene;
- separate manual and automatic 370Z variants;
- Resource-backed `CarSpecs` data for 370Z manual and automatic variants;
- catalog-driven model/variant Resources for car selection;
- a character-body based player car controller with runtime, powertrain, chassis and reset collaborators;
- procedural engine and tire squeal audio;
- generated oval track geometry built through modular track builder classes;
- free-drive and race menu flow with model -> variant car selection;
- AI opponents following the generated racing line;
- scene-driven main race/menu UI: `MainMenu`, `CountdownOverlay`, `LapPositionHud` and `ResultsScreen`;
- speedometer, gear display and tachometer;
- scene-driven mobile touch controls for Android playtesting;
- extended full-program smoke test scene for automated regression checks;
- game test adapter that centralizes smoke-test access to game state.

The project is still a prototype. The current priority is controlled cleanup and regression coverage, not adding more cars or game modes.

## Engine and project setup

- Engine: Godot 4.x
- Renderer: Forward Plus
- Physics: Jolt Physics
- Main scene: `scenes/main.tscn`
- Default branch: `master`

The repository is intentionally small and mostly text-based, which makes it suitable for review and AI-assisted iteration.

## How to run

1. Clone the repository.
2. Open the folder in Godot 4.
3. Open `project.godot`.
4. Run the project with `F5`.

The game starts from the main scene and displays the menu before spawning the selected car.

## Automated smoke test

An extended full-program smoke test is available at:

```text
scenes/tests/full_program_smoke_test.tscn
```

Recommended editor-scene flow:

1. Open `scenes/tests/full_program_smoke_test.tscn`.
2. Run it as the current scene.
3. Watch the Output panel for `[SMOKE][PASS]` / `[SMOKE][FAIL]` lines.

If you want to use Godot's script-run button instead, run this editor script:

```text
scripts/tests/run_full_program_smoke_test.gd
```

That launcher is an `@tool EditorScript` and starts the same smoke-test scene from the editor. Do not run `scripts/tests/full_program_smoke_test.gd` directly as a script; it is a normal runtime `Node` script attached to the test scene.

The smoke test instantiates `scenes/main.tscn`, presses menu buttons through `tryb -> tor -> model auta -> wariant auta`, simulates driving input through `Input.action_press()` / `Input.action_release()`, checks free-drive automatic/manual flow, checks race setup, verifies that `switch-car` is blocked in race mode, simulates race finish and verifies return-to-menu cleanup.

It also checks visible `Nissan 370Z` model selection, variant IDs for `nissan_370z_7at` and `nissan_370z_6mt`, automatic/manual acceleration segments, steering, handbrake/slip telemetry, braking, automatic reverse from near stop, manual neutral/reverse gear checks, AI race soak and post-race free-drive reentry.

`scripts/tests/game_test_adapter.gd` centralizes smoke-test access to the current car, opponents, selected mode/track, selected car variant, visible buttons and simulated player finish. The test runner should use that adapter instead of directly reading `GameManager` fields.

The test prints `[SMOKE][PASS]` / `[SMOKE][FAIL]` lines to the Output panel and exits with status code `0` on pass or `1` on failure when run from command line.

## Controls

Keyboard controls currently configured in `project.godot`:

| Action | Default input |
|---|---|
| Accelerate | `W` / Arrow Up / joypad trigger |
| Brake / reverse | `S` / Arrow Down / joypad trigger |
| Steer left | `A` / Arrow Left / joypad axis |
| Steer right | `D` / Arrow Right / joypad axis |
| Handbrake | Space |
| Reset car | `R` |
| Camera back | `C` |
| Pause | Esc |
| Switch car | `T` — free-drive mode only |
| Gear up | `E` / joypad button |
| Gear down | `Q` / joypad button |

On Android, `scenes/ui/mobile_drive_controls.tscn` creates a temporary touch overlay controlled by `scripts/ui/mobile_drive_controls.gd`. The overlay presses the same existing input actions. It is intended for testing, not final UI.

Mobile overlay buttons:

| Button | Action |
|---|---|
| `GAS` | `accelerate` |
| `BRAKE` | `brake` |
| `◀` / `▶` | `steer-left` / `steer-right` |
| `HB` | `handbrake` |
| `G+` / `G-` | `gear-up` / `gear-down` |
| `RESET` | `reset-car` |
| `CAM` | `camera-back` |

## Important files

### Project and scenes

| Path | Purpose |
|---|---|
| `project.godot` | Project settings and input map |
| `scenes/main.tscn` | Main composition scene |
| `scenes/tests/full_program_smoke_test.tscn` | Full-program automated smoke test scene |
| `scenes/cars/370z.tscn` | Base/manual 370Z-style car scene |
| `scenes/cars/370zat.tscn` | Automatic transmission 370Z variant |
| `scenes/tracks/simple_oval.tscn` | Current generated test/race track scene |
| `scenes/ui/main_menu.tscn` | Scene-driven main menu layout |
| `scenes/ui/countdown_overlay.tscn` | Scene-driven race countdown overlay layout |
| `scenes/ui/lap_position_hud.tscn` | Scene-driven lap and race-position HUD layout |
| `scenes/ui/results_screen.tscn` | Scene-driven race results screen layout |
| `scenes/ui/mobile_drive_controls.tscn` | Android touch-driving overlay scene |
| `scenes/ui/speedometer.tscn` | HUD speedometer and tachometer scene |

### Car data

| Path | Purpose |
|---|---|
| `resources/cars/catalog.tres` | Root car catalog Resource |
| `resources/cars/nissan/370z/model.tres` | Nissan 370Z model definition Resource |
| `resources/cars/nissan/370z/variants/370z_7at.tres` | Automatic 370Z variant definition |
| `resources/cars/nissan/370z/variants/370z_6mt.tres` | Manual 370Z variant definition |
| `resources/cars/nissan/370z/specs/370z_7at_specs.tres` | Automatic 370Z tuning data Resource |
| `resources/cars/nissan/370z/specs/370z_6mt_specs.tres` | Manual 370Z tuning data Resource |

### Game and race flow

| Path | Purpose |
|---|---|
| `scripts/game/game_manager.gd` | High-level menu/free-drive/race coordinator |
| `scripts/game/car_selection_state.gd` | Available car scene/variant selection state |
| `scripts/game/menu_options_builder.gd` | Builds menu options from track and car catalog data |
| `scripts/game/race_session_controller.gd` | Race-session facade around race manager, lap tracker, HUD and opponents |
| `scripts/game/car_spawner.gd` | Facade for player car, opponent and AI-driver instantiation |
| `scripts/game/car_instance_factory.gd` | Instantiates car scenes and applies variant specs |
| `scripts/game/player_car_spawn_controller.gd` | Owns current player-car instance lifecycle |
| `scripts/game/opponent_spawn_layout.gd` | Computes opponent spawn transforms and lane offsets |
| `scripts/game/opponent_participant_spawner.gd` | Creates opponent cars and AI driver nodes |
| `scripts/game/opponent_paint_randomizer.gd` | Randomizes opponent paint visuals |
| `scripts/race/race_manager.gd` | Race lifecycle, countdown and input lock helper |
| `scripts/race/lap_tracker.gd` | Lap, progress, position and result-order tracking |
| `scripts/race/ai_race_driver.gd` | Prototype AI driver |

### Vehicle model

| Path | Purpose |
|---|---|
| `scripts/car/car_controller.gd` | Thin player car runtime coordinator and public API |
| `scripts/car/car_runtime_state.gd` | Runtime speed, RPM, gear, input and start-transform state |
| `scripts/car/car_drive_config.gd` | Sanitized runtime copy of drive tuning |
| `scripts/car/car_drive_config_builder.gd` | Builds runtime config from `CarSpecs` or legacy scene exports |
| `scripts/car/car_powertrain_controller.gd` | Transmission, engine RPM, torque, resistance and forward-speed update |
| `scripts/car/car_chassis_controller.gd` | Steering, tire slip, skid dispatch, gravity and `move_and_slide()` |
| `scripts/car/car_reset_controller.gd` | Reset-to-start behavior |
| `scripts/car/car_specs.gd` | Resource class for car tuning data |
| `scripts/car/car_input.gd` | Player/external drive input helper |
| `scripts/car/manual_transmission_model.gd` | Manual gear-up/gear-down request helper |
| `scripts/car/automatic_transmission_model.gd` | Automatic gear-selection decision helper |
| `scripts/car/shift_timer_model.gd` | Shift-timer update and delay-selection helper |
| `scripts/car/drivetrain_model.gd` | Gear-ratio, wheel RPM, wheel-force and drive-acceleration helper |
| `scripts/car/engine_model.gd` | Engine RPM, torque curve and rev limiter helper |
| `scripts/car/resistance_model.gd` | Aerodynamic drag and rolling resistance helper |
| `scripts/car/torque_converter_model.gd` | Torque converter RPM-coupling and torque-multiplication helper |
| `scripts/car/tire_model.gd` | Lateral grip recovery and tire slip-intensity helper |
| `scripts/car/vehicle_motion_model.gd` | Local/global velocity projection helper |
| `scripts/car/skid_mark_emitter.gd` | Skid mark visual-effect emitter |
| `scripts/car/engine_audio.gd` | Procedural engine audio |
| `scripts/car/tire_squeal_audio.gd` | Procedural tire slip audio |

### Track generation

| Path | Purpose |
|---|---|
| `scripts/race/generated_track.gd` | Thin generated-track orchestration script |
| `scripts/track/track_generated_content_root.gd` | Stable `GeneratedContent` container and generated-child cleanup |
| `scripts/track/track_geometry_data.gd` | Typed generated track geometry container |
| `scripts/track/track_layout_builder.gd` | Catmull-Rom sampled layout, widths, edges and racing line |
| `scripts/track/track_surface_mesh_builder.gd` | Grass, roadside and asphalt mesh/body creation |
| `scripts/track/track_collision_builder.gd` | Grass, roadside and asphalt collision creation |
| `scripts/track/track_marker_builder.gd` | Finish line and edge marker generation |
| `scripts/track/track_barrier_builder.gd` | Barrier visual generation |
| `scripts/track/track_decoration_builder.gd` | Optional stadium, arrows, stands, spectators, roof and lights |
| `scripts/track/track_material_factory.gd` | Generated track material creation |

### Tests and docs

| Path | Purpose |
|---|---|
| `scripts/tests/full_program_smoke_test.gd` | Full-program smoke test runner attached to the smoke-test scene |
| `scripts/tests/car_controller_runtime_config_test.gd` | Runtime config and basic gear-display test |
| `scripts/tests/game_test_adapter.gd` | Diagnostic adapter used by the smoke test |
| `scripts/tests/run_full_program_smoke_test.gd` | EditorScript launcher for the full-program smoke test scene |
| `docs/architecture.md` | Current architecture baseline and cleanup direction |
| `docs/car_catalog.md` | Car model/variant/catalog structure and rules |
| `docs/roadmap.md` | Recommended implementation order |
| `docs/vehicle_model.md` | Current vehicle-model behavior baseline and regression checklist |

## Current architectural warning

The project works as a prototype, but the main risks are now these:

- `GameManager` still coordinates several systems and should remain a coordinator, not a place for new gameplay logic.
- `RaceSessionController` centralizes race lifecycle wiring, but lap tracking is still heuristic.
- `LapTracker` uses nearest racing-line progress and should later be replaced by checkpoint validation.
- `CarSpecs`, `CarDriveConfig` and legacy controller exports currently duplicate many fields by design; remove legacy scene tuning only after Resource-backed tuning is fully validated.
- `generated_track.gd` is now a thin builder orchestrator, but track layout data is still hardcoded in `TrackLayoutBuilder` rather than stored in a track Resource.
- Runtime-created menu option buttons and result rows are still script-built because they depend on runtime data.
- Mobile controls are scene-driven, but still a temporary Android testing overlay rather than final configurable input UI.
- Procedural audio may scale poorly with many active cars.

These should be addressed through small changes followed by the extended smoke test.

## Documentation

See:

- `docs/architecture.md` for the current validated structure and target architecture;
- `docs/car_catalog.md` for the model/variant/specs catalog structure;
- `docs/roadmap.md` for the recommended implementation order;
- `docs/vehicle_model.md` for the current vehicle-model behavior baseline and regression checklist;
- `docs/test_reports/` for dated validation and refactor reports.

## Working rule for future changes

Prefer small, reviewable changes:

1. one architectural concern per branch or commit;
2. no gameplay feature additions during structural refactors;
3. after every gameplay, race, UI, input, vehicle or track-generation change, run `scenes/tests/full_program_smoke_test.tscn`;
4. keep car tuning changes separate from architecture changes;
5. keep generated assets and procedural logic documented;
6. update this README and the relevant document under `docs/` when responsibilities move between scripts.
