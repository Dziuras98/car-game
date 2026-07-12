# Continuous integration

The repository has one required GitHub Actions workflow for pushes to `master`, pull requests targeting `master` and manual `workflow_dispatch` runs:

```text
.github/workflows/windows-tests.yml
```

The workflow uses Godot `4.7-stable`, runs on the explicit `windows-2025` image and retains diagnostics for 14 days. Superseded pull-request runs may be cancelled; authoritative `master` pushes and manually dispatched runs are never cancelled by newer executions. GitHub-maintained actions are pinned to full commit SHAs rather than mutable major-version tags. Dependabot proposes weekly updates for those pinned actions through `.github/dependabot.yml`.

## Windows gate

The job executes:

1. check out all reachable history and tags without persisting checkout credentials;
2. download the Godot 4.7 Windows console editor archive;
3. verify the editor archive against the reviewed SHA-512 value stored in `scripts/ci/godot_4_7_sha512.txt`;
4. verify the engine version;
5. run the single project-verification entrypoint and finalize its complete JUnit report;
6. publish JUnit totals and failure details to the GitHub Actions job summary, including after a verification failure;
7. restore or download the export-template archive cache;
8. verify the cached or downloaded template archive against the same repository-owned manifest on every run;
9. extract and install matching Windows release/debug templates from the verified archive;
10. derive package versions from the semantic tag or current commit SHA and workflow run number;
11. export the production and test presets;
12. restore the committed export-preset contents in a `finally` block;
13. smoke-test normal packaged startup and the packaged regression route;
14. upload test and export-smoke diagnostics for every run;
15. upload executable Windows packages only for successful trusted non-pull-request events, failing when expected package directories are absent.

The checksum manifest is an explicit trust root reviewed with source changes. CI does not download `SHA512-SUMS.txt` from the same release endpoint as the archives. Updating Godot therefore requires an intentional pull request that changes the engine version, archive names and reviewed checksum manifest together.

The cache stores the original export-template archive, not an already extracted executable directory. A cache hit therefore does not bypass integrity verification.

Pull-request artifacts are intentionally limited to diagnostic text/XML output:

```text
build/test-logs/
build/windows/*.log
build/windows-test/*.log
```

Executables and PCK files are generated for validation but are not published from PR-triggered runs. Push and manual runs may publish:

```text
build/windows/
build/windows-test/
```

## Verification entrypoint

The authoritative local/CI verification entrypoint is:

```text
scripts/ci/verify_project.ps1
```

It records all PowerShell preflight checks, runs the localization contract and then delegates static checks, project import and all discovered Godot tests to:

```text
scripts/ci/run_tests.ps1
```

Using `run_tests.ps1` directly remains possible for focused test work, but it is not the complete repository gate because its JUnit report intentionally excludes preflight, supply-chain, export-version and localization phases owned by `verify_project.ps1`.

### Public-repository safety checks

The complete verifier runs both current-tree and complete-history safety controls:

- `validate_public_repository_safety.ps1` rejects credential-like filenames, private-key headers, supported token formats and local user-profile paths in the current checkout;
- `validate_git_history_safety.ps1` scans all reachable refs for equivalent high-risk content and filenames;
- a deleted-secret regression fixture proves that content removed from the current tree remains detectable in history;
- non-`noreply` commit addresses are rejected unless explicitly declared as intentionally public.

These repository-owned checks are heuristic safeguards. They complement, rather than replace, GitHub secret scanning or another independently maintained scanner.

### Windows and supply-chain preflights

`scripts/ci/windows_platform_contract.ps1` owns the Windows-only platform contract. It verifies:

- D3D12 is the configured Windows rendering driver;
- exactly two x86-64 Windows Desktop export presets exist;
- the workflow uses `windows-2025` and canonical verification/export entrypoints;
- pull-request-only cancellation and strict trusted-package publication remain configured;
- `GODOT_CHECKSUMS_FILE` points to `scripts/ci/godot_4_7_sha512.txt`;
- the workflow does not reintroduce a downloaded `SHA512-SUMS.txt` trust path.

`scripts/ci/test_windows_platform_contract.ps1` validates positive and negative temporary fixtures. `scripts/ci/test_godot_checksum_manifest.ps1` separately requires exactly the reviewed editor and export-template archives, exact 128-character SHA-512 values, no duplicates and no unexpected entries.

### Export versions

`scripts/ci/export_version.ps1` derives version metadata without mutating committed repository state:

- a semantic tag such as `v2.3.4` produces product version `2.3.4`;
- an untagged build produces a product version containing the seven-character source SHA;
- the numeric Windows file version uses semantic components and the bounded GitHub Actions run number;
- the packaged regression preset receives the same identity with a `-test` suffix.

`scripts/ci/export_windows.ps1` saves the original `export_presets.cfg`, injects both production and test metadata, performs all exports and smoke tests, and restores the exact original contents in `finally`. `scripts/ci/test_export_version.ps1` covers tagged, branch and two-preset mutation behavior.

### Static checks

`scripts/ci/run_static_checks.ps1` guards architectural contracts that are difficult to express as runtime assertions. Current checks include:

- high-level game/race/lap coordinators must not regain dynamic production fallback paths;
- gameplay modes are owned by `GameModes`, and player indices and AI variant selection remain explicit rather than falling back;
- opponent spawning must retain prepare-then-commit semantics;
- car catalogs, models, variants and specs must retain authoritative validation paths;
- the track catalog must use explicit `default_track_id` ownership and must not use per-track boolean or first-entry fallbacks;
- the generated-track pipeline must retain typed config and mesh containers;
- the project and export presets must retain the Windows renderer and both Windows package routes;
- actions remain SHA-pinned, history checkout remains complete, checkout credentials remain disabled and pull-request runs do not publish executable package artifacts;
- the canonical full-program scene remains bound to the canonical smoke-test script.

