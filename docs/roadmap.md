# Roadmap

This roadmap prioritizes making the current prototype maintainable before adding more visible features.

## Current baseline

The project already has enough gameplay systems to be treated as a playable prototype:

- main menu;
- free-drive mode;
- race mode;
- player car spawning;
- two 370Z variants;
- Resource-backed car catalog and 370Z manual/automatic tuning data;
- generated oval track;
- AI opponents;
- lap/position/results UI;
- speedometer, tachometer and minimap;
- scene-driven main race/menu UI: `MainMenu`, `CountdownOverlay`, `LapPositionHud` and `ResultsScreen`;
- scene-driven mobile controls;
- modular car runtime/powertrain/chassis/reset split;
- modular generated-track builder split;
- procedural engine and tire audio;
- extended full-program smoke test;
- focused runtime-config test for the car controller helpers.

The next phase should focus on validation, small correctness fixes and data extraction. Do not add more cars or game modes until the current architecture is stable.

## Phase 0 — Documentation and baseline freeze

Status: refreshed after car-controller and generated-track decomposition.

Goal: document the current structure so future Codex tasks have stable context.

Tasks:

- [x] Add `README.md`.
- [x] Add `docs/architecture.md`.
- [x] Add `docs/roadmap.md`.
- [x] Add `docs/vehicle_model.md` before major handling changes.
- [x] Refresh documentation after car runtime/powertrain/chassis/reset extraction.
- [x] Refresh documentation after generated-track builder extraction.
- [ ] Add `docs/controls.md` if controls grow beyond README.
- [ ] Add `docs/tuning_notes.md` before detailed 370Z tuning.

Definition of done:

- repository has a readable project overview;
- major scripts and scenes are documented;
- refactor order is clear;
- future Codex tasks can reference explicit architecture goals.

## Phase 1 — Split the high-level game coordinator

Status: implemented.

Goal: remove unrelated responsibilities from the original high-level coordinator without changing gameplay behavior.

Completed:

- [x] Create `scripts/game/game_manager.gd`.
- [x] Move menu-selection flow and game-state transitions there.
- [x] Create `scripts/game/car_selection_state.gd`.
- [x] Move car scene/variant selection state there.
- [x] Create `scripts/game/menu_options_builder.gd`.
- [x] Move track and car menu option construction there.
- [x] Create `scripts/game/car_spawner.gd`.
- [x] Move player/opponent car instantiation behind a spawn facade.
- [x] Create `scripts/game/car_instance_factory.gd`.
- [x] Create `scripts/game/player_car_spawn_controller.gd`.
- [x] Create `scripts/game/opponent_spawn_layout.gd`.
- [x] Create `scripts/game/opponent_paint_randomizer.gd`.
- [x] Create `scripts/game/opponent_participant_spawner.gd`.
- [x] Create `scripts/race/race_manager.gd`.
- [x] Move race start, countdown, finish and opponent enable/disable logic there.
- [x] Create `scripts/race/lap_tracker.gd`.
- [x] Move lap, participant progress, position and result-order logic there.
- [x] Create `scripts/game/race_session_controller.gd`.
- [x] Move race-session wiring between spawner, race manager, lap tracker, HUD and minimap there.
- [x] Keep `ai_race_driver.gd` focused only on driving.
- [x] Remove the old `scripts/race/car_switcher.gd` name after equivalent behavior was preserved.

Definition of done:

- free drive works;
- race mode works;
- car choice still works;
- camera, speedometer and minimap still bind to the active car;
- AI opponents still spawn and move;
- lap and position UI still update;
- results screen still appears after race completion;
- no car handling/tuning changes are mixed into this phase.

## Phase 2 — Move race/menu/mobile UI into scenes

Status: implemented and validated by smoke-test reports.

Goal: stop building major UI layouts procedurally and make them scene-driven.

Completed:

- [x] Create `scripts/ui/race_hud.gd`.
- [x] Create `scenes/ui/countdown_overlay.tscn`.
- [x] Create `scripts/ui/countdown_overlay.gd`.
- [x] Create `scenes/ui/lap_position_hud.tscn`.
- [x] Create `scripts/ui/lap_position_hud.gd`.
- [x] Create `scenes/ui/results_screen.tscn`.
- [x] Create `scripts/ui/results_screen.gd`.
- [x] Create `scenes/ui/main_menu.tscn`.
- [x] Bind `scripts/ui/main_menu.gd` to the scene layout while keeping dynamic option buttons script-driven.
- [x] Create `scenes/ui/mobile_drive_controls.tscn`.
- [x] Bind `scripts/ui/mobile_drive_controls.gd` to scene buttons instead of constructing controls in script.
- [x] Wire race/menu UI scenes through their existing script facades.
- [x] Remove procedural UI construction from the race/game manager.
- [x] Keep runtime-generated option buttons and result rows in scripts because they depend on current menu/catalog/result data.

