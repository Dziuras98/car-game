# Fiat Punto Type 176 (1995) powertrain inventory

## Scope and source asset

This document defines the research baseline for integrating a calendar-year 1995 Fiat Punto Type 176 three-door hatchback.

Source model:

- repository path: `res://free_1995_fiat_punto_gt.glb`;
- original page: https://sketchfab.com/3d-models/free-1995-fiat-punto-gt-48db6facb4b64e99b60f36b8c01185e1;
- advertised trim: Fiat Punto GT, model year 1995.

The imported mesh represents a GT. It can provide the common Type 176 body shell, but using it unchanged for ordinary 55, 60, 75, 90 or diesel versions would be visually inaccurate because the GT has trim-specific bumpers, lamps, side skirts, wheels, brakes, badges and interior details.

This integration is deliberately limited to standard-geared hatchback variants. Body-code-dependent long-ratio five-speed versions, including the Punto 55 ED calibration, are outside the runtime scope. The dedicated Punto 55 six-speed and Punto 60 Selecta ECVT remain in scope because they are separate factory transmission types rather than long-ratio derivatives.

## Selected 1995 engine calibrations

| Commercial version | Engine code | Displacement | Aspiration / fuel | Output | Peak torque | 1995 status |
|---|---|---:|---|---:|---:|---|
| Punto 55 | `176A6.000` | 1,108 cc | naturally aspirated petrol | 40 kW / 54 PS at 5,500 RPM | 85 Nm at 3,500 RPM | full year |
| Punto 60 | `176A7.000` | 1,242 cc | naturally aspirated petrol | 43 kW / 58 PS at 5,500 RPM | 96 Nm at 3,000 RPM | selected 1995 calibration |
| Punto 75 | `176A8.000` | 1,242 cc | naturally aspirated petrol | 54 kW / 73 PS at 6,000 RPM | 106 Nm at 4,000 RPM | full year |
| Punto 90 | `176A9.000` | 1,581 cc | naturally aspirated petrol | 65 kW / 88 PS at 5,750 RPM | 127 Nm at 2,750 RPM | full year |
| Punto GT | `176A4.000` | 1,372 cc | turbocharged petrol | 98 kW / 133 PS at 5,750 RPM | 204 Nm at 3,000 RPM | full year; GT1 and GT2 share this calibration |
| Punto D | `176B3.000` | 1,698 cc | naturally aspirated diesel | 42 kW / 57 PS at 4,500 RPM | 98 Nm at 2,500 RPM | full year |
| Punto TD 70 | `176A5.000` | 1,698 cc | turbo-diesel | 52 kW / 71 PS at 4,500 RPM | 134 Nm at 2,500 RPM | selected 1995 calibration |

## Engine torque and power curves

Seven sampled `EngineTorqueCurve` resources are stored in:

```text
resources/cars/fiat/punto_176_1995/specs/
```

| Engine code | Curve resource |
|---|---|
| `176A6.000` | `176a6_1108_fire_torque_curve.tres` |
| `176A7.000` | `176a7_1242_fire_spi_torque_curve.tres` |
| `176A8.000` | `176a8_1242_fire_mpi_torque_curve.tres` |
| `176A9.000` | `176a9_1581_sohc_mpi_torque_curve.tres` |
| `176A4.000` | `176a4_1372_turbo_torque_curve.tres` |
| `176B3.000` | `176b3_1698_d_torque_curve.tres` |
| `176A5.000` | `176a5_1698_td_torque_curve.tres` |

No complete, unambiguously identified Fiat factory dynamometer trace was located for any of these exact engine codes. The resources are therefore constrained reconstructions, not digitized factory graphs.

Each curve follows these rules:

1. the multiplier at the published torque-peak RPM is exactly `1.0`;
2. torque at the published power-peak RPM is calculated from `T = P × 9549.2966 / RPM`;
3. interpolation over the entire stored RPM range reaches its global power maximum at the published power-peak RPM;
4. no interpolated point exceeds the published torque or power rating;
5. torque and power fall after the published power peak;
6. all values represent crankshaft output before driveline losses.

The GT curve represents progressive boost build-up toward the published 204 Nm point but does not model transient boost pressure or overboost duration as separate state.

Detailed methodology is documented in `resources/cars/fiat/punto_176_1995/specs/README.md`. `scripts/tests/fiat_punto_engine_curves_test.gd` validates all seven resources and scans every integer RPM in each stored range for hidden interpolation overshoot.

## Standard hardtop gearboxes

The gearbox and final-drive table supplied during integration is retained as provisional evidence because its exact publication or manual edition has not yet been identified.

### In-scope gear sets

| Gear set | 1st | 2nd | 3rd | 4th | 5th | 6th | Reverse |
|---|---:|---:|---:|---:|---:|---:|---:|
| standard petrol 5MT (`55, 60, 75, 90`) | 3.909 | 2.157 | 1.480 | 1.121 | 0.902 | - | 3.818 |
| Punto 55 6-Speed | 3.545 | 2.157 | 1.480 | 1.121 | 0.902 | 0.744 | 3.818 |
| Punto GT 5MT, supplied table | 3.909 | 2.238 | 1.541 | 1.156 | 0.891 | - | 3.909 |
| Punto TD 5MT | 3.909 | 2.238 | 1.440 | 1.029 | 0.794 | - | 3.909 |

### Final-drive ratios

