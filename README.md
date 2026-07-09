# Car Game

Godot 4 prototype focused on car driving, simple racing flow, procedural track geometry, HUD, minimap, AI opponents and car-specific drivetrain tuning.

This document describes the current baseline state of the project. It is intended to make further work with Codex and manual Godot testing easier.

## Current status

The project currently contains:

- a Godot 4 project configured for a 3D driving game;
- a main scene that composes the track, camera, HUD, minimap, menu and car spawning flow;
- a Nissan 370Z-inspired prototype car scene;
- separate manual and automatic transmission variants;
- a character-body based car controller;
- procedural engine and tire squeal audio;
- generated oval track geometry;
- free-drive and race menu flow;
- AI opponents following the generated racing line;
- lap, position and results UI;
- speedometer, gear display and tachometer.

The project is still a prototype. The next priority is architectural cleanup, not adding more cars or game modes.

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
| Switch car | `T` |
| Gear up | `E` / joypad button |
| Gear down | `Q` / joypad button |

## Important files

| Path | Purpose |
|---|---|
| `project.godot` | Project settings and input map |
| `scenes/main.tscn` | Main composition scene |
| `scenes/cars/370z.tscn` | Base 370Z-style car scene |
| `scenes/cars/370zat.tscn` | Automatic transmission 370Z variant |
| `scenes/tracks/simple_oval.tscn` | Current generated test/race track scene |
| `scenes/ui/speedometer.tscn` | HUD speedometer and tachometer scene |
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
| `scripts/ui/minimap.gd` | Minimap drawing logic |
| `scripts/ui/speedometer.gd` | HUD binding to active car |
| `scripts/car/car_controller.gd` | Main car controller and drivetrain prototype |
| `scripts/car/car_input.gd` | Player/external drive input helper |
| `scripts/car/skid_mark_emitter.gd` | Skid mark visual-effect emitter |
| `scripts/car/engine_audio.gd` | Procedural engine audio |
| `scripts/car/tire_squeal_audio.gd` | Procedural tire slip audio |

## Current architectural warning

The project works as a prototype, but some scripts still have too many responsibilities:

- `scripts/car/car_controller.gd` still manages drivetrain, transmission, resistance, steering, tire slip, reset and movement.
- `scripts/race/generated_track.gd` contains track layout data, mesh generation, collision generation and scenery generation.
- Race UI helpers still build HUD controls procedurally; they should later become scene-driven UI.

These should be refactored before adding more gameplay systems.

## Documentation

See:

- `docs/architecture.md` for the current structure and target architecture;
- `docs/roadmap.md` for the recommended implementation order.

## Working rule for future changes

Prefer small, reviewable changes:

1. one architectural concern per branch;
2. no gameplay feature additions during structural refactors;
3. after every refactor, run the project in Godot and verify free drive and race mode;
4. keep car tuning changes separate from architecture changes;
5. keep generated assets and procedural logic documented.
