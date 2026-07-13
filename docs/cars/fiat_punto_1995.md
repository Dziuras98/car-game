# Fiat Punto Type 176 (1995) powertrain inventory

## Scope and source asset

This document defines the research baseline for integrating a calendar-year 1995 Fiat Punto Type 176 three-door hatchback.

Source model:

- repository path: `res://free_1995_fiat_punto_gt.glb`;
- original page: https://sketchfab.com/3d-models/free-1995-fiat-punto-gt-48db6facb4b64e99b60f36b8c01185e1;
- advertised trim: Fiat Punto GT, model year 1995.

The imported mesh represents a GT. It can provide the common Type 176 body shell, but using it unchanged for ordinary 55, 60, 75, 90 or diesel versions would be visually inaccurate because the GT has trim-specific bumpers, lamps, side skirts, wheels, brakes, badges and interior details. Visual reuse must therefore be conditional on model inspection and model-specific hiding or replacement of GT equipment.

This inventory covers engine and transmission combinations that were available during 1995 in European three-door hatchback production. Equipment levels such as S, SX, EL, ELX and HSD are not separate runtime variants unless they introduce different engine, gearbox, final-drive, mass, tyre or brake data.

## Confirmed 1995 engine calibrations

| Commercial version | Engine code | Displacement | Aspiration / fuel | Output | Peak torque | 1995 status |
|---|---|---:|---|---:|---:|---|
| Punto 55 | `176A6.000` | 1,108 cc | naturally aspirated petrol | 40 kW / 54 PS at 5,500 RPM | 85 Nm at 3,500 RPM | full year |
| Punto 60, early | `176A7.000` | 1,242 cc | naturally aspirated petrol | 43 kW / 58 PS at 5,500 RPM | 96 Nm at 3,000 RPM | through approximately June 1995 |
| Punto 60, late | `176B4.000` | 1,242 cc | naturally aspirated petrol | 44 kW / 60 PS at 5,500 RPM | 96 Nm at 3,000 RPM | from approximately June 1995 |
| Punto 75 | `176A8.000` | 1,242 cc | naturally aspirated petrol | 54 kW / 73 PS at 6,000 RPM | 106 Nm at 4,000 RPM | full year |
| Punto 90 | `176A9.000` | 1,581 cc | naturally aspirated petrol | 65 kW / 88 PS at 5,750 RPM | 127 Nm at 2,750 RPM | full year |
| Punto GT | `176A4.000` | 1,372 cc | turbocharged petrol | 98 kW / 133 PS at 5,750 RPM | 204 Nm at 3,000 RPM | full year; both GT1 and GT2 use this calibration |
| Punto D | `176B3.000` | 1,698 cc | naturally aspirated diesel | 42 kW / 57 PS at 4,500 RPM | 98 Nm at 2,500 RPM | full year |
| Punto TD 70, no oxidation catalyst | `176A5.000` | 1,698 cc | turbo-diesel | 52 kW / 71 PS at 4,500 RPM | 134 Nm at 2,500 RPM | market-dependent, full year |
| Punto TD 70, oxidation catalyst | `176A3.000` | 1,698 cc | turbo-diesel | 51 kW / 69 PS at 4,500 RPM | 134 Nm at 2,500 RPM | market-dependent, available in 1995 |

The commercial name `Punto 60` hides a mid-1995 engine-code and rated-output transition. These calibrations must not be silently collapsed into one engine resource unless primary documentation proves that their complete torque curves and control behavior are equivalent.

## Required engine/transmission combinations

The following is the conservative candidate set. Stable IDs are reserved now so research does not later overwrite or ambiguously rename a playable variant.

