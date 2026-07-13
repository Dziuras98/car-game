# Car catalog structure

The car data model is organized around three typed levels:

```text
CarCatalog
  Array[CarModelDefinition]
    Array[CarVariantDefinition]
      CarSpecs
```

A car model is not the same thing as a playable car. A playable car is a variant of a model.

Example:

```text
Nissan 370Z
  370Z automat
  370Z manual
```

Both variants share the same model identity and visual family while each references its own authoritative `CarSpecs` resource. An AI-eligible variant additionally owns an explicit AI scene reference. The AI scene may be a dedicated optimized scene or, where intentionally configured and tested, the same scene used by the player variant.

## Current catalog

`resources/cars/catalog.tres` currently registers four models and fifteen playable variants:

```text
Nissan 370Z (Z34)
  370Z automat
  370Z manual

Nissan 370Z NISMO (Z34 NISMO V2)
  370Z NISMO 6MT (EU)
  370Z NISMO 7AT (global)

Shelby G.T. 500 (1967)
  428 V8 4-speed manual
  428 V8 C6 automatic

Fiat Punto Type 176 (1995)
  Punto 55 5MT
  Punto 55 6-Speed
  Punto 60 5MT
  Punto 60 Selecta CVT
  Punto 75 5MT
  Punto 90 5MT
  Punto GT 5MT
  Punto D 5MT
  Punto TD 70 5MT
```

The two Shelby variants are playable but not currently AI-eligible. All nine Punto variants are explicitly AI-eligible, including the Selecta CVT. Nissan AI variants use dedicated AI scenes.

This section is descriptive only. Catalog resources and their validation remain authoritative.

## Canonical folder layout

Use this layout for every future car model:

```text
resources/cars/
  catalog.tres
  <manufacturer>/
    <model>/
      model.tres
      specs/
        <variant>_specs.tres
      variants/
        <variant>.tres
```

Current model roots:

```text
resources/cars/nissan/370z/
resources/cars/nissan/370z_nismo/
resources/cars/ford/mustang_shelby_gt500_1967/
resources/cars/fiat/punto_176_1995/
```

Scene wrappers and shared visuals live under `scenes/cars/`. Audio profiles live under `resources/audio/`, while model-specific source documents live under `docs/cars/`.

## Resource responsibilities

### `CarCatalog`

File:

```text
scripts/car/car_catalog.gd
```

Purpose:

- stores a typed `Array[CarModelDefinition]`;
- validates the complete content graph before gameplay startup;
- enforces globally unique model and variant IDs;
- returns valid models and a flat list of variants;
- resolves models and variants by stable IDs;
- exposes derived scene and menu-name lists for spawners and menu construction.

The catalog is the only content-discovery path. There is no parallel `available_cars` fallback. `GameManager` rejects a catalog with any validation error rather than silently dropping invalid entries.

### `CarModelDefinition`

File:

```text
scripts/car/car_model_definition.gd
```

Purpose:

- stores model-level identity;
- stores manufacturer, model ID, display name, generation and production years;
- stores a typed `Array[CarVariantDefinition]`;
- validates model identity, production-year ordering, variant IDs and sort orders;
- resolves variants and an explicitly selected `default_variant_id`;
- requires `default_variant_id` to reference a variant in the same model.

Examples:

```text
resources/cars/nissan/370z/model.tres
resources/cars/ford/mustang_shelby_gt500_1967/model.tres
resources/cars/fiat/punto_176_1995/model.tres
```

### `CarVariantDefinition`

File:

```text
scripts/car/car_variant_definition.gd
```

Purpose:

- stores one selectable version of a car model;
- links to a playable player car scene;
- optionally links to an AI car scene;
- links to exactly one valid `CarSpecs` tuning resource;
- declares `ai_eligible` explicitly for variants supported by the current AI input model;
- stores presentation metadata that is not derivable from specs, such as engine and drivetrain labels;
- reads mass directly from `CarSpecs` and derives the transmission label from it so display data cannot drift from runtime physics;
- rejects an AI-eligible variant unless its specs use a geared transmission and `ai_car_scene` is present.

`ai_eligible` is not inferred from catalog order, scene identity or transmission type. `CarInstanceFactory` considers only variants for which `is_ai_eligible_for_race()` returns `true`.

The current AI can operate explicitly eligible:

- manual transmissions, using one-shot external shift requests;
- conventional automatics, which manage shifts and direction internally;
- CVTs, which manage ratio, centrifugal-clutch behavior and direction internally.

For manual opponents, `AiRaceDriver` upshifts near redline under power, downshifts at low RPM, uses an earlier reduction threshold while braking, and suppresses additional requests while a shift is in progress. Recovery explicitly traverses first gear, neutral and reverse while holding the service brake whenever direction changes. Automatic and CVT variants use the same external throttle/brake/steering channel but do not receive manual shift requests.

Every car scene that uses `CarVisualController` must expose a detailed root, a low-detail root and explicit model-specific detailed-wheel bindings. The controller creates a `VisibleOnScreenNotifier3D` covering the vehicle bounds and starts conservatively in low detail. When the notifier enters the active camera view, the detailed root becomes visible; when it leaves the view, the low-detail root replaces it.

Visibility detection is screen/frustum based. It is an approximate visibility heuristic and does not treat a car hidden behind walls or other geometry as invisible unless occlusion culling is configured. Both visual roots remain instantiated, so the policy reduces render work and hidden-wheel animation work rather than detailed-asset memory.

Examples:

```text
resources/cars/nissan/370z/variants/370z_7at.tres
resources/cars/ford/mustang_shelby_gt500_1967/variants/gt500_428_4mt.tres
resources/cars/fiat/punto_176_1995/variants/punto_60_cvt.tres
```

