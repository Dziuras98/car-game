# 1967 Shelby G.T. 500 runtime specifications

This directory contains the runtime tuning for both normal-production transmission variants.

## Resources

```text
gt500_428_pi_torque_curve.tres
gt500_428_4mt_specs.tres
gt500_428_3at_specs.tres
```

## Shared engine boundary

Both variants use the same naturally aspirated 428 FE Police Interceptor-based V8 with an aluminum mid-rise intake and two 600 CFM Holley four-barrel carburetors.

The sampled curve is constrained to:

- 420 lb-ft / 569.44 Nm at 3,200 RPM;
- 355 hp SAE gross / approximately 264.7 kW at 5,400 RPM;
- declining torque after the power peak;
- one shared resource for both transmissions.

Only the two published peak anchors are exact historical points. Intermediate samples are a documented reconstruction and must be revised if an identified factory or period dynamometer trace becomes available.

## Variant separation

`gt500_428_4mt_specs.tres` contains the close-ratio Toploader, 3.89 rear axle, manual shift interruption, manual driveline efficiency and period-tyre launch ceiling.

`gt500_428_3at_specs.tres` contains the C6 ratios, 3.50 rear axle, converter model, automatic shift schedule, automatic driveline efficiency and slower launch ceiling.

Engine output must not be reduced to tune acceleration. Straight-line performance is calibrated through mass, verified gearing, driveline losses, converter behavior, resistance and `max_drive_acceleration`.
