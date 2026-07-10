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
5. launch the exported executable without user arguments and verify that the normal main scene becomes ready;
6. launch the exported executable with `--export-smoke-test` and run the packaged regression scene;
7. upload any available Windows build and diagnostic files.

The job fails when any test, export or exported executable returns a non-zero exit code or omits an expected readiness marker. The editor/headless runner also captures both output streams and fails when Godot emits a runtime-error line such as `SCRIPT ERROR:`, `ERROR:` or the editor-style `E 0:00:...` prefix, even when Godot incorrectly exits with code `0`. The artifact upload uses `always()` so files already produced by a failed test or export stage remain available for diagnosis.

## Editor/headless test runner

The shared test runner is:

```text
scripts/ci/run_tests.ps1
```

It executes:

```text
scripts/tests/startup_router_test.gd
scripts/tests/car_controller_runtime_config_test.gd
scripts/tests/speedometer_car_binding_test.gd
scripts/tests/tire_squeal_audio_binding_test.gd
scripts/tests/legacy_controller_property_access_test.gd
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

The startup-router test verifies the configured project entry scene and both routing outcomes: ordinary arguments select `scenes/main.tscn`, while `--export-smoke-test` selects the packaged smoke scene.

The speedometer binding test instantiates the automatic 370Z and the production speedometer scene, verifies that the car has visible mesh geometry and confirms that the tachometer range comes from the selected variant's `CarSpecs` resource.

The tire-squeal audio test instantiates the automatic 370Z, verifies that procedural tire audio reads its speed normalization from the selected variant's `CarSpecs` resource and generates finite, bounded samples under forced slip.

The legacy controller-property test scans GDScript source for variables typed or cast as `PlayerCarController` and rejects direct reads of tuning fields removed during the `CarSpecs` refactor. Consumers must use `car_specs` or a public controller method instead. The detector includes positive and negative fixtures so a broken scanner cannot silently pass.

The PowerShell runner performs its own detector self-check and then evaluates the complete stdout/stderr output of every import, script test and scene test. This closes the gap where a GDScript runtime error is printed but the test process still returns a successful exit code. Each command receives a separate log under `build/test-logs/`.

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
build/windows/normal-startup-smoke.log
build/windows/exported-build-smoke.log
```

The exported executable starts through:

```text
scenes/startup.tscn
```

The first packaged launch passes no user arguments, so `scripts/game/startup_router.gd` must select `scenes/main.tscn`. CI supplies only the process environment variable `CAR_GAME_NORMAL_STARTUP_MARKER_PATH`. After the main scene completes its deferred startup, `main_scene_startup_marker.gd` writes the requested marker file and exits that test process with code `0`. Without the environment variable, normal game launches continue running and the marker node has no effect.

The second packaged launch passes `--export-smoke-test` after Godot's `--` separator. The router opens `scenes/tests/exported_build_smoke_test.tscn`, avoiding the unsupported `--scene` path override in official Windows export templates.

The packaged regression scene confirms that the release contains project settings, the car catalog, both 370Z scenes, the main scene and the generated track/checkpoint runtime. A successful process exit without the expected log marker is still treated as failure.

Godot export templates are cached by engine version. On a cache miss, the workflow downloads the official `Godot_v4.7-stable_export_templates.tpz` archive and installs its templates under the normal Windows Godot data directory.

## Build artifact

The workflow attempts to upload the entire `build/` directory even when a preceding stage fails, provided that diagnostic or export files exist. Successful runs publish it as:

```text
car-game-windows-<commit-sha>
```

The artifact is retained for 14 days. It contains the unsigned development executable, its PCK, both packaged smoke-test logs and the per-command editor/headless logs from `build/test-logs/`. Failed runs can contain a partial build, the workflow-wrapper failure report and whichever command logs were produced before the failure.

## Running locally on Windows

Run the editor/headless regression suite:

```powershell
./scripts/ci/run_tests.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Run the Windows release export and packaged-startup smoke tests:

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