| Candidate stable variant ID | Engine | Transmission | Research status |
|---|---|---|---|
| `fiat_punto_176_1995_55_5mt` | 1.1 `176A6.000` | normal five-speed manual | confirmed combination; exact ratios/final drive still required |
| `fiat_punto_176_1995_55_ed_5mt` | 1.1 `176A6.000` | Economy Drive five-speed manual with taller gearing | confirmed distinct transmission calibration; exact ratios/final drive still required |
| `fiat_punto_176_1995_55_6mt` | 1.1 `176A6.000` | six-speed manual with shorter overall final gearing | confirmed combination; exact ratios/final drive still required |
| `fiat_punto_176_1995_60_a7_5mt` | 1.2 `176A7.000` | five-speed manual | confirmed early-1995 combination; exact ratios/final drive still required |
| `fiat_punto_176_1995_60_b4_5mt` | 1.2 `176B4.000` | five-speed manual | confirmed late-1995 combination; exact ratios/final drive still required |
| `fiat_punto_176_1995_60_a7_ecvt` | 1.2 `176A7.000` | Selecta electronically controlled CVT | provisional engine-code split; primary evidence required |
| `fiat_punto_176_1995_60_b4_ecvt` | 1.2 `176B4.000` | Selecta electronically controlled CVT | provisional engine-code split; primary evidence required |
| `fiat_punto_176_1995_75_5mt` | 1.2 `176A8.000` | five-speed manual | confirmed combination; exact ratios/final drive still required |
| `fiat_punto_176_1995_90_5mt` | 1.6 `176A9.000` | five-speed manual | confirmed combination; Sporting/final-drive distinction still requires verification |
| `fiat_punto_176_1995_gt_5mt` | 1.4 turbo `176A4.000` | five-speed manual | confirmed; forward and reverse ratios known, final drive still required |
| `fiat_punto_176_1995_d_5mt` | 1.7 diesel `176B3.000` | five-speed manual | confirmed combination; exact ratios/final drive still required |
| `fiat_punto_176_1995_td70_5mt` | 1.7 turbo-diesel `176A5.000` | five-speed manual | confirmed market-dependent combination; exact ratios/final drive still required |
| `fiat_punto_176_1995_td70_cat_5mt` | 1.7 turbo-diesel `176A3.000` | five-speed manual | confirmed market-dependent combination; exact ratios/final drive still required |

The Selecta was sold throughout 1995, but currently available secondary summaries disagree or remain ambiguous about which 1.2 engine code was paired with the ECVT before and after the June 1995 transition. Two candidate IDs are therefore reserved without claiming that both are independently validated production combinations. Primary Fiat parts, workshop or homologation documentation must settle this before runtime resources are created.

## Confirmed transmission distinctions

### Punto 55 normal five-speed

This is the baseline manual gearbox used by regular Punto 55 versions. Exact individual ratios and final drive have not yet been accepted because no primary or clearly identified period table has been located.

### Punto 55 ED five-speed

`ED` means Economy Drive. It is not merely an equipment package: it uses a differently calibrated five-speed gearbox with taller gearing for lower fuel consumption. It therefore requires a separate `CarSpecs` resource even though the engine code is shared with the ordinary Punto 55.

### Punto 55 six-speed

The 1.1-litre 55 was offered with a six-speed manual. Period summaries describe it as using a shorter overall final ratio than the ordinary five-speed. This version therefore requires its own gear set and final drive rather than adding a sixth ratio to the standard 55 data.

Published launch dates differ by market-oriented secondary catalogues: one lists a September 1994 production interval, while another describes availability from May 1995. The combination was unquestionably available during calendar year 1995.

### Punto 60 Selecta ECVT

The Selecta uses an electronically controlled continuously variable transmission, not a stepped automatic with a hydraulic torque converter. The current `CarSpecs.TransmissionType` supports only direct drive, manual and conventional geared automatic modes, and its automatic validation and controller logic assume discrete forward ratios plus torque-converter stall/coupling parameters.

Consequently, the Selecta must not be approximated by a fake one-speed or multi-speed automatic. Faithful integration requires a dedicated CVT transmission type and runtime model covering at least:

- minimum and maximum variator ratios;
- final-drive ratio;
- clutch engagement behavior;
- commanded engine-speed schedule as a function of throttle, road speed and load;
- ratio-change response rate and efficiency;
- reverse implementation;
- over-temperature or launch limitations only if supported by evidence.

