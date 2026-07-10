# Continuous integration

## Platform policy

Windows is the primary target platform for the game. The required GitHub Actions test suite therefore runs on a GitHub-hosted Windows runner.

Android remains a manual compatibility and general-behavior test platform. Android export and device testing are not part of the required CI gate at this stage.

## Workflow

The workflow is defined in:

```text
.github/workflows/windows-tests.yml
```

It runs:

- after pushes to `master`;
- for pull requests targeting `master`;
- when started manually through `workflow_dispatch`.

The workflow downloads the official Godot 4.7 stable Windows editor build, uses its console executable, imports project resources and runs the complete automated test suite in headless mode.

Completed development stages are published to `master` as one atomic commit. This avoids cancelling an in-progress workflow through the workflow concurrency policy.

## Test runner

The shared Windows test runner is:

```text
scripts/ci/run_tests.ps1
```

The runner executes:

```text
scripts/tests/car_controller_runtime_config_test.gd
scenes/tests/car_catalog_validation_test.tscn
scenes/tests/car_specs_runtime_reconfiguration_test.tscn
scenes/tests/car_powertrain_controller_test.tscn
scenes/tests/car_chassis_motion_test.tscn
scenes/tests/track_layout_builder_test.tscn
scenes/tests/track_layout_resource_test.tscn
scenes/tests/lap_tracker_checkpoint_test.tscn
scenes/tests/full_program_smoke_test.tscn
```

The run stops immediately when resource import or any test returns a non-zero exit code. The focused checkpoint test runs before the full-program smoke test so sequence, direction or gate-generation failures are isolated.

## Running the suite locally on Windows

From the repository root, run:

```powershell
./scripts/ci/run_tests.ps1 -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

The supplied binary must be the Godot editor console executable, not an exported game or export template.

## Future platform checks

Potential later additions:

- a Windows export smoke check after `export_presets.cfg` is added;
- a scheduled performance test with several AI opponents;
- an optional manually triggered Android export check;
- artifact upload for test logs and exported Windows builds.
