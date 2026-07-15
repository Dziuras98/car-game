# Traffic Rider NPC vehicle research and import workflow

## Purpose

This document is the authoritative procedure for researching and integrating every non-heavy vehicle from the **Traffic Rider NPC Vehicles** bundle into the Godot project.

The workflow is intentionally model-by-model and variant-complete. A shared package scale, guessed wheelbase, generic collision copied between unrelated body classes, substituted transmission architecture, approximate engine sound based on another cylinder layout, or performance tuning against stale physics is not acceptable.

Every integration PR must complete the stages below in order and record its evidence, measurements, decisions, uncertainties and validation results.

The source bundle is used only for the project's private, noncommercial scope under the accepted-risk decision in `docs/accepted_risks.md`. The asset notice in `THIRD_PARTY_NOTICES.md` must remain intact.

## Scope

The repository contains 20 source GLBs to research and integrate:

- passenger cars and estate cars;
- SUVs and pickups;
- compact and full-size vans;
- light and medium commercial vehicles;
- Mercedes-Benz Unimog U5023.

The following large-truck models are outside this scope and must not be added through this workflow:

- Scania heavy truck;
- generic articulated truck;
- generic rigid truck.

The complete source inventory and current status are recorded in `docs/assets/traffic_rider_npc_vehicle_inventory.md`.

## Core rules

1. **Research the complete factory variant matrix before importing the model.** Identify every evidenced engine, transmission and drivetrain combination applicable to the represented generation/body across its production years and markets. Regional, facelift and limited factory variants must not be silently omitted.
2. **Stop for owner approval after research.** Present the complete matrix to the owner, ask whether every variant should be imported or only a subset, and ask whether any expected variant is missing. Do not begin geometry conversion, catalog creation, physics calibration or audio implementation until the owner answers.
3. **Keep the committed source GLB unchanged.** Technical adaptations belong in a derived GLB, Godot wrapper scene, imported material override or project-authored resource. Do not destructively overwrite the source file.
4. **Calibrate every model independently.** Scale must be based on verified dimensions for the represented body variant. The former package-wide `0.695` conversion is not authoritative and must not be reused as a default.
5. **Use wheelbase as the primary scale reference.** Overall length is a mandatory cross-check, not the only measurement. Wheel track, height and wheel diameter provide additional validation.
6. **Use the project coordinate convention.** `+Y` is up, local `-Z` is the vehicle front, local `-X` is vehicle-left and local `+X` is vehicle-right.
7. **Provide four independent wheel nodes.** The current source models generally contain one body mesh, one paired front-wheel mesh and one paired rear-wheel mesh. Each axle pair must be split into left and right wheel geometry with a hub-centred pivot.
8. **Use explicit wheel bindings.** Do not add generic name scanning or heuristic wheel discovery to `CarVisualController`.
9. **Match the real transmission architecture exactly.** A torque-converter planetary automatic must use a torque-converter automatic model; an automated manual must use an automated-clutch manual model; a dual-clutch transmission, CVT and conventional manual must each use their own correct architecture. Never substitute one transmission type because it already exists in the project.
10. **Implement missing transmission types faithfully.** If the project lacks the required transmission architecture or generation-specific behaviour, create or extend a dedicated model that preserves its real operating principles instead of adapting an unrelated model.
11. **Reproduce performance from evidence, not from labels.** Engine curves, gearing, mass, drag, tyres, drivetrain losses, shift behaviour and physical limits must combine to reproduce documented performance as closely as the current simulation permits.
12. **Build new engine-sound architectures from first principles.** If the synthesizer does not already contain the relevant engine architecture, create a dedicated synthesis model based on that engine's firing cadence, crank arrangement, bank/collector geometry, aspiration and mechanical character. Do not base the new architecture on an unrelated cylinder layout.
13. **Keep every model compatible with current `master` physics.** Before final validation, rebase or synchronize with `master`, inspect all relevant physics changes, and recalibrate every model and variant introduced earlier in the same PR when those changes affect it.
14. **Separate visual and physical data.** Collision, wheel contact, mass, powertrain and traffic behaviour are project-authored. They must not be inferred directly from the render mesh at runtime.
15. **Document uncertainty.** When an exact trim, body configuration, engine calibration, gearbox suffix or performance result cannot be established, record the uncertainty and use a clearly labelled provisional value.
16. **One model is complete only after full validation.** Merely importing a GLB without research, owner approval, scale, wheels, transmission, physics, audio, collision, visibility and runtime checks does not complete the workflow.

