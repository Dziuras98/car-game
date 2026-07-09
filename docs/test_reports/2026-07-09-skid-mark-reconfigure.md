# Skid mark reconfigure smoke test — 2026-07-09

## Scope

Validation after fixing runtime `car_specs` reconfiguration so the existing `SkidMarkEmitter` receives updated skid-mark parameters instead of keeping stale values.

Changed runtime files covered by this validation:

- `scripts/car/car_controller.gd`
- `scripts/car/skid_mark_emitter.gd`

Related documentation files updated in the same cleanup pass:

- `docs/roadmap.md`
- `docs/vehicle_model.md`

## Reported result

Project owner reported that tests completed successfully after the fix.

## Expected regression coverage

The successful test run is expected to cover the broad full-program smoke path:

- main scene loads;
- menu flow still works;
- free-drive automatic flow still works;
- free-drive manual flow still works;
- race mode still works;
- player car spawning still works;
- speedometer and minimap still bind to the active car;
- steering, braking, handbrake/slip and reset checks remain valid;
- race countdown and AI race soak still work;
- simulated finish and return-to-menu cleanup still work.

## Notes

No intentional handling, drivetrain, race, UI or track behavior changes were made. The runtime change is limited to keeping skid-mark emitter configuration synchronized with rebuilt `CarDriveConfig` values.
