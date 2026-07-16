# Voyage 3: Outlaw vehicle import workflow

## Purpose

This document is the authoritative orchestration procedure for integrating every retained vehicle from the **Voyage 3: Outlaw Playable & NPC Vehicles** bundle into the Godot project.

The workflow is intentionally model-by-model. A shared package scale, guessed wheelbase, generic collision copied between unrelated body classes, runtime wheel-name scanning, transmission substitution or generic engine-audio fallback is not acceptable. Every model must complete the stages below in order and record its measurements, evidence, decisions and deviations.

The following detailed contracts introduced and maintained by PR #107 are mandatory shared project contracts for this bundle:

- `docs/assets/traffic_rider_transmission_implementation_contract.md`;
- `docs/assets/traffic_rider_engine_audio_implementation_contract.md`;
- `docs/assets/traffic_rider_npc_vehicle_research_data_contract.md`;
- `docs/assets/traffic_rider_npc_vehicle_physics_v3_baseline.md`;
- `docs/assets/traffic_rider_npc_vehicle_workflow_suite.md`.

Their Traffic Rider filenames describe their origin, not a bundle restriction. Voyage integrations must follow them in full until equivalent project-wide paths replace them. No abbreviated model note may weaken or replace those contracts.

The source bundle is used only for the project's private, noncommercial scope under the accepted-risk decision in `docs/accepted_risks.md`. The asset notice in `THIRD_PARTY_NOTICES.md` must remain intact.

## Scope and processing order

The selected scope contains 18 source GLBs. The lower-detail UAZ Hunter Police duplicate and the GAZ Gazelle flatbed are excluded. Only the higher-detail UAZ Hunter Police and the GAZ Gazelle van are retained.

Research and later implementation order:

`01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18`

## Gate state

### Source-upload gate — satisfied

All 18 verified GLBs listed in `docs/assets/voyage_3_outlaw_source_upload.md` are committed with their required filenames. Every model must still pass byte-level SHA-256 verification before its research leaves `source_only`.

### Research-before-implementation gate — open

Complete research and obtain owner-scope approval for **every included model before any implementation begins**. An individual model reaching `approved` fixes only its scope. It does not authorize source relocation, geometry conversion, catalog exposure, physics calibration, transmission work or audio work while any other included model remains below `approved`.

**No model may enter `integrating` until all 18 included models have reached `approved`.**

### Physics dependency — satisfied, synchronization remains mandatory

PR #118, **Rework per-wheel vehicle physics and recalibrate DPI v3**, was merged into `master`. The authoritative merged implementation baseline is:

`3743f5e95391b63a97e81b95050984b8240b7f30`

The stacked PR inherits that work through its PR #107 base. Before model 01 enters `integrating`, the branch must nevertheless be synchronized with then-current `master`, the current physics commit must be recorded, the reviewed interfaces must be reconciled with `docs/assets/traffic_rider_npc_vehicle_physics_v3_baseline.md`, and the full current suite must pass.

A future shared physics change does not reopen owner scope, but it does require Stage 7 synchronization and recalibration.

## Core rules