## Status gates

Use these statuses in the inventory and model-specific record:

1. `source_only` — source GLB is committed but research has not started;
2. `researching` — identity, dimensions and full powertrain matrix are being established;
3. `awaiting_owner_scope` — research matrix has been presented and implementation is blocked on the owner's answer;
4. `approved` — the owner has confirmed all variants or an explicit subset and confirmed whether anything is missing;
5. `integrating` — geometry, catalog, physics, transmission and audio work is in progress;
6. `integrated` — all mandatory validation has passed against current `master`.

A model must not skip `awaiting_owner_scope`.

## Repository layout

When work begins on a model, move its source file from the repository root into a canonical third-party directory and update all references in the same commit:

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

Playable model and variant resources must follow the existing authoritative car-catalog hierarchy rather than creating a parallel catalog.

Do not retain duplicate source copies after relocation.

## Stage 0 — complete vehicle and powertrain research

This stage is mandatory before geometry import or runtime implementation.

### 0.1 Establish represented vehicle scope

1. Inspect the model visually from all sides.
2. Confirm the manufacturer, generation, body style and approximate model year represented by the mesh.
3. Compare lamps, grille, bumpers, body shell, cab style, wheel count, bed/box length and facelift details against references.
4. Record whether identity is:
   - verified;
   - probable;
   - unresolved.
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

Never infer a factory combination solely because an engine and gearbox were separately available somewhere in the same model family.

For every combination, classify evidence as:

- `verified_factory`;
- `strongly_supported`;
- `provisional`;
- `rejected/not_factory`.

Conflicting data must be preserved and resolved explicitly rather than silently selecting the most convenient value.

### 0.4 Mandatory owner decision gate

After completing the matrix, present it to the owner before implementing anything. The summary must include:

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

Wait for the owner's answer. Record the answer verbatim or as an unambiguous scope table in the model-specific integration record. No geometry processing, catalog resource, powertrain code or audio code may be committed for that model before this gate is satisfied.

## Stage 1 — establish dimensions and geometry evidence

Collect dimensional references, preferring the same primary-source hierarchy used in Stage 0.

Record at minimum:

- overall length;
- overall width excluding mirrors;
- overall height;
- wheelbase;
- front track;
- rear track;
- representative tyre size or rolling radius.

For chassis-cab and box-body vehicles, identify the represented wheelbase and body length separately. Do not apply dimensions from another commercial-body configuration without marking them provisional.

All sources and uncertainty must be written into the model-specific integration record.

## Stage 2 — inspect the source GLB

Create a source inspection record before conversion:

- file path and SHA-256;
- source root and mesh node names;
- mesh count;
- triangle count per mesh and total;
- material and embedded-texture count;
- source AABB dimensions;
- source forward direction;
- source ground offset;
- front- and rear-wheel mesh names;
- wheel-pair centres and approximate hub heights;
- presence of transparent windows, alpha-tested surfaces or double-sided materials;
- any detached geometry, non-uniform transforms or negative scales.

The inspection must confirm whether the normal three-mesh topology applies:

```text
Body
Front wheel pair
Rear wheel pair
```

A model with different topology requires a documented exception before conversion.

## Stage 3 — build the canonical visual derivative

Create a derived GLB only when required for wheel separation, pivot correction or hierarchy cleanup. The committed source remains untouched.

### 3.1 Orientation

Transform the derivative to the project convention:

- `+Y`: up;
- `-Z`: front;
- `-X`: left;
- `+X`: right.

