# FSO Polonez Caro MR'93 powertrain inventory

## Scope

This document defines the research boundary for adding the five-door,
wide-track Polonez Caro MR'93 to the car catalog.

The target generation begins with the August 1993 MR'93 update and ends when
the original Caro body was replaced by Caro Plus in 1997. Earlier narrow-track
Caro and later Plus bodies remain separate visual and chassis variants, but
cross-generation drivetrain evidence may be used where its limitations are
recorded explicitly.

Core scope:

- European and Polish series-production five-door Caro MR'93 applications;
- factory rear-wheel-drive engine and transmission combinations;
- the Ford 2.0 application now confirmed by the repository owner for the
  wide-track body, despite incomplete production-date coverage in common
  secondary tables;
- separate verification state for factory facts, forum-derived reconstruction
  and unresolved application details.

Excluded from the first implementation:

- Caro Plus, Atu, Atu Plus, Kombi, Cargo, Truck and special-service bodies;
- prototypes, motorsport cars, aftermarket conversions and engine swaps;
- LPG conversions unless a documented factory configuration is found.

## Imported visual asset

The repository currently contains the source model at its root as:

```text
1993_fso_polonez_caro_mr93_lp_new.glb
```

It corresponds to **1993 FSO Polonez Caro MR'93 (LP, new)** by Krzysztof
Stolorz (`KrStolorz`) on Sketchfab.

The source page displays **Free Standard**, not a Creative Commons license.
Sketchfab's standard terms restrict making licensed material available as a
standalone or extractable file. The raw GLB therefore must not be treated as
redistribution-cleared merely because it was downloadable. Visual integration,
asset relocation and attribution work remain blocked until the repository
owner obtains separate redistribution permission, confirms another applicable
license or removes the raw public copy. This is a project risk note, not legal
advice.

## Data files

```text
docs/cars/data/fso_polonez_caro_mr93_engines.csv
docs/cars/data/fso_polonez_caro_mr93_powertrains.csv
docs/cars/data/fso_polonez_caro_mr93_sources.csv
docs/cars/data/fso_polonez_gearbox_ratio_evidence.csv
```

The inventory now contains:

- 7 engine/output calibrations;
- 9 engine-code or family labels: `K16`, `AB`, `AE`, `AF`, `CB`, `CE`, `CF`,
  `Ford OHC / Pinto` and `XUD9A`;
- 7 rear-wheel-drive, five-speed-manual candidates;
- no evidenced factory automatic-transmission application in this body scope.

`AE / AF` and `CE / CF` remain paired calibrations until a source establishes a
gameplay-relevant output, catalyst, gearing, mass or production-date split.

## Core MR'93 engine applications

| Badge | Engine | Fuel system | Output | Torque | MR'93 overlap |
|---|---|---|---:|---:|---|
| 1.4 GLI 16V | Rover K16, 1398 cc DOHC 16V | multipoint injection | 76 kW / 103 PS at 6000 rpm | 127 Nm at 5000 rpm | Dec 1993–1997 |
| 1.5 GLE | FSO AB, 1481 cc OHV | carburettor | 60 kW / 82 PS at 5200 rpm | 114 Nm at 3400 rpm | Aug 1993–1994 |
| 1.5 GLI | FSO AE / AF, 1481 cc OHV | single-point injection | 57 kW / 77 PS at 5400 rpm | 115 Nm at 2800 rpm | Aug 1993–1995 |
| 1.6 GLE | FSO CB, 1598 cc OHV | carburettor | 64 kW / 87 PS at 5200 rpm | 132 Nm at 3800 rpm | Aug 1993–1994 |
| 1.6 GLI | FSO CE / CF, 1598 cc OHV | single-point injection | 60 kW / 81 PS at 5200 rpm | 125 Nm at 3200 rpm | Aug 1993–1997 |
| 2.0 GLE | Ford OHC/Pinto, 1993 cc SOHC 8V | carburettor | 77 kW / 105 PS at 5200 rpm | 157 Nm at 4000 rpm | confirmed MR'93 application; dates pending |
| 1.9 GLD | PSA XUD9A, 1905 cc SOHC IDI | indirect diesel injection | 51 kW / 70 PS at 4600 rpm | 120 Nm at 2000 rpm | Aug 1993–1996 |

The Ford MR'93 application is retained because the repository owner has
confirmed that it existed in this body. Common online tables often date the
broader Caro 2.0 GLE only to 1991, so exact production months and volume remain
open research questions rather than grounds for excluding the variant.

The Ford engine and gearbox came from the Sierra family. Published secondary
torque values differ; 157 Nm at 4000 rpm is retained as the current calibration
seed pending an application-specific FSO document.

## Provisional FSO five-speed ratios

Repository-owner forum research produced the following forward set for the
ordinary FSO production five-speed:

| Gear | Ratio |
|---:|---:|
| I | 3.753 |
| II | 2.132 |
| III | 1.378 |
| IV | 1.000 |
| V | 0.860 |

