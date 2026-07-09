# CarSpawner decomposition - 2026-07-09

## Scope

- Refactored `scripts/game/car_spawner.gd` into a facade.
- Added focused helper classes under `scripts/game`.
- Preserved the existing public `CarSpawner` API.
- Did not change gameplay tuning or scene/resource content.

## New classes

- `CarInstanceFactory`: owns available car scenes/variants, instantiates player/opponent cars, applies `CarVariantDefinition.car_specs`, chooses automatic-preferred opponent variants, and keeps the legacy no-catalog opponent automatic fallback.
- `PlayerCarSpawnController`: owns current player car state, spawn, switch, clear, current car, and current index.
- `OpponentSpawnLayout`: owns opponent grid transform math and AI lane offset math.
- `OpponentPaintRandomizer`: owns opponent paint material randomization using the existing mesh-name heuristic.
- `OpponentParticipantSpawner`: owns opponent spawning, AI driver creation, opponent/driver cleanup, and AI enable/disable.

## Remaining in CarSpawner

- Public facade API.
- Shared `RandomNumberGenerator`.
- Public lane/row spacing values.
- Configuration and delegation to the smaller classes.
- Safe fallbacks for calls before `configure(...)`.

## Moved from CarSpawner

- Available scene/variant storage and car instantiation moved to `CarInstanceFactory`.
- Current player car state and switching moved to `PlayerCarSpawnController`.
- Opponent spawn transform and lane offset math moved to `OpponentSpawnLayout`.
- Paint randomization moved to `OpponentPaintRandomizer`.
- Opponent arrays, AI driver arrays, AI driver setup, opponent spawning, cleanup, and AI enable/disable moved to `OpponentParticipantSpawner`.

## API compatibility

`CarSpawner` still exposes:

- `configure(...)`
- `has_available_cars()`
- `get_current_car()`
- `get_current_car_index()`
- `get_opponents()`
- `spawn_player_car(...)`
- `switch_to_next_car(...)`
- `clear_current_car()`
- `spawn_opponents(...)`
- `clear_opponents()`
- `set_ai_enabled(...)`

## Gameplay behavior

The refactor is responsibility-only. The previous player spawn flow, switch flow, opponent count, opponent names, AI driver names, AI driver properties, AI speed ranges, opponent grid layout, lane offsets, paint randomization, cleanup order, and AI enable/disable behavior were preserved.

## Unchanged areas

- Physics: unchanged.
- Tuning: unchanged.
- `CarSpecs`: unchanged.
- Car catalog/resources: unchanged.
- Car scenes: unchanged.
- AI algorithm: unchanged.
- Track: unchanged.
- Menu flow: unchanged.
- Race flow: unchanged.
- UI scenes: unchanged.
- Smoke test: unchanged.

## Validation

- Smoke test command:
  - `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`
- Smoke test result:
  - `[SMOKE] Extended full program smoke test passed: 79 checks`
- Manual log checks:
  - No new GDScript parser errors after project import.
  - No `Invalid call` errors for the new classes after project import.
  - No typed array errors.
  - Race opponents still spawn.
  - AI opponents still move after countdown, confirming AI drivers are created and enabled.
  - Results screen still appears after simulated finish.
  - Return to menu clears current car and opponents.
  - Re-entering free drive after race cleanup works.
- `git diff --check` result:
  - Passed with no output.

## Godot UID files

Godot import generated `.gd.uid` files for the five new scripts:

- `scripts/game/car_instance_factory.gd.uid`
- `scripts/game/player_car_spawn_controller.gd.uid`
- `scripts/game/opponent_spawn_layout.gd.uid`
- `scripts/game/opponent_paint_randomizer.gd.uid`
- `scripts/game/opponent_participant_spawner.gd.uid`