The correction must be baked consistently into the derived visual or represented explicitly in the wrapper scene. Do not compensate with contradictory rotations in several hierarchy levels.

### 3.2 Scale

Determine one scale factor for the individual model:

1. Measure the source front and rear axle centres.
2. Calculate source wheelbase.
3. Divide verified real wheelbase by source wheelbase.
4. Apply the resulting uniform scale.
5. Cross-check the result against real overall length, width, height, tracks and wheel diameter.
6. Investigate any material mismatch rather than averaging incompatible dimensions silently.

Acceptance targets for a verified body variant:

- wheelbase: within `1%` or `0.03 m`, whichever is larger;
- overall length: within `2%` or `0.08 m`, whichever is larger;
- width and height: within `3%`;
- wheel radius: within `3%`.

For a probable or unresolved commercial-body variant, use documented wider tolerances and keep the model marked provisional.

### 3.3 Origin and ground plane

The canonical visual origin must be:

- centred laterally on the vehicle centreline;
- positioned longitudinally at the midpoint between axle centres;
- placed vertically at the road plane (`Y = 0`).

The lowest tyre contact points, not the body mesh or bounding-box minimum of decorative geometry, define the road plane.

### 3.4 Independent wheels

Split paired axle meshes into four independent nodes:

```text
Body
WheelFrontLeft
WheelFrontRight
WheelRearLeft
WheelRearRight
```

Requirements:

- preserve material assignments, UVs, normals and source triangle count unless a separate optimisation change is documented;
- separate by connected components where possible, using lateral position only as a validated fallback;
- recenter every wheel node at its geometric hub centre;
- keep each wheel's local rotation axis aligned with local `X`;
- verify left/right assignment in the final `-Z`-forward convention;
- do not mirror one side to replace source geometry unless explicitly necessary and documented.

If a wheel contains multiple material surfaces, all surfaces must move under the same wheel pivot.

### 3.5 Materials

Inspect every material in Godot 4.7:

- base colour and texture colour space;
- roughness and metallic response;
- normal-map import mode;
- transparency for windows and lamps;
- alpha scissor versus alpha blend;
- back-face culling;
- texture filtering and mipmaps.

Use wrapper-scene material overrides when practical. Avoid creating duplicate texture files or duplicate materials solely to change one import parameter.

## Stage 4 — create the Godot visual wrapper

Prefer a shared data-driven traffic visual controller. Add a model-specific controller only when the shared contract cannot express the hierarchy or wheel behaviour.

The wrapper scene must provide:

- a stable model-specific root name;
- a detailed-root instance of the canonical GLB;
- explicit paths for all four wheels;
- a visibility AABB derived from final measured dimensions;
- a verified visual wheel radius;
- an optional low-detail visual or an explicit recorded decision to defer LOD;
- no runtime heuristic name scanning.

Each wheel binding must specify:

- stable wheel ID (`front_left`, `front_right`, `rear_left`, `rear_right`);
- pivot position;
- whether it steers;
- steering direction;
- spin direction;
- exact node path.

Run a wheel-animation scene check that applies positive and negative steering and at least one full revolution to every wheel.

## Stage 5 — implement the approved variant catalog

Only variants approved at the Stage 0 owner gate may be added.

Create one authoritative model definition containing every approved factory engine/transmission/drivetrain combination. Preserve distinctions between:

- production years and facelifts;
- markets and emissions calibrations;
- power/torque variants sharing an engine family;
- manual, torque-converter automatic, automated-manual, dual-clutch and CVT applications;
- FWD, RWD, selectable 4WD and permanent AWD systems;
- commercial chassis/body restrictions.

For each approved variant, research and encode:

- sampled full-load torque curve rather than only peak torque;
- idle, redline and limiter behaviour;
- all forward ratios, reverse ratio and final drive;
- transmission efficiency and shift timing based on the correct architecture;
- mass, static load distribution and centre-of-mass estimate;
- drag coefficient and frontal area;
- tyre sizes, rolling radius and grip calibration;
- brake performance;
- drivetrain layout and differential behaviour;
- documented top speed and acceleration targets.

