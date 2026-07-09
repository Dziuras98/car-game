# Roadmap

This roadmap prioritizes making the current prototype maintainable before adding more visible features.

## Current baseline

The project already has enough gameplay systems to be treated as a playable prototype:

- main menu;
- free drive mode;
- race mode;
- player car spawning;
- two 370Z variants;
- generated oval track;
- AI opponents;
- lap/position/results UI;
- speedometer, tachometer and minimap;
- procedural engine and tire audio.

The next phase should focus on stabilizing architecture.

## Phase 0 — Documentation and baseline freeze

Status: mostly complete.

Goal: document the current structure so future Codex tasks have stable context.

Tasks:

- [x] Add `README.md`.
- [x] Add `docs/architecture.md`.
- [x] Add `docs/roadmap.md`.
- [ ] Add `docs/controls.md` if controls grow beyond README.
- [x] Add `docs/vehicle_model.md` before major handling changes.
- [ ] Add `docs/tuning_notes.md` before detailed 370Z tuning.

Definition of done:

- repository has a readable project overview;
- major scripts and scenes are documented;
- refactor order is clear;
- future Codex tasks can reference explicit architecture goals.

## Phase 1 — Split the high-level game coordinator

Status: implemented, pending full local regression testing.

Goal: remove unrelated responsibilities from the original high-level coordinator without changing gameplay behavior.

Completed split:

- [x] Create `scripts/game/game_manager.gd`.
- [x] Move menu-selection flow and game-state transitions there.
- [x] Create `scripts/game/car_spawner.gd`.
- [x] Move player/opponent car instantiation there.
- [x] Create `scripts/race/race_manager.gd`.
- [x] Move race start, countdown, finish and opponent enable/disable logic there.
- [x] Create `scripts/race/lap_tracker.gd`.
- [x] Move lap, participant progress, position and result-order logic there.
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

## Phase 2 — Move race UI into scenes

Status: started. Race UI is split into helper scripts, but still builds controls procedurally.

Goal: stop building race UI procedurally and make it scene-driven.

Tasks:

- [ ] Create `scenes/ui/race_hud.tscn`.
- [x] Create `scripts/ui/race_hud.gd`.
- [ ] Create `scenes/ui/countdown_overlay.tscn`.
- [x] Create `scripts/ui/countdown_overlay.gd`.
- [ ] Create `scenes/ui/lap_position_hud.tscn`.
- [x] Create `scripts/ui/lap_position_hud.gd`.
- [ ] Create `scenes/ui/results_screen.tscn`.
- [x] Create `scripts/ui/results_screen.gd`.
- [ ] Wire these scenes from `main.tscn` or instantiate them from `game_manager.gd`.
- [x] Remove procedural UI construction from the race/game manager.

Definition of done:

- UI layout is editable in Godot scenes;
- scripts only update values and visibility;
- existing visual behavior remains equivalent or better.

## Phase 3 — Extract non-driving effects from the car controller

Status: implemented, pending local regression testing.

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

## Phase 4 — Extract drivetrain model

Status: started. Engine RPM/torque/limiter, resistance logic and drivetrain helper calculations are split out. Transmission selection and torque converter behavior remain in `PlayerCarController`.

Goal: separate engine/transmission simulation from movement and steering.

Tasks:

- [x] Create `scripts/car/engine_model.gd`.
- [x] Move RPM calculation.
- [x] Move torque curve calculation.
- [x] Create `scripts/car/resistance_model.gd`.
- [x] Move aerodynamic drag calculation.
- [x] Move rolling resistance calculation.
- [x] Create `scripts/car/drivetrain_model.gd`.
- [x] Move gear-ratio and wheel-coupled RPM helper calculations.
- [x] Move wheel force and drive-acceleration helper calculations.
- [ ] Move manual transmission logic.
- [ ] Move automatic transmission logic.
- [ ] Move torque converter approximation.
- [ ] Expose a small API returning wheel drive acceleration/force, RPM, load and gear text.

Definition of done:

- speedometer still receives speed, RPM and gear text;
- engine audio still receives RPM/load/throttle;
- manual and automatic 370Z variants behave at least as before;
- tuning parameters are still visible in the Godot inspector or moved cleanly to a Resource.

## Phase 5 — Introduce car specs as Resources

Goal: stop storing all car tuning directly in scene overrides and controller export variables.

Tasks:

- [ ] Create `scripts/car/car_specs.gd` extending `Resource`.
- [ ] Add drivetrain fields.
- [ ] Add mass/resistance fields.
- [ ] Add tire/steering fields.
- [ ] Create `resources/cars/370z_manual.tres`.
- [ ] Create `resources/cars/370z_automatic.tres`.
- [ ] Let car scenes reference specs.

Definition of done:

- adding a new car variant does not require duplicating controller parameters manually;
- menu can later read car names from car definitions;
- car tuning can be versioned as data.

## Phase 6 — Replace heuristic lap tracking with checkpoints

Goal: make race progress robust enough for more complex tracks.

Tasks:

- [ ] Add checkpoint/final-line areas to generated track or track scenes.
- [ ] Create `scripts/race/checkpoint.gd`.
- [ ] Let `lap_tracker.gd` validate checkpoint order.
- [ ] Add wrong-way or missed-checkpoint handling.
- [ ] Keep nearest-racing-line progress only as a position-sorting aid.

Definition of done:

- laps cannot be counted by cutting across the track;
- driving backwards over the finish line does not count incorrectly;
- AI and player use the same participant tracking rules.

## Phase 7 — Track data and multiple tracks

Goal: separate track data from procedural generation.

Tasks:

- [ ] Create `scripts/race/track_layout_resource.gd`.
- [ ] Move control points from `generated_track.gd` into a Resource.
- [ ] Add track metadata: name, width, scenery options, lap count suggestion.
- [ ] Create `resources/tracks/simple_oval.tres`.
- [ ] Update menu track list to use available track data.

Definition of done:

- adding a second track no longer requires editing `generated_track.gd` internals;
- minimap and AI still get racing-line points;
- generated road, barriers and scenery still work.

## Phase 8 — Performance and quality pass

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

Only start this after the architecture is less coupled.

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

Do not add new cars, tracks or major gameplay systems until Phase 1 is locally regression-tested and Phase 2 is complete.