### `CarSpecs`

File:

```text
scripts/car/car_specs.gd
```

Purpose:

- is the authoritative source of all vehicle tuning values;
- contains driving, engine, transmission, automatic-transmission, CVT, resistance, tire and grounding data;
- uses `TransmissionType` as the sole transmission-mode state;
- validates values before `CarDriveConfig` is built;
- differs between variants when engine, gearbox, mass, tires or other tuning changes.

Current transmission values are:

```text
DIRECT_DRIVE
MANUAL
AUTOMATIC
CVT
```

In addition to per-field ranges, validation enforces relationships between fields:

- discrete forward gear ratios must be strictly descending;
- the configured maximum speed cannot exceed the rev-limited speed available in the highest discrete gear;
- automatic downshift RPM must not fall below idle;
- automatic upshift, kickdown and torque-converter coupling thresholds must remain within the engine operating range;
- torque-converter stall/coupling and automatic shift thresholds must remain correctly ordered;
- CVT target RPM and centrifugal-clutch thresholds must be ordered and remain inside the engine operating range;
- longitudinal tire coefficient and peak slip ratio must be positive, while the sliding-grip multiplier must remain in `[0, 1]`;
- the summed four-probe suspension support must exceed configured gravity with the required reserve.

Examples:

```text
resources/cars/nissan/370z/specs/370z_7at_specs.tres
resources/cars/ford/mustang_shelby_gt500_1967/specs/gt500_428_3at_specs.tres
resources/cars/fiat/punto_176_1995/specs/punto_60_cvt_specs.tres
```

Variant scenes may serialize the exact same `CarSpecs` resource that the catalog variant references so direct scene launches and catalog spawning use identical data. They must not contain a second divergent copy of tuning values. `CarInstanceFactory` still assigns the variant resource before scene-tree entry and treats the catalog as authoritative.

## Tire calibration ownership

Every production variant currently specifies:

- front/rear lateral grip and tire width;
- longitudinal grip coefficient;
- peak longitudinal slip ratio;
- sliding longitudinal grip multiplier;
- handbrake lateral multiplier and steering/slip thresholds;
- skid-mark dimensions and timing.

The runtime does not interpret `brake_deceleration` or drivetrain force as unlimited tire authority. `TireModel` constrains drive, reverse, service braking and handbrake acceleration according to surface grip, active ground contacts, lateral friction use and the variant's longitudinal calibration. The combined lateral/longitudinal slip intensity drives effects and steering reduction.

## Validation ownership

Each level validates the state it owns:

```text
CarCatalog.validate()
  -> global model/variant uniqueness
  -> CarModelDefinition.validate()
       -> model identity, years, default variant, local ordering
       -> CarVariantDefinition.validate()
            -> player scene, AI scene, specs, labels and AI eligibility
            -> CarSpecs.validate()
                 -> numeric and relational tuning constraints
```

Callers must treat a non-empty validation result as a configuration error. Menu construction may still be defensive, but it is not the authoritative validation boundary.

## Rules for adding future cars

1. Add one folder per model, not per variant.
2. Put every playable version in `variants/`.
3. Put every tuning payload in `specs/`.
4. A variant must reference one playable player scene and one valid `CarSpecs` resource.
5. Store transmission mode only in `CarSpecs.transmission_type`.
6. Do not duplicate mass or transmission labels in variant resources.
7. If two variants share identical visuals, they may reference the same player scene structure but different specs.
8. If two variants need different meshes, audio profiles or nodes, they may reference different wrapper scenes.
9. Set `ai_eligible = true` only when the current AI can operate the variant without additional gearbox or control logic.
10. Every AI-eligible variant must use a geared transmission (`MANUAL`, `AUTOMATIC` or `CVT`) and reference a valid `ai_car_scene`.
11. A dedicated AI scene is preferred when it provides an explicitly validated lower-cost audio or visual backend; sharing the player scene is allowed only when intentional and covered by performance/behavior tests.
12. Every car visual wrapper must use `CarVisualController` screen-visibility LOD or provide an equivalent explicitly tested policy.
13. Add the model to `resources/cars/catalog.tres`; do not add a fallback scene array elsewhere.
14. Use globally unique model and variant IDs and unique sort orders inside each model.
15. Add focused negative validation fixtures with every new content rule.
16. Document source-asset attribution and license/provenance status before committing external binary assets.

## Selection and spawning flow

`GameManager` loads `resources/cars/catalog.tres`, validates the full catalog and derives menu options through `MenuOptionsBuilder`.

```text
tryb -> tor -> model auta -> wariant auta -> ładowanie -> sesja
```

`MainMenu` emits the selected `variant_id` after showing the loading panel. `CarSelectionState` resolves it to the matching catalog index, and `CarSpawner` delegates instantiation to `CarInstanceFactory`.

The factory:

1. resolves the exact `CarVariantDefinition` and rejects an index outside the catalog range;
2. instantiates `car_scene` for the player or `ai_car_scene` for an opponent;
3. verifies the selected scene root is `PlayerCarController`;
4. assigns the variant's `CarSpecs` before adding the car to the scene tree;
5. selects opponents only from the explicit AI-eligible subset;
6. rejects missing or invalid catalog data instead of silently selecting fallback content.

Opponent spawning prepares the complete requested set of car/driver pairs before adding any participant to the active scene. If any pair cannot be created or configured, no partial opponent set is committed and race startup is rejected.

In free drive, the switch-car action selects uniformly from catalog variants other than the active one when at least two variants exist. The committed variant ID and active-car HUD label are updated only after replacement succeeds.
