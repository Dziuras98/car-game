# Fiat Punto Type 176 (1995) engine torque curves

## Evidence status

The seven resources in this directory are dense, constrained reconstructions of full-load crankshaft torque curves. The research pass did not locate a complete, identified Fiat factory dynamometer trace for any of the exact selected 1995 engine codes.

Each curve therefore separates:

- exact published anchors: maximum torque and its RPM, plus maximum power and its RPM;
- reconstructed intermediate samples selected to produce a smooth and physically plausible full-load characteristic;
- calibrated high-RPM samples that force power to fall after the published power peak.

These resources must not be described as digitized factory graphs. They are gameplay-grade reconstructions designed to be replaceable if an identified Fiat homologation curve, factory dynamometer plot or period engine-dynamometer record becomes available.

## Construction contract

1. Future `CarSpecs.peak_engine_torque` must equal the published maximum torque.
2. The multiplier at the published torque-peak RPM is exactly `1.0`.
3. Torque at the published power-peak RPM is calculated from `T = P × 9549.2966 / RPM`.
4. Linear interpolation between stored samples reaches its global maximum power at the published power-peak RPM.
5. No interpolated point exceeds the published maximum torque or maximum power.
6. The last stored samples provide a controlled falloff and are not presented as measured limiter data.
7. All values represent crankshaft output before transmission and tyre losses.

## Engine resources and exact anchors

| Engine code | Runtime identity | Exact torque anchor | Exact power anchor | Resource |
|---|---|---:|---:|---|
| `176A6.000` | Punto 55 1.1 FIRE SPI | 85 Nm at 3,500 RPM | 40 kW at 5,500 RPM | `176a6_1108_fire_torque_curve.tres` |
| `176A7.000` | Punto 60 1.2 FIRE SPI | 96 Nm at 3,000 RPM | 43 kW at 5,500 RPM | `176a7_1242_fire_spi_torque_curve.tres` |
| `176A8.000` | Punto 75 1.2 FIRE MPI | 106 Nm at 4,000 RPM | 54 kW at 6,000 RPM | `176a8_1242_fire_mpi_torque_curve.tres` |
| `176A9.000` | Punto 90 1.6 MPI | 127 Nm at 2,750 RPM | 65 kW at 5,750 RPM | `176a9_1581_sohc_mpi_torque_curve.tres` |
| `176A4.000` | Punto GT 1.4 Turbo | 204 Nm at 3,000 RPM | 98 kW at 5,750 RPM | `176a4_1372_turbo_torque_curve.tres` |
| `176B3.000` | Punto D 1.7 naturally aspirated diesel | 98 Nm at 2,500 RPM | 42 kW at 4,500 RPM | `176b3_1698_d_torque_curve.tres` |
| `176A5.000` | Punto TD 70 1.7 turbo-diesel | 134 Nm at 2,500 RPM | 52 kW at 4,500 RPM | `176a5_1698_td_torque_curve.tres` |

## Calibration distinctions

### Punto GT

The GT reconstruction represents the published 204 Nm full-load peak and a progressive turbo build-up before 3,000 RPM. The engine resource does not simulate transient boost pressure, overboost duration, charge temperature or wastegate state. Those effects require a separate forced-induction model if they are introduced later.

## Validation

`scripts/tests/fiat_punto_engine_curves_test.gd` loads all seven resources and verifies:

- resource validation;
- exact torque-peak multipliers;
- calculated power at the published power peak;
- the global power maximum over every integer RPM in the stored range;
- post-peak torque falloff.

The numerical construction was also checked independently at one-RPM resolution before the resources were committed.

## Replacement policy

A future curve may replace a reconstruction only when the source unambiguously identifies the matching engine code or production calibration. A chassis-dynamometer wheel curve must not directly replace these crankshaft curves without a documented driveline-loss correction. The source and whether each sample is measured, digitized or reconstructed must remain recorded.
