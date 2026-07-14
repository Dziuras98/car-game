# Roadmap

This roadmap prioritizes correctness, maintainability and reproducible Windows exports before uncontrolled feature expansion.

## Current baseline

The following remediation and expansion stages are complete for the present prototype:

- catalog-driven car models, variants and specs with typed exported arrays;
- four car models and fifteen playable variants:
  - standard Nissan 370Z 6MT/7AT;
  - Nissan 370Z NISMO 6MT/7AT;
  - 1967 Shelby G.T. 500 four-speed/C6;
  - nine 1995 Fiat Punto Type 176 variants, including Selecta CVT, petrol, turbo and diesel engines;
- catalog-driven track selection with an explicit default track ID;
- two production track resources: the simple oval and calibrated Tor Poznań reconstruction;
- modular game, spawning, race and vehicle coordinators;
- scene-driven menu, loading, race, pause, HUD and minimap UI;
- Resource-backed generated-track layout and typed builder pipeline;
- progress-based width, shoulder, barrier, racing-line and banking profiles;
- atomic track rebuilds and geometry revision notifications;
- plane-crossing checkpoints and ordered lap validation;
- continuous participant progress and race positions;
- manual clutch abstraction, conventional automatic/torque converter and native CVT transmission type;
- `TransmissionType` as the sole transmission-mode state;
- built-in manual upshift throttle cut and downshift RPM blip;
- bounded vehicle substeps;
- four-point ground contact, typed surface grip, lateral slip and longitudinal slip-ratio traction/braking limits;
- combined-slip steering/effect coupling and collision-resolved velocity synchronization;
- explicit AI eligibility with support for manual, conventional automatic and CVT variants;
- model-specific live engine synthesis plus Nissan baked AI banks;
- Polish/English localization and global UI theme;
- keyboard/gamepad player input and a separate external AI channel;
- automatic test discovery, per-test timeouts, runtime-error detection and exact warning allowlists;
- Windows production/test export plus packaged startup validation and retained export-smoke logs.

The repository remains regression-first: every behavior or ownership change needs focused coverage and compatibility with the canonical full-program smoke test.

## Phase 0 — Baseline documentation

Status: complete; documentation must be maintained incrementally.

- [x] repository README;
- [x] architecture baseline;
- [x] vehicle-model baseline;
- [x] catalog documentation;
- [x] model-specific Nissan, Shelby and Fiat integration documents;
- [x] Tor Poznań reconstruction document;
- [x] engine-audio backend/baking documentation;
- [x] Windows CI documentation;
- [x] accepted-risk register and third-party notices;
- [x] roadmap.

## Phase 1 — High-level coordination split

Status: complete.

- [x] `GameManager` reduced to high-level coordination;
- [x] menu option and selection state helpers;
- [x] transactional session-start helper with staged loading progress;
- [x] active-track lifecycle helper;
- [x] player and opponent spawn helpers;
- [x] race-session facade;
- [x] race state separated from lap tracking;
- [x] AI limited to drive-input and manual-shift production.

## Phase 2 — Data ownership

Status: complete for current content.

### Cars

- [x] `CarCatalog`, model, variant and `CarSpecs` resources;
- [x] typed `CarModelDefinition` and `CarVariantDefinition` catalog arrays;
- [x] standard 370Z 6MT and 7AT variants;
- [x] 370Z NISMO 6MT and 7AT variants;
- [x] Shelby G.T. 500 four-speed and C6 variants;
- [x] nine selected 1995 Fiat Punto variants;
- [x] `CarSpecs -> CarDriveConfig` as the only active tuning path;
- [x] direct-drive/manual/automatic/CVT `TransmissionType` enum as the only transmission-mode source;
- [x] variant specs assigned before scene-tree entry;
- [x] catalog/scene/spec consistency validation;
- [x] explicit per-variant AI eligibility and AI scene ownership;
- [x] explicit tire calibration for every production variant;
- [x] typed and validated engine-audio profiles for all current live synthesizers;
- [x] removed-property interception deleted from `PlayerCarController`.

### Tracks

- [x] `TrackCatalog` and `TrackDefinition` resources;
- [x] typed `TrackDefinition` catalog array;
- [x] `default_track_id` as the sole default declaration;
- [x] `TrackLayoutResource` for geometry and decoration parameters;
- [x] simple oval catalog entry;
- [x] calibrated Tor Poznań geometry and catalog entry;
- [x] menu options and recommended laps sourced from track metadata.

## Phase 3 — Vehicle runtime

Status: complete for the current arcade model.

- [x] runtime state and sanitized config;
- [x] engine, drivetrain, resistance and torque-converter models;
- [x] manual and conventional automatic transmission models;
- [x] dedicated CVT model with continuous ratio and centrifugal clutch;
- [x] clutch engagement abstraction;
- [x] manual shift throttle assistance;
- [x] bounded physics substeps;
- [x] lateral tire/slip model and steering coupling;
- [x] car-level longitudinal slip ratio and peak/sliding grip response;
- [x] four-point ground probes and suspension support;
- [x] surface-dependent grip;
- [x] lateral/longitudinal combined-slip effects;
- [x] collision-resolved velocity feedback;
- [x] runtime specs reconfiguration;
- [x] catalog-wide tire and performance regression coverage.

Possible later work:

- wheel-load transfer;
- per-wheel slip angle, wheel speed and tire force state;
- differential and driven-axle torque distribution;
- ABS and traction-control assists;
- tire temperature, pressure and wear;
- damage and mechanical failures;
- analog clutch support for suitable controllers;
- more realistic automatic and CVT control.

