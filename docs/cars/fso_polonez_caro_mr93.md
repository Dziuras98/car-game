# FSO Polonez Caro MR'93 powertrain inventory

## Scope

This document defines the research boundary for adding the five-door,
wide-track Polonez Caro MR'93 to the car catalog.

The target generation begins with the August 1993 MR'93 update and ends when
the original Caro body was replaced by Caro Plus in 1997. The inventory does
not silently merge the earlier narrow-track 1991–1993 Caro or the later Caro
Plus into the same playable model.

Core scope:

- European and Polish series-production five-door Caro MR'93 applications;
- factory rear-wheel-drive engine and transmission combinations;
- calibrations that actually overlapped the wide-track body;
- separate verification state for unresolved engine-code and gearbox details.

Excluded from the first implementation:

- pre-MR'93 Caro variants, including the 1991-only 2.0 Ford application;
- Caro Plus, Atu, Atu Plus, Kombi, Cargo, Truck and special-service bodies;
- prototypes, short experimental runs, motorsport cars, aftermarket conversions
  and engine swaps;
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
owner either obtains separate redistribution permission, confirms a different
applicable license or removes the raw public copy. This is a project risk note,
not legal advice.

## Data files

The normalized research data is stored in:

```text
docs/cars/data/fso_polonez_caro_mr93_engines.csv
docs/cars/data/fso_polonez_caro_mr93_powertrains.csv
docs/cars/data/fso_polonez_caro_mr93_sources.csv
```

The first-pass inventory contains:

- 6 engine/output calibrations;
- 8 recorded engine codes or code labels: `K16`, `AB`, `AE`, `AF`, `CB`,
  `CE`, `CF` and `XUD9A`;
- 6 rear-wheel-drive, five-speed manual powertrain candidates;
- no verified factory automatic-transmission application in this body scope.

`AE / AF` and `CE / CF` are retained as paired calibrations for now because the
available secondary table does not establish a gameplay-relevant output
change or an exact catalyst/build-date split. They must be separated later if
primary FSO documentation proves different power, torque, gearing, mass or
availability.

## Core MR'93 engine applications

| Badge | Engine | Fuel system | Output | Torque | MR'93 overlap |
|---|---|---|---:|---:|---|
| 1.4 GLI 16V | Rover K16, 1398 cc DOHC 16V | multipoint injection | 76 kW / 103 PS at 6000 rpm | 127 Nm at 5000 rpm | Dec 1993–1997 |
| 1.5 GLE | FSO AB, 1481 cc OHV | carburettor | 60 kW / 82 PS at 5200 rpm | 114 Nm at 3400 rpm | Aug 1993–1994 |
| 1.5 GLI | FSO AE / AF, 1481 cc OHV | single-point injection | 57 kW / 77 PS at 5400 rpm | 115 Nm at 2800 rpm | Aug 1993–1995 |
| 1.6 GLE | FSO CB, 1598 cc OHV | carburettor | 64 kW / 87 PS at 5200 rpm | 132 Nm at 3800 rpm | Aug 1993–1994 |
| 1.6 GLI | FSO CE / CF, 1598 cc OHV | single-point injection | 60 kW / 81 PS at 5200 rpm | 125 Nm at 3200 rpm | Aug 1993–1997 |
| 1.9 GLD | PSA XUD9A, 1905 cc SOHC IDI | indirect diesel injection | 51 kW / 70 PS at 4600 rpm | 120 Nm at 2000 rpm | Aug 1993–1996 |

The kW values are rounded conversions from the cited PS ratings. Before a
playable `CarSpecs` resource is produced, primary material should replace the
secondary output and production-date compilation wherever possible.

## Transmission inventory

Every verified core candidate is represented as:

```text
RWD + 5-speed manual
```

No factory automatic is currently supported by the reviewed MR'93 production
record. This does not mean one physical gearbox calibration can be copied to
all variants.

The Rover K16 and PSA XUD9A installations require application-specific checks
for at least:

- bellhousing and clutch arrangement;
- forward and reverse ratios;
- final-drive ratio;
- propeller-shaft and differential application;
- speedometer drive and homologated tire size.

The FSO 1.5 and 1.6 applications also need build-date-specific ratio and final
drive verification. Until those values are sourced, every matrix row remains
`availability_verified_family_pending` and must not be converted into a
finished `CarSpecs` by inventing or copying ratios from another Polonez era.

## Excluded Ford 2.0 application

The 1993 cc Ford SOHC 2.0 GLE appears in the broader Caro history, but the
reviewed production table dates it to 1991. It is therefore a predecessor
application rather than a core wide-track MR'93 variant and is deliberately
excluded from the CSV matrix.

If a primary FSO record later proves a factory-built MR'93 overlap, add it as a
new engine calibration and a gearbox-specific candidate instead of expanding
the current generation boundary by assumption.

## Suggested implementation order

1. `caro_mr93_16_gli_5mt` as the representative long-running FSO-engine model;
2. `caro_mr93_14_gli_16v_5mt` as the highest-performance factory model;
3. `caro_mr93_19_gld_5mt` as the diesel application;
4. `caro_mr93_15_gli_5mt`;
5. the short-overlap carburettor variants.

Each playable variant will need its own verified mass, tire package, torque
curve, gearbox ratios, final drive, redline, braking target and longitudinal
handling calibration.

## Reference hierarchy

Primary FSO service manuals, homologation sheets, price lists and period
brochures should replace secondary compilations before final physics tuning.
The current source register records:

- the Sketchfab asset page and its displayed license label;
- Sketchfab's standard license restrictions;
- a secondary Polonez chronology and engine table;
- an independent generation-boundary cross-check;
- an XUD9A engine-family cross-check;
- this project's explicit reconstruction assumptions.
