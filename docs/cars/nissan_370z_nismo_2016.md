# Nissan 370Z NISMO V2 (2016)

## Scope

The game model represents the facelifted Z34 NISMO V2 body introduced for model year 2015 and used in 2016.

The default variant represents the European-market 2016 NISMO with the six-speed manual transmission. The seven-speed automatic is explicitly labelled as a contemporary global-market configuration: it is based on North American and Japanese availability and is not presented as a European 2016 homologation.

The current catalog also contains the standard Z34 370Z as a separate model with six-speed manual and seven-speed automatic variants.

## Source assets and rights boundary

The standard and NISMO visuals use separate Sketchfab GLBs stored under `assets/third_party/sketchfab/`. Their uploader-stated CC BY-NC-SA 4.0 terms, attribution wording and unresolved upstream game-asset provenance risk are documented in `THIRD_PARTY_NOTICES.md` and `assets/third_party/sketchfab/README.md`.

The project owner's current noncommercial-prototype decision is recorded in `docs/accepted_risks.md`. It does not assert full upstream rights clearance and must be reviewed before public redistribution or commercialization.

## Reference hierarchy and market scope

The implementation separates published vehicle data from gameplay tuning:

1. published engine output, dimensions, axle tracks and tire sizes are physical reference targets;
2. transmission availability is recorded per market rather than merged into one fictional specification;
3. mass, resistance, lateral/longitudinal tire coefficients, suspension constants, shift interruption and torque-converter behavior are gameplay calibration values;
4. procedural-audio parameters describe the synthesizer, not measured acoustic data from a production car.

Reference cross-checks used for this model:

- Nissan 370Z model and NISMO overview, including VQ37VHR output and market history: https://en.wikipedia.org/wiki/Nissan_370Z
- European technical-data cross-check for 253 kW / 344 PS at 7,400 RPM, 371 Nm at 5,200 RPM, 1,550/1,595 mm axle tracks and manual-only NISMO presentation: https://de.wikipedia.org/wiki/Nissan_370Z
- VQ37VHR displacement, bore/stroke and 7,500 RPM redline cross-check: https://en.wikipedia.org/wiki/Nissan_VQ_engine

These secondary references are retained because stable official 2016 regional press-kit URLs were not available during implementation. Any future replacement should preserve the market distinctions above and record the exact Nissan document edition.

## Published reference targets

- engine: naturally aspirated VQ37VHR NISMO, 3,696 cm³ V6;
- maximum power: 253 kW / 344 PS at 7,400 RPM;
- maximum torque: 371 Nm at 5,200 RPM;
- driven wheels: rear;
- governed maximum-speed target: 250 km/h;
- wheelbase: 2,550 mm;
- front axle track: 1,550 mm;
- rear axle track: 1,595 mm;
- approximate NISMO V2 exterior length: 4.41–4.43 m depending on market measurement convention;
- approximate width excluding mirrors: 1,870 mm;
- approximate height: 1,310 mm;
- tire reference: 245/40 R19 front and 285/35 R19 rear.

The in-game mass is normalized against the existing 1,495 kg standard-370Z tuning rather than copied from one market's type-approval convention. The manual NISMO is set to 1,560 kg and the automatic to 1,580 kg.

## Engine curve

The runtime uses the sampled resource:

```text
resources/cars/nissan/370z_nismo/specs/370z_nismo_torque_curve.tres
```

This keeps the published torque peak, power peak, redline and limiter as separate concepts:

- idle: 850 RPM;
- maximum torque: 371 Nm at 5,200 RPM;
- maximum power: approximately 253 kW at 7,400 RPM;
- redline: 7,500 RPM;
- limiter: 7,600 RPM in the gameplay model.

The limiter is placed 100 RPM above the published redline so the runtime can model a short cut window without treating the maximum-power point as the rev limit. The sampled curve falls after 7,400 RPM instead of holding the power-peak multiplier through the limiter.

| RPM | Torque multiplier | Torque (Nm) | Approx. power (kW) |
|---:|---:|---:|---:|
| 850 | 0.520 | 192.9 | 17.2 |
| 2,000 | 0.709 | 263.0 | 55.1 |
| 3,000 | 0.879 | 326.1 | 102.4 |
| 4,000 | 0.928 | 344.3 | 144.2 |
| 5,200 | 1.000 | 371.0 | 202.0 |
| 6,000 | 0.964 | 357.6 | 224.7 |
| 6,500 | 0.924 | 342.8 | 233.3 |
| 7,000 | 0.891 | 330.6 | 242.4 |
| 7,400 | 0.880 | 326.5 | 253.0 |
| 7,500 | 0.864 | 320.5 | 251.8 |
| 7,600 | 0.840 | 311.6 | 248.0 |

## Transmissions

### European six-speed manual

