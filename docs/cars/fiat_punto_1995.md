# Fiat Punto Type 176 (1995) integration

## Scope

This integration adds the 1995 three-door Fiat Punto Type 176 as a complete playable and AI-eligible model family.

Source visual asset:

- repository path: `res://free_1995_fiat_punto_gt.glb`;
- source page: https://sketchfab.com/3d-models/free-1995-fiat-punto-gt-48db6facb4b64e99b60f36b8c01185e1;
- advertised trim: 1995 Fiat Punto GT.

The selected scope deliberately excludes body-code-dependent long-ratio five-speeds, Punto 55 ED, the late `176B4.000` 1.2 calibration and the catalyst-equipped `176A3.000` TD calibration.

## Catalog model

Model resource:

```text
res://resources/cars/fiat/punto_176_1995/model.tres
```

Stable model ID:

```text
fiat_punto_176_1995
```

Default variant:

```text
fiat_punto_176_1995_gt_5mt
```

All nine variants are registered in `resources/cars/catalog.tres` and are eligible for both player and AI use.

## Implemented variants

| Stable variant ID | Engine | Transmission | Target 0–100 km/h | Stored top speed |
|---|---|---|---:|---:|
| `fiat_punto_176_1995_55_5mt` | `176A6.000`, 1.1 FIRE | standard 5MT | 17.0 s | 150 km/h |
| `fiat_punto_176_1995_55_6mt` | `176A6.000`, 1.1 FIRE | dedicated 6MT | 16.0 s | 150 km/h |
| `fiat_punto_176_1995_60_a7_5mt` | `176A7.000`, 1.2 FIRE SPI | standard 5MT | 14.5 s | 160 km/h |
| `fiat_punto_176_1995_60_a7_ecvt` | `176A7.000`, 1.2 FIRE SPI | Selecta CVT | 17.0 s | 150 km/h |
| `fiat_punto_176_1995_75_5mt` | `176A8.000`, 1.2 FIRE MPI | standard 5MT | 12.0 s | 170 km/h |
| `fiat_punto_176_1995_90_5mt` | `176A9.000`, 1.6 MPI | standard 5MT | 11.0 s | 178 km/h |
| `fiat_punto_176_1995_gt_5mt` | `176A4.000`, 1.4 Turbo | GT 5MT | 8.0 s | 200 km/h |
| `fiat_punto_176_1995_d_5mt` | `176B3.000`, 1.7 diesel | reconstructed 5MT | 20.0 s | 150 km/h |
| `fiat_punto_176_1995_td70_5mt` | `176A5.000`, 1.7 turbo-diesel | TD 5MT | 14.8 s | 163 km/h |

The deterministic integration test currently measures approximately:

| Variant | Simulated 0–100 km/h |
|---|---:|
| Punto 55 5MT | 17.78 s |
| Punto 55 6-Speed | 17.37 s |
| Punto 60 5MT | 15.93 s |
| Punto 60 Selecta CVT | 16.39 s |
| Punto 75 5MT | 13.09 s |
| Punto 90 5MT | 11.87 s |
| Punto GT 5MT | 8.73 s |
| Punto D 5MT | 19.80 s |
| Punto TD 70 5MT | 14.71 s |

The regression tolerance is ±1.5 seconds because the project drivetrain is a deterministic gameplay model rather than a tyre-temperature, launch-technique and atmospheric-condition simulation.

## Engine calibrations and torque curves

| Commercial version | Engine code | Output | Peak torque |
|---|---|---:|---:|
| Punto 55 | `176A6.000` | 40 kW at 5,500 RPM | 85 Nm at 3,500 RPM |
| Punto 60 | `176A7.000` | 43 kW at 5,500 RPM | 96 Nm at 3,000 RPM |
| Punto 75 | `176A8.000` | 54 kW at 6,000 RPM | 106 Nm at 4,000 RPM |
| Punto 90 | `176A9.000` | 65 kW at 5,750 RPM | 127 Nm at 2,750 RPM |
| Punto GT | `176A4.000` | 98 kW at 5,750 RPM | 204 Nm at 3,000 RPM |
| Punto D | `176B3.000` | 42 kW at 4,500 RPM | 98 Nm at 2,500 RPM |
| Punto TD 70 | `176A5.000` | 52 kW at 4,500 RPM | 134 Nm at 2,500 RPM |

Seven sampled `EngineTorqueCurve` resources are stored under:

```text
resources/cars/fiat/punto_176_1995/specs/
```

No complete, unambiguously identified Fiat factory dynamometer trace was located for these exact calibrations. The intermediate samples are constrained reconstructions, not digitized factory graphs. Each curve:

1. reaches multiplier `1.0` at the published torque peak;
2. reproduces the published power at the published power-peak RPM;
3. does not overshoot the published torque or power during interpolation;
4. reaches its global power maximum at the published RPM;
5. falls after the power peak.

`scripts/tests/fiat_punto_engine_curves_test.gd` scans every integer RPM over every stored curve.

## Manual gearboxes

### Standard petrol 5MT

Used by Punto 55, 60, 75 and 90:

```text
3.909 / 2.157 / 1.480 / 1.121 / 0.902
reverse: 3.818
```

Final drives:

- Punto 55: `3.866`;
- Punto 60: `3.563`;
- Punto 75: `3.733`;
- Punto 90: `3.563`.

### Punto 55 6-Speed

```text
3.545 / 2.157 / 1.480 / 1.121 / 0.902 / 0.744
reverse: 3.818
final drive: 4.923
```

This is modeled as a dedicated transmission, not as a five-speed with an appended ratio.

### Punto GT

The runtime uses the user-supplied set:

```text
3.909 / 2.238 / 1.541 / 1.156 / 0.891
reverse: 3.909
final drive: 3.353
```

