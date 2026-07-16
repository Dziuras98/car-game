# Traffic Rider NPC vehicle import workflow

## Purpose

This document is the authoritative procedure for integrating every non-heavy vehicle from the **Traffic Rider NPC Vehicles** bundle into the Godot project.

The workflow is intentionally model-by-model. A shared package scale, guessed wheelbase, generic collision copied between unrelated body classes, runtime wheel-name scanning, transmission substitution or generic engine-audio fallback is not acceptable. Every integration PR must complete the stages below in order and record its measurements, evidence, decisions and deviations.

The source bundle is used only for the project's private, noncommercial scope under the accepted-risk decision in `docs/accepted_risks.md`. The asset notice in `THIRD_PARTY_NOTICES.md` must remain intact.

## Scope and processing order

The repository contains 20 source GLBs. Research and owner-scope approval proceed in ascending order of the numeric prefix assigned during source extraction.

Research and later implementation order:

`01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18 → 20 → 23`

All 20 owner-scope decisions are now complete. The approved combined scope is recorded in `docs/assets/traffic_rider_npc_vehicle_inventory.md`.

### Global research-before-implementation gate

Complete research and obtain owner-scope approval for **every included model before any implementation begins**. An individual model reaching `approved` records only that its scope is fixed; it does not authorize geometry conversion, source relocation, catalog/resource creation, physics calibration, transmission work or audio work while any other included model remains below `approved`.

**No model may enter `integrating` until all included models have reached `approved`.** This research condition is satisfied, but the separate physics dependency below remains blocking.

### Mandatory physics dependency — PR #118

No Traffic Rider vehicle implementation may begin until PR #118, **Rework per-wheel vehicle physics and recalibrate DPI v3**, is completed and its final physics work is integrated into `master`.

No source relocation, processed GLB, runtime vehicle scene, catalog resource, transmission implementation, engine-audio implementation, physics calibration or performance calibration may be committed before all of the following are true:

1. PR #118 is merged into `master`, or the owner explicitly identifies a merged successor carrying the same physics work;
2. this branch is synchronized with the resulting `master`;
3. the final merged physics commit is recorded as the implementation baseline;
4. per-wheel contact, slip, load transfer, drivetrain inertia, differentials, AWD, braking, steering/yaw, drag, transmissions and DPI/performance interfaces are reviewed;
5. shared calibration assumptions and model-specific implementation plans are updated for the final interfaces;
6. the full current test suite passes before model 01 enters `integrating`.

Closing PR #118 without integrating its intended physics changes does not satisfy this dependency unless a merged successor is explicitly identified.

The following large-truck models remain outside this scope:

- Scania heavy truck;
- generic articulated truck;
- generic rigid truck.

## Core rules

