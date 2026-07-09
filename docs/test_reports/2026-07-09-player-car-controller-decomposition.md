# PlayerCarController decomposition report - 2026-07-09

## Scope

This report covers the behavior-preserving decomposition of `scripts/car/car_controller.gd` into smaller runtime, configuration, powertrain, chassis, and reset collaborators.

## New classes and responsibilities

- `CarRuntimeState`: owns runtime drive state, input readout state, and the captured start transform.
- `CarDriveConfig`: owns the runtime copy of drive tuning and minimal sanitization guards.
- `CarDriveConfigBuilder`: builds runtime config from `CarSpecs` first, or from legacy `PlayerCarController` exports when no specs resource is assigned.
- `CarPowertrainController`: owns transmission, shift timer, engine RPM, torque, drivetrain, torque converter, resistance, speed update, engine load, and gear text.
- `CarChassisController`: owns steering, slip-limited steering, tire/slip update, skid mark update calls, local/global horizontal velocity conversion, gravity/floor stick, and `move_and_slide()`.
- `CarResetController`: owns reset-to-start coordination for transform, velocity, runtime state, powertrain RPM reset, and skid mark timer reset.

## PlayerCarController after refactor

`PlayerCarController` keeps the scene-compatible export fields, `car_specs`, `CarInput`, skid mark emitter ownership, public getters/setters, `_physics_process()` orchestration, runtime reconfiguration, and reset delegation.

The physics tick is now a pipeline:

1. reset check;
2. input read;
3. runtime input snapshot;
4. powertrain update;
5. steering update;
6. tire/skid update;
7. velocity application.

## Moved from PlayerCarController

Powertrain logic moved to `CarPowertrainController`: shift timer, manual and automatic gear selection, RPM update, speed update, resistance, drivetrain acceleration, torque converter helpers, torque multiplier, rev limiter multiplier, engine load, and gear text.

Chassis logic moved to `CarChassisController`: tire model update, skid mark update, smoothstep helper, steering, slip-limited steering, velocity application, and horizontal/local speed conversion.

Reset state handling moved to `CarRuntimeState` and `CarResetController`.

## Public API

The public `PlayerCarController` API used by UI, AI, smoke tests, and other systems remains available:

- `get_forward_speed()`
- `get_speed_kmh()`
- `get_engine_rpm()`
- `get_throttle_input()`
- `get_engine_load()`
- `get_tire_slip_intensity()`
- `get_gear_text()`
- `set_player_input_enabled(...)`
- `set_external_input_enabled(...)`
- `set_external_drive_inputs(...)`

Read-only test helpers were added:

- `get_current_gear_for_test()`
- `get_lateral_speed_for_test()`

## Runtime config source

Runtime tuning now comes from `CarDriveConfig`.

`CarSpecs` is the preferred source of runtime config when assigned. Legacy export fields remain on `PlayerCarController` only as scene compatibility fallback when `car_specs == null`.

Changing `car_specs` after the node is inside the tree calls `_reconfigure_drive_runtime(true)`, rebuilding config and reconfiguring powertrain/chassis while preserving motion state where possible and clamping the current gear to the new gear count.

## Intentionally unchanged

This refactor did not intentionally change:

- physics formulas;
- tuning values;
- resources;
- car scenes;
- AI;
- track generation;
- race flow;
- menu flow;
- UI;
- full-program smoke test flow.

## Validation

Runtime config model test:

```text
[CAR_RUNTIME_CONFIG_TEST] Passed: 19 checks
```

Full-program smoke test:

```text
[SMOKE] Extended full program smoke test passed: 79 checks
```

`git diff --check`:

```text
passed with no output
```

## Test coverage note

Added `scripts/tests/car_controller_runtime_config_test.gd` for config builder, geared-transmission checks, runtime state reset, and basic manual/automatic gear text formatting. Full vehicle physics remains covered by the existing full-program smoke test.

## Generated Godot uid files

Godot created `.gd.uid` files for the new scripts and test:

- `scripts/car/car_runtime_state.gd.uid`
- `scripts/car/car_drive_config.gd.uid`
- `scripts/car/car_drive_config_builder.gd.uid`
- `scripts/car/car_powertrain_controller.gd.uid`
- `scripts/car/car_chassis_controller.gd.uid`
- `scripts/car/car_reset_controller.gd.uid`
- `scripts/tests/car_controller_runtime_config_test.gd.uid`

During import Godot also re-created missing `.gd.uid` files for existing scripts:

- `scripts/game/car_selection_state.gd.uid`
- `scripts/game/menu_options_builder.gd.uid`
- `scripts/game/race_session_controller.gd.uid`

## Left for later

- Remove legacy export fields after scenes are migrated fully to specs/config resources.
- Split `CarSpecs` into sub-resources.
- Make larger vehicle physics model changes.
- Add fuller unit coverage for drive math.
