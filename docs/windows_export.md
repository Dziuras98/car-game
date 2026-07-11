# Windows export

The project defines one release preset:

```text
export_presets.cfg
Windows Desktop
```

The preset exports a 64-bit Windows build to:

```text
build/windows/car-game.exe
build/windows/car-game.pck
```

The PCK remains separate from the executable so the exported data package can be inspected and replaced independently during development.

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

1. validates both output paths and clears `build/windows` and `build/windows-test`;
2. exports the `Windows Desktop` release preset;
3. verifies that both the executable and PCK were created;
4. starts the exported executable without user arguments;
5. supplies `CAR_GAME_NORMAL_STARTUP_MARKER_PATH`, waits for `scenes/main.tscn` to write the readiness marker and requires the process to exit with code `0`;
6. starts the executable again and passes `--export-smoke-test` after Godot's `--` separator;
7. requires a zero exit code and the packaged regression success marker.

The exported project starts with `scenes/startup.tscn`. Its router opens `scenes/main.tscn` during ordinary launches and `scenes/tests/exported_build_smoke_test.tscn` when the smoke-test argument is present. The argument-based route is required because official Windows export templates do not support the `--scene` path override.

The environment variable affects only the CI handshake after the normal main scene is ready; it is not a user argument and does not alter router selection. Without it, the exported game continues running normally.

The normal launch writes `build/windows/normal-startup-smoke.log`. The packaged regression launch writes `build/windows/exported-build-smoke.log` and validates that the release contains the main scene, car catalog, both 370Z variants, the track Resource and the generated racing-line/checkpoint APIs.

## Continuous integration

The required Windows workflow installs or restores the matching export templates after the editor test suite passes. It then runs the same export script and attempts to upload:

```text
build/windows/
```

as an Actions artifact named:

```text
car-game-windows-<commit-sha>
```

The upload step runs even after a preceding failure so partial builds and available logs remain inspectable. Successful artifacts are retained for 14 days and contain the executable, PCK and both packaged-startup logs.

## Distribution status

The current preset is an unsigned development build. It does not configure Authenticode signing, an installer, automatic updates or store packaging. Windows may display a reputation warning when the downloaded artifact is launched manually.