Definition of done:

- UI layout is editable in Godot scenes;
- scripts only update values, visibility and signals;
- dynamic option buttons and result rows may still be created in scripts from runtime data;
- existing visual behavior remains equivalent or better.

Optional later work:

- [ ] Create `scenes/ui/race_hud.tscn`, if a single wrapper scene becomes useful later.
- [ ] Create reusable option/result row scenes if the dynamic rows become visually complex.

## Phase 3 — Extract car input and non-driving effects

Status: implemented.

Goal: reduce `scripts/car/car_controller.gd` before touching handling or drivetrain math.

Completed:

- [x] Create `scripts/car/car_input.gd`.
- [x] Move player/external drive input state and sampling there.
- [x] Create `scripts/car/skid_mark_emitter.gd`.
- [x] Move skid mark material creation, parent creation and mark spawning there.
- [x] Let `PlayerCarController` report tire slip and delegate skid mark emission.

Definition of done:

- player and AI input still work;
- reset still works;
- skid marks still appear under the same conditions;
- car movement is unchanged;
- tire squeal audio still reacts to slip intensity;
- `car_controller.gd` loses input and visual-effect responsibilities.

## Phase 4 — Extract drivetrain, runtime config, chassis and reset controllers

Status: implemented at current architecture level.

Goal: separate engine/transmission simulation, runtime state, steering/tire/movement application and reset coordination from `PlayerCarController`.

Completed drivetrain and powertrain helpers:

- [x] Create `scripts/car/engine_model.gd`.
- [x] Move RPM calculation.
- [x] Move torque curve calculation.
- [x] Create `scripts/car/resistance_model.gd`.
- [x] Move aerodynamic drag calculation.
- [x] Move rolling resistance calculation.
- [x] Create `scripts/car/drivetrain_model.gd`.
- [x] Move gear-ratio and wheel-coupled RPM helper calculations.
- [x] Move wheel force and drive-acceleration helper calculations.
- [x] Create `scripts/car/torque_converter_model.gd`.
- [x] Move torque converter RPM-coupling helper calculation.
- [x] Move torque converter torque-multiplication helper calculation.
- [x] Create `scripts/car/manual_transmission_model.gd`.
- [x] Move manual gear-up/gear-down request helper.
- [x] Create `scripts/car/automatic_transmission_model.gd`.
- [x] Move automatic gear-selection decision helper.
- [x] Create `scripts/car/shift_timer_model.gd`.
- [x] Move shift-timer update and delay-selection helper.
- [x] Create `scripts/car/car_powertrain_controller.gd`.
- [x] Move transmission input, shift timer, RPM, resistance and forward-speed update there.
- [x] Keep public speed/RPM/load/gear telemetry available through `PlayerCarController`.

Completed runtime/chassis/reset helpers:

- [x] Create `scripts/car/car_runtime_state.gd`.
- [x] Move runtime speed, RPM, gear, input snapshot and start-transform state there.
- [x] Create `scripts/car/car_drive_config.gd`.
- [x] Create `scripts/car/car_drive_config_builder.gd`.
- [x] Build runtime config from `CarSpecs` first and legacy scene exports as fallback.
- [x] Create `scripts/car/tire_model.gd`.
- [x] Move lateral grip recovery helper.
- [x] Move tire slip-intensity calculation helper.
- [x] Create `scripts/car/vehicle_motion_model.gd`.
- [x] Move local/global horizontal velocity projection.
- [x] Create `scripts/car/car_chassis_controller.gd`.
- [x] Move steering, slip-limited steering, tire/skid update, gravity and `move_and_slide()` there.
- [x] Create `scripts/car/car_reset_controller.gd`.
- [x] Move reset-to-start coordination there.
- [x] Add `scripts/tests/car_controller_runtime_config_test.gd`.
- [x] Reconfigure `SkidMarkEmitter` when runtime `car_specs` changes.

Definition of done:

- speedometer still receives speed, RPM and gear text;
- engine audio still receives RPM/load/throttle;
- manual and automatic 370Z variants behave at least as before;
- public `PlayerCarController` API used by UI, AI and tests remains available;
- `PlayerCarController` is a thin coordinator instead of a physics monolith.

Remaining work:

- [ ] Add focused tests for `CarPowertrainController` behavior beyond gear-text checks.
- [ ] Add focused tests for `CarChassisController` and `VehicleMotionModel` behavior.
- [ ] Add focused tests for runtime `car_specs` reconfiguration behavior.
- [ ] Remove legacy export tuning after all scenes rely on `CarSpecs`.

## Phase 5 — Introduce car specs and catalog Resources

Status: implemented for current 370Z variants; cleanup remains.

