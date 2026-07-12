# Windows export

The project defines two Windows Desktop presets in `export_presets.cfg`:

```text
Windows Desktop
Windows Test
```

The production preset exports a 64-bit Windows build to:

```text
build/windows/car-game.exe
build/windows/car-game.pck
```

The packaged regression preset exports to:

```text
build/windows-test/car-game-test.exe
build/windows-test/car-game-test.pck
```

The PCK remains separate from the executable so the exported data package can be inspected independently during development.

## Local export

Requirements:

- Godot 4.7 stable Windows editor console executable;
- matching Godot 4.7 stable export templates installed through the editor template manager;
- PowerShell 7 or Windows PowerShell compatible with the repository scripts.

From the repository root, run:

```powershell
./scripts/ci/export_windows.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Optional `-OutputDirectory` and `-TestOutputDirectory` overrides must resolve to separate, non-nested descendants of the repository `build` directory. The exporter rejects the repository root, the `build` root, paths outside `build`, existing files and paths that pass through symbolic links or junctions before it removes any previous artifacts.

The script:

1. resolves the current source revision and semantic tag when available;
2. temporarily injects source-derived product and numeric file versions into both Windows presets;
3. validates both output paths and clears `build/windows` and `build/windows-test`;
4. exports the `Windows Desktop` release preset;
5. verifies that both the executable and PCK were created and validates production PCK contents;
6. starts the production executable without `--headless`, using the normal configured renderer and a deterministic dummy audio driver;
7. requires both the passive `[GAME_READY] Main scene initialized` log message and a native Windows application window, then terminates the long-running game process externally;
8. starts the production executable again with `--export-smoke-test` and requires the same normal windowed startup, proving that private packaged-test routing is unavailable in production;
9. exports and runs the `Windows Test` preset with the private end-to-end smoke argument in headless mode;
10. starts the test executable again in windowed mode with `--live-audio-smoke-test`, requires a native window and verifies repeated live `AudioStreamGeneratorPlayback` buffer refills;
11. requires zero exit codes for self-terminating tests, their explicit success markers and runtime logs without `SCRIPT ERROR:`, `ERROR:` or timestamped Godot `E` entries;
12. restores the exact committed `export_presets.cfg` contents in a `finally` block after success or failure.

The production scene contains no CI environment-variable hook, marker-file writer or test-owned quit path. `MainSceneReadinessReporter` only publishes a passive diagnostic line after `GameManager` has completed its required initialization contracts.

## Version metadata

`scripts/ci/export_version.ps1` derives package identity as follows:

- a tag such as `v2.3.4` produces product version `2.3.4` and test product version `2.3.4-test`;
- an untagged build includes the seven-character commit SHA in both product versions;
- the Windows numeric file version uses the semantic components plus the bounded GitHub Actions run number;
- local exports resolve `git rev-parse HEAD` when `GITHUB_SHA` is unavailable.

The static values committed in `export_presets.cfg` are development defaults only. Exported artifacts receive derived values without leaving the working tree modified.

## Startup routes

The exported project starts with `scenes/startup.tscn`. Its router opens `scenes/main.tscn` during ordinary launches. A `Windows Test` export may additionally route:

- `--export-smoke-test` to `scenes/tests/exported_build_smoke_test.tscn`;
- `--live-audio-smoke-test` to `scenes/tests/live_audio_smoke_test.tscn`.

Production exports ignore both private arguments. Argument-based routing is required because official Windows export templates do not support the `--scene` path override.

The normal windowed launch writes `build/windows/normal-startup-smoke.log`. The production argument-isolation check writes `build/windows/production-smoke-argument.log`. The packaged regression launch writes `build/windows-test/exported-build-smoke.log`. The windowed audio validation writes `build/windows-test/live-audio-smoke.log`. All logs are checked by the shared runtime-error detector used by the editor-side test runner.

## Continuous integration

The required Windows workflow installs or restores the matching export templates after the editor test suite passes. The editor and template archives are verified against `scripts/ci/godot_4_7_sha512.txt`, not against a checksum file downloaded from the same release endpoint.

Pull-request runs retain diagnostic logs but do not publish executable packages. Successful trusted push and manual runs upload both:

```text
build/windows/
build/windows-test/
```

as an Actions artifact named:

```text
car-game-windows-<commit-sha>
```

The trusted upload fails when either expected package directory is absent. Artifacts are retained for 14 days.

## Distribution status

The current presets produce unsigned development builds. They do not configure Authenticode signing, an installer, automatic updates or store packaging. Windows may display a reputation warning when a downloaded artifact is launched manually.
