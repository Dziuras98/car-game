# FSO Polonez Caro MR'93 runtime integration

## Runtime scope

The playable catalog entry uses the shared five-door MR'93 body and exposes seven
rear-wheel-drive, five-speed-manual variants:

| Variant | Engine | Power | Torque | Gearbox | Final drive | 0–100 calibration | Top speed |
|---|---|---:|---:|---|---:|---:|---:|
| 1.4 GLI 16V | Rover K16 1398 cc DOHC MPI | 103 PS at 6000 rpm | 127 Nm at 5000 rpm | FSO 5MT | 4.30 | 15.1 s | 176 km/h |
| 1.5 GLE | FSO AB 1481 cc OHV carburettor | 82 PS at 5200 rpm | 114 Nm at 3400 rpm | FSO 5MT | 4.10 | 17.6 s | 155 km/h |
| 1.5 GLI | FSO AE/AF 1481 cc OHV ABIMEX SPI | 77 PS at 5400 rpm | 115 Nm at 2800 rpm | FSO 5MT | 4.10 | 17.1 s | 158 km/h |
| 1.6 GLE | FSO CB 1598 cc OHV carburettor | 87 PS at 5200 rpm | 132 Nm at 3800 rpm | FSO 5MT | 3.90 | 16.1 s | 160 km/h |
| 1.6 GLI | FSO CE/CF 1598 cc OHV ABIMEX SPI | 81 PS at 5200 rpm | 125 Nm at 3200 rpm | FSO 5MT | 3.90 | 16.2 s | 163 km/h |
| 2.0 GLE Ford | Ford Pinto 1993 cc SOHC carburettor | 105 PS at 5200 rpm | 157 Nm at 4000 rpm | Ford Type 9 proxy | 3.64 | 13.4 s | 179 km/h |
| 1.9 GLD | PSA XUD9A 1905 cc IDI diesel | 70 PS at 4600 rpm | 120 Nm at 2000 rpm | FSO 5MT | 3.72 | 19.6 s | 153 km/h |

The FSO gearbox uses the project-approved provisional ratios
`3.753 / 2.132 / 1.378 / 1.000 / 0.860` and estimated reverse `3.870`.
The Ford proxy uses `3.650 / 1.970 / 1.370 / 1.000 / 0.820`, reverse
`3.660` and Sierra-derived final drive `3.640`. The 0–100 figures above are
measured by the deterministic Godot drivetrain test using the stored torque
curves, masses, tire model and shift timing. They are not claimed period
road-test values.

## Chassis calibration

Shared body values:

- body length: 4.318 m;
- body width: 1.650 m;
- body height: 1.420 m;
- wheelbase: 2.509 m;
- reconstructed MR'93 tracks: 1.38 m front and 1.36 m rear;
- common runtime wheel radius: 0.298 m;
- body drag calibration: `Cd 0.38`, frontal area `1.86 m²`;
- independent front suspension and a compliant live rear axle are represented
  by moderate front grip, lower rear grip, long suspension travel and slow
  steering response.

Variant masses span 1075–1115 kg. Base FSO and diesel versions use 165 mm tire
width; the Rover and Ford variants use a 185 mm runtime calibration. These
track, tire and aerodynamic values are explicit simulation reconstructions
where an application-specific MR'93 factory sheet has not yet been recovered.

## Sampled torque curves

Every engine has a dedicated `EngineTorqueCurve` resource rather than relying on
the generic analytic fallback. The samples lock:

- published peak torque and its engine speed;
- published power-peak engine speed;
- an engine-family-specific low-speed shape;
- realistic high-speed torque falloff before the limiter.

The OHV carburettor curves have more inertia and a broader mid-range. ABIMEX
single-point-injection curves are smoother and make peak torque earlier. The
Rover K16 has weaker low-speed output but continues building toward 5000–6000
rpm. The XUD9A peaks near 2000 rpm and retains an IDI diesel plateau.

## Dedicated procedural synthesizers

All seven variants use a unique class and a unique audio profile. They share a
Polonez-specific four-cylinder synthesis core with separate combustion,
long-exhaust resonance, intake, timing-drive, pushrod/injection, flywheel,
starter, limiter and overrun layers.

Distinctive targets:

- **Rover K16:** smooth idle, pronounced high-rpm induction bark, timing-drive
  whine, metallic DOHC valvetrain and the sharp rising rasp characteristic of a
  Rover-powered Polonez;
- **FSO carburettor OHV:** uneven idle, carburettor flutter, pushrod clatter,
  heavy flywheel pulses and a hollow low-frequency exhaust boom;
- **FSO ABIMEX OHV:** reduced carburettor flutter, audible injection ticks,
  smoother idle and a slightly cleaner exhaust pulse;
- **Ford Pinto:** deeper exhaust body, belt/SOHC mechanical layer and strong
  carburettor induction;
- **PSA XUD9A:** indirect-injection combustion knock, injector rattle, mechanical
  diesel clatter, slow response and no turbocharger layer.

The automated content test generates deterministic sample buffers from every
synthesizer and verifies that every pair retains a distinct waveform signature.

## Visual and collision integration

`1993_fso_polonez_caro_mr93_lp_new.glb` is instantiated through a dedicated
visual wrapper. Runtime code measures its imported bounds, normalizes it to the
4.318 m body length, centers it on the vehicle origin and applies the project
forward-axis convention.

The source hierarchy is preserved because it does not expose a stable documented
wheel-node contract. An independently authored low-detail fallback contains four
explicit wheel pivots at the 2.509 m wheelbase and is used for wheel rotation and
screen-distance LOD. Its two body meshes plus four wheels stay within the
six-mesh-per-car AI fleet budget. Three collision volumes cover the front
structure, cabin and rear body.

## Validation

`scripts/tests/fso_polonez_caro_mr93_content_test.gd` verifies:

- catalog and model registration;
- all seven stable variant IDs;
- authoritative specs, sampled torque curves and audio profiles;
- selected gearbox, reverse and final-drive values;
- deterministic 0–100 performance windows for all seven drivetrains;
- scene instantiation and four-wheel visual bindings;
- the exact dedicated synthesizer class used by each engine;
- finite, audible and pairwise-distinct procedural output.

## Third-party asset boundary

The visual GLB is by Krzysztof Stolorz (`KrStolorz`) and its Sketchfab page
displays **Free Standard**, not a Creative Commons license. Sketchfab standard
terms restrict standalone or extractable redistribution. The technical wrapper
does not change the licensing status of the underlying GLB.

The runtime integration is therefore not evidence that public source or binary
redistribution is permitted. Separate written redistribution permission,
a different applicable license, or replacement/removal of the raw model remains
necessary before treating the visual asset as distribution-cleared.