Goal: stop storing all car tuning directly in scene overrides and controller export variables.

Completed:

- [x] Create `scripts/car/car_specs.gd` extending `Resource`.
- [x] Add drivetrain fields.
- [x] Add mass/resistance fields.
- [x] Add tire/steering fields.
- [x] Create model/variant Resource types.
- [x] Create root car catalog Resource.
- [x] Move 370Z manual and automatic specs into `resources/cars/nissan/370z/specs/`.
- [x] Move 370Z model and variants into `resources/cars/nissan/370z/`.
- [x] Let menu model/variant selection come from the catalog.
- [x] Let `CarInstanceFactory` apply variant specs after scene instantiation.

Remaining work:

- [ ] Remove duplicated scene override tuning after Resource-backed tuning is validated.
- [ ] Split `CarSpecs` into sub-resources only if the flat file becomes hard to maintain.
- [ ] Add validation helper/tests for missing specs, missing scenes and duplicate variant IDs.

Definition of done:

- adding a new car variant does not require duplicating controller parameters manually;
- menu reads car names from model/variant definitions;
- car tuning can be versioned as data;
- existing 370Z manual and automatic behavior remains equivalent after smoke testing.

## Phase 6 — Split generated track building

Status: implemented at builder level; data extraction remains.

Goal: keep generated-track orchestration small and move geometry, surfaces, collisions and decorations into separate helpers.

Completed:

- [x] Keep `scripts/race/generated_track.gd` as the public scene script and builder orchestrator.
- [x] Create `scripts/track/track_generated_content_root.gd`.
- [x] Create `scripts/track/track_geometry_data.gd`.
- [x] Create `scripts/track/track_layout_builder.gd`.
- [x] Create `scripts/track/track_surface_mesh_builder.gd`.
- [x] Create `scripts/track/track_collision_builder.gd`.
- [x] Create `scripts/track/track_marker_builder.gd`.
- [x] Create `scripts/track/track_barrier_builder.gd`.
- [x] Create `scripts/track/track_decoration_builder.gd`.
- [x] Create `scripts/track/track_material_factory.gd`.
- [x] Preserve public `get_racing_line_points()` compatibility for AI, minimap and lap tracker.

Remaining work:

- [ ] Add focused tests for `TrackLayoutBuilder` output.
- [ ] Move hardcoded control points from `TrackLayoutBuilder` into a Resource.
- [ ] Add track metadata: name, width, scenery options, lap-count suggestion.
- [ ] Update menu track list to use track data instead of hardcoded options.

Definition of done:

- adding a second track no longer requires editing generated-track internals;
- minimap and AI still get racing-line points;
- generated road, barriers and scenery still work;
- generated content is isolated under `GeneratedContent`.

## Phase 7 — Replace heuristic lap tracking with checkpoints

Status: not started.

Goal: make race progress robust enough for more complex tracks.

Tasks:

- [ ] Add checkpoint/final-line areas to generated track or track scenes.
- [ ] Create `scripts/race/checkpoint.gd`.
- [ ] Create a checkpoint sequence model or helper.
- [ ] Let `lap_tracker.gd` validate checkpoint order.
- [ ] Add wrong-way or missed-checkpoint handling.
- [ ] Keep nearest-racing-line progress only as a position-sorting aid.

Definition of done:

- laps cannot be counted by cutting across the track;
- driving backwards over the finish line does not count incorrectly;
- AI and player use the same participant tracking rules.

## Phase 8 — Performance and quality pass

Status: not started.

Goal: make the prototype stable enough for longer sessions.

Tasks:

- [ ] Add simple profiling notes.
- [ ] Add audio LOD or disable procedural audio for distant AI opponents.
- [ ] Avoid unnecessary per-frame redraws where possible.
- [ ] Cache racing-line lookup for AI or restrict nearest-point search window.
- [ ] Review generated mesh and collision rebuild frequency.
- [ ] Add basic export preset once gameplay stabilizes.

Definition of done:

- race with several AI opponents stays stable;
- no obvious CPU spikes from audio or procedural track rebuilds;
- UI remains responsive;
- project can be exported locally when needed.

## Phase 9 — Feature expansion

Only start this after the architecture is less coupled and the current regression gates are reliable.

Candidate features:

- more cars;
- better imported car models;
- different tracks;
- improved AI racing behavior;
- ghost laps;
- lap timer and best lap storage;
- gamepad tuning;
- pause menu;
- replay camera;
- garage/car selection screen;
- better tire model;
- basic collisions and barriers with stronger gameplay consequences.

## Current rule

Do not add new cars, tracks or major gameplay systems until:

1. the Resource-backed car tuning path is validated;
2. the full-program smoke test passes after checkout;
3. helper tests cover the subsystem being changed;
4. the relevant documentation is updated in the same change.