1. **Research the complete factory variant matrix before importing the model.** Identify every evidenced engine, transmission and drivetrain combination applicable to the represented generation/body across its production years and markets. Regional, facelift, limited-production and factory special-order variants must not be silently omitted.
2. **Stop for owner approval after research.** Present the complete matrix, ask whether all or a subset should be imported and ask whether any expected variant is missing.
3. **Finish all model scopes before implementing any model.** All 18 model records must reach `approved` before model 01 may enter implementation.
4. **Retain research as structured input.** Engines, curves, masses, ratios, transmission identities, tyres, aerodynamics and validation targets must be migrated into stable data rather than researched again or replaced by guesses.
5. **Keep the committed source GLB unchanged.** Technical adaptations belong in a deterministic derived GLB, Godot wrapper, material override or project-authored resource.
6. **Calibrate every model independently.** A package-wide conversion factor is not authoritative.
7. **Use wheelbase as the primary scale reference.** Cross-check overall dimensions, track, height and tyre diameter.
8. **Use the project coordinate convention.** `+Y` is up, local `-Z` is front, local `-X` is left and local `+X` is right.
9. **Provide explicit independent wheel nodes.** Split paired axle meshes into left/right hub-centred geometry. Multi-axle and dual-rear-wheel vehicles require every physical wheel position represented explicitly.
10. **Use explicit wheel bindings.** Do not add generic name scanning or heuristic wheel discovery to `CarVisualController`.
11. **Match the real transmission architecture exactly.** Torque-converter planetary automatics, automated manuals, DCTs, CVTs, conventional manuals and electric reductions require correct mechanics and semantics.
12. **Implement missing transmission types faithfully.** A missing architecture requires a dedicated model or clean shared extension, not a fallback.
13. **Treat the transmission and driveline as a complete torque path.** Ratios and shift delay alone do not implement launch devices, shift phases, converter lock-up, clutch preselection, transfer cases, range systems, differential state or AWD couplings.
14. **Reproduce performance from evidence, not labels.** Complete torque curves, gearing, mass, drag, tyres, drivetrain losses, shift behaviour and physical limits must produce the result.
15. **Build new engine-sound architectures from first principles.** Cylinder layout, crank and firing sequence, banks and collectors, combustion, aspiration and transients define the backend. A profile, pitch shift or EQ does not change architecture.
16. **Define player and AI audio backends explicitly.** Player vehicles use explicit live synthesis. AI uses a committed baked bank or a justified live backend with a measured fleet budget.
17. **Keep every model compatible with current `master` physics.** Recalibrate affected rows rather than adding compatibility hacks.
18. **Separate visual and physical data.** Collision, wheel contact, mass, powertrain and traffic behaviour are authored data, not runtime render-mesh inference.
19. **Document uncertainty.** Evidence-blocked rows may remain approved in scope but unavailable; guessed parameters are prohibited.
20. **One model is complete only after full validation.** An imported GLB alone is not an integrated vehicle.
21. **Do not reintroduce excluded source representations.** The low-detail UAZ and Gazelle flatbed require a new explicit owner decision before they may be committed or implemented.

## Status gates

Use these statuses in the inventory and model record:

1. `source_only` — source committed; byte verification and research not started;
2. `researching` — identity, dimensions and complete powertrain matrix being established;
3. `awaiting_owner_scope` — complete matrix presented for owner decision;
4. `approved` — owner scope fixed; implementation not yet started;
5. `integrating` — source/visual, structured data, catalog, transmission, physics and audio implementation in progress;
6. `integrated` — every mandatory contract passes against current `master`.

A model must not skip `awaiting_owner_scope`. No row may be exposed merely because its parent model is `integrating`.

## Repository layout

Move a source only when its numbered implementation begins, preserving bytes and updating references in the same commit:

```text
assets/third_party/sketchfab/voyage_3_outlaw_vehicles/<vehicle_id>/source/<original_filename>.glb
```

Store a deterministic project-oriented derivative when geometry must be split, centred or reoriented:

```text
assets/third_party/sketchfab/voyage_3_outlaw_vehicles/<vehicle_id>/processed/<vehicle_id>_processed.glb
```

Project-authored integration files use:

```text
scenes/traffic/vehicles/<vehicle_id>_visuals.tscn
resources/traffic/vehicles/<vehicle_id>.tres
docs/vehicles/traffic/<vehicle_id>.md
resources/cars/<manufacturer>/<model>/...
scenes/cars/<vehicle_id>...
resources/audio/...
```

Playable resources must use the authoritative car-catalog hierarchy. Do not create a parallel catalog or retain a duplicate root source.

## Stage 0 — complete vehicle, powertrain and workflow research

### 0.1 Establish represented scope

1. Inspect the model from all sides.
2. Confirm manufacturer, generation, body and approximate year.
3. Compare lamps, grille, bumpers, shell, cab, wheel count, bed/box and facelift details.
4. Record identity confidence.
5. Define production-year and market research boundaries.

### 0.2 Enumerate every factory combination

For each evidenced combination retain:

- year/production range and market;
- body/chassis/trim restriction where material;
- engine family/code, fuel, aspiration, displacement and cylinder layout;
- power/torque standard, complete torque curve, idle, peaks, redline and limiter/governor;
- transmission name, family/code, architecture and launch device;
- forward/reverse ratios, CVT range and final drive;
- drivetrain, transfer case, range, coupling and differential state;
- mass, axle loads and body/payload state;
- tyre/wheel and rolling radius;
- drag, frontal area, brakes and documented performance.

A row labelled only `automatic` is insufficient. Conventional manuals, torque-converter automatics, automated manuals, DCTs, CVTs, electric reductions and range systems must be identified independently.

Commercial vehicles additionally require wheelbase, cab/body, axle and gross-weight compatibility.

### 0.3 Evidence order and states

Prefer:

1. manufacturer technical and homologation data;
2. official brochures, price lists, workshop and transmission documents;
3. recognized technical databases and instrumented period tests;
4. reputable specialist sources;
5. community evidence only for explicitly marked gaps.

Classify every combination and material value as `verified_factory`, `strongly_supported`, `provisional`, `evidence_blocked` or `rejected/not_factory`. Preserve conflicts and resolve them explicitly.

Factory special-order vehicles with no public brochure may be admitted as `strongly_supported_factory_special_order` only when vehicle-level evidence, provenance and mechanical data are independently corroborated. Their incomplete values remain evidence-blocked.

### 0.4 Owner decision

Present:

- total mechanically distinct combinations;
- engine families and calibrations;
- exact transmission architectures and known codes;
- drivetrain layouts;
- regional, year-only, limited-production and special-order variants;
- unresolved rows;
- required new transmission models;
- required new audio architectures.

Record the owner's decision in the model record. The approved scope is immutable unless the owner explicitly amends it.

### 0.5 Structured migration gate

Before exposing a row:

1. assign a stable candidate ID;
2. retain its engine and calibration record;
3. retain curves, mass, gearing, tyre, aero and validation data;
4. retain explicit evidence states for missing exact values;
5. prove transmission, driveline and audio architecture decisions;
6. keep incomplete rows unavailable.

Follow `docs/assets/traffic_rider_npc_vehicle_research_data_contract.md`.

### 0.6 Voyage all-model completion gate

After model 18 is approved:

1. verify every inventory row is `approved`;
2. verify every model has a complete research record and owner decision;
3. report the final combined model and configuration count;
4. resolve cross-model duplicates and shared architectures without deleting mechanically distinct variants;
5. synchronize with current `master`;
6. record the current physics baseline;
7. review vehicle, transmission, AWD/4WD, tyre, braking, steering/yaw, audio and performance assumptions;
8. run the full current suite;
9. only then move model 01 to `integrating`.

## Stage 1 — establish dimensions and geometry evidence

Collect length, width excluding mirrors, height, wheelbase, front/rear track, ground clearance and representative tyre size/rolling radius. Use wheelbase as primary scale and dimensions as cross-checks. Commercial bodies require represented chassis/body length separately.

## Stage 2 — inspect the source GLB

Record path and SHA-256, root and mesh names, triangles, surfaces, materials/textures, AABB, axes, ground offset, axle/wheel centres, pivots, transparency, transforms and detached geometry. Document every topology exception.

## Stage 3 — build the canonical visual derivative

Create a deterministic derivative only when needed. Convert to `+Y` up and local `-Z` front, scale from measured wheelbase, centre between axles, ground at tyre contact and create exact `Body`, `FrontLeftWheel`, `FrontRightWheel`, `RearLeftWheel`, `RearRightWheel` geometry. Preserve materials, UVs, normals and source triangles unless optimization is separately documented and tested.

Multi-axle, dual-rear-wheel or decorative-wheel topology requires a model-specific plan naming every physical wheel and separating decorative geometry.

## Stage 4 — create the Godot visual wrapper

Use a shared data-driven controller where appropriate. Provide explicit body and wheel paths, hub-centred pivots, visibility AABB, wheel radius and LOD decision. Test independent steering and spin state for all physical wheels. Do not add runtime name heuristics.

## Stage 5 — build approved model and variant data

Create exactly the owner-approved rows. Migrate rather than reconstruct complete curves, idle/redline/limiter, ratios, mass/load distribution, drag, tyres, brakes, drivetrain and targets. Do not merge mechanically distinct calibrations or create marketing-alias duplicates.

No playable or AI scene is catalog-exposed until its row is complete and architecture-correct.

## Stage 6 — implement exact transmission and driveline architecture

Follow `docs/assets/traffic_rider_transmission_implementation_contract.md` in full.

The minimum rules remain:

- classic automatic is not automated manual;
- automated manual retains the manual gearset and clutch interruption;
- DCT requires two clutch paths and preselection;
- CVT requires continuous ratio control and its actual launch device;
- EV requires motor, inverter, battery, regeneration and fixed reduction;
- xDrive/Haldex/on-demand AWD requires dynamic coupling state;
- selectable 4WD requires real 2H/4H/4L/range semantics;
- portal and e-axle reductions affect torque, speed and inertia.

When absent, add a dedicated architecture model or clean shared extension. Implement time-resolved launch, creep, clutch/converter, lock-up, shift, kickdown/skip-shift, rev-match, torque handover/interruption, protection and truthful telemetry. Preserve exact ratios and integrate AI, UI, audio load and per-wheel torque. Do not force an unsupported transmission through a fallback path.

