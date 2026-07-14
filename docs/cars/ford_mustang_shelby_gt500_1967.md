# Ford Mustang Shelby G.T. 500 (1967)

## Scope and naming

This package represents the normal-production 1967 Shelby G.T. 500 fastback. The imported file retains its Sketchfab title, `1967_ford_mustang_shelby_cobra_gt500.glb`, but the catalog display name is `Shelby G.T. 500 (1967)`.

`Cobra GT500` is not used as the 1967 display name. The Cobra designation was applied to the Shelby GT350 and GT500 model lines for 1968.

Source model:

- repository path: `res://1967_ford_mustang_shelby_cobra_gt500.glb`;
- original page: https://sketchfab.com/3d-models/1967-ford-mustang-shelby-cobra-gt500-e310cc7537bf4d1aa644a2c233a5fec6;
- author and license: not currently recorded in the repository; see `THIRD_PARTY_NOTICES.md` before any redistribution decision.

## Production variants

The normal-production 1967 G.T. 500 used one engine specification with two transmissions. Both variants are registered in `resources/cars/catalog.tres`:

| Stable variant ID | Transmission | Rear axle | Runtime status |
|---|---|---:|---|
| `ford_mustang_shelby_gt500_1967_4mt` | close-ratio four-speed Ford Toploader | 3.89:1 | playable |
| `ford_mustang_shelby_gt500_1967_3at` | three-speed Ford C6 SelectShift Cruise-O-Matic | 3.50:1 | playable |

The manual is the default catalog variant. Neither variant is currently AI-eligible because dedicated AI scenes and an opponent-audio/performance contract have not yet been authored.

## Shared 428 FE engine

Reference specification:

- Ford FE family;
- 428 cu in / approximately 7.0 L;
- Police Interceptor-based Shelby application;
- naturally aspirated, front-mounted V8;
- aluminum mid-rise intake;
- two 600 CFM Holley four-barrel carburetors;
- advertised compression ratio: 10.5:1;
- advertised maximum torque: 420 lb-ft / 569.44 Nm at 3,200 RPM;
- advertised maximum power: 355 hp (SAE gross) / approximately 264.7 kW at 5,400 RPM.

This is not the 1968 428 Cobra Jet used by the G.T. 500KR.

## Torque and power curve methodology

No complete factory dynamometer trace for the exact dual-four-barrel 1967 Shelby application was located in the available factory-derived summaries, archival references or identified period material. The runtime curve is therefore a dense, constrained reconstruction rather than a falsely labelled surviving factory graph.

The reconstruction follows these rules:

1. the 3,200 RPM sample is fixed exactly at 420 lb-ft;
2. the 5,400 RPM sample is calculated to produce exactly 355 hp using the SAE mechanical-horsepower relation;
3. the curve remains broad through the mid-range, consistent with the 428 FE architecture and the low advertised torque peak;
4. torque falls after the power peak and continues falling toward the limiter;
5. the same engine resource is shared by both transmissions;
6. gearbox, converter and tire calibration remain outside the engine curve.

Authoritative resource:

```text
resources/cars/ford/mustang_shelby_gt500_1967/specs/gt500_428_pi_torque_curve.tres
```

### Sampled runtime curve

