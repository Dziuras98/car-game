# Continuous integration

The repository uses two required GitHub Actions workflows for pushes to `master`, pull requests targeting `master` and manual `workflow_dispatch` runs:

```text
.github/workflows/windows-tests.yml
.github/workflows/android-export.yml
```

Both workflows use Godot `4.7-stable`, cache matching export templates, cancel superseded runs on the same ref and retain build/diagnostic artifacts for 14 days.

## Windows gate

The Windows job runs on `windows-latest` and executes:

1. download the Godot 4.7 console editor;
2. verify the engine version;
3. run static checks, project import and all discovered regression tests;
4. restore or install matching Windows export templates;
5. verify release and debug templates;
6. export the production and test presets;
7. smoke-test normal packaged startup;
8. smoke-test the packaged regression route;
9. upload the complete `build/` directory even after a failure when diagnostic files exist.

The shared runner is:

```text
scripts/ci/run_tests.ps1
```

### Static checks

`scripts/ci/run_static_checks.ps1` guards architectural contracts that are difficult to express as runtime assertions. Current checks include:

- mobile controls must not synthesize global input actions;
- high-level game/race/lap coordinators must not regain dynamic `call()`/`has_method()` fallback paths;
- car specs and variant resources must not regain removed legacy fields;
- the track catalog must use explicit `default_track_id` ownership and must not use per-track boolean or first-entry fallbacks;
- the generated-track pipeline must retain typed config and mesh containers;
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

The runtime-error detector has its own self-check so a broken regex cannot silently make the suite permissive.

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

The Android job runs on `ubuntu-latest` with Java 17 and the runner-provided Android SDK. It executes:

1. download Godot 4.7 and verify its SHA-512 checksum;
2. restore or install matching export templates and verify their checksum;
3. configure Godot's Android SDK and Java paths;
4. import the project headlessly;
5. export and validate the debug APK;
6. upload `build/android/` even when validation fails after producing diagnostics.

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

Windows tests:

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

1. `build/test-logs/current-command.log` when present;
2. `workflow-runner-failure.log`;
3. the log named after the failed import/script/scene command;
4. packaged startup/export logs.

For Android failures, inspect:

1. `android-export.log`;
2. `android-validation.log`;
3. `android-manifest.xml`;
4. `aapt-badging.txt` and `aapt-diagnostics.txt`;
5. `apksigner-verification.txt`.

A green PR requires both workflow conclusions to be `success` on the same head commit.