### Automatic test discovery

The runner imports the project, then recursively discovers:

- every `scripts/tests/**/*.gd` file whose top-level base is `SceneTree`;
- every `scenes/tests/**/*.tscn` file except packaged-only fixtures explicitly excluded by the runner.

This removes the need to maintain a duplicated handwritten test list. Adding a qualifying test at any directory depth automatically adds it to the Windows gate. Dedicated nested discovery fixtures are required by the runner so removing recursive enumeration cannot silently reduce test coverage.

### Test script ownership

`scripts/ci/validate_test_script_ownership.ps1` recursively scans both `scripts/tests/**` and `scenes/tests/**`. Every GDScript under the test tree must satisfy at least one ownership rule:

- it is a standalone `SceneTree` test discovered by the runner;
- it is an `EditorScript` launcher;
- a test scene references it through `res://scripts/tests/...`;
- it is listed as an explicit helper.

This prevents helper-like or scene-bound scripts from being silently orphaned inside a nested directory.

Each Godot invocation has:

- a separate timeout;
- a current-command marker;
- a combined stdout/stderr log under `build/test-logs/`;
- exit-code validation;
- scanning for `SCRIPT ERROR:`, `ERROR:` and editor-style `E 0:00:...` lines;
- scanning for `WARNING:` and editor-style `W 0:00:...` lines;
- exact, anchored warning allowlists assigned only to the negative-path tests that intentionally emit them;
- an individual JUnit testcase containing its status, duration and captured output.

Unexpected warnings are failures even when Godot exits with code `0`. This includes importer warnings, invalid UID fallbacks and `ObjectDB` leak diagnostics. The runtime-log validator has a dedicated regression test covering errors, warnings, ANSI escapes, duplicate lines, allowlist matches, allowlist misses and leaked-object warnings.

### JUnit diagnostics

The complete verification report is:

```text
build/test-logs/junit.xml
```

`verify_project.ps1` records preflight cases including:

- export output-directory safety;
- current-snapshot and complete-history repository safety;
- Windows platform and pinned-checksum contracts;
- source-derived export versioning;
- Godot runtime-log validation;
- JUnit serialization, merging and summary rendering;
- recursive test-script ownership;
- input-action ownership;
- localization validation.

`run_tests.ps1` independently records static checks, project import, both discovery phases and every discovered script/scene test. The top-level verifier writes a temporary preflight report outside `build/test-logs/`, then merges it with the runner report from a `finally` block. Therefore `junit.xml` contains all completed phases and the first recorded failure even when verification stops before the full suite finishes.

After the verification step, `scripts/ci/write_junit_step_summary.ps1` reads the final report and appends a compact Markdown summary to `$GITHUB_STEP_SUMMARY`. The step uses `if: always()`, so a valid partial report remains visible when verification fails.

### Canonical full-program smoke test

The end-to-end scene is:

```text
scenes/tests/full_program_smoke_test.tscn
```

It runs `scripts/tests/full_program_smoke_test.gd` and validates menu navigation, automatic and manual free drive, acceleration, steering, braking, reverse, reset, car switching, race participant setup, countdown locks, AI movement, result presentation, cleanup and post-race re-entry.

### Packaged validation

`scripts/ci/export_windows.ps1` produces the release and test builds and validates two startup routes.

Normal packaged launch:

- starts at `scenes/startup.tscn`;
- receives no user argument;
- routes to `scenes/main.tscn`;
- writes a readiness marker only when the CI environment variable requests it;
- exits non-zero when main-scene initialization fails.

Packaged smoke launch:

- passes `--export-smoke-test` after Godot's argument separator;
- routes to `scenes/tests/exported_build_smoke_test.tscn`;
- verifies required project settings, catalog resources, car scenes and generated-track/checkpoint runtime;
- must emit the expected success marker and return code `0`.

The PR diagnostics artifact contains the corresponding startup logs when they are created:

```text
build/windows/normal-startup-smoke.log
build/windows/production-smoke-argument.log
build/windows-test/exported-build-smoke.log
```

Diagnostic artifacts are named `car-game-diagnostics-<commit-sha>`. Trusted push/manual package artifacts are named `car-game-windows-<commit-sha>`.

## Running locally

Complete project verification:

```powershell
./scripts/ci/verify_project.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Focused tests without preflight and localization orchestration:

```powershell
./scripts/ci/run_tests.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Production/test export and packaged smoke tests:

```powershell
./scripts/ci/export_windows.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Matching Godot 4.7 Windows export templates are required for local export commands. Local untagged exports use the current Git commit when available and `unknown` only when no source revision can be resolved.

## Required repository settings

The workflow should be configured as a required status check for `master` through a branch-protection rule or repository ruleset. The intended settings are:

- require pull requests before merging;
- require the current Windows workflow check to pass;
- require branches to be up to date before merging;
- block force pushes and branch deletion;
- require at least one approval when external collaborators are accepted.

These settings live in GitHub repository configuration rather than version-controlled files.

## Failure diagnosis

Inspect in this order:

1. the GitHub Actions job summary for totals and the first failure rows;
2. `build/test-logs/junit.xml` for the completed phase list and full structured failure data;
3. repository-safety and localization logs;
4. `build/test-logs/current-command.log` when present;
5. `workflow-runner-failure.log`;
6. the log named after the failed import/script/scene command;
7. packaged startup/export logs under `build/windows/` or `build/windows-test/`.

A green pull request requires the Windows workflow conclusion to be `success` on the current head commit.
