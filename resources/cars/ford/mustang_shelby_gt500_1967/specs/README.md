# 1967 Shelby G.T. 500 specs plan

This directory will contain the authoritative runtime tuning for the two production powertrain variants.

## Planned resources

```text
gt500_428_pi_torque_curve.tres
gt500_428_4mt_specs.tres
gt500_428_3at_specs.tres
```

## Shared engine boundary

Both production variants use the same naturally aspirated 428 FE Police Interceptor-based V8 with an aluminum mid-rise intake and two 600 CFM Holley four-barrel carburetors.

Published reference points retained for future curve reconstruction:

- advertised maximum power: 355 bhp at 5,400 RPM;
- advertised maximum torque: 420 lb-ft / approximately 569 Nm at 3,200 RPM;
- advertised compression ratio: 10.5:1.

These peak values do not define a complete torque curve. The `.tres` curve must not be created by holding peak torque across the operating range or by substituting a 1968 Cobra Jet curve.

## Transmission separation

`gt500_428_4mt_specs.tres` is reserved for the four-speed Ford manual configuration.

`gt500_428_3at_specs.tres` is reserved for the three-speed Ford C6 SelectShift Cruise-O-Matic configuration.

The specs must remain separate for:

- forward and reverse ratios;
- final-drive ratio;
- shift interruption and automatic shift logic;
- torque-converter behavior;
- transmission and driveline losses;
- any verified transmission-dependent mass.

Do not create the runtime resources until exact application-specific gearbox and axle data are supported by an authoritative source.