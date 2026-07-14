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

Older and newer Polonez applications are nevertheless retained as gearbox
comparison evidence where they can establish a transmission family, ratio
change or final-drive option without being added to the playable MR'93 catalog.

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
docs/cars/data/fso_polonez_gearbox_ratio_evidence.csv
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

## Cross-generation gearbox evidence

The broader search currently establishes the following ratio boundaries:

| Application | Gearbox evidence | Final drive | Confidence and use |
|---|---|---:|---|
| Polski Fiat 125p 1500, four-speed predecessor | 3.75 / 2.30 / 1.49 / 1.00; reverse 3.87 | 4.10 | Exact secondary baseline only; not a Polonez five-speed set |
| Original Polonez 1300/1500 MR'78 | period KFT test confirms that second and third differed from 125p | unresolved | Strong evidence that copying the complete 125p set is incorrect |
| Polonez 1500 X | production five-speed, internal ratios unresolved | 4.30 | Older FSO OHV passenger application |
| Polonez 2.0 D Turbo, VM engine | production five-speed, internal ratios unresolved | 3.727 | Low-volume older diesel; not direct proof for XUD9A |
| Late FSO 125p | adopted Polonez powertrain and five-speed in 1988–1991 | unresolved | Useful reverse-search target for manuals and parts catalogs |
| Caro 2.0 GLE Ford | Ford Sierra engine and gearbox | unresolved | Separate gearbox family; exclude from FSO ratio reconstruction |
| Caro MR'91–MR'93 | five-speed manual confirmed | unresolved | Direct model-family evidence, but no numerical set found yet |
| Polonez Kombi Plus 1.6 GSi passenger | five-speed manual | 3.90 | Later passenger-car evidence |
| Polonez Kombi Plus 1.6 GSi van | five-speed manual | 4.30 | Same nominal engine era, commercial body/load application |

This evidence proves that final-drive selection was application-dependent. The
later Kombi passenger/van pair is particularly useful because it records 3.9
and 4.3 with the same nominal 1.6 engine family, demonstrating that body and
load target could change the axle ratio without requiring a different engine.

### What is not yet verified

No accessible source reviewed so far provides a defensible complete numerical
set for the ordinary FSO production five-speed used by the MR'93 1.5/1.6 cars.
In particular, the frequently repeated approach of taking the 125p four-speed
ratios `3.75 / 2.30 / 1.49 / 1.00`, adding an unspecified overdrive fifth and
calling it a Polonez gearbox is rejected: the 1978 period comparison explicitly
states that second and third were changed for the Polonez.

The following values are therefore not assigned to MR'93 candidates yet:

- first through fifth internal ratios;
- reverse ratio;
- exact 1.4 Rover, 1.5, 1.6 and 1.9 XUD final drives;
- gearbox code and tooth-count mapping by engine/build date.

The 3.9 later passenger-car axle and the 3.727 earlier diesel axle are retained
as comparison candidates only. They are not represented as factory MR'93 facts.

### Highest-value remaining sources

Research should now prioritize:

1. Edward Morawski, `POLONEZ Budowa Eksploatacja Naprawa`, preferably an edition
   covering the production five-speed;
2. MR'91/MR'93 and Caro Plus workshop manuals or owner manuals with technical
   specifications;
3. FSO gearbox and rear-axle parts catalogs with paired gear tooth counts;
4. the complete September 1978 `Kraftfahrzeugtechnik` road-test scan;
5. FIA homologation forms 656 and 657, separating standard-production entries
   from optional competition ratios;
6. late FSO 125p service documentation, because that model received the Polonez
   powertrain in 1988–1991.

A verified tooth-count pair is sufficient to reconstruct a ratio, but the
result must still be tied to a gearbox code and vehicle application before it
is used as a production calibration.

## Excluded Ford 2.0 application

The 1993 cc Ford SOHC 2.0 GLE appears in the broader Caro history, but the
reviewed production table dates it to 1991. It is therefore a predecessor
application rather than a core wide-track MR'93 variant and is deliberately
excluded from the CSV matrix.

The wider gearbox search also confirms that this car used the Ford Sierra
gearbox. Its ratios cannot be used to reconstruct the ordinary FSO five-speed.

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

A provisional gameplay gearbox may be created later only if it is named and
flagged as a reconstruction rather than presented as factory data. The research
CSV intentionally keeps verified evidence and simulation assumptions separate.

## Reference hierarchy

Primary FSO service manuals, homologation sheets, price lists and period
brochures should replace secondary compilations before final physics tuning.
The current source register records:

- the Sketchfab asset page and its displayed license label;
- Sketchfab's standard license restrictions;
- a secondary Polonez chronology and engine table;
- the exact four-speed 125p predecessor baseline;
- the period KFT statement that the original Polonez changed second and third;
- older and newer Polonez final-drive evidence: 4.3, 3.9 and 3.727;
- FIA homologation-form leads;
- an independent generation-boundary cross-check;
- an XUD9A engine-family cross-check;
- this project's explicit reconstruction assumptions.