Do not duplicate variants merely because sources use different marketing labels for the same mechanical configuration. Conversely, do not merge materially different engine calibrations or transmissions into one generic entry.

## Stage 6 — implement the exact transmission architecture

### 6.1 No architecture substitution

The implementation must match the factory transmission type:

- conventional manual: driver-operated clutch and discrete manual gear selection;
- torque-converter planetary automatic: converter multiplication/slip, creep, planetary ratios, hydraulic/electronic shift scheduling and lock-up behaviour;
- automated manual/SMG: manual gearsets with automated clutch opening, launch slip, torque interruption and rev-matched shifts;
- dual-clutch transmission: two clutch paths, preselection, launch clutch behaviour and architecture-appropriate shift overlap/interruption;
- CVT: continuous ratio bounds, target-ratio control and architecture-appropriate launch device;
- other architectures: implement their actual mechanical/control principle and document it.

A classic automatic must never be represented as an automated manual. An automated manual must never receive torque-converter creep or multiplication. A DCT must not be approximated by shortening a conventional automatic shift delay.

### 6.2 Missing model requirement

If the required type or generation-specific behaviour is absent from the repository:

1. create a dedicated transmission model or a clean architecture-specific extension point;
2. document the mechanical model and evidence;
3. implement the relevant launch, creep, clutch/converter, lock-up, shift, kickdown, rev-match and torque-interruption behaviour;
4. preserve exact gear counts and ratios;
5. add deterministic standalone tests for architecture identity and operating behaviour;
6. ensure menu/gear indication and AI control use the correct semantics;
7. validate that audio load and wheel-side torque can differ during shifts where the real architecture requires it.

Do not force an unsupported transmission through a fallback path.

## Stage 7 — physics and performance calibration

### 7.1 Evidence-based targets

Use multiple documented targets where available:

- kerb mass by exact variant;
- 0–50 km/h, 0–100 km/h and higher-speed acceleration;
- standing 400 m or standing kilometre;
- in-gear acceleration;
- maximum speed and whether electronically limited;
- engine speed at known road speeds;
- braking distance/deceleration;
- shift time and launch behaviour;
- turning circle and lateral behaviour where documented.

Manufacturer figures and independent instrumented tests must be kept distinct. Record test conditions, transmission mode, tyres and uncertainty.

### 7.2 Calibration method

Performance must emerge from the correct physical inputs:

- sampled torque curve;
- exact ratios and final drive;
- wheel radius;
- vehicle mass;
- drivetrain efficiency and architecture losses;
- converter/clutch behaviour;
- aero drag and frontal area;
- rolling resistance;
- tyre force limits and load transfer;
- shift scheduling and delays.

Do not match acceleration by using a false peak torque, wrong mass, incorrect gearbox type or arbitrary acceleration cap that hides an upstream error. Any gameplay limit must be separately named and justified.

Add deterministic regression tests for:

- gear-valid maximum speed;
- acceleration targets within documented tolerance;
- architecture-correct shift behaviour;
- stable results across repeated runs;
- no regression in other variants sharing the implementation.

### 7.3 Mandatory `master` physics synchronization

Before final validation and again immediately before marking the PR ready:

1. synchronize the branch with current `master`;
2. record the `master` commit used as the physics baseline;
3. inspect changes to `CarSpecs`, drive configuration, transmission models, wheel/tire state, load transfer, suspension contact, drag/rolling resistance, braking, steering/yaw and performance-index logic;
4. identify every already-added model and variant in the current PR affected by those changes;
5. rerun their complete physics/performance tests;
6. recalibrate every affected model in the PR to the new physics rather than adding compatibility hacks for the old behaviour;
7. rerun catalog-wide regressions when shared code changed.

A model calibrated against an earlier physics revision may not remain in the PR unchanged if `master` altered the relevant physical model.

## Stage 8 — implement architecture-correct engine audio

### 8.1 Research the real sound-producing architecture

