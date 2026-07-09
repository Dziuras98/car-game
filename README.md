# Car Game

Godot 4 prototype focused on car driving, simple racing flow, procedural track geometry, HUD, minimap, AI opponents and car-specific drivetrain tuning.

This document describes the current baseline state of the project. It is intended to make further work with Codex and manual Godot testing easier.

## Current status

The project currently contains:

- a Godot 4 project configured for a 3D driving game;
- a main scene that composes the track, camera, HUD, minimap, menu and car spawning flow;
- a Nissan 370Z-inspired prototype car scene;
- separate manual and automatic transmission variants;
- Resource-backed `CarSpecs` data for the 370Z manual and automatic variants;
- a character-body based car controller;
- extracted vehicle-motion helper for local/global velocity projection;
- procedural engine and tire squeal audio;
- generated oval track geometry;
- free-drive and race menu flow;
- AI opponents following the generated racing line;
- lap, position and results UI;
- speedometer, gear display and tachometer;
- scene-driven mobile touch controls for Android playtesting;
- extended full-program smoke test scene for automated regression checks;
- game test adapter that centralizes smoke-test access to game state;
- validated Android and smoke-test baseline report.

The project is still a prototype. The next priority is controlled architectural cleanup, not adding more cars or game modes.

## Engine and project setup

- Engine: Godot 4.x
- Renderer: Forward Plus
- Physics: Jolt Physics
- Main scene: `scenes/main.tscn`
- Default branch: `master`

The repository is intentionally small and mostly text-based, which makes it suitable for code review and AI-assisted iteration.

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

The test instantiates `scenes/main.tscn`, presses menu buttons, simulates driving input through `Input.action_press()` / `Input.action_release()`, checks free-drive automatic/manual flow, checks race setup, verifies that `switch-car` is blocked in race mode, simulates race finish and verifies return-to-menu cleanup.

The extended coverage includes longer automatic/manual acceleration segments, steering left/right, handbrake/slip telemetry, braking, automatic reverse from near stop, manual neutral/reverse gear checks, a longer AI race soak segment and post-race free-drive reentry.

`scripts/tests/game_test_adapter.gd` centralizes smoke-test access to the current car, opponents, selected mode/track, visible buttons and simulated player finish. The test runner should use that adapter instead of directly reading `GameManager` fields.

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

| Path | Purpose |
|---|---|
| `project.godot` | Project settings and input map |
| `scenes/main.tscn` | Main composition scene |
| `scenes/tests/full_program_smoke_test.tscn` | Full-program automated smoke test scene |
| `scenes/cars/370z.tscn` | Base 370Z-style car scene |
| `scenes/cars/370zat.tscn` | Automatic transmission 370Z variant |
| `scenes/tracks/simple_oval.tscn` | Current generated test/race track scene |
| `scenes/ui/mobile_drive_controls.tscn` | Android touch-driving overlay scene |
| `scenes/ui/speedometer.tscn` | HUD speedometer and tachometer scene |
| `resources/cars/370z_manual.tres` | Manual 370Z tuning data Resource |
| `resources/cars/370z_automatic.tres` | Automatic 370Z tuning data Resource |
| `scripts/tests/full_program_smoke_test.gd` | Full-program smoke test runner attached to the smoke-test scene |
| `scripts/tests/game_test_adapter.gd` | Diagnostic adapter used by the smoke test |
| `scripts/tests/run_full_program_smoke_test.gd` | EditorScript launcher for the full-program smoke test scene |
| `scripts/game/game_manager.gd` | High-level menu/free-drive/race coordinator |
| `scripts/game/car_spawner.gd` | Player car, opponent and AI-driver instantiation helper |
| `scripts/race/race_manager.gd` | Race lifecycle, countdown and input lock helper |
| `scripts/race/lap_tracker.gd` | Lap, progress, position and result-order tracking |
| `scripts/race/ai_race_driver.gd` | Prototype AI driver |
| `scripts/race/generated_track.gd` | Procedural track and scenery generator |
| `scripts/ui/race_hud.gd` | Race HUD facade used by the game manager |
| `scripts/ui/countdown_overlay.gd` | Procedural countdown overlay helper |
| `scripts/ui/lap_position_hud.gd` | Procedural lap and race-position HUD helper |
| `scripts/ui/results_screen.gd` | Procedural results screen helper |
| `scripts/ui/main_menu.gd` | Main menu flow |
| `scripts/ui/mobile_drive_controls.gd` | Binds the Android touch overlay scene buttons to input actions |
| `scripts/ui/minimap.gd` | Minimap drawing logic |
| `scripts/ui/speedometer.gd` | HUD binding to active car |
| `scripts/car/car_controller.gd` | Main car controller and drivetrain prototype |
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
| `docs/architecture.md` | Current validated architecture baseline and target cleanup direction |
| `docs/vehicle_model.md` | Current vehicle-model behavior baseline and regression checklist |
| `docs/test_reports/2026-07-09-android-and-smoke-baseline.md` | Validated Android and extended-smoke-test baseline report |

## Current architectural warning

The project works as a prototype, but some scripts still have too many responsibilities:

- `scripts/car/car_controller.gd` still manages applying selected gears, steering, grounding, reset and movement, although local/global velocity projection and car tuning data have been partly extracted.
- `resources/cars/*.tres` now hold 370Z tuning data, but old exported scene values are intentionally kept as a fallback while this path is validated.
- `scripts/race/generated_track.gd` contains track layout data, mesh generation, collision generation and scenery generation.
- Race UI helpers still build HUD controls procedurally; they should later become scene-driven UI.
- Mobile controls are now scene-driven, but they are still a temporary Android testing overlay rather than final input UI.
- `GameTestAdapter` still knows selected `GameManager` internals; this is centralized now, but a future production-facing diagnostic API would be cleaner.

These should be refactored through small changes, followed by the extended smoke test.

## Documentation

See:

- `docs/architecture.md` for the current validated structure and target architecture;
- `docs/roadmap.md` for the recommended implementation order;
- `docs/vehicle_model.md` for the current vehicle-model behavior baseline and regression checklist;
- `docs/test_reports/2026-07-09-android-and-smoke-baseline.md` for the current validated baseline report.

## Working rule for future changes

Prefer small, reviewable changes:

1. one architectural concern per branch;
2. no gameplay feature additions during structural refactors;
3. after every refactor, run `scenes/tests/full_program_smoke_test.tscn`;
4. keep car tuning changes separate from architecture changes;
5. keep generated assets and procedural logic documented.
