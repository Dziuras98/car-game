# Nissan 370Z NISMO V2 (2016)

## Scope

The game model represents the facelifted Z34 NISMO V2 body introduced for model year 2015 and used in 2016.

The authoritative European 2016 configuration is the six-speed manual. A seven-speed automatic variant is also included as a clearly labelled global-market configuration because that transmission was available on contemporary North American and Japanese NISMO models.

## Published reference targets

- engine: naturally aspirated VQ37VHR NISMO, 3,696 cm³ V6;
- maximum power: 253 kW / 344 PS at 7,400 RPM;
- maximum torque: 371 Nm at 5,200 RPM;
- driven wheels: rear;
- governed maximum speed: 250 km/h;
- wheelbase: 2,550 mm;
- approximate NISMO V2 exterior length: 4,410 mm;
- approximate width excluding mirrors: 1,870 mm;
- approximate height: 1,310 mm;
- tyre reference: 245/40 R19 front and 285/35 R19 rear.

The in-game mass is normalized against the existing 1,495 kg standard-370Z tuning rather than copied from one market's type-approval convention. The manual NISMO is set to 1,560 kg and the automatic to 1,580 kg.

## Engine curve

The runtime `EngineModel` uses three smooth torque sections rather than an arbitrary sampled lookup table. The NISMO parameters are:

- idle: 850 RPM;
- torque peak: 5,200 RPM;
- power peak / redline target: 7,400 RPM;
- limiter: 7,500 RPM;
- peak torque: 371 Nm;
- low-RPM multiplier: 0.52;
- mid-RPM multiplier: 0.88;
- redline multiplier: 0.88.

The 0.88 redline multiplier is deliberate: `371 Nm × 0.88 × 7,400 RPM` produces approximately 253 kW, matching the published NISMO power target while preserving the measured torque peak at 5,200 RPM.

| RPM | Torque (Nm) | Power (kW) | Power (PS) |
|---:|---:|---:|---:|
| 850 | 192.92 | 17.17 | 23.35 |
| 1,000 | 194.66 | 20.38 | 27.71 |
| 1,500 | 220.41 | 34.62 | 47.07 |
| 2,000 | 262.98 | 55.08 | 74.89 |
| 2,500 | 304.23 | 79.65 | 108.29 |
| 3,000 | 326.01 | 102.42 | 139.25 |
| 3,500 | 331.08 | 121.35 | 164.99 |
| 4,000 | 344.41 | 144.27 | 196.15 |
| 4,500 | 359.67 | 169.49 | 230.44 |
| 5,000 | 369.89 | 193.67 | 263.32 |
| 5,200 | 371.00 | 202.03 | 274.68 |
| 5,500 | 368.74 | 212.38 | 288.76 |
| 6,000 | 357.62 | 224.70 | 305.51 |
| 6,500 | 342.74 | 233.29 | 317.19 |
| 7,000 | 330.36 | 242.17 | 329.25 |
| 7,200 | 327.52 | 246.94 | 335.75 |
| 7,400 | 326.48 | 253.00 | 343.98 |

## Transmissions

### European six-speed manual

- ratios: 3.794 / 2.324 / 1.624 / 1.271 / 1.000 / 0.794;
- reverse: 3.446;
- final drive: 3.916;
- gameplay shift interruption: 0.24 s;
- intended presentation: SynchroRev Match-equipped European NISMO.

The shorter 3.916 final drive distinguishes the NISMO V2 manual from the standard 370Z manual's 3.692 final drive.

### Global seven-speed automatic

- ratios: 4.923 / 3.193 / 2.042 / 1.411 / 1.000 / 0.862 / 0.771;
- reverse: 3.972;
- final drive: 3.357;
- paddle-shift / downshift-rev-match presentation;
- gameplay automatic shift interruption: 0.17 s;
- more aggressive kickdown threshold than the standard 370Z automatic.

This variant is not presented as a European 2016 configuration. It exists to model the contemporary global-market NISMO automatic and to provide an AI-compatible NISMO opponent.

## Chassis tuning

Compared with the standard 370Z tuning, the NISMO receives:

- higher lateral grip: 11.3 instead of 10.0;
- faster steering response;
- firmer suspension spring and damping values;
- shorter suspension travel;
- slightly stronger engine braking and service braking;
- wider rear tyre geometry.

## Procedural audio differences

Both cars retain the same VQ37VHR firing architecture. The NISMO profile changes the acoustic balance rather than replacing it with an unrelated engine sound.

| Parameter | Standard 370Z | 370Z NISMO | Intended result |
|---|---:|---:|---|
| Combined synthesis/output gain | 12.5 dB | 12.5 dB | Equal comparison level and headroom |
| Idle player level | -10 dB | -9 dB | More audible sport exhaust at light load |
| Intake presence | 0.18 | 0.24 | Stronger high-RPM induction |
| Intake plenum detail | 0.10 | 0.14 | More defined VQ intake texture |
| Exhaust resonance | 0.54 | 0.66 | Fuller lower-backpressure exhaust body |
| Exhaust bank separation | 0.30 | 0.38 | More pronounced dual-bank character |
| High-RPM rasp | 0.07 | 0.11 | Sharper 7,400-RPM power-band character |
| Overrun crackle | 0.10 | 0.13 | Slightly stronger lift-off signature |
| Limiter residual combustion | 0.20 | 0.24 | Audible but non-digital short limiter window |

## Visual differences

The NISMO scene shares the correctly proportioned Z34 cabin and lamp geometry with the standard model, then adds original low-poly NISMO-specific geometry:

- extended GT-R-inspired front fascia;
- central grille and two larger side intakes;
- black splitter with red accent line;
- deeper side skirts with red lower accents;
- extended rear bumper, diffuser and side vents;
- larger rear wing with supports intersecting the rear deck;
- dark wheel finish;
- red brake calipers and mirror accents.

The add-on meshes are closed overlapping volumes. Their intersections with the shared shell are intentional and prevent floating components or visible air gaps.
