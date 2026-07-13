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

## User-supplied hardtop gearbox table

A gearbox and final-drive table supplied during integration provides the following data for 1993-1999 hardtop Punto models. The exact publication, manual edition or catalogue page has not yet been identified, so these values are recorded as high-value provisional evidence rather than primary-source-confirmed runtime data.

### Five- and six-speed gear sets

| Gear set | 1st | 2nd | 3rd | 4th | 5th | 6th | Reverse |
|---|---:|---:|---:|---:|---:|---:|---:|
| standard petrol 5MT (`55, 60, 75, 90`) | 3.909 | 2.157 | 1.480 | 1.121 | 0.902 | - | 3.818 |
| long petrol 5MT (`55*`, `60**`, `90***`) | 3.909 | 2.157 | 1.345 | 0.974 | 0.808 | - | 3.818 |
| Punto 55 6-Speed | 3.545 | 2.157 | 1.480 | 1.121 | 0.902 | 0.744 | 3.818 |
| Punto GT 5MT, supplied table | 3.909 | 2.238 | 1.541 | 1.156 | 0.891 | - | 3.909 |
| Punto TD 5MT | 3.909 | 2.238 | 1.440 | 1.029 | 0.794 | - | 3.909 |

Body-code qualifiers attached to the long petrol gear set:

- Punto 55: `176BA53F`, `176BA55F`, `176BA53P`, `176BA55P`;
- Punto 60: `176BB53F`, `176BB55F`, `176BB53P`, `176BB55P`;
- Punto 90: `176BL53A`, `176BL55A`, `176BL53P`, `176BL55P`.

The body-code table proves that the commercial engine name alone is insufficient to select the transmission calibration. Runtime variant selection must either encode the relevant transmission family explicitly or resolve it from a verified body-code/trim mapping.

### Final-drive ratios

| Commercial version | Final drive | Qualification |
|---|---:|---|
| Punto 55 standard | 3.866 | normal five-speed candidate |
| Punto 55 long / ED candidate | 3.563 | applies to the listed `176BA...` body codes |
| Punto 55 6-Speed | 4.923 | dedicated six-speed final drive |
| Punto 60 | 3.563 | shared final drive in the supplied table; individual gear set still depends on body code |
| Punto 75 | 3.733 | standard petrol five-speed |
| Punto 90 | 3.563 | individual gear set still depends on body code |
| Punto GT | 3.353 | GT five-speed |
| Punto TD | 3.733 | TD five-speed |

No hardtop final-drive entry was supplied for the naturally aspirated Punto D. It must not be assumed to use the TD final drive without separate evidence.

### GT ratio conflict

An earlier secondary technical table recorded the GT gear set as:

`3.909 / 2.238 / 1.520 / 1.156 / 0.872`, reverse `3.909`.

The newly supplied table instead gives:

`3.909 / 2.238 / 1.541 / 1.156 / 0.891`, reverse `3.909`, final drive `3.353`.

The conflict affects third and fifth gear. Neither pair is promoted to authoritative runtime data until the gearbox variant, source edition and production applicability are identified. The final drive `3.353` is retained as provisional evidence.

### Cabriolet table

The supplied information also includes Cabriolet-specific gear and final-drive tables. They are not imported into the hatchback variant matrix because the current source model is a hardtop and this document deliberately scopes passenger hatchbacks. The Cabriolet table also contains an apparent `0.121` fourth-gear transcription in one column; that value must be checked against the original source before any future Cabriolet work.

## Required engine/transmission combinations

The candidate set now separates every transmission calibration exposed by the supplied hardtop table. IDs remain research reservations until body-code applicability and source provenance are verified.

| Candidate stable variant ID | Engine | Transmission | Research status |
|---|---|---|---|
| `fiat_punto_176_1995_55_5mt` | 1.1 `176A6.000` | standard 5MT, `3.909/2.157/1.480/1.121/0.902`, FD `3.866` | provisional ratios; body-code applicability still to verify |
| `fiat_punto_176_1995_55_ed_5mt` | 1.1 `176A6.000` | long 5MT, `3.909/2.157/1.345/0.974/0.808`, FD `3.563` | strongly consistent with Economy Drive; listed `176BA...` codes require primary confirmation |
| `fiat_punto_176_1995_55_6mt` | 1.1 `176A6.000` | 6MT, `3.545/2.157/1.480/1.121/0.902/0.744`, FD `4.923` | complete provisional ratio set |
| `fiat_punto_176_1995_60_a7_5mt` | 1.2 `176A7.000` | standard 5MT, FD `3.563` | provisional engine/body-code intersection |
| `fiat_punto_176_1995_60_a7_long_5mt` | 1.2 `176A7.000` | long 5MT, FD `3.563` | provisional; applies only if an early-1995 car used a listed `176BB...` code |
| `fiat_punto_176_1995_60_b4_5mt` | 1.2 `176B4.000` | standard 5MT, FD `3.563` | provisional engine/body-code intersection |
| `fiat_punto_176_1995_60_b4_long_5mt` | 1.2 `176B4.000` | long 5MT, FD `3.563` | provisional; applies only if a late-1995 car used a listed `176BB...` code |
| `fiat_punto_176_1995_60_a7_ecvt` | 1.2 `176A7.000` | Selecta electronically controlled CVT | provisional engine-code split; CVT data required |
| `fiat_punto_176_1995_60_b4_ecvt` | 1.2 `176B4.000` | Selecta electronically controlled CVT | provisional engine-code split; CVT data required |
| `fiat_punto_176_1995_75_5mt` | 1.2 `176A8.000` | standard 5MT, FD `3.733` | complete provisional ratio set |
| `fiat_punto_176_1995_90_5mt` | 1.6 `176A9.000` | standard 5MT, FD `3.563` | provisional body-code applicability |
| `fiat_punto_176_1995_90_long_5mt` | 1.6 `176A9.000` | long 5MT, FD `3.563` | listed `176BL...` body-code combination; primary confirmation required |
| `fiat_punto_176_1995_gt_5mt` | 1.4 turbo `176A4.000` | GT 5MT, provisional FD `3.353` | third- and fifth-gear source conflict unresolved |
| `fiat_punto_176_1995_d_5mt` | 1.7 diesel `176B3.000` | five-speed manual | ratios and final drive still unresolved |
| `fiat_punto_176_1995_td70_5mt` | 1.7 turbo-diesel `176A5.000` | TD 5MT, `3.909/2.238/1.440/1.029/0.794`, FD `3.733` | complete provisional ratio set |
| `fiat_punto_176_1995_td70_cat_5mt` | 1.7 turbo-diesel `176A3.000` | TD 5MT, `3.909/2.238/1.440/1.029/0.794`, FD `3.733` | complete provisional ratio set; market applicability still required |

