# Roadmap

This roadmap prioritizes correctness, maintainability and reproducible Windows exports before visible feature expansion.

## Current baseline

The following remediation stages are complete for the present prototype:

- catalog-driven car models, variants and specs with typed exported arrays;
- catalog-driven track selection with an explicit default track ID;
- modular game, spawning, race and vehicle coordinators;
- scene-driven menu, race, pause, HUD and minimap UI;
- Resource-backed generated-track layout and typed builder pipeline;
- atomic track rebuilds and geometry revision notifications;
- plane-crossing checkpoints and ordered lap validation;
- continuous participant progress and race positions;
- manual clutch abstraction and automatic transmission/torque converter;
- `TransmissionType` as the sole transmission-mode state;
- bounded powertrain substeps;
- four-point ground contact, surface grip and friction-circle coupling;
- collision-resolved velocity synchronization;
- bounded skid marks, procedural-audio voices and stadium/render batches;
- Polish/English localization and global UI theme;
- keyboard/gamepad player input and a separate external AI channel;
- automatic test discovery, per-test timeouts and runtime-error detection;
- Windows production/test export plus packaged startup validation.

The branch should remain regression-first: every behavior or ownership change needs focused coverage and compatibility with the canonical full-program smoke test.

## Phase 0 — Baseline documentation

Status: complete; documentation must be maintained incrementally.

- [x] repository README;
- [x] architecture baseline;
- [x] vehicle-model baseline;
- [x] catalog documentation;
- [x] Windows CI documentation;
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
- [x] typed `CarModelDefinition` and `CarVariantDefinition` catalog arrays;
- [x] 370Z 6MT and 7AT variants;
- [x] `CarSpecs -> CarDriveConfig` as the only active tuning path;
- [x] `TransmissionType` enum as the only transmission-mode source;
- [x] variant specs assigned before scene-tree entry;
- [x] catalog/scene/spec consistency validation;
- [x] `scenes/cars/370z.tscn` contains visual and structural data only;
- [x] removed-property interception deleted from `PlayerCarController`.

### Tracks

- [x] `TrackCatalog` and `TrackDefinition` resources;
- [x] typed `TrackDefinition` catalog array;
- [x] `default_track_id` as the sole default declaration;
- [x] `TrackLayoutResource` for geometry and decoration parameters;
- [x] menu options and recommended laps sourced from track metadata.

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
- analog clutch support for suitable controllers;
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

Status: complete for current screens and input sources.

- [x] menu, countdown, lap/position, results and pause scenes;
- [x] speedometer/tachometer and minimap scenes;
- [x] global theme;
- [x] Polish and English catalogs loaded before main-scene routing;
- [x] keyboard and gamepad action mappings;
- [x] independent player and external AI input channels;
- [x] rear-view camera behavior;
- [x] pause lifecycle and input cleanup.

Possible later work:

- remappable controls;
- gamepad calibration and dead-zone UI;
- steering-wheel and pedal profiles;
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
- [x] Windows production/test export and packaged smoke tests.

Distribution work remains deferred until required:

- executable signing;
- installer or store packaging;
- tagged release workflow and retention policy;
- automatic update delivery.

## Phase 7 — Test and repository hygiene

Status: complete for the current remediation baseline; maintained continuously afterward.

Completed:

- [x] automatic standalone and scene-test discovery;
- [x] timeout and current-command diagnostics;
- [x] runtime-error detector self-check;
- [x] static architecture assertions;
- [x] canonical full-program smoke scene;
- [x] orphaned test-script detection;
- [x] removal of the duplicate smoke-test implementation;
- [x] explicit default-track regression coverage;
- [x] no test-only suffixes in production GDScript APIs;
- [x] no test simulation facades in production coordinators;
- [x] static guards for completed scene, catalog and transmission migrations;
- [x] one Windows platform workflow and two Windows export presets.

Ongoing rules:

- a test script must be discoverable, scene-referenced, an editor launcher or an allowed helper;
- no second implementation of an existing end-to-end scenario;
- update fixtures when a compatibility field is intentionally removed;
- keep CI logs useful enough to identify the first failing command.

## Phase 8 — Feature expansion

Status: ready for separate prioritization.

Candidates:

- additional cars and higher-quality imported models;
- additional tracks;
- improved AI overtaking and avoidance;
- lap timer, sectors and best-lap persistence;
- ghost laps and replay data;
- configurable assists;
- garage/car-selection presentation;
- tire temperature, wear and damage consequences;
- richer keyboard, gamepad and steering-wheel configuration.

## Change rule

Every subsystem change should include:

1. a focused regression test or an explicit explanation why one is unnecessary;
2. compatibility with the canonical full-program smoke test;
3. relevant documentation updates;
4. no unrelated handling-tuning changes in the same commit;
5. successful Windows verification and packaged export checks before a pull request is marked ready.
