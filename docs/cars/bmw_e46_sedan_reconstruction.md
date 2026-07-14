# BMW E46 sedan data reconstruction

## Purpose

This document records the reconstruction method used to turn incomplete BMW E46
sedan reference material into auditable simulation seeds. It does not claim that
reconstructed values are factory measurements.

The generated data files are:

```text
docs/cars/data/bmw_e46_sedan_engine_runtime_targets.csv
docs/cars/data/bmw_e46_sedan_torque_curves_petrol_4cyl.csv
docs/cars/data/bmw_e46_sedan_torque_curves_petrol_6cyl_eu.csv
docs/cars/data/bmw_e46_sedan_torque_curves_petrol_6cyl_regional.csv
docs/cars/data/bmw_e46_sedan_torque_curves_diesel.csv
docs/cars/data/bmw_e46_sedan_drivetrain_dynamics_petrol.csv
docs/cars/data/bmw_e46_sedan_drivetrain_dynamics_diesel.csv
docs/cars/data/bmw_e46_sedan_sources.csv
```

The drivetrain table covers all 51 European sedan candidates already enumerated
in `bmw_e46_sedan_powertrains.csv`. The four curve tables cover all 24 retained engine
calibrations, including the six deferred regional calibrations.

## Quality classes

Values are deliberately classified rather than presented with false precision:

- `factory_exact`: copied from a matching BMW technical-data sheet;
- `factory_carryover`: a later engine revision with unchanged published vehicle
  hardware and headline targets;
- `factory_body_proxy`: factory data for the matching powertrain in the E46
  Touring, retained as a gearbox/chassis-family proxy for the sedan;
- `factory_ratio_reconstructed_final`: factory internal ratios with an unclear
  or missing final-drive cell;
- `period_test_anchor`: an instrumented contemporary road-test result;
- `multi_source_compromise`: conflicting or incomplete references reconciled to
  one target;
- `family_proxy`: a gearbox or chassis-family value applied to an application
  that still needs build-date-specific confirmation;
- `reconstructed`: a simulation seed derived from physical anchors.

A candidate can contain values from several classes. For example, its internal
gear ratios can be `factory_exact` while its 100–0 km/h distance remains a
reconstruction.

## Engine curves

BMW technical sheets normally publish maximum torque, its engine speed or
plateau, maximum power and its engine speed. They do not publish a dense
full-load torque map.

Each reconstructed curve therefore:

1. preserves the published maximum-torque point or plateau;
2. converts the published maximum-power point to torque with:

```text
torque_nm = power_kw * 9549.296596 / rpm
```

3. uses a family-specific shape between the anchors:
   - M43: early mid-range peak and a stronger high-speed torque falloff;
   - N42/N46: weaker low-speed fill, broad Valvetronic mid-range and a later
     power peak;
   - M52TU/M54/M56: broad six-cylinder mid-range with a progressive fall after
     approximately 4500 rpm;
   - M47/M57: rapid turbo torque rise, a published plateau where available and
     a controlled fall toward 4000 rpm;
4. forces reconstructed power after the published power peak to decline;
5. adds redline and limiter points as gameplay seeds rather than manufacturer
   limiter measurements.

`published_anchor` rows are sourced or algebraically derived from a published
power anchor. All other rows are `reconstructed`.

### Resolved conflicts

- M54B25 European maximum-power speed appears as both 6000 and 6100 rpm in
  retained references. The shared curve uses 6050 rpm. The 50 rpm difference is
  negligible for gameplay while keeping the disagreement explicit.
- N46B20 maximum-torque speed is reported as 3600 or 3750 rpm. The reconstruction
  uses 3700 rpm and a deliberately broad peak.
- Deferred US and SULEV curves reuse the corresponding M54 family shape but are
  rescaled to their regional published outputs.
- The ZHP curve retains more torque above the normal M54B30 power peak and uses
  its higher redline.

The curve should later be validated against a digitized stock-engine dyno plot.
A chassis dyno must first be corrected for drivetrain loss and should not replace
the published crankshaft anchors.

## Transmissions and final drives