| RPM | Torque multiplier | Torque (Nm) | Power (kW) | Power (hp) | Evidence status |
|---:|---:|---:|---:|---:|---|
| 700 | 0.595238 | 339.0 | 24.8 | 33.3 | reconstructed idle/load transition |
| 1,000 | 0.714286 | 406.7 | 42.6 | 57.1 | reconstructed |
| 1,500 | 0.833333 | 474.5 | 74.5 | 100.0 | reconstructed |
| 2,000 | 0.916667 | 522.0 | 109.3 | 146.6 | reconstructed |
| 2,500 | 0.976190 | 555.9 | 145.5 | 195.2 | reconstructed |
| 2,800 | 0.992857 | 565.4 | 165.8 | 222.3 | reconstructed approach to peak |
| 3,200 | 1.000000 | 569.4 | 190.8 | 255.9 | exact advertised torque anchor |
| 3,500 | 0.992857 | 565.4 | 207.2 | 277.9 | reconstructed |
| 4,000 | 0.964286 | 549.1 | 230.0 | 308.4 | reconstructed |
| 4,500 | 0.928571 | 528.8 | 249.2 | 334.2 | reconstructed |
| 5,000 | 0.878571 | 500.3 | 262.0 | 351.3 | reconstructed |
| 5,200 | 0.852381 | 485.4 | 264.3 | 354.4 | reconstructed |
| 5,400 | 0.822793 | 468.5 | 264.7 | 355.0 | exact advertised power anchor |
| 5,600 | 0.773810 | 440.6 | 258.4 | 346.5 | reconstructed falloff |
| 5,800 | 0.714286 | 406.7 | 247.0 | 331.3 | calibrated redline |
| 6,000 | 0.642857 | 366.1 | 230.0 | 308.4 | calibrated limiter boundary |

The table represents crankshaft output before driveline losses. It must not be compared directly with chassis-dynamometer wheel-horsepower plots without correcting for transmission, converter, axle and tire losses.

## Transmission calibration

### Four-speed manual

- ratios: 2.32 / 1.69 / 1.29 / 1.00;
- reverse: 2.32;
- rear axle: 3.89;
- driveline efficiency input: 0.78;
- shift interruption: 0.35 s;
- drivetrain acceleration safety ceiling: 5.4 m/s².

### C6 automatic

- ratios: 2.46 / 1.46 / 1.00;
- reverse: 2.18;
- rear axle: 3.50;
- driveline efficiency input: 0.74;
- full-throttle upshift target: 5,200 RPM;
- shift interruption: 0.42 s;
- converter stall reference: 1,800 RPM;
- converter coupling reference: 3,200 RPM;
- stall torque multiplier: 1.45;
- drivetrain acceleration safety ceiling: 4.4 m/s².

`max_drive_acceleration` is a final drivetrain-output guard, not the complete tire model. Both transmissions additionally pass drive, reverse and braking requests through the same longitudinal tire capacity and slip-ratio model.

The converter parameters are simulation calibration values constrained to reproduce period automatic performance. They are not presented as a recovered Ford engineering map.

## Chassis, resistance and tire calibration

Shared geometry and baseline assumptions:

- wheelbase: 2.7432 m;
- front/rear track input: 1.4732 m;
- tire-width input: 0.195 m front and rear;
- effective loaded wheel radius: 0.345 m;
- manual mass input: 1,575 kg;
- automatic mass input: 1,600 kg;
- drag coefficient input: 0.46;
- frontal area input: 2.05 m²;
- rolling-resistance coefficient: 0.018;
- live-axle/bias-ply behavior represented by lower lateral grip and earlier slip than the modern 370Z fleet.

Longitudinal tire calibration shared by both variants:

- grip coefficient: `0.68`;
- peak slip ratio: `0.16`;
- sliding grip multiplier: `0.66`.

The runtime therefore limits acceleration and braking by surface grip, active ground-contact fraction and remaining friction-circle capacity after lateral use. Requests beyond peak capacity produce longitudinal slip and transition toward the lower sliding-grip level. This replaces the earlier interpretation of `max_drive_acceleration` as the sole launch-traction model.

Mass, drag and tire coefficients are gameplay calibration inputs selected from the range of published dimensions, test weights and period-car behavior. They are not all direct type-approval measurements.

## Performance regression

The deterministic regression executes the same `CarPowertrainController`, clutch, converter, resistance and longitudinal tire logic used by gameplay. It integrates straight-line distance at 120 Hz.

Accepted bands cover variation among period tests, launch technique, tire condition and axle/transmission configuration:

| Variant | 0-60 mph target | Quarter-mile target | Trap-speed target | Maximum-speed target |
|---|---:|---:|---:|---:|
| four-speed | 6.0-7.8 s | 14.0-16.5 s | 90-108 mph | 190-207 km/h |
| C6 automatic | 6.2-8.5 s | 14.4-17.2 s | 87-108 mph | 188-207 km/h |

`scripts/tests/mustang_gt500_content_test.gd` logs the measured result on every run and gates the ranges above. Exact measured values are intentionally not frozen in this document because structural tire-model changes may alter them while remaining inside the approved behavior bands.

The manual and automatic differ through gearing, losses, shift behavior, converter behavior, mass and drivetrain ceiling—not through separate or falsified engine curves.

## Detailed visual integration

The imported GLB was inspected and converted to a permanent model-specific visual contract.

Measured imported content:

- 71 render meshes;
- source bounds after applying the 100x unit correction: 1.7936 m wide, 1.3534 m high and 4.8189 m long;
- measured wheelbase from tire centers: 2.7437 m;
- reference wheelbase used by physics: 2.7432 m;
- four separate tires, wheels, brake rotors and calipers;
- source front axis corrected into Godot project forward without mirroring the finished vehicle.

`MustangShelbyGT5001967VisualController` binds all four detailed tire/wheel/rotor groups explicitly. Front calipers follow steering without spinning; rear calipers remain fixed. The screen-visibility LOD controller swaps the detailed GLB and the model-specific low-detail fallback.

## Procedural audio

Both versions share `resources/audio/ford_428_fe_audio_profile.tres` and the dedicated `CrossPlaneV8EngineAudioSynthesizer` path. The scene explicitly configures eight cylinders and forces full live runtime generation for the player.

The profile uses:

- eight-cylinder firing frequency;
- strong low-frequency exhaust resonance;
- separated V-bank pulse character;
- audible dual-carburetor induction;
- lower mechanical rasp than the VQ37 profiles;
- restrained overrun and a non-digital limiter cut.

The profile is a synthesis calibration, not measured acoustic data from a surviving production car. No Shelby AI audio backend currently exists.

## Non-production configurations

The following are deliberately excluded from the normal 1967 model:

- the one-off 427 FE G.T. 500 Super Snake prototype;
- the 1968 428 Cobra Jet / G.T. 500KR;
- the G.T. 350 289 Hi-Po;
- regular Mustang six-cylinder, 289, 302 and 390 engines;
- later 427/428/429 or modern crate-engine swaps;
- five- and six-speed restomod transmissions;
- Eleanor, continuation-car and modern Shelby-licensed restomod configurations.

The Super Snake may only be added later as a separately identified prototype with independent engine, driveline, visual and performance research.

## Research references

- Shelby model history, production engine, axle ratios, approximate period performance and 1967/1968 naming distinction: https://en.wikipedia.org/wiki/Shelby_Mustang
- Ford FE configuration list and exact 1967 Shelby 2×4V rating: https://en.wikipedia.org/wiki/Ford_FE_engine
- Toploader close- and wide-ratio gear sets: https://en.wikipedia.org/wiki/Ford_Toploader_transmission
- Ford C6 ratios and application context: https://en.wikipedia.org/wiki/Ford_C6_transmission
- production totals cross-check: https://en.wikipedia.org/wiki/Shelby_American

No intermediate torque sample is represented as a measured factory point. A future revision should replace secondary summaries with scanned Ford/Shelby order sheets, SAAC registry records or identified period road-test pages wherever licensing and stable archival access permit.

## Remaining work

1. verify imported material transparency, normals and shadow behavior in representative gameplay lighting;
2. complete the author/license/provenance record and relocate the binary GLB into its third-party asset directory in one atomic path-update commit;
3. create dedicated AI scenes and an explicit opponent-audio/performance contract before enabling either variant for AI;
4. replace reconstructed torque samples if an identified period dynamometer trace becomes available.
