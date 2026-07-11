# Continuous integration

The repository has one required GitHub Actions workflow for pushes to `master`, pull requests targeting `master` and manual `workflow_dispatch` runs:

```text
.github/workflows/windows-tests.yml
```

The workflow uses Godot `4.7-stable`, runs on the explicit `windows-2025` image, cancels superseded runs on the same ref and retains build/diagnostic artifacts for 14 days. GitHub-maintained actions are pinned to full commit SHAs rather than mutable major-version tags.

## Windows gate

The job executes:

1. download the Godot 4.7 console editor and the official `SHA512-SUMS.txt` file;
2. verify the editor archive SHA-512 checksum and engine version;
3. run the single project-verification entrypoint and finalize its complete JUnit report;
4. publish JUnit totals and failure details to the GitHub Actions job summary, including after a verification failure;
5. restore or install matching Windows export templates after verifying their SHA-512 checksum;
6. verify release and debug templates;
7. export the production and test presets;
8. smoke-test normal packaged startup;
9. smoke-test the packaged regression route;
10. upload the complete `build/` directory, including the JUnit report, even after a failure when diagnostic files exist.

The authoritative local/CI verification entrypoint is:

```text
scripts/ci/verify_project.ps1
```

It records the PowerShell preflight checks, runs the localization contract and then delegates static checks, project import and all discovered Godot tests to:

```text
scripts/ci/run_tests.ps1
```

Using `run_tests.ps1` directly remains possible for focused test work, but it is not the complete repository gate because its JUnit report intentionally excludes the preflight and localization phases owned by `verify_project.ps1`.

### Static checks

`scripts/ci/run_static_checks.ps1` guards architectural contracts that are difficult to express as runtime assertions. Current checks include:

- high-level game/race/lap coordinators must not regain dynamic `call()`/`has_method()` fallback paths;
- gameplay modes, player indices and AI variant selection must remain explicit rather than falling back;
- opponent spawning must retain prepare-then-commit semantics;
- car specs and variant resources must not regain removed legacy fields;
- the track catalog must use explicit `default_track_id` ownership and must not use per-track boolean or first-entry fallbacks;
- the generated-track pipeline must retain typed config and mesh containers;
- the project and export presets must retain the Windows renderer and both Windows package routes;
- the Windows workflow must use an explicit runner label, full action commit SHAs and SHA-512 verification for downloaded Godot archives;
- the canonical full-program scene must remain bound to the canonical smoke-test script.

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

This prevents helper-like or scene-bound scripts from being silently orphaned inside a nested directory. `scripts/ci/test_test_script_ownership.ps1` validates the algorithm against a temporary multi-level fixture: it detects a nested orphan, accepts a nested scene reference and detects the script again after that reference is removed.

Each Godot invocation has:

- a separate timeout;
- a current-command marker;
- a combined stdout/stderr log under `build/test-logs/`;
- exit-code validation;
- scanning for `SCRIPT ERROR:`, `ERROR:` and editor-style `E 0:00:...` lines;
- an individual JUnit testcase containing its status, duration and captured output.

The runtime-error detector has a dedicated regression test so a broken regex cannot silently make the suite permissive. `run_tests.ps1` preserves the localization log created by `verify_project.ps1` instead of deleting diagnostics from an earlier verification phase.

### JUnit diagnostics

The complete verification report is:

```text
build/test-logs/junit.xml
```

`verify_project.ps1` records these preflight cases before invoking Godot:

- export output-directory safety;
- Godot runtime-log validation;
- JUnit serialization and merge behavior;
- JUnit job-summary rendering and workflow wiring;
- recursive test-script ownership regression;
- recursive ownership validation of the repository test trees;
- localization validation.

`run_tests.ps1` independently records static checks, project import, both discovery phases and every discovered script/scene test. The top-level verifier writes a temporary preflight report outside `build/test-logs/`, then merges it with the runner report from a `finally` block. Therefore `junit.xml` contains all completed phases and the first recorded failure even when verification stops before the full suite finishes. The merge itself is covered by the JUnit regression test.

Each testcase includes its status, duration, failure message and captured output when available. Reports use UTF-8 without a byte-order mark, XML-safe text and invariant decimal formatting.

After the verification step, `scripts/ci/write_junit_step_summary.ps1` reads the final report and appends a compact Markdown summary to `$GITHUB_STEP_SUMMARY`. It displays the result, test count, failure count, total duration and up to 20 escaped failure rows. The step uses `if: always()`, so a valid partial report remains visible when verification fails. Missing, malformed or zero-test reports fail the summary step; recorded test failures are displayed without replacing the original verification failure.

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

### Packaged validation

`scripts/ci/export_windows.ps1` produces the release and test builds and validates two startup routes.

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

They contain the generated executable/PCK, packaged smoke logs, per-command test diagnostics and the complete `build/test-logs/junit.xml` report.

## Running locally

Complete project verification:

```powershell
./scripts/ci/verify_project.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Focused tests without the preflight and localization orchestration:

```powershell
./scripts/ci/run_tests.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Production/test export and packaged smoke tests:

```powershell
./scripts/ci/export_windows.ps1 `
    -GodotBinary "C:\path\to\Godot_v4.7-stable_win64_console.exe"
```

Matching Godot 4.7 Windows export templates are required for local export commands.

## Failure diagnosis

Inspect in this order:

1. the GitHub Actions job summary for totals and the first failure rows;
2. `build/test-logs/junit.xml` for the completed phase list and full structured failure data;
3. `build/test-logs/localization-validation.log` when localization was reached;
4. `build/test-logs/current-command.log` when present;
5. `workflow-runner-failure.log`;
6. the log named after the failed import/script/scene command;
7. packaged startup/export logs.

A green pull request requires the Windows workflow conclusion to be `success` on the current head commit.