1. **Research the complete factory variant matrix before importing the model.** Identify every evidenced engine, transmission and drivetrain combination applicable to the represented generation/body across its production years and markets. Regional, facelift and limited factory variants must not be silently omitted.
2. **Stop for owner approval after research.** Present the complete matrix to the owner, ask whether every variant should be imported or only a subset, and ask whether any expected variant is missing.
3. **Finish all model scopes before implementing any model.** Do not begin geometry conversion, catalog creation, physics calibration, transmission implementation or audio implementation until every included model is `approved`.
4. **Wait for the authoritative physics baseline.** Even after every scope is approved, do not begin implementation until the PR #118 dependency is satisfied and the resulting `master` commit is recorded.
5. **Keep the committed source GLB unchanged.** Technical adaptations belong in a derived GLB, Godot wrapper scene, imported material override or project-authored resource. Do not destructively overwrite the source file.
6. **Calibrate every model independently.** Scale must be based on verified dimensions for the represented body variant. The former package-wide `0.695` conversion is not authoritative and must not be reused as a default.
7. **Use wheelbase as the primary scale reference.** Overall length is a mandatory cross-check, not the only measurement. Wheel track, height and wheel diameter provide additional validation.
8. **Use the project coordinate convention.** `+Y` is up, local `-Z` is the vehicle front, local `-X` is vehicle-left and local `+X` is vehicle-right.
9. **Provide four independent wheel nodes.** The current source models generally contain one body mesh, one paired front-wheel mesh and one paired rear-wheel mesh. Each axle pair must be split into left and right wheel geometry with a hub-centred pivot.
10. **Use explicit wheel bindings.** Do not add generic name scanning or heuristic wheel discovery to `CarVisualController`.
11. **Match the real transmission architecture exactly.** A torque-converter planetary automatic must use a torque-converter automatic model; an automated manual must use an automated-clutch manual model; a dual-clutch transmission, CVT and conventional manual must each use their own correct architecture. Never substitute one transmission type because it already exists in the project.
12. **Implement missing transmission types faithfully.** If the project lacks the required transmission architecture or generation-specific behaviour, create or extend a dedicated model that preserves its real operating principles instead of adapting an unrelated model.
13. **Reproduce performance from evidence, not from labels.** Engine curves, gearing, mass, drag, tyres, drivetrain losses, shift behaviour and physical limits must combine to reproduce documented performance as closely as the current simulation permits.
14. **Build new engine-sound architectures from first principles.** If the synthesizer does not already contain the relevant engine architecture, create a dedicated synthesis model based on that engine's firing cadence, crank arrangement, bank/collector geometry, aspiration and mechanical character. Do not base the new architecture on an unrelated cylinder layout.
15. **Keep every model compatible with current `master` physics.** Before implementation and final validation, synchronize with `master`, inspect all relevant physics changes, and recalibrate every affected model and variant rather than adding compatibility hacks.
16. **Separate visual and physical data.** Collision, wheel contact, mass, powertrain and traffic behaviour are project-authored. They must not be inferred directly from the render mesh at runtime.
17. **Document uncertainty.** When an exact trim, body configuration, engine calibration, gearbox suffix or performance result cannot be established, record the uncertainty and use a clearly labelled provisional value. Evidence-blocked rows may remain approved in scope but may not receive guessed parameters.
18. **One model is complete only after full validation.** Merely importing a GLB without research, owner approval, scale, wheels, transmission, physics, audio, collision, visibility and runtime checks does not complete the workflow.

## Status gates

Use these statuses in the inventory and model-specific record:

1. `source_only` — source GLB is committed but research has not started;
2. `researching` — identity, dimensions and full powertrain matrix are being established;
3. `awaiting_owner_scope` — research matrix has been presented and the next numbered model is blocked on the owner's answer;
4. `approved` — the owner has fixed the scope, but implementation remains deferred until the global research and physics-dependency gates are satisfied;
5. `integrating` — every scope is approved, the PR #118 dependency is satisfied, and geometry, catalog, physics, transmission and audio work is in progress;
6. `integrated` — all mandatory validation has passed against the final current `master` physics baseline.

A model must not skip `awaiting_owner_scope`. No model may enter `integrating` while either the all-model research gate or PR #118 dependency remains unresolved.

## Repository layout

Only after both global gates have passed, move a model's source file from the repository root into a canonical third-party directory and update all references in the same commit:

```text
assets/third_party/sketchfab/traffic_rider_npc_vehicles/<vehicle_id>/source/<original_filename>.glb
```

Store a derived, project-oriented GLB only when geometry must be split or recentered:

```text
assets/third_party/sketchfab/traffic_rider_npc_vehicles/<vehicle_id>/processed/<vehicle_id>_godot.glb
```

Project-authored integration files use:

```text
scenes/traffic/vehicles/<vehicle_id>_visuals.tscn
resources/traffic/vehicles/<vehicle_id>.tres
docs/vehicles/traffic/<vehicle_id>.md
```

Playable model and variant resources must follow the existing authoritative car-catalog hierarchy rather than creating a parallel catalog. Do not retain duplicate source copies after relocation.

## Stage 0 — complete vehicle and powertrain research

This stage is mandatory for every included model before any geometry import or runtime implementation begins for the bundle.

### 0.1 Establish represented vehicle scope

1. Inspect the model visually from all sides.
2. Confirm the manufacturer, generation, body style and approximate model year represented by the mesh.
3. Compare lamps, grille, bumpers, body shell, cab style, wheel count, bed/box length and facelift details against references.
4. Record whether identity is verified, probable or unresolved.
5. Define the production-year and market scope to research. Do not assume one market represents the full factory range.

