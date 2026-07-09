# Android and smoke test baseline report — 2026-07-09

## Scope

This report records the current validated baseline after the architecture cleanup, Android playtesting, mobile touch-controls addition, race-mode `switch-car` restriction and extended full-program smoke test setup.

## Environment

Manual runtime validation:

- Platform: Android device
- Runtime/editor: Godot Android Editor
- Project transfer method: GitHub ZIP download
- Project branch: `master`

Automated runtime validation:

- Test scene: `scenes/tests/full_program_smoke_test.tscn`
- Optional editor launcher: `scripts/tests/run_full_program_smoke_test.gd`
- Test runner: `scripts/tests/full_program_smoke_test.gd`

## Manual validation result

Status: PASS

Validated manually on Android:

- project opens without script parse errors;
- project runs without startup errors;
- menu flow works;
- free-drive flow works;
- race flow works;
- countdown works;
- AI opponents behave as expected;
- gameplay logic that does not require vehicle input works;
- mobile touch controls work;
- automatic 370Z works;
- manual 370Z works;
- gear-up and gear-down work;
- reset works;
- handling behavior appears unchanged after refactors;
- engine audio works on Android;
- tire/audio behavior works on Android.

## Automated smoke test result

Status: PASS

The extended full-program smoke test ran without errors.

Covered by the automated test:

- instantiates `scenes/main.tscn`;
- verifies the main menu exists;
- verifies no player car is spawned before menu selection;
- presses visible menu buttons by label;
- selects free-drive mode;
- spawns automatic 370Z;
- verifies speedometer and minimap visibility;
- simulates acceleration through `Input.action_press()` / `Input.action_release()`;
- checks RPM/load telemetry is available;
- performs longer automatic acceleration segment;
- tests steering left and right while moving;
- tests handbrake/slip telemetry segment;
- tests braking;
- tests reset;
- tests automatic reverse from near stop;
- checks `switch-car` works in free-drive mode;
- selects manual 370Z;
- tests manual gear sequence `1 -> 2 -> 1 -> N -> R -> N -> 1`;
- performs longer manual acceleration segment;
- tests manual steering while moving;
- enters race mode;
- verifies opponent spawn count;
- verifies `switch-car` is blocked during countdown;
- verifies `switch-car` is blocked after race start;
- verifies at least one AI opponent starts moving;
- waits through an extended race soak segment;
- verifies player car remains stable during race soak;
- verifies AI opponents keep moving during race soak;
- simulates player finish;
- verifies results screen;
- verifies return-to-menu cleanup;
- verifies opponents are cleared;
- verifies free-drive can be entered again after race cleanup;
- verifies the car can accelerate after post-race free-drive reentry.

## Known limitations of this baseline

The validation does not yet prove:

- full real lap completion through physically driven laps;
- correctness on non-oval tracks;
- checkpoint-based lap validation, because checkpoints do not exist yet;
- long-session stability over many repeated races;
- performance on low-end Android devices;
- final mobile UI usability, because current mobile controls are a temporary procedural overlay;
- scalability with many more AI cars;
- final audio performance with large fields of cars.

## Current accepted risks

- `scripts/car/car_controller.gd` is still the main technical-risk file because gear application, steering, local/global velocity projection and movement remain coupled there.
- `scripts/race/generated_track.gd` still mixes track data, mesh generation, collision generation and scenery.
- `scripts/race/lap_tracker.gd` still uses racing-line progress heuristics instead of physical checkpoints.
- `scripts/tests/full_program_smoke_test.gd` currently reads selected private `GameManager` fields and calls selected private callbacks. This is acceptable for the prototype but should later be replaced by a small test/diagnostic adapter.
- `scripts/ui/mobile_drive_controls.gd` is a temporary procedural overlay and should later become scene-driven UI.

## Regression gate

Before future changes are treated as stable, run:

```text
scenes/tests/full_program_smoke_test.tscn
```

or launch it through:

```text
scripts/tests/run_full_program_smoke_test.gd
```

Expected result:

```text
[SMOKE] Extended full program smoke test passed: <N> checks
```

Any `[SMOKE][FAIL]` line should be treated as a regression until investigated.

## Recommended next work

1. Add a small test/diagnostic adapter so the smoke test does not rely on private `GameManager` fields.
2. Convert mobile controls from procedural runtime UI to `scenes/ui/mobile_drive_controls.tscn`.
3. Extract only local/global velocity projection helpers from `car_controller.gd` into `VehicleMotionModel`.
4. Move car tuning data into `CarSpecs` Resources.
5. Add checkpoint-based lap validation before adding more complex tracks.
