# Roadmap

This roadmap prioritizes correctness, maintainability and reproducible exports before visible feature expansion.

## Current baseline

The following remediation stages are complete for the present prototype:

- catalog-driven car models, variants and specs;
- catalog-driven track selection with an explicit default track ID;
- modular game, spawning, race and vehicle coordinators;
- scene-driven menu, race, pause, HUD, minimap and mobile UI;
- Resource-backed generated-track layout and typed builder pipeline;
- atomic track rebuilds and geometry revision notifications;
- plane-crossing checkpoints and ordered lap validation;
- continuous participant progress and race positions;
- manual clutch abstraction and automatic transmission/torque converter;
- bounded powertrain substeps;
- four-point ground contact, surface grip and friction-circle coupling;
- collision-resolved velocity synchronization;
- bounded skid marks, procedural-audio voices and stadium/render batches;
- Polish/English localization and global UI theme;
- automatic test discovery, per-test timeouts and runtime-error detection;
- Windows export plus normal/package smoke validation;
- Android APK export, integrity and manifest validation.

The branch should remain regression-first: every behavior or ownership change needs focused coverage and compatibility with the canonical full-program smoke test.

## Phase 0 — Baseline documentation

Status: complete; documentation must be maintained incrementally.

- [x] repository README;
- [x] architecture baseline;
- [x] vehicle-model baseline;
- [x] catalog documentation;
- [x] Windows and Android CI documentation;
- [x] roadmap.

## Phase 1 — High-level coordination split

Status: complete.

- [x] `GameManager` reduced to high-level coordination;
- [x] menu option and selection state helpers;
- [x] active-track lifecycle helper;
- [x] player and opponent spawn helpers;
- [x] race-session facade;
- [x] race state separated from lap tracking;
- [x] AI limited to drive-input production.

## Phase 2 — Data ownership

Status: complete for current content.

### Cars

- [x] `CarCatalog`, model, variant and `CarSpecs` resources;
- [x] 370Z 6MT and 7AT variants;
- [x] `CarSpecs -> CarDriveConfig` as the only active tuning path;
- [x] variant specs assigned before scene-tree entry;
- [x] catalog/scene/spec consistency validation.

### Tracks

- [x] `TrackCatalog` and `TrackDefinition` resources;
- [x] `default_track_id` as the sole default declaration;
- [x] `TrackLayoutResource` for geometry and decoration parameters;
- [x] menu options and recommended laps sourced from track metadata.

Remaining cleanup:

- [ ] resave or replace `scenes/cars/370z.tscn` without inert serialized tuning keys;
- [ ] remove `PlayerCarController`'s ignored-property compatibility list after that scene migration;
- [ ] consider typed exported catalog arrays when Godot serialization remains stable across editor/export builds.

## Phase 3 — Vehicle runtime

Status: complete for the current arcade model.

- [x] runtime state and sanitized config;
- [x] engine, drivetrain, resistance and torque-converter models;
- [x] manual and automatic transmission models;
- [x] clutch engagement abstraction;
- [x] bounded physics substeps;
- [x] tire/slip model and steering coupling;
- [x] four-point ground probes and suspension support;
- [x] surface-dependent grip;
- [x] friction-circle longitudinal-force budget;
- [x] collision-resolved velocity feedback;
- [x] runtime specs reconfiguration;
- [x] focused stability and mapping tests.

Possible later work:

- wheel-load transfer;
- per-wheel tire state;
- damage and mechanical failures;
- more complete manual clutch input;
- more realistic automatic transmission control.

## Phase 4 — Generated track and race correctness

Status: complete for the current oval.

- [x] typed generation configuration and mesh outputs;
- [x] modular layout/surface/collision/marker/barrier/checkpoint/decoration builders;
- [x] shared render/collision geometry metadata;
- [x] atomic generated-content replacement;
- [x] geometry revision notifications;
- [x] ordered checkpoint gates with segment-plane crossing;
- [x] reverse and out-of-order crossing rejection;
- [x] racing-line progress used only for position ordering;
- [x] active-track replacement and dependent-system refresh tests.

Possible later work:

- more track resources;
- banking and elevation;
- pit lane and sector timing;
- configurable checkpoint visualization;
- track editor tooling.

## Phase 5 — UI, localization and input

Status: complete for current screens.

- [x] menu, countdown, lap/position, results and pause scenes;
- [x] speedometer/tachometer and minimap scenes;
- [x] global theme;
- [x] Polish and English catalogs loaded before main-scene routing;
- [x] safe-area layout support;
- [x] independent player, AI and touch input channels;
- [x] rear-view camera behavior;
- [x] pause lifecycle and input cleanup.

Possible later work:

- remappable controls;
- gamepad calibration and dead-zone UI;
- final mobile control layout;
- accessibility settings;
- garage presentation.

## Phase 6 — Performance and export quality

Status: complete for the current content scale.

- [x] bounded racing-line lookup;
- [x] update-rate limits for dynamic HUD/minimap work;
- [x] cached minimap track projection;
- [x] change-driven race HUD updates;
- [x] thresholded tachometer redraws;
- [x] coalesced generated-track rebuilds;
- [x] bounded skid-mark storage;
- [x] bounded procedural-audio voices and listener-distance gating;
- [x] batched edge markers and barriers;
- [x] bounded stadium `MultiMesh` groups;
- [x] deterministic performance regression budgets;
- [x] Windows production/test export and packaged smoke tests;
- [x] Android APK export and manifest validation.

Distribution work remains deferred until required:

- executable/APK signing;
- installer or store packaging;
- tagged release workflow and retention policy;
- automatic update delivery;
- physical-device Android smoke automation.

## Phase 7 — Test and repository hygiene

Status: active maintenance.

Completed:

- [x] automatic standalone and scene-test discovery;
- [x] timeout and current-command diagnostics;
- [x] runtime-error detector self-check;
- [x] static architecture assertions;
- [x] canonical full-program smoke scene;
- [x] orphaned test-script detection;
- [x] removal of the duplicate smoke-test implementation;
- [x] explicit default-track regression coverage.

Ongoing rules:

- a test script must be discoverable, scene-referenced, an editor launcher or an allowed helper;
- no second implementation of an existing end-to-end scenario;
- update fixtures when a compatibility field is intentionally removed;
- keep CI logs useful enough to identify the first failing command.

## Phase 8 — Feature expansion

Status: ready for prioritization after this PR is considered reviewable.

Candidates:

- additional cars and higher-quality imported models;
- additional tracks;
- improved AI overtaking and avoidance;
- lap timer, sectors and best-lap persistence;
- ghost laps and replay data;
- configurable assists;
- garage/car-selection presentation;
- tire temperature, wear and damage consequences.

## Change rule

Every subsystem change should include:

1. a focused regression test or an explicit explanation why one is unnecessary;
2. compatibility with the canonical full-program smoke test;
3. relevant documentation updates;
4. no unrelated handling-tuning changes in the same commit;
5. verification of both required workflows before the PR is marked ready.
