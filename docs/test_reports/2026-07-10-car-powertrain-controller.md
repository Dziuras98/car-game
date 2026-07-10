# Car powertrain controller test — 2026-07-10

## Environment

Reported test environment:

- Godot Engine v4.7.stable.official.5b4e0cb0f
- Vulkan 1.3.284
- Forward Mobile renderer
- Qualcomm Adreno 830 GPU

## Test scene

```text
scenes/tests/car_powertrain_controller_test.tscn
```

## Result

Passed.

The scene reported:

```text
[CAR_POWERTRAIN_TEST] Passed: 24 checks
```

## Covered checks

The reported run passed these validation points:

- manual gear-up moves from first to second gear;
- manual gear-up applies manual shift delay;
- manual gear text reports second gear;
- manual shift timer decays with delta;
- manual gear-down moves from second to first gear;
- manual neutral does not drive the car;
- manual gear text reports neutral;
- manual drive is blocked while shift timer is active;
- manual reverse gear drives the car backwards with throttle;
- manual gear text reports reverse;
- automatic brake from near stop selects reverse;
- automatic reverse applies backwards drive with brake input;
- automatic gear text reports reverse;
- automatic throttle from reverse selects first drive gear;
- automatic first drive gear applies forward drive with throttle;
- automatic gear text reports first drive gear;
- automatic high RPM requests upshift;
- automatic upshift applies automatic shift delay;
- automatic gear text reports second drive gear;
- fallback non-geared drive accelerates forward with throttle;
- fallback gear text reports drive while moving forward;
- fallback brake reduces forward speed;
- fallback brake from stop applies reverse acceleration;
- fallback gear text reports reverse while moving backwards.

## Notes

This validates the focused scene-runnable `CarPowertrainController` regression test added after the powertrain extraction. It covers deterministic transmission and speed-direction behavior without relying on the full car scene or exact acceleration magnitudes.
