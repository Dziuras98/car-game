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

The script:

1. clears `build/windows`;
2. exports the `Windows Desktop` release preset;
3. verifies that both the executable and PCK were created;
4. starts the exported executable in headless mode;
5. runs `scenes/tests/exported_build_smoke_test.tscn` from the exported package;
6. requires a zero process exit code and a success marker in the generated log.

The exported-build smoke test validates that the release package contains the main scene, car catalog, both 370Z variants, the track Resource and the generated racing-line/checkpoint APIs.

## Continuous integration

The required Windows workflow installs or restores the matching export templates after the editor test suite passes. It then runs the same export script and uploads:

```text
build/windows/
```

as an Actions artifact named:

```text
car-game-windows-<commit-sha>
```

Artifacts are retained for 14 days and contain the executable, PCK and exported-build smoke log.

## Distribution status

The current preset is an unsigned development build. It does not configure Authenticode signing, an installer, automatic updates or store packaging. Windows may display a reputation warning when the downloaded artifact is launched manually.