The table now contains 16 reserved candidates. This is not a claim that all 16 were independently orderable combinations. Four Punto 60 manual IDs represent the unresolved intersection of two 1995 engine calibrations with two body-code-dependent gear sets. They must be collapsed only after original Fiat documentation proves which intersections did not exist.

The Selecta was sold throughout 1995, but currently available secondary summaries disagree or remain ambiguous about which 1.2 engine code was paired with the ECVT before and after the June 1995 transition. Two candidate IDs are therefore reserved without claiming that both are independently validated production combinations.

## Confirmed and provisional transmission distinctions

### Punto 55 normal five-speed

The supplied table gives the standard petrol gear set and a `3.866` final drive. This combination remains provisional pending identification of the original source and its production/body-code scope.

### Punto 55 ED five-speed

`ED` means Economy Drive. It is not merely an equipment package: it uses a differently calibrated five-speed gearbox with taller third, fourth and fifth gears. The supplied `176BA...` body-code list and `3.563` final drive are consistent with the expected ED behavior, but the explicit ED-to-body-code mapping still requires primary confirmation.

### Punto 55 six-speed

The six-speed is a genuinely different transmission calibration, not the standard five-speed with an added ratio. It uses a shorter first gear, a sixth gear of `0.744` and a much shorter `4.923` final drive.

### Punto 60 and Punto 90 five-speeds

The supplied body-code qualifiers show that selected Punto 60 and Punto 90 cars used the long petrol gear set. Because their final drives remain the same as the corresponding standard versions, the distinction exists in third, fourth and fifth gear rather than the differential ratio.

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

The manual-transmission gap is substantially reduced, but the table is still not sufficient by itself for authoritative physics implementation. Before creating final playable resources, obtain or cross-check:

1. the original publication or Fiat document containing the supplied hatchback ratio tables;
2. exact body-code meaning and the trim/engine/date applicability of every `176BA`, `176BB` and `176BL` code;
3. which early/late Punto 60 engine codes were actually paired with each five-speed family;
4. the correct GT third and fifth gears (`1.520/0.872` versus `1.541/0.891`);
5. Punto D gearbox ratios and final drive;
6. Selecta ECVT ratio range, final drive and control behavior;
7. complete or defensibly reconstructed torque curves, with published power/torque anchors preserved exactly;
8. engine idle, governed/redline and limiter behavior;
9. curb mass by three-door powertrain rather than generic model range;
10. tyre size, wheel radius, drag coefficient and frontal area by version;
11. performance targets from identified period road tests for regression bands;
12. market applicability of both TD 70 calibrations and both possible 1995 Selecta engine-code pairings.

No unknown ratio should be invented merely to make a variant playable. A reconstructed value must be labelled as calibration and constrained by identified performance evidence.

## Repository integration implications

The current catalog contract requires one model definition with one variant resource and one authoritative `CarSpecs` resource per playable engine/transmission calibration. Shared visuals are permitted, but visually incompatible GT equipment must be removed or replaced for ordinary versions.

Recommended implementation order:

1. inspect and normalize the GLB, identify GT1 versus GT2, and establish a model-specific visual contract;
2. recover the source provenance and resolve the GT ratio conflict;
3. build the GT drivetrain after its final ratio set is settled;
4. implement 55, 55 ED, 55 6-Speed, 75 and TD manual variants from the supplied table, with provisional-source annotations until primary corroboration is obtained;
5. resolve Punto 60 and Punto 90 body-code intersections before exposing their additional long-geared variants;
6. recover Punto D gearing;
7. add a dedicated CVT model before exposing Selecta;
8. author trim-specific visual substitutions and only then register non-GT variants in the catalog.

## Research references

- Type 176 production range, 1995 equipment/transmission notes, engine codes, output, torque and production periods: https://de.wikipedia.org/wiki/Fiat_Punto_%28Typ_176%29
- Italian 1993-1996 three-door range and descriptions of 55 ED, 55 6 Speed and Selecta: https://it.wikipedia.org/wiki/Fiat_Punto_%281993%29
- GT production phases, engine specification and an earlier secondary gearbox-ratio table: https://it.wikipedia.org/wiki/Fiat_Punto_GT
- Period-oriented catalogue cross-check for three-door production intervals, masses and transmission types: https://www.automoto.it/catalogo/fiat/punto
- user-supplied 1993-1999 hardtop gearbox/final-drive table, exact originating publication not yet identified.

Secondary and user-supplied evidence must be replaced or corroborated with Fiat technical documentation, homologation data, a clearly identified period road test or an original owner/workshop manual before drivetrain-critical values are accepted as authoritative.