- ratios: 3.794 / 2.324 / 1.624 / 1.271 / 1.000 / 0.794;
- reverse: 3.446;
- final drive: 3.916;
- gameplay shift interruption: 0.24 s;
- presentation: SynchroRev Match-equipped European NISMO.

The shorter 3.916 final drive distinguishes the NISMO V2 manual from the standard 370Z manual's 3.692 final drive. Runtime downshifts use the shared RPM-targeted throttle blip; upshifts use the shared throttle cut.

### Global seven-speed automatic

- ratios: 4.923 / 3.193 / 2.042 / 1.411 / 1.000 / 0.862 / 0.771;
- reverse: 3.972;
- final drive: 3.357;
- paddle-shift/downshift-rev-match presentation;
- gameplay automatic shift interruption: 0.17 s;
- more aggressive kickdown threshold than the standard 370Z automatic.

This variant models a contemporary non-European NISMO automatic. Both NISMO variants are explicitly AI-eligible and use dedicated AI scenes.

## Chassis and tire tuning

The runtime represents front and rear geometry independently:

- front/rear axle tracks: 1.550/1.595 m;
- front/rear tire widths: 0.245/0.285 m;
- front/rear lateral-grip inputs: 11.0/11.6;
- the four ground probes follow their respective axle tracks;
- tire width and axle-grip balance affect lateral recovery and yaw response;
- suspension stiffness, damping and travel remain NISMO-specific gameplay calibration.

Longitudinal calibration is explicit and catalog-tested:

| Model family | Grip coefficient | Peak slip ratio | Sliding grip multiplier | Full brake demand |
|---|---:|---:|---:|---:|
| standard 370Z variants | 1.02 | 0.11 | 0.82 | 10.0 m/s² |
| NISMO variants | 1.08 | 0.10 | 0.84 | 10.5 m/s² |

Drive, reverse, service-brake and handbrake requests pass through the shared tire model. Surface grip, active contacts and lateral friction use constrain applied longitudinal acceleration. Demand beyond peak grip generates signed longitudinal slip and approaches the sliding-grip multiplier.

The numeric grip values are dimensionless simulation coefficients, not tire test measurements.

## Player and AI audio backends

Nissan player scenes use live `ProfiledEngineAudioSynthesizer` generation with `force_full_runtime_generation = true`. Dedicated Nissan AI scenes use committed coast/load WAV banks through `BakedEngineAudioPlayer`.

Profiles:

```text
resources/audio/370z_stock_audio_profile.tres
resources/audio/370z_nismo_audio_profile.tres
```

| Parameter | Standard 370Z | 370Z NISMO | Intended result |
|---|---:|---:|---|
| Idle player level | -10.0 dB | -9.0 dB | More present sport exhaust at light load |
| Load player level | 0.0 dB | -0.5 dB | Control high-load output independently of synthesis drive |
| Synthesis gain | 1.0 dB | 0.5 dB | Avoid using nonlinear saturation as a loudness control |
| Output boost | 11.5 dB | 11.0 dB | Calibrate the final player stage separately |
| Intake presence | 0.18 | 0.24 | Stronger high-RPM induction |
| Intake plenum detail | 0.10 | 0.14 | More defined VQ intake texture |
| Exhaust resonance | 0.54 | 0.66 | Fuller exhaust body |
| Exhaust bank separation | 0.30 | 0.38 | More pronounced dual-bank character |
| High-RPM rasp | 0.07 | 0.11 | Sharper upper-range character |
| Overrun crackle | 0.10 | 0.13 | Slightly stronger lift-off signature |
| Limiter residual combustion | 0.20 | 0.24 | Audible but non-digital limiter cut |

Decibel values at different processing stages are not added and presented as a loudness equivalence. Regression tests generate deterministic live audio, validate the committed AI banks and protect the Nissan production race fixture of one live player plus three baked opponents.

See `docs/audio/vq37vhr_procedural_model.md` and `docs/baked_engine_audio.md`.

## Visual construction and collision

The NISMO scene uses the imported 2015 Sketchfab GLB through `370z_nismo_visuals.tscn`; it does not reuse the standard 370Z body package. The wrapper applies only source scale, forward-axis correction and ground alignment, while gameplay collision remains independently authored.

`Nismo370ZVisualController` binds exactly four logical wheel assemblies to explicit imported node paths. Front calipers follow steering without spinning, rear calipers remain fixed, and each tire/rim pair rotates around one axle pivot. This avoids name-based matching of unrelated brake-light and interior steering-wheel nodes.

The NISMO collision uses three simple boxes for the cabin, front aero and rear body. This covers the extended body without enclosing the complete wing volume or a large amount of empty space. Screen-visibility LOD swaps the detailed imported root and the model-specific low-detail fallback while retaining both in memory.
