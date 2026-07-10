# Car specs runtime reconfiguration test — 2026-07-10

## Environment

Reported test environment:

- Godot Engine v4.7.stable.official.5b4e0cb0f
- Vulkan 1.3.284
- Forward Mobile renderer
- Qualcomm Adreno 830 GPU

## Test scene

```text
scenes/tests/car_specs_runtime_reconfiguration_test.tscn
```

## Result

Passed.

The scene reported:

```text
[CAR_SPECS_RECONFIG_TEST] Passed: 21 checks
```

## Covered checks

The reported run passed these validation points:

- car creates `SkidMarkEmitter` during `_ready()`;
- emitter creates a parent container;
- initial configure creates one `SkidMarks` container;
- runtime reconfiguration rebuilds `CarDriveConfig`;
- `CarDriveConfig` applies new skid-mark minimum slip, interval, lifetime, width and length;
- runtime reconfiguration reuses the existing `SkidMarkEmitter`;
- runtime reconfiguration reuses the existing `SkidMarks` parent;
- emitter applies new skid-mark minimum slip, interval, lifetime, width and length;
- runtime reconfiguration does not create duplicate `SkidMarks` containers;
- runtime reconfiguration clamps current gear to the new forward gear count;
- runtime reconfiguration preserves forward speed before the next physics tick;
- runtime reconfiguration preserves lateral speed before the next physics tick;
- runtime reconfiguration preserves engine RPM before the next physics tick.

## Notes

This validates the focused regression test added after synchronizing `SkidMarkEmitter` with runtime `car_specs` changes.