For each engine family record:

- cylinder count and arrangement;
- bank angle where relevant;
- crankshaft layout and firing order;
- firing intervals and dominant crank orders;
- exhaust manifold and collector grouping;
- intake/plenum arrangement;
- naturally aspirated, turbocharged or supercharged induction;
- diesel/petrol combustion and injection characteristics;
- valvetrain and major mechanical-noise sources;
- starter, idle, load, overrun, limiter and shutdown behaviour;
- representative recordings used for perceptual comparison.

### 8.2 New architecture requirement

If the relevant engine architecture is not already represented accurately in the synthesizer, build a new architecture-specific synthesis model from first principles.

The new model must not use an unrelated cylinder layout as its primary waveform or merely alter pitch/EQ on another architecture. For example, an inline-three, flat-four, odd-fire V6, cross-plane V8, inline-five or large commercial diesel requires its own cadence, pulse grouping, harmonic structure and transient behaviour.

Shared low-level DSP utilities are allowed, but the combustion pulse model, collector cadence and architecture-defining layers must be independently derived.

### 8.3 Audio validation

Add tests and evidence for:

- correct firing and collector frequencies across RPM;
- correct cylinder/crank identity;
- architecture-specific harmonic balance;
- load and throttle response;
- turbo/supercharger spool and release where applicable;
- start, idle, overrun, limiter and shutdown;
- sample-rate scaling and anti-alias safety;
- finite, non-silent output;
- perceptual distinction from unrelated engine layouts.

Each materially different engine family/calibration needs an appropriate profile. Do not allow a newly added variant to silently fall back to a generic engine sound.

## Stage 9 — define traffic geometry and behaviour

Create a traffic-vehicle resource separately from the visual scene and playable powertrain data.

Required data:

- vehicle category;
- measured length, width and height;
- wheelbase and tracks;
- wheel radius;
- collision profile;
- traffic speed class;
- acceleration and braking class;
- steering limit and turning-radius class;
- spawn weight;
- clearance and lane-width requirements.

Collision requirements:

- use simple project-authored box or convex volumes;
- use multiple primitive volumes where one box materially misrepresents a pickup bed, van body or cab-over truck;
- do not use the render mesh as a dynamic trimesh collision shape;
- keep collision inside the visible body except for small deliberate gameplay margins;
- validate front and rear overhang relative to the axle positions.

Vehicle classes may share baseline traffic behaviour, but dimensions and collision volumes remain model-specific.

## Stage 10 — LOD and runtime performance

For every model:

1. Record source triangle and material counts.
2. Measure imported resource size and scene-instantiation cost.
3. Verify that all embedded textures use mipmaps.
4. Define visibility and LOD distances appropriate to the vehicle's screen size.
5. Use the existing low-detail/visibility architecture rather than model-specific process loops.
6. Test a representative traffic group, not only one isolated vehicle.
7. Test representative approved playable variants where the model is player-selectable.

A separate optimisation pass may simplify geometry or textures, but it must preserve the source GLB and document visual impact.

## Stage 11 — mandatory validation

A model may move to `integrated` status only when all checks pass against current `master`.

### Research and scope contract

- complete factory engine/transmission/drivetrain matrix is documented;
- evidence/confidence is recorded for every included or rejected combination;
- the owner was shown the complete matrix;
- the owner answered whether to import all variants or a subset and whether anything was missing;
- implementation contains exactly the approved scope.

### Asset contract

- source GLB remains present and unchanged;
- canonical derivative loads without importer errors;
- node names and wheel paths are stable;
- no missing textures or materials;
- no unexpected negative or non-uniform scale remains.

### Dimensional contract

- wheelbase matches the chosen reference tolerance;
- length, width and height pass cross-checks;
- wheel radius and track widths are plausible and documented;
- road-plane alignment is correct.

### Direction and animation contract

- local `-Z` is visibly the front;
- front wheels steer around their own hubs;
- all four wheels spin around local `X`;
- wheel spin direction matches forward travel;
- no body or opposite-side wheel is accidentally reparented under a wheel pivot.