| Commercial version | Final drive |
|---|---:|
| Punto 55 standard | 3.866 |
| Punto 55 6-Speed | 4.923 |
| Punto 60 standard | 3.563 |
| Punto 75 standard | 3.733 |
| Punto 90 standard | 3.563 |
| Punto GT | 3.353 |
| Punto TD | 3.733 |

No hardtop final-drive entry was supplied for the naturally aspirated Punto D. It must not be assumed to use the TD final drive.

### GT gearbox conflict

An earlier secondary table gives the GT ratios as:

`3.909 / 2.238 / 1.520 / 1.156 / 0.872`, reverse `3.909`.

The user-supplied table gives:

`3.909 / 2.238 / 1.541 / 1.156 / 0.891`, reverse `3.909`, final drive `3.353`.

The conflict affects third and fifth gear. Neither pair is authoritative until the source edition and production applicability are identified.

## Required engine/transmission combinations

| Candidate stable variant ID | Engine | Transmission | Research status |
|---|---|---|---|
| `fiat_punto_176_1995_55_5mt` | 1.1 `176A6.000` | standard 5MT, FD `3.866` | curve and provisional ratio set available |
| `fiat_punto_176_1995_55_6mt` | 1.1 `176A6.000` | 6MT, FD `4.923` | curve and provisional ratio set available |
| `fiat_punto_176_1995_60_a7_5mt` | 1.2 `176A7.000` | standard 5MT, FD `3.563` | curve and provisional ratio set available |
| `fiat_punto_176_1995_60_a7_ecvt` | 1.2 `176A7.000` | Selecta ECVT | engine curve available; CVT model and pairing evidence required |
| `fiat_punto_176_1995_75_5mt` | 1.2 `176A8.000` | standard 5MT, FD `3.733` | curve and provisional ratio set available |
| `fiat_punto_176_1995_90_5mt` | 1.6 `176A9.000` | standard 5MT, FD `3.563` | curve and provisional ratio set available |
| `fiat_punto_176_1995_gt_5mt` | 1.4 turbo `176A4.000` | GT 5MT, provisional FD `3.353` | engine curve available; gearbox conflict unresolved |
| `fiat_punto_176_1995_d_5mt` | 1.7 diesel `176B3.000` | standard 5MT | engine curve available; gearbox unresolved |
| `fiat_punto_176_1995_td70_5mt` | 1.7 TD `176A5.000` | TD 5MT, FD `3.733` | curve and provisional ratio set available |

The table contains nine reserved standard-scope candidates.

## Punto 60 Selecta ECVT

The Selecta uses an electronically controlled continuously variable transmission, not a stepped automatic with a hydraulic torque converter. The current `CarSpecs.TransmissionType` supports only direct drive, manual and conventional geared automatic modes.

Faithful integration requires a dedicated CVT model covering at least:

- minimum and maximum variator ratios;
- final-drive ratio;
- clutch engagement behavior;
- commanded engine-speed schedule as a function of throttle, road speed and load;
- ratio-change response and efficiency;
- reverse implementation.

Until that model exists, Selecta must remain catalog-ineligible.

## 1995 GT visual split

The GT changed from the first version to the second version during 1995. Both retained engine code `176A4.000`, 98 kW and the same basic drivetrain. The split is primarily visual and equipment-related. The imported GLB must be inspected for GT1 versus GT2 details before its visual identity is declared.

## Excluded combinations

- body-code-dependent long-ratio five-speed variants;
- Punto 55 ED long-ratio calibration;
- 1.2 85 16V / 86 PS, introduced in 1997;
- 1.7 TD 60 / 63 PS, introduced in 1996;
- 1997-onward GT `176B6.000` / 130 PS;
- Cabriolet and Van body variants;
- tuner, competition, prototype and engine-swap configurations.

## Remaining research

Before final playable `CarSpecs` resources are accepted, resolve or corroborate:

1. the originating publication for the supplied gearbox table;
2. the correct GT third and fifth ratios;
3. Punto D gearbox ratios and final drive;
4. Selecta ECVT ratio range, final drive and control behavior;
5. confirmation that the selected Punto 60 calibration was paired with Selecta in the relevant 1995 production period;
6. idle, redline and limiter behavior for every engine;
7. curb mass, tyres, wheel radius, drag coefficient and frontal area by version;
8. period performance targets for deterministic regression;
9. market applicability of the selected TD 70 calibration;
10. any identified factory or period dynamometer traces that can replace reconstructed intermediate curve samples.

No reconstructed value may be relabelled as measured factory data.

## Recommended implementation order

1. inspect and normalize the GLB and identify GT1 versus GT2;
2. resolve the GT gearbox conflict;
3. create `CarSpecs` resources using the completed engine curves and resolved gearbox data;
4. recover Punto D gearing;
5. implement CVT support before exposing Selecta;
6. author trim-specific visual substitutions before registering non-GT variants.

## Research references

- Type 176 production range, engine codes, output, torque and production periods: https://de.wikipedia.org/wiki/Fiat_Punto_%28Typ_176%29
- Italian 1993-1996 range and descriptions of 55 6 Speed and Selecta: https://it.wikipedia.org/wiki/Fiat_Punto_%281993%29
- GT production phases and engine specification: https://it.wikipedia.org/wiki/Fiat_Punto_GT
- Period-oriented catalogue cross-check: https://www.automoto.it/catalogo/fiat/punto
- user-supplied 1993-1999 hardtop gearbox/final-drive table, originating publication not yet identified.

Secondary and user-supplied evidence must remain distinguishable from identified Fiat technical documentation, homologation data or period test material.