## Phase 4 — Generated tracks and race correctness

Status: complete for the current two-track catalog.

- [x] typed generation configuration and mesh outputs;
- [x] modular layout/surface/collision/marker/barrier/checkpoint/decoration builders;
- [x] shared render/collision geometry metadata;
- [x] atomic generated-content replacement;
- [x] geometry revision notifications;
- [x] ordered checkpoint gates with segment-plane crossing;
- [x] reverse and out-of-order crossing rejection;
- [x] racing-line progress used only for position ordering;
- [x] active-track replacement and dependent-system refresh tests;
- [x] progress-based road, shoulder, barrier, racing-line and banking profiles;
- [x] traced and length-calibrated Tor Poznań centerline;
- [x] Tor Poznań pit complex, paddock, curbs, gantry, grandstands, buildings and trackside forest;
- [x] loop-profile continuity and race-grid validation.

Possible later work:

- additional circuits beyond the current catalog;
- elevation reconstructed from surveyed or licensed source data;
- separate drivable pit lane and pit rules;
- sector timing and lap records;
- configurable checkpoint visualization;
- track editor tooling.

## Phase 5 — UI, localization and input

Status: complete for current screens and input sources.

- [x] menu, blocking loading step, countdown, lap/position, results and pause scenes;
- [x] speedometer/tachometer and minimap scenes;
- [x] active-car label in the driving HUD;
- [x] uniformly random different-car switching in free drive;
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
- garage/car-selection presentation;
- explicit assist settings for manual shift assistance, ABS or traction control if those become configurable.

## Phase 6 — AI and race participation

Status: complete for current basic racing behavior.

- [x] explicit `ai_eligible` ownership per variant;
- [x] all-or-nothing opponent preparation and deterministic seeded selection;
- [x] typed AI driver profiles;
- [x] bounded racing-line target search;
- [x] manual upshift/downshift requests with hysteresis;
- [x] forward/neutral/reverse recovery for manual cars;
- [x] conventional automatic and CVT direction recovery;
- [x] controlled braking and session teardown on AI contract faults;
- [x] finished opponents stop receiving active drive commands.

Possible later work:

- overtaking and opponent awareness;
- collision avoidance and defensive lines;
- per-car AI performance envelopes;
- wet/low-grip strategy adaptation;
- difficulty presets and qualifying behavior.

## Phase 7 — Performance and audio quality

Status: complete for the current content scale, with backend-specific follow-up still available.

- [x] bounded racing-line lookup;
- [x] update-rate limits for dynamic HUD/minimap work;
- [x] cached minimap track projection;
- [x] change-driven race HUD updates;
- [x] thresholded tachometer redraws;
- [x] coalesced generated-track rebuilds;
- [x] screen-visibility vehicle LOD with model-specific wheel bindings;
- [x] bounded skid-mark storage;
- [x] full live procedural player audio;
- [x] Nissan baked AI audio banks;
- [x] dedicated VQ37VHR, Ford FE cross-plane and Fiat petrol/diesel/turbo synthesis paths;
- [x] live procedural playback disabled on the headless display server while offline synthesis remains testable;
- [x] production Nissan race audio benchmark;
- [x] batched edge markers and barriers;
- [x] bounded stadium/trackside `MultiMesh` groups;
- [x] deterministic performance regression budgets;
- [x] Windows production/test export and packaged smoke tests;
- [x] export startup logs retained in pull-request diagnostic artifacts.

Possible later work:

- dedicated baked AI banks for Fiat variants if race profiling shows the shared live backend is too costly;
- AI scenes and an explicit audio/performance backend for the Shelby;
- broader production benchmarks covering mixed-model opponent fleets;
- native/DSP implementation of live synthesis if GDScript cost becomes limiting.

Distribution work remains deferred until required:

- executable signing;
- installer or store packaging;
- tagged release workflow and retention policy;
- automatic update delivery;
- complete rights/provenance clearance for every redistributed third-party asset.

## Phase 8 — Test and repository hygiene

Status: complete for the current remediation baseline; maintained continuously afterward.

Completed:

- [x] automatic standalone and scene-test discovery;
- [x] timeout and current-command diagnostics;
- [x] runtime-error and unexpected-warning detector self-checks;
- [x] exact per-test warning allowlists for deliberate negative-path coverage;
- [x] failure on invalid resource UIDs, unexpected importer warnings and `ObjectDB` leak warnings;
- [x] static architecture assertions;
- [x] canonical full-program smoke scene;
- [x] orphaned test-script detection;
- [x] explicit default-track regression coverage;
- [x] no test-only suffixes in production GDScript APIs;
- [x] no test simulation facades in production coordinators;
- [x] static guards for completed scene, catalog and transmission migrations;
- [x] current-tree and complete-history public-repository safety checks;
- [x] one Windows platform workflow and two Windows export presets.

Ongoing rules:

- a test script must be discoverable, scene-referenced, an editor launcher or an allowed helper;
- no second implementation of an existing end-to-end scenario;
- update fixtures when a compatibility field is intentionally removed;
- add an anchored warning allowlist only when a warning is the behavior under test;
- keep CI logs useful enough to identify the first failing command;
- update catalog-wide tests whenever a model, variant, transmission type, track or audio backend is added.

## Phase 9 — Further feature expansion

Status: ready for separate prioritization.

Candidates:

- additional vehicle generations and trim-correct visual models;
- additional circuits beyond the oval and Tor Poznań;
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
