# Ford Mustang Shelby G.T. 500 (1967)

## Scope and naming

This content package represents the production 1967 Shelby G.T. 500 fastback. The uploaded source file retains the Sketchfab title `1967_ford_mustang_shelby_cobra_gt500.glb`, but the intended in-game display name is `Shelby G.T. 500 (1967)`.

`Cobra GT500` is not used as the historical 1967 display name. Ford and Shelby applied the Cobra name to the GT350 and GT500 model lines for the 1968 model year.

The source model was uploaded as:

```text
res://1967_ford_mustang_shelby_cobra_gt500.glb
```

Original source:

https://sketchfab.com/3d-models/1967-ford-mustang-shelby-cobra-gt500-e310cc7537bf4d1aa644a2c233a5fec6

## Production powertrain research

The production 1967 G.T. 500 has one engine configuration and two documented transmission choices. The game should therefore expose exactly two normal production variants.

### Shared production engine

- family: Ford FE;
- displacement: 428 cu in / approximately 7.0 L;
- application: Police Interceptor-based Shelby specification;
- induction: aluminum mid-rise intake with two 600 CFM Holley four-barrel carburetors;
- aspiration: naturally aspirated;
- layout: front-mounted V8, rear-wheel drive;
- advertised output: 355 bhp at 5,400 RPM;
- advertised torque: 420 lb-ft / approximately 569 Nm at 3,200 RPM;
- advertised compression ratio: 10.5:1.

This is not the later 428 Cobra Jet used by the 1968 G.T. 500KR. The 1968 Cobra Jet must not be substituted when the 1967 production torque curve is authored.

### Production transmission matrix

| Planned stable variant ID | Engine | Transmission | Catalog status |
|---|---|---|---|
| `ford_mustang_shelby_gt500_1967_4mt` | 428 FE Police Interceptor, dual 4V | Ford four-speed manual, Toploader family | planned production variant |
| `ford_mustang_shelby_gt500_1967_3at` | 428 FE Police Interceptor, dual 4V | Ford C6 SelectShift Cruise-O-Matic three-speed automatic | planned production variant |

The four-speed manual is the proposed default variant because it is the mechanically simpler reference configuration and provides the clearest baseline for torque-curve and driveline validation. This is a content decision, not a claim that every production car used the manual.

The two variants should share one authoritative engine torque-curve resource and use separate `CarSpecs` resources for transmission ratios, shift behavior, driveline losses and any verified mass difference.

### Data not yet authoritative enough for runtime tuning

The following values remain deliberately unset until they can be tied to a factory document, Shelby registry entry, build sheet or equivalent primary record:

- exact close-ratio or wide-ratio Toploader gear set used by each documented car configuration;
- reverse ratio for the manual gearbox;
- exact C6 forward and reverse ratios for the installed calibration;
- production rear-axle ratios and whether they varied by transmission or order;
- torque-converter stall and coupling behavior;
- transmission-specific curb mass;
- limiter behavior and a complete measured 428 PI torque curve.

Generic Toploader or C6 ratios must not be copied into `CarSpecs` merely because they are common for the transmission family. The final game data should identify the exact 1967 G.T. 500 application.

## Non-production and incompatible configurations

### 427 FE Super Snake prototype

One 1967 fastback was converted into the G.T. 500 Super Snake test car with a 427 FE GT40-derived racing engine. It was a single prototype associated with a high-speed Goodyear tire demonstration, not a normal production engine option.

Consequences for the game catalog:

- do not include it in the standard 1967 G.T. 500 production model;
- do not count it as a third production engine/transmission combination;
- if it is added later, represent it as a separately named prototype or special vehicle with independent research, specs, audio and validation;
- do not infer its transmission or final-drive data from the normal 428 variants without an authoritative record.

### Explicitly excluded configurations

The following powertrains may fit a 1967 Mustang-derived body physically, but do not belong to this historical production model:

- 1967 G.T. 350 289 Hi-Po V8;
- regular-production Mustang six-cylinder, 289, 302 or 390 engines;
- 1968 428 Cobra Jet / G.T. 500KR specification;
- later 427, 428, 429 or modern crate-engine swaps;
- five- and six-speed restomod transmissions;
- movie `Eleanor`, continuation-car and modern Shelby-licensed restomod configurations.

## Research source hierarchy

Runtime values should be selected in this order:

1. Ford or Shelby factory specification, order sheet, homologation record or period service publication;
2. Shelby American Automobile Club registry documentation tied to the 1967 model year;
3. documented period road tests identifying the tested car and transmission;
4. reputable historical summaries only for cross-checking.

Current cross-check sources retained for the research phase:

- Shelby Mustang model history and 1967/1968 distinction: https://en.wikipedia.org/wiki/Shelby_Mustang
- Ford FE 428 configuration summary: https://en.wikipedia.org/wiki/Ford_FE_engine
- Ford Toploader family and generic ratio sets: https://en.wikipedia.org/wiki/Ford_Toploader_transmission

These secondary summaries establish the model boundary and candidate transmission families. They are not sufficient by themselves for the final sampled torque curve, gearbox ratios or axle calibration.

## Added visual structure

```text
scenes/cars/
  mustang_shelby_gt500_1967_visuals.tscn
  mustang_shelby_gt500_1967_low_detail_visuals.tscn
scenes/dev/
  mustang_shelby_gt500_1967_visual_preview.tscn
scripts/dev/
  car_model_visual_preview.gd
```

The detailed wrapper isolates source-model alignment under `ModelAlignment`. Scale, orientation and ground alignment can therefore be corrected without modifying the imported GLB.

The low-detail scene provides an inexpensive silhouette and exposes the standard wheel node names expected by `CarVisualController`:

- `WheelFrontLeft`;
- `WheelFrontRight`;
- `WheelRearLeft`;
- `WheelRearRight`.

Its geometry is an initial visual approximation, not an authoritative dimensional model.

## Preview workflow

Open and run:

```text
res://scenes/dev/mustang_shelby_gt500_1967_visual_preview.tscn
```

The preview script collects all imported `MeshInstance3D` bounds, frames the model automatically and places the ground plane under the lowest visual point. This makes scale and orientation defects visible even when the GLB imports at an unexpected unit scale.

## Remaining integration work

1. relocate the binary GLB from the repository root;
2. establish exact source scale, forward axis and ground offset;
3. clean imported materials and textures;
4. record explicit detailed-wheel node bindings;
5. create player and AI scenes;
6. author collision volumes;
7. obtain authoritative gearbox and axle ratios;
8. reconstruct and validate the 428 FE PI torque curve;
9. create the V8 procedural-audio profile;
10. add the two complete production variants and model resource to the catalog;
11. add runtime, catalog, visual and audio regression tests.

The car must not be added to `resources/cars/catalog.tres` before at least one complete production variant passes catalog validation.