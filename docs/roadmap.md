# Roadmap

This roadmap prioritizes correctness, test coverage and maintainability before visible feature expansion.

## Current baseline

The repository currently provides:

- main menu;
- free-drive and race modes;
- catalog-driven 370Z manual and automatic variants;
- Resource-backed generated oval track;
- AI opponents;
- lap, position and results UI;
- speedometer, tachometer and minimap;
- scene-driven menu, race and mobile-control UI;
- modular game/race/spawn coordination;
- modular powertrain, chassis, tire, reset and input code;
- Resource-backed vehicle tuning;
- modular generated-track builders;
- Windows GitHub Actions regression suite.

Do not add more cars or major game modes until the remaining checkpoint-validation and performance work is complete.

## Phase 0 — Documentation and baseline freeze

Status: complete and maintained incrementally.

Completed:

- [x] project README;
- [x] architecture baseline;
- [x] vehicle-model documentation;
- [x] roadmap;
- [x] continuous-integration documentation.

## Phase 1 — Split the high-level game coordinator

Status: complete.

Completed:

- [x] game/menu state coordination;
- [x] catalog/model/variant selection state;
- [x] menu option builder;
- [x] player and opponent spawn helpers;
- [x] race-session facade;
- [x] race manager and lap tracker separation;
- [x] AI driver limited to producing drive input.

## Phase 2 — Scene-driven UI

Status: complete for current UI.

Completed:

- [x] main menu scene;
- [x] countdown overlay scene;
- [x] lap/position HUD scene;
- [x] results screen scene;
- [x] mobile controls scene;
- [x] speedometer and minimap scenes;
- [x] dynamic rows/buttons kept script-driven where runtime data requires them.

## Phase 3 — Extract car input and non-driving effects

Status: complete.

Completed:

- [x] `CarInput` abstraction;
- [x] external AI input path;
- [x] `SkidMarkEmitter` extraction;
- [x] public slip telemetry preserved.

## Phase 4 — Modular vehicle runtime

Status: complete at the current architecture level.

Completed:

- [x] engine, resistance and drivetrain models;
- [x] manual and automatic transmission models;
- [x] torque-converter model;
- [x] shift-timer model;
- [x] powertrain controller;
- [x] runtime state;
- [x] drive config and builder;
- [x] tire and vehicle-motion models;
- [x] chassis and reset controllers;
- [x] collision-resolved velocity synchronization;
- [x] grounded-only lateral tire recovery;
- [x] current-frame slip used by steering;
- [x] automatic `D -> R` / `R -> D` direction interlock;
- [x] RPM-safe runtime specs reconfiguration;
- [x] focused powertrain, chassis and reconfiguration tests.

## Phase 5 — Resource-backed car catalog and tuning

Status: active runtime migration complete.

Completed:

- [x] `CarSpecs`, model, variant and catalog Resource types;
- [x] 370Z 6MT and 7AT specs Resources;
- [x] catalog-driven menu and spawning;
- [x] variant specs applied before scene-tree entry;
- [x] controller tuning exports removed;
- [x] legacy `CarDriveConfigBuilder` fallback removed;
- [x] automatic fallback opponents selected through `CarSpecs`;
- [x] helper/test scenes explicitly reference specs;
- [x] catalog test validates scene/spec alignment;
- [x] runtime-config test validates absence of legacy exports.

Minor cleanup:

- [ ] resave the large base `370z.tscn` in Godot to remove inert serialized keys from old exports;
- [ ] remove the temporary ignored-property compatibility list after that resave;
- [ ] split `CarSpecs` into sub-resources only if the flat Resource becomes difficult to maintain.

The inert base-scene keys are no longer an active tuning path and cannot affect runtime configuration.

## Phase 6 — Resource-backed generated track

Status: complete for the current simple oval.

Completed:

- [x] generated-content root helper;
- [x] geometry-data container;
- [x] layout, surface, collision, marker, barrier and decoration builders;
- [x] material factory;
- [x] stable `get_racing_line_points()` API;
- [x] focused `TrackLayoutBuilder` topology and geometry tests;
- [x] deterministic rebuild checks;
- [x] track-width, width-variation and shoulder-width input sanitization;
- [x] `TrackLayoutResource` with control points and sampling density;
- [x] simple-oval metadata, road and decoration data moved into a Resource;
- [x] generated-track scenes reference the Resource instead of scene overrides;
- [x] menu track options use Resource ID, label and recommended-lap metadata;
- [x] Resource-to-builder-to-scene regression test in Windows CI.

## Phase 7 — Checkpoint-based lap validation

Status: not started.

Tasks:

- [ ] add checkpoint and finish-line areas;
- [ ] add checkpoint sequence data/helper;
- [ ] validate checkpoint order in `LapTracker`;
- [ ] reject reverse finish-line crossings and track cuts;
- [ ] add wrong-way or missed-checkpoint handling;
- [ ] keep racing-line progress only for position sorting.

## Phase 8 — Performance and export quality

Status: not started.

Tasks:

- [ ] add profiling notes and repeatable opponent-count checks;
- [ ] disable or reduce procedural audio for distant AI cars;
- [ ] cache or window AI nearest-racing-line lookup;
- [ ] avoid unnecessary UI redraws;
- [ ] verify generated mesh/collision rebuild frequency;
- [ ] add a Windows export preset and export smoke check.

## Phase 9 — Feature expansion

Start only after checkpoint validation and the performance pass.

Candidates:

- more cars and improved imported models;
- additional tracks;
- improved AI racecraft;
- lap timer and best-lap storage;
- ghost laps;
- gamepad tuning;
- pause menu;
- replay camera;
- garage/car selection presentation;
- improved tire and collision consequences.

## Current change rule

Every subsystem change should include:

1. focused regression coverage;
2. full smoke-test compatibility;
3. relevant documentation updates;
4. no unrelated handling or feature changes in the same commit series.
