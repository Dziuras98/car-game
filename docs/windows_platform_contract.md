# Windows platform contract

Windows is the sole supported platform for the current project baseline. The authoritative repository validation is:

```text
scripts/ci/validate_windows_platform_contract.ps1
```

The validator uses the reusable parser and contract implementation in `scripts/ci/windows_platform_contract.ps1`. It reads the configuration by section instead of relying only on unrelated substring checks.

## Project renderer

`project.godot` must define the Windows rendering driver as D3D12:

```text
rendering_device/driver.windows="d3d12"
```

## Export presets

`export_presets.cfg` must contain exactly two primary presets:

- `Windows Desktop`, runnable, exported to `build/windows/car-game.exe`;
- `Windows Test`, non-runnable, carrying the `export_smoke_test` feature and exported to `build/windows-test/car-game-test.exe`.

Both presets must:

- target `Windows Desktop`;
- use the `x86_64` binary architecture;
- enable S3TC/BPTC texture output;
- disable ETC2/ASTC texture output.

Any additional platform preset fails verification.

## Workflow

Every job in `.github/workflows/windows-tests.yml` must run on the explicit `windows-2025` image. The workflow must retain:

- the Win64 Godot editor archive and console executable;
- the Win64 release and debug export templates;
- `scripts/ci/verify_project.ps1` as the complete repository gate;
- `scripts/ci/export_windows.ps1` as the package/export entrypoint.

## Regression coverage

`scripts/ci/test_windows_platform_contract.ps1` builds temporary configuration fixtures and verifies detection of:

- a non-D3D12 renderer;
- an additional Linux preset;
- non-x86_64 exports;
- a non-Windows workflow runner;
- replacement of the canonical Windows export entrypoint.

Both the regression suite and validation of the real repository are recorded by `verify_project.ps1` in the complete JUnit report. A pull request is not mergeable until the complete Windows workflow succeeds on its current head commit.