Until that model exists, Selecta variants must remain catalog-ineligible.

### Punto GT five-speed

The period technical table currently provides these gearbox ratios:

| Gear | Ratio |
|---|---:|
| 1 | 3.909 |
| 2 | 2.238 |
| 3 | 1.520 |
| 4 | 1.156 |
| 5 | 0.872 |
| Reverse | 3.909 |

The final-drive ratio is still required from an identified primary or period technical source before a runtime `CarSpecs` file is authored.

## 1995 GT visual split

The GT changed from the first version to the second version during 1995. Both retained engine code `176A4.000`, 98 kW / 133 PS and the same basic five-speed drivetrain. The change is therefore primarily a visual/equipment distinction rather than a separate powertrain variant.

Before choosing the visual identity, inspect the imported GLB for the distinguishing GT2 details, particularly dark internal headlamp treatment, body-colour side skirts, revised side mouldings and GT badges. The filename alone is insufficient evidence of which 1995 production phase the model reproduces.

## Excluded combinations

The following must not be added as 1995 production powertrains:

- 1.2 85 16V / 86 PS, introduced in 1997;
- 1.7 TD 60 / 63 PS, introduced in 1996;
- 1997-onward GT `176B6.000` / 130 PS;
- Cabrio-only presentation variants when their engine and transmission duplicate the hatchback powertrain;
- Van equipment/body configurations when their powertrain duplicates a passenger version;
- the unproduced Punto Abarth concept;
- tuner, competition, prototype and engine-swap configurations.

## Evidence quality and unresolved data

This first pass establishes the complete candidate powertrain matrix, but it is not sufficient for physics implementation. Before creating playable resources, obtain or cross-check:

1. Fiat workshop-manual or homologation gearbox tables for every five- and six-speed version;
2. all final-drive ratios;
3. Selecta ECVT ratio range and control behavior;
4. complete or defensibly reconstructed torque curves, with published power/torque anchors preserved exactly;
5. engine idle, governed/redline and limiter behavior;
6. curb mass by three-door powertrain rather than generic model range;
7. tyre size, wheel radius, drag coefficient and frontal area by version;
8. performance targets from identified period road tests for regression bands;
9. market applicability of both TD 70 calibrations and both possible 1995 Selecta engine-code pairings;
10. whether the Punto 90 Sporting uses transmission or final-drive ratios distinct from ordinary Punto 90 versions.

No unknown ratio should be invented merely to make a variant playable. A reconstructed value must be labelled as calibration and constrained by identified performance evidence.

## Repository integration implications

The current catalog contract requires one model definition with one variant resource and one authoritative `CarSpecs` resource per playable engine/transmission calibration. Shared visuals are permitted, but visually incompatible GT equipment must be removed or replaced for ordinary versions.

Recommended implementation order:

1. inspect and normalize the GLB, identify GT1 versus GT2, and establish a model-specific visual contract;
2. recover exact manual gearbox and final-drive tables;
3. build the GT drivetrain first because its gear ratios and engine anchors are the best documented;
4. implement and validate ordinary manual variants only after their exact gearing is recovered;
5. add a dedicated CVT model before exposing Selecta;
6. author trim-specific visual substitutions and only then register non-GT variants in the catalog.

## Research references

- Type 176 production range, 1995 equipment/transmission notes, engine codes, output, torque and production periods: https://de.wikipedia.org/wiki/Fiat_Punto_%28Typ_176%29
- Italian 1993-1996 three-door range and descriptions of 55 ED, 55 6 Speed and Selecta: https://it.wikipedia.org/wiki/Fiat_Punto_%281993%29
- GT production phases, engine specification and period gearbox-ratio table: https://it.wikipedia.org/wiki/Fiat_Punto_GT
- Period-oriented catalogue cross-check for three-door production intervals, masses and transmission types: https://www.automoto.it/catalogo/fiat/punto

These are secondary research sources. The next phase should replace or corroborate every drivetrain-critical number with Fiat technical documentation, homologation data, a clearly identified period road test or an original owner/workshop manual before gameplay tuning is accepted as authoritative.
