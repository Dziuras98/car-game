# Ford Mustang Shelby G.T. 500 (1967)

## Scope and naming

This package represents the normal-production 1967 Shelby G.T. 500 fastback. The imported file retains its Sketchfab title, `1967_ford_mustang_shelby_cobra_gt500.glb`, but the catalog display name is `Shelby G.T. 500 (1967)`.

`Cobra GT500` is not used as the 1967 display name. The Cobra designation was applied to the Shelby GT350 and GT500 model lines for 1968.

Source model:

- repository path: `res://1967_ford_mustang_shelby_cobra_gt500.glb`;
- original page: https://sketchfab.com/3d-models/1967-ford-mustang-shelby-cobra-gt500-e310cc7537bf4d1aa644a2c233a5fec6.

## Production variants

The normal-production 1967 G.T. 500 used one engine specification with two transmissions. Both variants are registered in `resources/cars/catalog.tres`:

| Stable variant ID | Transmission | Rear axle | Runtime status |
|---|---|---:|---|
| `ford_mustang_shelby_gt500_1967_4mt` | close-ratio four-speed Ford Toploader | 3.89:1 | playable |
| `ford_mustang_shelby_gt500_1967_3at` | three-speed Ford C6 SelectShift Cruise-O-Matic | 3.50:1 | playable |

The manual is the default catalog variant. Neither variant is currently AI-eligible because dedicated AI scenes and validated detailed-wheel bindings are still required.

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
- advertised maximum power: 355 bhp / approximately 264.7 kW at 5,400 RPM.

This is not the 1968 428 Cobra Jet used by the G.T. 500KR.

## Torque and power curve methodology

No complete factory dynamometer trace for the exact dual-four-barrel 1967 Shelby application was located in the available primary and archival material. The runtime curve is therefore a dense, constrained reconstruction rather than a falsely labelled surviving factory graph.

The reconstruction follows these rules:

1. the 3,200 RPM sample is fixed exactly at 420 lb-ft;
2. the 5,400 RPM sample is calculated to produce exactly 355 bhp;
3. the curve remains broad through the mid-range, consistent with the 428 FE architecture and the low advertised torque peak;
4. torque falls after the power peak and continues falling toward the limiter;
5. the same engine resource is shared by both transmissions;
6. gearbox, converter and traction calibration are kept outside the engine curve so performance tuning cannot corrupt the published engine anchors.

Authoritative resource:

```text
resources/cars/ford/mustang_shelby_gt500_1967/specs/gt500_428_pi_torque_curve.tres
```

### Sampled runtime curve

| RPM | Torque multiplier | Torque (Nm) | Power (kW) | Power (bhp) | Evidence status |
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
| 5,400 | 0.822143 | 468.2 | 264.7 | 355.0 | exact advertised power anchor |
| 5,600 | 0.773810 | 440.6 | 258.4 | 346.5 | reconstructed falloff |
| 5,800 | 0.714286 | 406.7 | 247.0 | 331.3 | calibrated redline |
| 6,000 | 0.642857 | 366.1 | 230.0 | 308.4 | calibrated limiter boundary |

The table represents crankshaft output before driveline losses. It must not be compared directly with chassis-dynamometer wheel-horsepower plots without correcting for transmission, converter, axle and tyre losses.

## Transmission calibration

### Four-speed manual

- ratios: 2.32 / 1.69 / 1.29 / 1.00;
- reverse: 2.32;
- rear axle: 3.89;
- driveline efficiency input: 0.78;
- shift interruption: 0.35 s;
- calibrated launch acceleration ceiling: 6.5 m/s².

The acceleration ceiling represents the longitudinal traction available from the period-sized tyre and live-axle chassis. It prevents the true 428 torque curve from producing a modern-tyre launch while leaving in-gear engine output intact.

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
- calibrated launch acceleration ceiling: 4.4 m/s².

The converter parameters are simulation calibration values constrained to reproduce period automatic performance. They are not presented as a recovered Ford engineering map.

## Chassis and resistance calibration

Shared geometry and baseline assumptions:

- wheelbase: 2.7432 m;
- front/rear track input: 1.4732 m;
- tyre-width input: 0.195 m front and rear;
- effective loaded wheel radius: 0.345 m;
- manual mass input: 1,575 kg;
- automatic mass input: 1,600 kg;
- drag coefficient input: 0.46;
- frontal area input: 2.05 m²;
- rolling-resistance coefficient: 0.018;
- live-axle/bias-ply behavior is represented by lower lateral-grip and earlier slip values than the modern 370Z fleet.

Mass, drag and tyre coefficients are calibration inputs selected from the range of published dimensions, test weights and period-car behavior. They are not all direct type-approval measurements.

## Performance targets and regression policy

The deterministic powertrain regression executes the same `CarPowertrainController`, clutch, converter, resistance and shift logic used by gameplay. It integrates straight-line distance at 120 Hz and records:

- 0-60 mph;
- quarter-mile elapsed time;
- quarter-mile trap speed;
- stabilized maximum speed.

Accepted reference bands intentionally cover variation among period tests, launch technique, tyre condition and axle/transmission configuration:

| Variant | 0-60 mph target | Quarter-mile target | Approximate maximum-speed region |
|---|---:|---:|---:|
| four-speed | 5.8-7.8 s | 14.0-16.5 s | 190-207 km/h |
| C6 automatic | 6.2-8.5 s | 14.4-17.2 s | 188-207 km/h |

The test also requires the manual not to be materially slower than the automatic. Exact CI-produced values are printed under the `MUSTANG_GT500_PERFORMANCE` prefix.

## Procedural audio

Both versions share `resources/audio/ford_428_fe_audio_profile.tres`. It configures the existing live synthesizer for:

- eight cylinders;
- strong low-frequency exhaust resonance;
- separated V-bank pulse character;
- audible dual-carburetor induction;
- low mechanical rasp compared with the VQ37 profiles;
- restrained overrun and a non-digital limiter cut.

The profile is a synthesis calibration, not measured acoustic data from a surviving production car.

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

The implementation cross-checks the surviving published anchors against multiple independent summaries and transmission references:

- Shelby model history, production engine and 1967/1968 naming distinction: https://en.wikipedia.org/wiki/Shelby_Mustang
- Ford FE configuration list and the exact 1967 Shelby 2×4V rating: https://en.wikipedia.org/wiki/Ford_FE_engine
- Toploader close- and wide-ratio gear sets: https://en.wikipedia.org/wiki/Ford_Toploader_transmission
- Ford C6 history and application context: https://en.wikipedia.org/wiki/Ford_C6_transmission
- historical and auction documentation should be preferred over current restomod specifications whenever an additional value is introduced.

A future revision should replace secondary summaries with scanned Ford/Shelby order sheets, SAAC registry records or identified period road-test pages wherever licensing and stable archival access permit.

## Remaining visual work

The car is playable and catalogued, but the imported model still requires completion of the detailed visual contract:

1. measure and apply the authoritative source scale, forward axis and ground offset;
2. bind four detailed wheel assemblies to exact imported node paths;
3. attach the standard screen-visibility LOD controller;
4. verify materials, transparency, normals and shadows;
5. relocate the GLB into its third-party asset directory;
6. create dedicated AI scenes after the visual wheel contract is valid.
