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

Both variants share the same model identity and may share a player scene, while each references its own authoritative `CarSpecs` resource. An AI-eligible variant additionally owns a dedicated lightweight AI scene so opponent spawning does not instantiate player-only detailed assets.

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

Current example:

```text
resources/cars/
  catalog.tres
  nissan/
    370z/
      model.tres
      specs/
        370z_6mt_specs.tres
        370z_7at_specs.tres
      variants/
        370z_6mt.tres
        370z_7at.tres
```

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

Example:

```text
resources/cars/nissan/370z/model.tres
```

### `CarVariantDefinition`

File:

```text
scripts/car/car_variant_definition.gd
```

Purpose:

- stores one selectable version of a car model;
- links to a playable player car scene;
- links AI-compatible variants to a separate lightweight AI car scene;
- links to exactly one valid `CarSpecs` tuning resource;
- declares `ai_eligible` explicitly for variants supported by the current AI input model;
- stores presentation metadata that is not derivable from specs, such as the engine and drivetrain labels;
- derives mass and transmission labels from `CarSpecs` so display data cannot drift from runtime physics;
- rejects an AI-eligible variant unless its specs use an automatic transmission and `ai_car_scene` is present.

`ai_eligible` is not inferred from catalog order or from the presence of an automatic gearbox. The current AI requires a valid automatic-transmission variant, an explicit dedicated AI scene, and `CarInstanceFactory` considers only variants for which `is_ai_eligible_for_race()` returns `true`. The manual 370Z remains player-selectable but is not an opponent fallback.

The AI scene must retain the `PlayerCarController` root and compatible collision/audio/runtime structure, but it must not reference player-only detailed GLB models. This prevents hidden detailed scenes from consuming memory after visual LOD has switched to a fallback.

Examples:

```text
resources/cars/nissan/370z/variants/370z_7at.tres
resources/cars/nissan/370z/variants/370z_6mt.tres
```

### `CarSpecs`

File:

```text
scripts/car/car_specs.gd
```

Purpose:

- is the authoritative source of all vehicle tuning values;
- contains driving, engine, transmission, automatic-transmission, resistance, tire and grounding data;
- uses `TransmissionType` as the sole transmission-mode state;
- validates values before `CarDriveConfig` is built;
- differs between variants when engine, gearbox, mass or other tuning changes.

In addition to per-field ranges, validation enforces relationships between fields:

- forward gear ratios must be strictly descending;
- the configured maximum speed cannot exceed the rev-limited speed available in the highest gear;
- automatic downshift RPM must not fall below idle;
- automatic upshift, kickdown and torque-converter coupling thresholds must remain within the engine operating range;
- torque-converter stall/coupling and automatic shift thresholds must remain correctly ordered.

Examples:

```text
resources/cars/nissan/370z/specs/370z_7at_specs.tres
resources/cars/nissan/370z/specs/370z_6mt_specs.tres
```

`scenes/cars/370z.tscn` contains visual, collision and audio structure only. It does not serialize vehicle tuning values.

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
7. If two variants share identical visuals, they may reference the same player scene but different specs.
8. If two variants need different meshes or nodes, they may reference different player scenes.
9. Set `ai_eligible = true` only when the current AI can operate the variant without additional gearbox or control logic.
10. Every AI-eligible variant must reference a dedicated lightweight `ai_car_scene` with no detailed player GLB dependency.
11. Add the model to `resources/cars/catalog.tres`; do not add a fallback scene array elsewhere.
12. Use globally unique model and variant IDs and unique sort orders inside each model.
13. Add focused negative validation fixtures with every new content rule.

## Selection and spawning flow

`GameManager` loads `resources/cars/catalog.tres`, validates the full catalog and derives menu options through `MenuOptionsBuilder`.

```text
tryb -> tor -> model auta -> wariant auta
```

`MainMenu` emits the selected `variant_id`. `CarSelectionState` resolves it to the matching catalog index, and `CarSpawner` delegates instantiation to `CarInstanceFactory`.

The factory:

1. resolves the exact `CarVariantDefinition` and rejects an index outside the catalog range;
2. instantiates `car_scene` for the player or `ai_car_scene` for an opponent;
3. verifies the selected scene root is `PlayerCarController`;
4. assigns the variant's `CarSpecs` before adding the car to the scene tree;
5. selects opponents only from the explicit AI-eligible subset;
6. rejects missing or invalid catalog data instead of silently selecting fallback content.

Opponent spawning prepares the complete requested set of car/driver pairs before adding any participant to the active scene. If any pair cannot be created or configured, no partial opponent set is committed and race startup is rejected.

Current catalog-backed menu content:

```text
Nissan 370Z
  370Z automat
  370Z manual
```