An earlier secondary table reported third and fifth ratios of `1.520` and `0.872`. The selected values therefore remain documented as provisional until an identified Fiat source resolves the conflict.

### Punto D and TD

The supplied TD set is:

```text
3.909 / 2.238 / 1.440 / 1.029 / 0.794
reverse: 3.909
final drive: 3.733
```

It is authoritative only as user-supplied provisional TD data. The naturally aspirated Punto D lacked an independently identified gear set, so its runtime resource uses the TD ratios as an explicit gameplay reconstruction and is calibrated against the known acceleration and top-speed targets. This must be replaced if original D gearbox documentation becomes available.

## Dedicated CVT type

`CarSpecs.TransmissionType.CVT` is a fourth transmission type. It is not represented as a conventional automatic and does not contain fake forward gears.

Runtime implementation:

```text
res://scripts/car/cvt_transmission_model.gd
```

The simplified model stores only:

- the shortest/highest numerical variator ratio (`cvt_max_ratio`);
- final drive and reverse ratio;
- target engine-RPM range;
- ratio response rate;
- centrifugal-clutch engagement range.

There is intentionally no configurable longest/lowest numerical ratio. At increasing road speed the calculated ratio may continue toward zero, with only a small internal epsilon preventing division by zero.

The Selecta calibration uses:

- shortest ratio: `2.503`;
- final drive: `4.071`;
- target engine speed: 1,700–5,500 RPM;
- clutch engagement: 1,200–2,100 RPM.

The controller supports:

- automatic drive/reverse selection;
- continuous ratio control from throttle, speed and load;
- centrifugal-clutch launch behavior;
- reverse launch and AI recovery;
- `D`/`R` display;
- AI eligibility without manual shift requests.

`scripts/tests/cvt_transmission_model_test.gd` verifies the absence of a configured longest-ratio floor, partial-load RPM control and sufficient reverse launch force for the AI recovery contract.

## Engine audio

All Punto variants use the dedicated procedural synthesizer:

```text
res://scripts/car/fiat_punto_engine_audio.gd
```

Each of the seven engine calibrations has a separate `EngineAudioProfile` resource. The synthesizer models:

- four-cylinder firing pulses;
- engine-speed-dependent intake and exhaust resonances;
- valvetrain and rotating-assembly layers;
- idle irregularity;
- starter and shutdown transients;
- hard-cut limiter behavior;
- load and throttle transients.

### Petrol engines

The FIRE SPI, FIRE MPI, 1.6 and GT profiles use different combustion sharpness, intake presence, exhaust resonance, mechanical content and pitch scaling. They are not copies of the Nissan V6 synthesizer.

### Diesel engines

The naturally aspirated D and TD use a separate compression-ignition pulse shape plus independent layers for:

- injection rattle;
- mechanical clatter;
- low-frequency exhaust roughness;
- slower engine response;
- longer starter and shutdown behavior.

The naturally aspirated diesel has no turbo layer.

### Turbochargers

Punto GT and TD 70 include separate turbo synthesis:

- spool-dependent rotor whistle;
- engine-speed and load-dependent pitch;
- throttle-lift release envelope;
- GT compressor flutter and blow-off character;
- lower-pitched, restrained TD whistle without a petrol-style blow-off valve.

## Visual integration

The detailed GLB is wrapped by:

```text
res://scenes/cars/fiat_punto_176_visuals.tscn
```

`FiatPunto176VisualController` calculates imported mesh bounds at runtime, normalizes the source to the 3.76 m body length, centers it, places the tyres at the ground plane and corrects project-forward orientation.

The gameplay body uses three collision volumes for front, cabin and rear sections.

A six-mesh low-detail fallback is provided for visual LOD and AI performance:

- body;
- cabin;
- four wheels.

The source mesh is a GT. Ordinary versions currently share this detailed visual and therefore retain GT-specific exterior details. The runtime data, physics, audio and catalog variants are distinct, but trim-correct non-GT mesh substitutions remain a future visual refinement.

The source materials use the older specular/glossiness workflow. Godot converts them to metallic/roughness during import; CI permits only this exact known importer warning.

## Validation

The integration is covered by:

- `scripts/tests/fiat_punto_engine_curves_test.gd`;
- `scripts/tests/cvt_transmission_model_test.gd`;
- `scripts/tests/fiat_punto_content_test.gd`;
- general CarSpecs, drive-config, catalog and variant tests;
- visual mesh-budget tests;
- full-program race smoke tests;
- Windows export and exported-build smoke tests.

The complete Windows Godot pipeline imports the GLB, validates all resources, executes the full test suite, exports the game and launches the exported build.

## Evidence boundaries

The following values remain calibrated or provisional rather than primary-source-confirmed:

- intermediate torque-curve samples;
- redline and limiter behavior;
- the selected GT third and fifth ratios;
- the naturally aspirated D gearbox ratios;
- the simplified Selecta variator and clutch calibration;
- some masses, resistance and tyre parameters used to match performance targets;
- non-GT visual presentation.

No reconstructed value should be relabelled as a measured Fiat factory value.

## Research references

- Type 176 production range, engine codes, output, torque and production periods: https://de.wikipedia.org/wiki/Fiat_Punto_%28Typ_176%29
- Italian 1993–1996 range and descriptions of Punto 55 6-Speed and Selecta: https://it.wikipedia.org/wiki/Fiat_Punto_%281993%29
- GT production phases and engine specification: https://it.wikipedia.org/wiki/Fiat_Punto_GT
- period-oriented catalogue cross-check: https://www.automoto.it/catalogo/fiat/punto
- user-supplied 1993–1999 hardtop gearbox and final-drive table; originating publication not identified.