### 0.2 Enumerate every factory combination

Build a complete matrix of all evidenced factory combinations applicable to the represented generation/body. At minimum record:

- model year or production range;
- sales market/region;
- trim or commercial-body restriction where relevant;
- engine family and exact engine code where known;
- fuel and aspiration;
- displacement, cylinder count and layout;
- factory power and torque calibration with measurement standard;
- idle speed, peak-power speed, peak-torque range, redline and limiter where available;
- transmission marketing name, manufacturer/family and exact suffix/code where known;
- transmission architecture;
- forward gear count or CVT ratio range;
- gear ratios, reverse ratio and final drive;
- driven wheels and AWD/4WD system;
- differential type or torque distribution where material;
- kerb mass and gross mass applicable to the variant;
- tyre/wheel size;
- documented performance figures.

The matrix must cover conventional manuals, torque-converter automatics, automated manuals, dual-clutch transmissions, CVTs and other factory types independently. A single row labelled only `automatic` is insufficient.

For commercial vehicles, research wheelbase, axle, cab and body combinations because powertrain availability may depend on chassis configuration and gross-weight class.

### 0.3 Evidence requirements

Prefer sources in this order:

1. manufacturer technical data and homologation/type-approval documents;
2. official brochures, price lists, workshop manuals and transmission documentation;
3. recognized technical databases and period instrumented tests;
4. reputable specialist secondary sources;
5. community sources only for gaps, explicitly marked as lower-confidence evidence.

Never infer a factory combination solely because an engine and gearbox were separately available somewhere in the same model family. For every combination, classify evidence as `verified_factory`, `strongly_supported`, `provisional` or `rejected/not_factory`. Conflicting data must be preserved and resolved explicitly.

### 0.4 Mandatory owner decision gate

After completing the matrix, present it to the owner. The summary must include:

- total number of identified factory combinations;
- grouped engine families and calibrations;
- exact transmission types and known gearbox codes;
- drivetrain layouts;
- regional or model-year-only variants;
- unresolved or disputed combinations;
- combinations that would require a new transmission model;
- engine architectures that would require a new audio synthesizer.

Then explicitly ask:

> I identified the following complete set of evidenced variants. Do you want all of them imported, or only a selected subset? Is any engine, transmission, drivetrain or model-year variant missing from this list?

Record the answer verbatim or as an unambiguous scope table in the model-specific record and set that model to `approved`. No geometry processing, source relocation, catalog resource, powertrain code or audio code may be committed until every included model has passed this gate.

### 0.5 Global owner-scope completion and physics-dependency gate

After model 23 is approved:

1. verify that every included inventory row is `approved`;
2. verify that every model has a complete research record and recorded owner decision;
3. report the final combined model and variant count;
4. resolve cross-model duplicate or shared-architecture decisions without deleting mechanically distinct variants;
5. wait for PR #118 or its explicitly identified successor to merge the final physics work into `master`;
6. synchronize this branch with that resulting `master`;
7. record the merged physics commit as the implementation baseline;
8. review and update all vehicle, transmission, AWD, tyre, braking, steering/yaw and performance assumptions;
9. rerun the full current suite;
10. only then move model 01 to `integrating` and begin Stage 1.

## Stage 1 — establish dimensions and geometry evidence

Collect overall length, width excluding mirrors, height, wheelbase, front and rear track, and representative tyre size or rolling radius from the same primary-source hierarchy. For commercial bodies, identify represented wheelbase and body length separately.

## Stage 2 — inspect the source GLB

Record file path and SHA-256, root and mesh names, mesh/triangle/material/texture counts, source AABB, axes, ground offset, wheel-pair centres, pivots, transparency, detached geometry and transforms. A topology other than body plus paired front and rear wheels requires a documented exception.

## Stage 3 — build the canonical visual derivative

Create a derivative only when required. Convert to `+Y` up and `-Z` front, scale from verified wheelbase, centre between axle centres, ground from tyre contact points and split paired axle meshes into `Body`, `WheelFrontLeft`, `WheelFrontRight`, `WheelRearLeft` and `WheelRearRight`. Preserve materials, UVs, normals and source triangles unless a separate optimisation is documented.

