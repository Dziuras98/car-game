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
- the Ford 2.0 application confirmed by the repository owner for the wide-track
  body despite incomplete production-date coverage in common secondary tables;
- separate verification state for factory facts, forum-derived reconstruction
  and explicit gameplay estimates.

Excluded from the first implementation:

- Caro Plus, Atu, Atu Plus, Kombi, Cargo, Truck and special-service bodies;
- prototypes, motorsport cars, aftermarket conversions and engine swaps;
- LPG conversions unless a documented factory configuration is found.

## Imported visual asset

The repository currently contains:

```text
1993_fso_polonez_caro_mr93_lp_new.glb
```

It corresponds to **1993 FSO Polonez Caro MR'93 (LP, new)** by Krzysztof
Stolorz (`KrStolorz`) on Sketchfab.

The source page displays **Free Standard**, not a Creative Commons license.
The raw GLB must not be treated as redistribution-cleared merely because it was
downloadable. Visual integration remains blocked until separate redistribution
permission or another applicable license is established, or the raw public copy
is removed. This is a project risk note, not legal advice.

## Data files

```text
docs/cars/data/fso_polonez_caro_mr93_engines.csv
docs/cars/data/fso_polonez_caro_mr93_powertrains.csv
docs/cars/data/fso_polonez_caro_mr93_sources.csv
docs/cars/data/fso_polonez_gearbox_ratio_evidence.csv
```

The inventory contains:

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

The Ford engine and gearbox came from the Sierra family. The exact FSO build
window and gearbox suffix remain open research questions.

## Provisional FSO five-speed gearbox

Repository-owner forum research supplied the forward ratios. The reverse ratio
is now filled as an explicit estimate:

| Gear | Ratio | Evidence state |
|---:|---:|---|
| I | 3.753 | forum-derived |
| II | 2.132 | forum-derived |
| III | 1.378 | forum-derived |
| IV | 1.000 | forum-derived; direct drive |
| V | 0.860 | forum-derived; overdrive |
| R | 3.870 | gameplay estimate |

The reverse estimate is 3.1% shorter than first gear and matches the documented
3.870 reverse ratio of the predecessor 125p transmission family. It is a
reasonable simulation value, but it is not presented as an FSO factory
specification.

This complete provisional set is attached to the FSO-family 1.4, 1.5, 1.6 and
1.9 candidates. Exact gearbox codes, tooth counts and any Rover/XUD internal
changes remain unresolved.

## Ford 2.0 Sierra-derived drivetrain

The Ford candidate uses a separate provisional Ford Type 9 set copied from a
rear-wheel-drive Sierra-derived application:

| Gear | Ratio |
|---:|---:|
| I | 3.650 |
| II | 1.970 |
| III | 1.370 |
| IV | 1.000 |
| V | 0.820 |
| R | 3.660 |
| Final drive | 3.640 |

The Type 9 ratios and 3.64 final drive are retained as one matched Ford-family
set rather than mixing the gearbox with a bridge selected from another vehicle.
The documented donor application is the Sierra-derived Merkur XR4Ti, which has
a different engine calibration from the naturally aspirated Polonez. The value
is therefore a deliberate cross-application gameplay reconstruction, not proof
that FSO used the identical differential casing or tooth count.

This is not the FSO gearbox with different numbers. It remains a separate Ford
candidate because the Polonez 2.0 used the Sierra engine-and-gearbox family. An
original Ford/FSO document identifying the exact installed gearbox suffix and
axle hardware has not yet been recovered.

## Final-drive application map

The selected bridge distribution is:

| Ratio | Provisional application | Interpretation |
|---:|---|---|
| 3.64 | Ford 2.0 Type 9 reconstruction | matched Sierra/Merkur drivetrain proxy |
| 3.72 | PSA/Citroën diesel, including 1.9 GLD | tallest common FSO axle, lowest cruising rpm |
| 3.90 | common 1.6 passenger versions | balanced acceleration and cruising rpm |
| 4.10 | 1.5 and some 1.6 versions | shorter gearing and stronger acceleration |
| 4.30 | Rover 1.4 16V and some 1.6 versions | shortest common FSO production axle |

The current candidate defaults are:

| Candidate | Provisional final drive | Status |
|---|---:|---|
| 1.4 GLI 16V | 4.30 | forum mapping pending primary confirmation |
| 1.5 GLE | 4.10 | forum mapping pending primary confirmation |
| 1.5 GLI | 4.10 | forum mapping pending primary confirmation |
| 1.6 GLE | 3.90 | selected table default; 4.10/4.30 alternatives retained only as evidence |
| 1.6 GLI | 3.90 | selected table default; 4.10/4.30 alternatives retained only as evidence |
| 1.9 GLD | 3.72 | forum mapping; exact 3.727 possibility retained |
| 2.0 GLE Ford | 3.64 | copied with the matched Sierra-derived Type 9 set |

The 1.6 alternatives are not expanded into extra playable variants until a
parts catalog, build sheet or owner manual maps them to specific engine codes,
trims or production periods.

## Evidence boundary

Independent cross-generation evidence supports the existence of the FSO axle
families:

- the older Polonez 2.0 D Turbo VM is reported with a 3.727 axle;
- the later passenger Polonez Kombi 1.6 used 3.90;
- its van counterpart used 4.30;
- the older Polonez 1500 X is reported with 4.30.

The Ford 3.64 value belongs to a separate cross-application reconstruction and
is not evidence for an FSO-family bridge.

The ordinary FSO ratio set, estimated reverse, axle map and complete Ford proxy
are usable for clearly labeled provisional gameplay models. They must not be
described as manufacturer-verified Polonez specifications until matched to
service documentation or measured factory hardware.

## Remaining uncertainty

- exact FSO gearbox codes and tooth-count mapping;
- whether Rover and XUD installations retained every internal ratio;
- exact 1.6 assignment of 3.90, 4.10 and 4.30;
- exact Ford Type 9 suffix and whether the Polonez used the same 3.64 tooth count;
- month-level production windows and market differences.

## Suggested implementation order

1. `caro_mr93_16_gli_5mt` using FSO 3.753–0.860, reverse 3.870 and axle 3.90;
2. `caro_mr93_14_gli_16v_5mt` with axle 4.30;
3. `caro_mr93_19_gld_5mt` with axle 3.72;
4. the 1.5 variants with axle 4.10;
5. `caro_mr93_20_gle_ford_5mt` using Type 9 ratios and axle 3.64;
6. alternate 1.6 final-drive variants only after application mapping.

Each playable variant also requires mass, tire package, torque curve, redline,
braking target and longitudinal/lateral handling calibration.

## Highest-value remaining sources

1. Edward Morawski, `POLONEZ Budowa Eksploatacja Naprawa`;
2. MR'91/MR'93 and Caro Plus workshop or owner manuals;
3. FSO gearbox and rear-axle parts catalogs with tooth counts;
4. original Ford Sierra workshop data tied to the exact Type 9 suffix;
5. Ford/FSO parts records confirming the Polonez 2.0 differential tooth count;
6. original forum threads behind the provisional ratio and axle map.