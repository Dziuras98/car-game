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

Both variants share the same model identity and visual scene, while each references its own authoritative `CarSpecs` resource.

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
- returns valid models and a flat list of variants;
- resolves models and variants by stable IDs;
- exposes derived scene and menu-name lists for spawners and menu construction.

The catalog is the only content-discovery path. There is no parallel `available_cars` fallback.

### `CarModelDefinition`

File:

```text
scripts/car/car_model_definition.gd
```

Purpose:

- stores model-level identity;
- stores manufacturer, model ID, display name, generation and production years;
- stores a typed `Array[CarVariantDefinition]`;
- resolves variants and an explicitly selected `default_variant_id`.

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
- links to a playable car scene;
- links to exactly one `CarSpecs` tuning resource;
- stores presentation metadata that is not derivable from specs, such as the engine and drivetrain labels;
- derives mass and transmission labels from `CarSpecs` so display data cannot drift from runtime physics.

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

Examples:

```text
resources/cars/nissan/370z/specs/370z_7at_specs.tres
resources/cars/nissan/370z/specs/370z_6mt_specs.tres
```

`scenes/cars/370z.tscn` contains visual, collision and audio structure only. It does not serialize vehicle tuning values.

## Rules for adding future cars

1. Add one folder per model, not per variant.
2. Put every playable version in `variants/`.
3. Put every tuning payload in `specs/`.
4. A variant must reference one playable scene and one valid `CarSpecs` resource.
5. Store transmission mode only in `CarSpecs.transmission_type`.
6. Do not duplicate mass or transmission labels in variant resources.
7. If two variants share identical visuals, they may reference the same scene but different specs.
8. If two variants need different meshes or nodes, they may reference different scenes.
9. Add the model to `resources/cars/catalog.tres`; do not add a fallback scene array elsewhere.
10. Extend catalog validation and focused regression coverage with new content.

## Selection and spawning flow

`GameManager` loads `resources/cars/catalog.tres` and derives menu options through `MenuOptionsBuilder`.

```text
tryb -> tor -> model auta -> wariant auta
```

`MainMenu` emits the selected `variant_id`. `CarSelectionState` resolves it to the matching catalog index, and `CarSpawner` delegates instantiation to `CarInstanceFactory`.

The factory:

1. resolves the `CarVariantDefinition`;
2. instantiates its `PackedScene`;
3. verifies the root is `PlayerCarController`;
4. assigns the variant's `CarSpecs` before adding the car to the scene tree;
5. rejects missing or invalid catalog data instead of silently selecting fallback content.

Current catalog-backed menu content:

```text
Nissan 370Z
  370Z automat
  370Z manual
```