## Stage 4 — create the Godot visual wrapper

Use a shared data-driven visual controller where possible. Provide explicit wheel paths and binding data, final measured visibility AABB, wheel radius and LOD decision. Do not add runtime name heuristics.

## Stage 5 — build the approved model and variant catalog

Create exactly the owner-approved variants. Research full torque curves, idle/redline/limiter behaviour, ratios, mass, load distribution, drag, tyres, brakes, drivetrain layout and performance targets. Do not merge mechanically distinct calibrations or duplicate marketing aliases.

## Stage 6 — implement the exact transmission architecture

A classic automatic must never be represented as an automated manual. An automated manual must not receive torque-converter behaviour. A DCT must not be approximated by shortening a conventional automatic shift delay. CVTs require continuous ratio control and their actual launch device.

When a required model is absent, create a dedicated transmission model or clean architecture-specific extension. Implement launch, creep, clutch/converter, lock-up, shift, kickdown, rev-match and torque-interruption behaviour; preserve exact ratios; add deterministic tests; and ensure gear display, AI, audio load and wheel torque use correct semantics. Do not force an unsupported transmission through a fallback path.

## Stage 7 — physics and performance calibration

Use evidence-based mass, acceleration, standing-distance, in-gear, top-speed, engine-speed, braking, shift and turning targets. Performance must emerge from sampled torque, gearing, wheel radius, mass, architecture losses, converter/clutch behaviour, aero, rolling resistance, tyres, load transfer and shift scheduling. Do not match acceleration by using a false peak torque, wrong mass, wrong gearbox or arbitrary hidden cap.

### Mandatory `master` physics synchronization

Before any Stage 7 parameter commitment, before final validation and again before marking the PR ready:

1. verify that the PR #118 dependency is satisfied;
2. synchronize with current `master`;
3. record the physics-baseline commit;
4. inspect changes to specs, drivetrain, transmissions, wheels/tires, load transfer, suspension contact, drag, braking, steering/yaw and performance logic;
5. identify all affected models and variants;
6. rerun full tests;
7. recalibrate every affected model to current physics rather than adding compatibility hacks;
8. rerun catalog-wide regressions when shared code changed.

## Stage 8 — implement architecture-correct engine audio

Research cylinder arrangement, crank and firing order, firing intervals, collector grouping, intake, exhaust, aspiration, combustion/injection, mechanical sources and transients. If absent, build a new architecture-specific synthesis model from first principles. It must not use an unrelated cylinder layout as its primary waveform or merely change pitch/EQ. Test cadence, dominant orders, load, induction, boost, start, idle, overrun, limiter, shutdown, sample-rate safety and perceptual distinction.

## Stage 9 — define traffic geometry and behaviour

Create traffic data separately from playable powertrain data. Record measured dimensions, wheelbase, tracks, wheel radius, collision, speed/acceleration/braking/steering classes, spawn weight and clearance. Use simple authored collision volumes, not dynamic render-mesh trimeshes.

## Stage 10 — LOD and runtime performance

Record geometry/material/resource cost, verify mipmaps, define LOD and visibility distances, use shared visibility architecture and test representative traffic groups and approved playable variants.

## Stage 11 — mandatory validation

A model may become `integrated` only when all research/scope, asset, dimensional, direction/animation, powertrain, audio, current-physics, scene and regression contracts pass. The owner-approved variant scope must match implementation exactly; transmission and audio fallbacks are prohibited; the branch must be synchronized to current `master`; full Godot tests, Windows export and packaged smoke tests must pass.

## Per-model integration record

Every model record under `docs/vehicles/traffic/` must contain identity, reference dimensions, source inspection, complete engine/transmission/drivetrain matrix, evidence states, the owner's recorded scope decision, conversion data, exact powertrain/transmission/audio plans, physics baseline, runtime integration, validation and unresolved work.

## Integration order

Research and owner-scope approval are complete. After the PR #118 dependency is satisfied, implementation proceeds by numeric source prefix, ascending. The earlier geometry-class pilot list remains useful for shared-tool validation, but it does not override the owner-directed numeric order or permit implementation before the physics dependency is resolved.