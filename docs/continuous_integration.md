# Continuous integration

The repository uses two required GitHub Actions workflows for pushes to `master`, pull requests targeting `master` and manual `workflow_dispatch` runs:

```text
.github/workflows/windows-tests.yml
.github/workflows/android-export.yml
```

Both workflows use Godot `4.7-stable`, cache matching export templates, cancel superseded runs on the same ref and retain build/diagnostic artifacts for 14 days. GitHub-maintained actions are pinned to full commit SHAs rather than mutable major-version tags.

## Windows gate

The Windows job runs on the explicit `windows-2025` image and executes:

1. download the Godot 4.7 console editor and the official `SHA512-SUMS.txt` file;
2. verify the editor archive SHA-512 checksum and engine version;
3. run the single project-verification entrypoint;
4. restore or install matching Windows export templates after verifying their SHA-512 checksum;
5. verify release and debug templates;
6. export the production and test presets;
7. smoke-test normal packaged startup;
8. smoke-test the packaged regression route;
9. upload the complete `build/` directory even after a failure when diagnostic files exist.

The authoritative local/CI verification entrypoint is:

```text
scripts/ci/verify_project.ps1
```

It runs the localization contract first and then delegates static checks, project import and all discovered Godot tests to:

```text
scripts/ci/run_tests.ps1
```

Using `run_tests.ps1` directly remains possible for focused test work, but it is not the complete repository gate because it intentionally does not duplicate localization orchestration.

### Static checks

`scripts/ci/run_static_checks.ps1` guards architectural contracts that are difficult to express as runtime assertions. Current checks include:

- mobile controls must not synthesize global input actions;
- high-level game/race/lap coordinators must not regain dynamic `call()`/`has_method()` fallback paths;
- gameplay modes, player indices and AI variant selection must remain explicit rather than falling back;
- opponent spawning must retain prepare-then-commit semantics;
- car specs and variant resources must not regain removed legacy fields;
- the track catalog must use explicit `default_track_id` ownership and must not use per-track boolean or first-entry fallbacks;
- the generated-track pipeline must retain typed config and mesh containers;
- both workflows must use explicit runner labels and full action commit SHAs;
- the Windows workflow must retain SHA-512 verification for downloaded Godot archives;
- required Windows/Android export settings must remain present;
- test scripts must be discoverable, referenced by a test scene, an editor launcher or an explicitly allowed helper;
- the canonical full-program scene must remain bound to the canonical smoke-test script.

### Automatic test discovery

The runner imports the project, then discovers:

- every `scripts/tests/*.gd` file whose top-level base is `SceneTree`;
- every `scenes/tests/*.tscn` file except packaged-only fixtures explicitly excluded by the runner.

This removes the need to maintain a duplicated handwritten test list. Adding a qualifying test automatically adds it to the Windows gate.

Each Godot invocation has:

- a separate timeout;
- a current-command marker;
- a combined stdout/stderr log under `build/test-logs/`;
- exit-code validation;
- scanning for `SCRIPT ERROR:`, `ERROR:` and editor-style `E 0:00:...` lines.

The runtime-error detector has its own self-check so a broken regex cannot silently make the suite permissive. `run_tests.ps1` preserves the localization log created by `verify_project.ps1` instead of deleting diagnostics from an earlier verification phase.

### Canonical full-program smoke test

The end-to-end scene is:

```text
scenes/tests/full_program_smoke_test.tscn
```

It must run:

```text
scripts/tests/full_program_smoke_test.gd
```

The scenario validates menu back-navigation, automatic and manual free drive, acceleration, steering, braking, reverse, reset, free-drive car switching, race participant setup, countdown locks, AI movement, result presentation, cleanup and post-race re-entry.

### Windows packaged validation

`scripts/ci/export_windows.ps1` produces the Windows release and test builds and validates two startup routes.

Normal packaged launch:

- starts at `scenes/startup.tscn`;
- receives no user argument;
- routes to `scenes/main.tscn`;
- writes a readiness marker only when the CI environment variable requests it.

Packaged smoke launch:

- passes `--export-smoke-test` after Godot's argument separator;
- routes to `scenes/tests/exported_build_smoke_test.tscn`;
- verifies required project settings, catalog resources, car scenes and generated-track/checkpoint runtime;
- must emit the expected success marker and return code `0`.

Successful artifacts are named:

```text
car-game-windows-<commit-sha>
```

They contain the generated executable/PCK, packaged smoke logs and per-command test diagnostics.

## Android gate

The Android job runs on the explicit `ubuntu-24.04` image with Java 17 and the runner-provided Android SDK. It executes:

1. validate localization catalogs;
2. download Godot 4.7 and verify its SHA-512 checksum;
3. restore or install matching export templates and verify their checksum;
4. configure Godot's Android SDK and Java paths;
5. import the project headlessly;
6. export and validate the debug APK;
7. upload `build/android/` even when validation fails after producing diagnostics.

The export/validation script is:

```text
scripts/ci/export_android.sh
```

It validates:

- a non-empty APK is produced;
- ZIP/archive integrity;
- application ID `com.dziuras98.cargame`;
- version name `0.1.0`;
- manifest extraction and SDK metadata through `apkanalyzer`;
- compiled package and application label through `aapt`;
- APK signature through `apksigner`;
- absence of obvious `res://scripts/tests/` and `res://scenes/tests/` paths in the production package.

The workflow deliberately does not invoke `adb`. Export correctness must not depend on a connected emulator or physical device. Device installation, graphics compatibility and touch usability remain manual/platform-lab tests.

Successful artifacts are named:

```text
car-game-android-<commit-sha>
```

They contain the APK, export log, validation log, extracted manifest and Android tool diagnostics.

## Running locally

Complete Windows project verification:

```powershell
./scripts/ci/verify_project.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Focused Windows tests without the localization orchestration step:

```powershell
./scripts/ci/run_tests.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Windows export and packaged smoke tests:

```powershell
./scripts/ci/export_windows.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Android export on Linux/macOS with a configured Android SDK:

```bash
chmod +x ./scripts/ci/export_android.sh
./scripts/ci/export_android.sh /path/to/Godot_v4.7-stable_linux.x86_64
```

Matching Godot 4.7 export templates are required for local export commands.

## Failure diagnosis

For Windows failures, inspect in this order:

1. `build/test-logs/localization-validation.log` when localization was reached;
2. `build/test-logs/current-command.log` when present;
3. `workflow-runner-failure.log`;
4. the log named after the failed import/script/scene command;
5. packaged startup/export logs.

For Android failures, inspect:

1. `android-export.log`;
2. `android-validation.log`;
3. `android-manifest.xml`;
4. `aapt-badging.txt` and `aapt-diagnostics.txt`;
5. `apksigner-verification.txt`.

A green PR requires both workflow conclusions to be `success` on the same head commit.