## Stage 7 — physics and performance calibration

Use evidence-based mass, acceleration, standing-distance, in-gear, top-speed, engine-speed, braking, shift, grade and turning targets. Results must emerge from sampled torque, gearing, wheel radius, mass, architecture losses, converter/clutch behaviour, aero, rolling resistance, tyres, load transfer, coupling/differentials and scheduling.

Do not match performance with false torque, wrong mass, wrong transmission, shared arbitrary loss, hidden speed cap or cargo mass used to conceal an incorrect kerb setup.

### Mandatory `master` synchronization

Before parameter commitment, final validation and marking ready:

1. synchronize with current `master`;
2. record the current physics-baseline commit;
3. inspect specs, drivetrain, transmissions, wheel/tyre, load transfer, contact, drag, braking, steering/yaw and performance changes;
4. identify affected models and rows;
5. rerun full tests;
6. recalibrate affected rows rather than add compatibility hacks;
7. run catalog-wide regressions when shared code changed.

## Stage 8 — implement architecture-correct engine audio

Follow `docs/assets/traffic_rider_engine_audio_implementation_contract.md` in full.

Research and implement cylinder layout, crank/firing order and intervals, banks/collectors, intake/exhaust, combustion/injection, aspiration, mechanical sources and transients. A new physical architecture requires an appropriate procedural source model; profiles calibrate a correct architecture but do not transform an unrelated waveform.

Player scenes use explicit live synthesis. AI receives an explicit committed baked bank or justified live backend with a fleet budget. Test firing orders, identity, load, induction, turbo/supercharger, start, idle, shifts, overrun, limiter, shutdown, sample-rate safety, summed loudness and perceptual distinction.

Limiter torque cut is not pedal lift: it must not erase turbo state or trigger false release audio. Added layers must not make the complete engine exceed the loudness reference merely through gain stacking.

## Stage 9 — define traffic geometry and behaviour

Traffic data is separate from playable powertrain data. Record measured dimensions, wheelbase, tracks, radius, authored collision, speed/acceleration/braking/steering classes, spawn weight and clearance. Use simple authored collision volumes, not runtime render-mesh trimeshes.

## Stage 10 — LOD, audio backend and runtime performance

Record geometry, material and resource cost, mipmaps, LOD and visibility distances. Test representative traffic groups and playable rows. Update engine-audio backend documentation and fleet benchmarks whenever supported opponent composition changes. Verify exports include scripts, profiles, banks, WAVs and processed assets.

## Stage 11 — mandatory validation

A model may become `integrated` only when all of the following pass:

- owner scope and exact catalog count;
- structured research-data completeness;
- source/processed hash and geometry contracts;
- dimensions, orientation, collision and independent wheel animation;
- transmission/driveline architecture and no fallback;
- engine/audio architecture, level and backend contracts;
- current-physics and performance validation;
- player, AI and traffic scenes;
- LOD, runtime and fleet budgets;
- shared and catalog-wide regressions;
- Windows export and packaged smoke test.

Transmission and audio fallbacks are prohibited. Evidence-blocked rows remain unexposed.

## Per-model integration record

Every model record under `docs/vehicles/traffic/` must contain:

- identity/body scope and dimensions;
- source and processed visual evidence;
- complete approved engine/transmission/drivetrain matrix;
- structured data and evidence state;
- recorded owner decision;
- conversion data and explicit visual bindings;
- exact transmission/driveline implementation decision;
- exact engine-audio family and player/AI backend decision;
- physics baseline and calibration targets;
- runtime integration and validation results;
- unresolved rows kept unavailable.

## Research and integration order

Research proceeds by numeric source prefix and each model must pass its owner decision gate before research moves to the next model.

After all 18 models are approved and the all-model completion gate passes, implementation also proceeds by numeric source prefix. Model 02 remains queued until model 01 reaches `integrated`. Shared architecture work created for an earlier model may be reused later only when the detailed transmission and audio contracts prove semantic compatibility.

## PR #107 conformance record

This workflow was reconciled against the current PR #107 orchestration document identified by Git blob:

`fc81ebccf14687d6fa6b941dd23e4d60993487a9`

Intentional bundle-specific differences are limited to the Voyage source count, file paths, exclusions, current research state and the still-open all-model research gate. Transmission, driveline, physics, structured-data, audio, validation and sequential-integration requirements are inherited without relaxation.
