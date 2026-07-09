# Car catalog structure

The car data model is organized around three levels:

```text
CarCatalog
  CarModelDefinition
    CarVariantDefinition
      CarSpecs
```

This means a car model is not the same thing as a playable car. A playable car is a variant of a model.

Example:

```text
Nissan 370Z
  370Z automat
  370Z manual
```

Both variants share the same model identity, but they can reference different scenes and different tuning specs.

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

- stores all available car models;
- can return models;
- can return a flat list of all variants;
- can return flat variant scenes for compatibility with the current spawn flow;
- can return variant display names for compatibility paths.

### `CarModelDefinition`

File:

```text
scripts/car/car_model_definition.gd
```

Purpose:

- stores model-level identity;
- stores manufacturer, model ID, display name, generation and production years;
- stores all variants for that model;
- can return the default variant.

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
- links to one `CarSpecs` tuning Resource;
- stores human-readable metadata such as engine, transmission, drivetrain and mass.

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

- stores the actual tuning values used by `PlayerCarController`;
- contains driving, engine, transmission, automatic-transmission, resistance, tire and grounding data;
- should differ between variants when engine, gearbox, mass or other tuning changes.

Examples:

```text
resources/cars/nissan/370z/specs/370z_7at_specs.tres
resources/cars/nissan/370z/specs/370z_6mt_specs.tres
```

## Rules for adding future cars

1. Add one folder per model, not per variant.
2. Put every playable version in `variants/`.
3. Put every tuning payload in `specs/`.
4. A variant should reference one playable scene and one `CarSpecs` Resource.
5. The same model may have many variants with different engines, gearboxes, drivetrain layouts, mass, tires or tuning.
6. If two variants share identical visuals, they can reference the same scene but different specs.
7. If two variants need different meshes or nodes, they can reference different scenes.
8. Add the model to `resources/cars/catalog.tres` so the menu and game flow can discover it.

## Current integration status

The data layer exists and the current 370Z variants are represented in the catalog.

`GameManager` now loads `resources/cars/catalog.tres` and derives the active model list, active variant list and playable scene list from it. `MainMenu` receives model and variant data from `GameManager`; it does not load the catalog Resource directly.

The menu selection flow is now:

```text
tryb -> tor -> model auta -> wariant auta
```

Current visible catalog-backed menu labels:

```text
Nissan 370Z
  370Z automat
  370Z manual
```

`MainMenu` emits the selected `variant_id`, and `GameManager` maps that ID back to the matching `CarVariantDefinition` index before calling `CarSpawner`.

`CarSpawner` receives both the flat scene list and the flat variant list. When variants are available, it instantiates cars from `CarVariantDefinition` and applies the variant's `CarSpecs` before the car enters the scene tree. The old `available_cars` scene array remains as a fallback for now.