### Powertrain contract

- every approved variant exists exactly once;
- transmission architecture matches the factory type;
- no architecture uses an unrelated fallback model;
- all ratios, final drives, engine curves and drivetrain layouts are evidence-backed;
- performance targets are reproduced within documented tolerances;
- shared transmission changes retain regression coverage.

### Audio contract

- every approved engine family has an appropriate profile;
- previously unsupported architectures use a dedicated first-principles model;
- no unrelated cylinder-layout fallback is used;
- architecture, transient and sample-safety tests pass.

### Current-physics contract

- branch is synchronized with current `master`;
- physics baseline commit is recorded;
- all models and variants added earlier in the PR were retested after relevant `master` physics changes;
- every affected model was recalibrated to the current physics;
- shared and catalog-wide regressions pass.

### Scene contract

- wrapper scene instantiates in Godot 4.7 without errors or warnings;
- visibility AABB encloses the final visual;
- collision encloses the intended solid body without excessive empty volume;
- traffic resource validates;
- model can spawn, move, despawn and be culled through the shared traffic path;
- approved playable variants can be selected, spawned and driven through the standard catalog path.

### Regression contract

- source inventory test passes;
- model-specific content test passes;
- transmission architecture tests pass;
- performance regressions pass;
- engine-audio architecture tests pass;
- repository static checks pass;
- full Godot test suite passes;
- Windows export and packaged smoke test pass.

## Per-model integration record

Create `docs/vehicles/traffic/<vehicle_id>.md` from this template:

```markdown
# <Display name> research and integration

## Identity
- source GLB:
- source SHA-256:
- represented body/generation:
- identity confidence:
- researched production years/markets:

## Complete factory variant matrix
| Years/market | Engine/code | Power/torque | Transmission/code | Architecture | Drivetrain | Evidence/confidence |
|---|---|---:|---|---|---|---|

## Owner scope decision
- date/question presented:
- import all or selected subset:
- approved variants:
- owner-reported missing variants:
- exclusions:

## Reference dimensions
- length:
- width:
- height:
- wheelbase:
- front track:
- rear track:
- tyre/wheel radius:
- sources:

## Source inspection
- hierarchy:
- mesh/triangle counts:
- source axes:
- source wheel centres:
- material notes:

## Canonical conversion
- scale factor:
- orientation correction:
- origin/ground correction:
- wheel split method:
- derived GLB path:

## Approved powertrains
- engine curves and evidence:
- transmission implementations:
- gear/final-drive data:
- mass/aero/tyre data:
- performance targets:
- measured simulation results:

## Engine audio
- architecture/firing order:
- existing or new synthesizer:
- first-principles model notes:
- profile coverage:
- validation results:

## Runtime integration
- visual scene:
- traffic resource:
- playable catalog resources:
- collision profile:
- LOD/visibility settings:

## Physics synchronization
- master baseline commit:
- relevant master physics changes reviewed:
- affected variants recalibrated:
- catalog-wide regressions:

## Validation
- dimensional results:
- wheel animation:
- transmission behaviour:
- performance results:
- audio results:
- traffic spawn/runtime:
- playable spawn/runtime:
- automated tests:

## Uncertainty and deferred work
- ...
```

## Integration order

For each model, complete Stage 0 and obtain owner approval before any visual or runtime integration.

After approval, validate the implementation workflow on one representative model from each geometry class before bulk integration:

1. **Volkswagen Golf VII 2013** — passenger hatchback baseline;
2. **Chevrolet Silverado 2014** — pickup/SUV collision and wheel-track baseline;
3. **Mercedes-Benz Sprinter 2014** — long van and visibility/LOD baseline;
4. **Nissan Atleon 2004** — cab-over medium commercial baseline.

After these four pilots pass the same contracts, integrate the remaining models in small PR batches grouped by body class. Do not weaken the workflow to accommodate a model; record a justified exception or improve the shared physics, transmission, audio or visual architecture instead.
