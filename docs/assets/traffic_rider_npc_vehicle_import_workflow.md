# Traffic Rider NPC vehicle import workflow

## Purpose

This document is the authoritative procedure for integrating every non-heavy vehicle from the **Traffic Rider NPC Vehicles** bundle into the Godot project.

The workflow is intentionally model-by-model. A shared package scale, guessed wheelbase, generic collision copied between unrelated body classes, or runtime wheel-name scanning is not acceptable. Every integration PR must complete the stages below in order and record its measurements, evidence, decisions and deviations.

The source bundle is used only for the project's private, noncommercial scope under the accepted-risk decision in `docs/accepted_risks.md`. The asset notice in `THIRD_PARTY_NOTICES.md` must remain intact.

## Scope

The repository contains 20 source GLBs to integrate:

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

1. **Keep the committed source GLB unchanged.** Technical adaptations belong in a derived GLB, Godot wrapper scene, imported material override or project-authored resource. Do not destructively overwrite the source file.
2. **Calibrate every model independently.** Scale must be based on verified dimensions for the represented body variant. The former package-wide `0.695` conversion is not authoritative and must not be reused as a default.
3. **Use wheelbase as the primary scale reference.** Overall length is a mandatory cross-check, not the only measurement. Wheel track, height and wheel diameter provide additional validation.
4. **Use the project coordinate convention.** `+Y` is up, local `-Z` is the vehicle front, local `-X` is vehicle-left and local `+X` is vehicle-right.
5. **Provide four independent wheel nodes.** The current source models generally contain one body mesh, one paired front-wheel mesh and one paired rear-wheel mesh. Each axle pair must be split into left and right wheel geometry with a hub-centred pivot.
6. **Use explicit wheel bindings.** Do not add generic name scanning or heuristic wheel discovery to `CarVisualController`.
7. **Separate visual and physical data.** Collision, wheel contact, mass and traffic behaviour are project-authored. They must not be inferred directly from the render mesh at runtime.
8. **Do not invent a playable powertrain.** These assets are initially traffic visuals. Playable variants require a separate researched model definition, drivetrain data and audio scope.
9. **Document uncertainty.** When the exact body length, wheelbase, trim or commercial-body configuration cannot be identified, record the uncertainty and use a clearly labelled provisional value.
10. **One model is complete only after validation.** Merely importing a GLB without scale, wheel, collision, visibility and runtime checks does not complete the workflow.

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

Do not retain duplicate source copies after relocation.

## Stage 1 — establish identity and evidence

Before editing geometry or creating a scene:

1. Inspect the model visually from all sides.
2. Confirm the manufacturer, model generation, body style and approximate model year represented by the mesh.
3. Do not rely only on the filename. Compare lamps, grille, body shell, cab style, bed/box length and wheel count against references.
4. Record whether the identity is:
   - verified;
   - probable;
   - unresolved.
5. Collect dimensional references, preferring:
   - manufacturer technical data;
   - homologation/type-approval documents;
   - official brochures or workshop documentation;
   - reputable secondary specifications only when primary documentation is unavailable.
6. Record at minimum:
   - overall length;
   - overall width excluding mirrors;
   - overall height;
   - wheelbase;
   - front track;
   - rear track;
   - representative tyre size or rolling radius.
7. For chassis-cab and box-body vehicles, identify the represented wheelbase and body length separately. Do not apply dimensions from another commercial-body configuration without marking them provisional.

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

## Stage 5 — define traffic geometry and behaviour

Create a traffic-vehicle resource separately from the visual scene.

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

Vehicle classes may share baseline behaviour, but dimensions and collision volumes remain model-specific.

## Stage 6 — LOD and runtime performance

For every model:

1. Record source triangle and material counts.
2. Measure imported resource size and scene-instantiation cost.
3. Verify that all embedded textures use mipmaps.
4. Define visibility and LOD distances appropriate to the vehicle's screen size.
5. Use the existing low-detail/visibility architecture rather than model-specific process loops.
6. Test a representative traffic group, not only one isolated vehicle.

A separate optimisation pass may simplify geometry or textures, but it must preserve the source GLB and document visual impact.

## Stage 7 — mandatory validation

A model may move to `integrated` status only when all checks pass:

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

### Scene contract

- wrapper scene instantiates in Godot 4.7 without errors or warnings;
- visibility AABB encloses the final visual;
- collision encloses the intended solid body without excessive empty volume;
- traffic resource validates;
- model can spawn, move, despawn and be culled through the shared traffic path.

### Regression contract

- source inventory test passes;
- model-specific content test passes;
- repository static checks pass;
- full Godot test suite passes;
- Windows export and packaged smoke test pass.

## Per-model integration record

Create `docs/vehicles/traffic/<vehicle_id>.md` from this template:

```markdown
# <Display name> traffic integration

## Identity
- source GLB:
- source SHA-256:
- represented body/generation:
- identity confidence:

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

## Runtime integration
- visual scene:
- traffic resource:
- collision profile:
- LOD/visibility settings:

## Validation
- dimensional results:
- wheel animation:
- traffic spawn/runtime:
- automated tests:

## Uncertainty and deferred work
- ...
```

## Integration order

Validate the workflow on one representative model from each geometry class before bulk integration:

1. **Volkswagen Golf VII 2013** — passenger hatchback baseline;
2. **Chevrolet Silverado 2014** — pickup/SUV collision and wheel-track baseline;
3. **Mercedes-Benz Sprinter 2014** — long van and visibility/LOD baseline;
4. **Nissan Atleon 2004** — cab-over medium commercial baseline.

After these four pilots pass the same contracts, integrate the remaining models in small PR batches grouped by body class. Do not weaken the workflow to accommodate a model; record a justified exception or improve the shared tooling/controller instead.