Fourth is direct drive and fifth is an overdrive. The reverse ratio, gearbox
codes and gear tooth counts remain unresolved.

This set is stored as a **provisional forum-derived calibration**, not as a
factory-documented value. It is nevertheless substantially more plausible than
copying the Polski Fiat 125p four-speed set: a period 1978 comparison explicitly
states that the original Polonez changed second and third relative to 125p.

The forward set is provisionally attached to the FSO-family 1.4, 1.5, 1.6 and
1.9 candidates. It is not attached to the Ford 2.0 candidate.

## Final-drive application map

Forum research supplied the following practical map:

| Ratio | Provisional application | Interpretation |
|---:|---|---|
| 3.72 | PSA/Citroën diesel, including 1.9 GLD | Tallest common axle, lowest cruising rpm |
| 3.90 | common 1.6 passenger versions | Balanced acceleration and cruising rpm |
| 4.10 | 1.5 and some 1.6 versions | Shorter gearing and stronger acceleration |
| 4.30 | Rover 1.4 16V and some 1.6 versions | Shortest common production axle |

The initial candidate defaults are therefore:

| Candidate | Provisional final drive | Status |
|---|---:|---|
| 1.4 GLI 16V | 4.30 | forum mapping pending primary confirmation |
| 1.5 GLE | 4.10 | forum mapping pending primary confirmation |
| 1.5 GLI | 4.10 | forum mapping pending primary confirmation |
| 1.6 GLE | 3.90 | default reconstruction; 4.10/4.30 alternatives unresolved |
| 1.6 GLI | 3.90 | default reconstruction; 4.10/4.30 alternatives unresolved |
| 1.9 GLD | 3.72 | forum mapping; determine whether exact ratio is 3.727 |
| 2.0 GLE Ford | unresolved | separate Ford Sierra gearbox and axle application |

The 1.6 range must eventually be expanded into separate drivetrain candidates
if a parts catalog, build sheet or owner manual maps 3.90, 4.10 and 4.30 to
specific engine codes, trims or production periods.

Independent cross-generation evidence supports the general map:

- the older Polonez 2.0 D Turbo VM is reported with a 3.727 axle;
- the later passenger Polonez Kombi 1.6 used 3.90;
- its van counterpart used 4.30;
- the older Polonez 1500 X is reported with 4.30.

These comparisons support the existence of the axle families but do not replace
MR'93-specific tooth-count or build-date evidence.

## Ford 2.0 transmission boundary

The 2.0 GLE is a distinct powertrain candidate:

```text
Ford 1993 cc OHC engine + Ford Sierra five-speed manual
```

Do not assign the FSO forward ratios to this car. Before creating its
`CarSpecs`, identify:

- exact Sierra gearbox family and application;
- I–V and reverse ratios;
- Polonez-specific final drive;
- clutch and propeller-shaft arrangement;
- homologated tire size and curb mass;
- exact MR'93 build dates or identifying production records.

## Remaining uncertainty

The following values still require better documentation:

- reverse ratio for the FSO five-speed;
- exact gearbox code and tooth-count mapping;
- whether Rover and XUD installations retained every internal FSO ratio;
- exact 1.6 assignment of 3.90, 4.10 and 4.30;
- exact Ford Sierra gearbox and final drive;
- month-level production windows and market differences.

The forum values are usable for a clearly labeled provisional gameplay model.
They must not be described as manufacturer-verified until matched to an FSO
service manual, parts catalog, homologation sheet or measured factory gearbox.

## Suggested implementation order

1. `caro_mr93_16_gli_5mt` using the 3.753–0.860 FSO set and provisional 3.90 axle;
2. `caro_mr93_14_gli_16v_5mt` with provisional 4.30 axle;
3. `caro_mr93_19_gld_5mt` with provisional 3.72 axle;
4. the 1.5 variants with provisional 4.10 axle;
5. 1.6 alternate-final-drive variants after their applications are mapped;
6. `caro_mr93_20_gle_ford_5mt` after its Sierra gearbox ratios are identified.

Each playable variant also requires mass, tire package, torque curve, redline,
braking target and longitudinal/lateral handling calibration.

## Highest-value remaining sources

1. Edward Morawski, `POLONEZ Budowa Eksploatacja Naprawa`;
2. MR'91/MR'93 and Caro Plus workshop or owner manuals;
3. FSO gearbox and rear-axle parts catalogs with tooth counts;
4. full September 1978 `Kraftfahrzeugtechnik` road-test scan;
5. FIA homologation forms 656 and 657, separating production and competition
   options;
6. Ford Sierra service data tied to the exact 2.0 OHC gearbox installed by FSO;
7. the original forum threads behind the provisional ratio and axle map.

A verified tooth-count pair is sufficient to reconstruct a ratio, but it must
still be tied to a gearbox code and vehicle application before being promoted
from reconstruction to manufacturer-supported calibration.
