# Continuous integration

## Platform policy

Windows is the primary target platform for the game. The required GitHub Actions suite therefore runs on a GitHub-hosted Windows runner.

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

The job downloads the official Godot 4.7 stable Windows editor build and uses its console executable. Completed development stages are published to `master` as one atomic commit so the workflow concurrency policy does not cancel an earlier stage run.

The required job performs these stages in order:

1. verify the Godot version;
2. import project resources and run the editor/headless regression suite;
3. restore or install the matching Godot 4.7 export templates;
4. export the `Windows Desktop` release preset;
5. launch the exported executable in headless mode and run the exported-build smoke scene;
6. upload the Windows build directory as a workflow artifact.

The job stops immediately when any test, export or exported executable returns a non-zero exit code.

## Editor/headless test runner

The shared test runner is:

```text
scripts/ci/run_tests.ps1
```

It executes:

```text
scripts/tests/car_controller_runtime_config_test.gd
scenes/tests/car_catalog_validation_test.tscn
scenes/tests/car_specs_runtime_reconfiguration_test.tscn
scenes/tests/car_powertrain_controller_test.tscn
scenes/tests/car_chassis_motion_test.tscn
scenes/tests/track_layout_builder_test.tscn
scenes/tests/track_layout_resource_test.tscn
scenes/tests/lap_tracker_checkpoint_test.tscn
scenes/tests/performance_regression_test.tscn
scenes/tests/full_program_smoke_test.tscn
```

Focused geometry, checkpoint and performance tests run before the full-program smoke test so subsystem failures remain isolated.

The performance regression test logs wall-clock timings for diagnostics, but pass/fail decisions use deterministic operation budgets. This avoids false failures caused by variable GitHub-hosted runner load.

## Windows export gate

The release preset is defined in:

```text
export_presets.cfg
```

The export and packaged-build runner is:

```text
scripts/ci/export_windows.ps1
```

It creates:

```text
build/windows/car-game.exe
build/windows/car-game.pck
build/windows/exported-build-smoke.log
```

The exported executable starts through:

```text
scenes/startup.tscn
```

For ordinary launches, `scripts/game/startup_router.gd` opens `scenes/main.tscn`. The smoke runner passes the user argument `--export-smoke-test` after Godot's `--` separator, causing the router to open `scenes/tests/exported_build_smoke_test.tscn` instead. This avoids the unsupported `--scene` path override in official Windows export templates.

The smoke scene confirms that the release package can load project settings, the car catalog, both 370Z scenes, the main scene and the generated track/checkpoint runtime. A successful process exit without the expected log marker is still treated as failure.

Godot export templates are cached by engine version. On a cache miss, the workflow downloads the official `Godot_v4.7-stable_export_templates.tpz` archive and installs its templates under the normal Windows Godot data directory.

## Build artifact

After all tests and the exported-build smoke check pass, the workflow uploads `build/windows/` as:

```text
car-game-windows-<commit-sha>
```

The artifact is retained for 14 days and contains the unsigned development executable, its PCK and the smoke-test log.

## Running locally on Windows

Run the editor/headless regression suite:

```powershell
./scripts/ci/run_tests.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Run the Windows release export and exported-build smoke test:

```powershell
./scripts/ci/export_windows.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

The supplied binary must be the Godot editor console executable. The export command also requires matching Godot 4.7 stable export templates to be installed.

## Future platform checks

Potential later additions:

- an optional manually triggered Android export check;
- code signing and installer validation when distribution requirements are defined;
- longer-lived release artifacts for tagged builds.