The exact BMW sheets provide a strong numeric base for the facelift 318i,
320i/325i/330i, later diesels and contemporary AWD Touring applications.

Where a sedan-specific cell is missing:

- internal ratios are inherited only from the identified gearbox family;
- the final drive is selected to remain consistent with the application,
  published maximum speed, tire circumference and neighboring BMW variants;
- the result is marked `family_proxy` rather than `factory_exact`;
- automatic top speed is not assumed to occur in the overdrive gear. Several
  period torque-converter applications can reach maximum speed in fourth gear.

All configured top-speed targets were checked against the rev-limited speed
available in the numerically highest forward gear so that they satisfy the
current `CarSpecs` validation rule.

The SMG rows preserve their geared ratios and performance targets but remain
runtime-blocked. They must not use torque-converter multiplication.

## Mass and performance

Mass is normalized to DIN curb mass without the EU 75 kg driver/luggage addition.
The companion `mass_eu_kg` column is retained for comparison with BMW technical
sheets.

Factory acceleration and maximum-speed data are used where a matching sedan
sheet is available. Early variants and AWD sedan rows use a compromise between
archived sedan targets, matching factory Touring data and neighboring
powertrains. The 0–1000 m and 80–120 km/h fields are reconstructed where the
technical sheet did not publish them.

A reconstructed intermediate acceleration is a calibration target. It is not an
independent measurement and should be rechecked after the complete physics model
can reproduce 0–100 km/h and maximum speed simultaneously.

## Braking

BMW sheets provide rotor dimensions and brake construction but generally do not
provide 100–0 km/h stopping distance. The stopping targets are reconstructed
from:

- tire section and period-appropriate road-tire capability;
- front and rear rotor group;
- DIN mass and drivetrain layout;
- representative contemporary instrumented tests;
- ABS-equipped dry asphalt behavior.

The implied constant-deceleration check is:

```text
deceleration_mps2 = (100 / 3.6)^2 / (2 * stopping_distance_m)
```

The resulting targets span approximately 9.6–10.5 m/s². They represent a fresh,
warm road car on dry asphalt, not a cold, wet, faded or worn-brake condition.

## Steering and cornering

Matching BMW sheets establish:

| Layout | Steering ratio | Lock-to-lock | Turning circle |
|---|---:|---:|---:|
| RWD sedan | 13.7:1 | 3.0 turns | 10.5 m |
| AWD family | 15.5:1 | 3.5 turns | 10.9 m |

The road-wheel angle is reconstructed as 33 degrees for RWD and 30.5 degrees for
AWD. This is a physics/controller target, not a quoted alignment specification.

Lateral acceleration targets are grouped by tires, mass, brakes/suspension
package and drivetrain. The 330xi period-test result is retained as an anchor
for a soft, base-tire AWD setup; other values are reconstructed. These values
must be used to calibrate the tire model rather than serialized directly as a
claim about a specific tire brand.

## Geometry and resistance

The working sedan geometry is:

- wheelbase: 2.725 m;
- front/rear track: 1.481 / 1.493 m for the retained facelift reference;
- frontal area: 2.06 m²;
- turning-circle and steering differences as listed above.

Drag coefficient targets are 0.29–0.30 for petrol RWD variants, approximately
0.30 for petrol AWD, 0.31 for RWD diesels and 0.32 for AWD diesels. Early-body
and equipment-specific differences remain lower-confidence than the shared
dimensions.

## Required validation before catalog registration

Before a row becomes a production `CarSpecs` resource:

1. generate its Godot torque-curve resource from the CSV;
2. confirm exact gearbox and differential applicability by market and build
   month;
3. verify tire and brake package for the selected trim;
4. tune drivetrain efficiency and shift interruption until 0–100 km/h,
   intermediate acceleration and maximum speed agree together;
5. tune tire coefficients until both stopping distance and lateral target agree;
6. test manual, automatic and AWD behavior separately;
7. keep SMG disabled until an automated-manual runtime exists.

This reconstruction is intentionally more complete than a placeholder but it is
still a calibration baseline, not homologation data.
