# BMW 3 Series Sedan E46/4 non-M powertrain inventory

## Scope

This document is the research boundary for adding the non-M BMW E46 sedan to the car catalog.

The imported source asset currently stored at the repository root as
`low_poly_car_-_bmw_e46_1998.glb` is the Sketchfab model
**Low Poly Car - BMW E46 1998** by **ROH3D**. The uploader marks it as
Creative Commons Attribution (CC BY). Before the visual is wired into a
playable scene, it must be moved under the third-party asset hierarchy and
receive the same attribution/provenance treatment as the existing external
car assets.

The first implementation target is the four-door sedan (`E46/4`):

- European series-production powertrains are the core catalog baseline;
- both pre-facelift and facelift sedan drivetrains are inventoried;
- RWD and factory AWD (`xi` / `xd`) applications are separate;
- M3, M3 CSL, Alpina, aftermarket conversions and engine swaps are excluded;
- Touring, Coupe, Cabriolet and Compact are excluded because their bodies,
  masses, tire packages and production ranges differ;
- regional non-M calibrations are retained as deferred data rather than
  silently merged into European variants.

The sedan was produced through 2005, with its body facelift introduced in
September 2001. The current GLB is titled as a 1998 car, so its initial visual
wrapper should be treated as pre-facelift unless mesh inspection proves
otherwise.

## Data files

The normalized source data is split into:

```text
docs/cars/data/bmw_e46_sedan_engines.csv
docs/cars/data/bmw_e46_sedan_powertrains.csv
```

The engine file contains:

- 18 core European engine/output calibrations;
- 6 deferred regional calibrations;
- published power and torque targets;
- market and implementation status.

The powertrain file contains 51 European sedan candidates:

- 25 manual combinations;
- 22 torque-converter automatic combinations;
- 4 non-M SMG combinations.

A candidate row is not yet a playable `CarVariantDefinition`. Exact curb mass,
final drive, tire size, gear ratios, torque curve and gameplay calibration
still need to be resolved before a `CarSpecs` resource is created.

## Core European sedan applications

| Badge | Engine calibration | Layout | Factory transmission choices represented |
|---|---|---|---|
| 316i | M43TU B19, 77 kW / 165 Nm | RWD | 5MT, 4AT |
| 316i | N42B18, 85 kW / 175 Nm | RWD | 5MT, 5AT |
| 316i | N46B18, 85 kW / 175 Nm | RWD | 5MT, 5AT |
| 318i | M43TU B19, 87 kW / 180 Nm | RWD | 5MT, 4AT |
| 318i | N42B20, 105 kW / 200 Nm | RWD | 5MT, 5AT |
| 318i | N46B20A, 105 kW / 200 Nm | RWD | 5MT, 5AT |
| 320i | M52TU B20, 110 kW / 190 Nm | RWD | 5MT, 5AT |
| 320i | M54B22, 125 kW / 210 Nm | RWD | 5MT, 5AT |
| 323i | M52TU B25, 125 kW / 245 Nm | RWD | 5MT, 5AT |
| 325i | M54B25 EU, 141 kW / 245 Nm | RWD | 5MT, 5AT, 5-speed SMG, 6-speed SMG |
| 325xi | M54B25 EU, 141 kW / 245 Nm | AWD | 5MT, 5AT |
| 328i | M52TU B28, 142 kW / 280 Nm | RWD | 5MT, 5AT |
| 330i | M54B30 EU, 170 kW / 300 Nm | RWD | 5MT, 6MT from 2003, 5AT, 5-/6-speed SMG |
| 330xi | M54B30 EU, 170 kW / 300 Nm | AWD | 5MT, 6MT from 2003, 5AT |
| 318d | M47D20, 85 kW / 265 Nm | RWD | 5MT, 5AT |
| 318d | M47TU D20, 85 kW / 280 Nm | RWD | 5MT, 5AT |
| 320d | M47D20, 100 kW / 280 Nm | RWD | 5MT, 5AT |
| 320d | M47TU D20, 110 kW / 330 Nm | RWD | 5MT, 6MT from 2003, 5AT |
| 330d | M57D30, 135 kW / 390 Nm | RWD | 5MT, 5AT |
| 330d | M57TU D30, 150 kW / 410 Nm | RWD | 6MT, 5AT |
| 330xd | M57D30, 135 kW / 390 Nm | AWD | 5MT, 5AT |
| 330xd | M57TU D30, 150 kW / 410 Nm | AWD | 6MT, 5AT |

Production years and gearbox transitions are recorded per candidate in the
CSV. The year ranges are model-family boundaries, not a substitute for
month-level VIN/build-date verification.

## Deferred regional calibrations

The engine manifest retains these non-M sedan calibrations but marks them
`deferred`:

- 316i N40B16, 85 kW / 150 Nm, selected displacement-tax markets;
- 316i N45B16O1, 85 kW / 150 Nm, selected displacement-tax markets;
- 325i US M54B25, 137 kW / 237 Nm;
- 325i SULEV M56B25, 135 kW / 234 Nm;
- 330i US M54B30, 168 kW / 290 Nm;
- 330i ZHP/ZAM M54B30, 175 kW / 301 Nm.

These need separate market-specific variants. They must not reuse European
power output, final drive or emissions-era mass data by badge alone.

## Transmission families

The inventory records both the transmission type and the best currently
supported family identification.

Known E46 non-M families include:

- Getrag S5D 250G five-speed manual for lower-output petrol applications;
- ZF S5-31 / S5D 320Z-family five-speed manual for higher-torque petrol
  applications;
- ZF GS6-37 six-speed manual for 330i/330xi and later 320d applications;
- ZF GS6-53 six-speed manual for later 330d/330xd applications;
- GM 4L30-E (`A4S270R`) four-speed automatic;
- ZF 5HP19 (`A5S325Z`) five-speed automatic;
- GM 5L40-E-family (`A5S360R` / `A5S390R`) five-speed automatic;
- BMW non-M SMG automated manuals, five-speed through 2002 and six-speed
  afterwards.

A gearbox family name is not sufficient to produce a `CarSpecs` resource.
The exact application, ratios and final drive must be selected by badge,
engine, market, body and build date. CSV rows marked
`availability_verified_family_partial` or
`availability_verified_family_pending` intentionally preserve that work.

## Verified AWD ratio seed

An official BMW technical-data sheet for the contemporary 325xi, 330xi and
330xd Touring provides a primary-source gearbox-ratio seed:

| Application | Forward ratios | Reverse |
|---|---|---:|
| 325xi / 330xi 5MT | 4.21 / 2.49 / 1.66 / 1.24 / 1.00 | 3.85 |
| 325xi / 330xi 5AT | 3.42 / 2.22 / 1.60 / 1.00 / 0.75 | 3.03 |
| 330xd 5MT | 5.24 / 2.92 / 1.82 / 1.27 / 1.00 | 4.72 |
| 330xd 5AT | 3.52 / 2.22 / 1.60 / 1.00 / 0.75 | 3.03 |

The sheet is for Touring models. Gearbox internal ratios are useful evidence,
but its curb masses and final-drive values must not be copied into sedan specs
without a sedan-specific cross-check.

## Runtime compatibility

The current `CarSpecs.TransmissionType` supports:

```text
MANUAL
AUTOMATIC
CVT
```

It has no automated-manual/SMG state. The four SMG candidates are therefore
recorded with `availability_verified_runtime_blocked`.

They must not be silently modeled as conventional torque-converter
automatics. A faithful implementation needs at least:

- a clutch-actuated geared transmission mode;
- automatic and manual shift commands;
- shift-time torque interruption;
- launch-clutch behavior;
- no torque-converter multiplication or coupling logic.

The remaining 47 manual and conventional-automatic candidates can use the
existing transmission categories once their authoritative numeric data is
complete.

## Catalog implementation order

To keep the first playable set useful without producing dozens of weakly
verified resources, implement in this order:

1. `330i_6mt` and `330i_5at`;
2. `325i_5mt` and `325i_5at`;
3. `320i_m54_5mt` and `320i_m54_5at`;
4. `320d_m47tu_6mt` and `320d_m47tu_5at`;
5. remaining RWD variants;
6. AWD variants after transfer-case behavior and sedan-specific mass data are
   validated;
7. SMG only after runtime support exists;
8. deferred regional calibrations last.

Each resulting `CarSpecs` must use a separate torque curve and exact
transmission/final-drive data where the physical drivetrain differs.

## Reference hierarchy

Primary or manufacturer-authored material should replace secondary data
whenever a stable document is available.

Current references:

- source visual and uploader license declaration:
  https://sketchfab.com/3d-models/low-poly-car-bmw-e46-1998-d9bfd8126e754164b48ded833c017bbf
- BMW technical data for 325xi, 330xi and 330xd Touring:
  https://www.treffseiten.de/bmw/info/daten_325xi_330xi_330xd_touring.pdf
- BMW parts-catalog model selector for build-date/application checks:
  https://www.realoem.com/bmw/enUS/select?product=P&archive=1&series=E46
- comprehensive German engine/transmission table used as the European
  enumeration cross-check:
  https://de.wikipedia.org/wiki/BMW_E46
- broader regional engine and gearbox-family cross-check:
  https://en.wikipedia.org/wiki/BMW_3_Series_(E46)

Before a candidate becomes playable, record the exact source edition and
market for its mass, tires, gearbox ratios and final drive in this document or
a dedicated variant source note.
