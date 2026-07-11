# Continuous integration

The repository has one required GitHub Actions workflow for pushes to `master`, pull requests targeting `master` and manual `workflow_dispatch` runs:

```text
.github/workflows/windows-tests.yml
```

The workflow uses Godot `4.7-stable`, runs on the explicit `windows-2025` image, cancels superseded runs on the same ref and retains diagnostics for 14 days. GitHub-maintained actions are pinned to full commit SHAs rather than mutable major-version tags. Dependabot proposes weekly updates for those pinned actions through `.github/dependabot.yml`.

## Windows gate

The job executes:

1. check out all reachable history and tags without persisting checkout credentials;
2. download the Godot 4.7 console editor and the official `SHA512-SUMS.txt` file;
3. verify the editor archive SHA-512 checksum and engine version;
4. run the single project-verification entrypoint and finalize its complete JUnit report;
5. publish JUnit totals and failure details to the GitHub Actions job summary, including after a verification failure;
6. restore or download the export-template archive cache;
7. verify the cached or downloaded archive against the official SHA-512 list on every run;
8. extract and install matching Windows release/debug templates from the verified archive;
9. export the production and test presets;
10. smoke-test normal packaged startup and the packaged regression route;
11. upload diagnostics for every run;
12. upload executable Windows packages only for trusted non-pull-request events.

The cache stores the original export-template archive, not an already extracted executable directory. A cache hit therefore does not bypass integrity verification.

Pull-request artifacts are intentionally limited to `build/test-logs/`. Executables and PCK files are generated for validation but are not published from PR-triggered runs. Push and manual runs may publish:

```text
build/windows/
build/windows-test/
```

The authoritative local/CI verification entrypoint is:

```text
scripts/ci/verify_project.ps1
```

It records the PowerShell preflight checks, runs the localization contract and then delegates static checks, project import and all discovered Godot tests to:

```text
scripts/ci/run_tests.ps1
```

Using `run_tests.ps1` directly remains possible for focused test work, but it is not the complete repository gate because its JUnit report intentionally excludes the preflight and localization phases owned by `verify_project.ps1`.

### Public-repository safety checks

The complete verifier runs both current-tree and complete-history safety controls:

- `validate_public_repository_safety.ps1` rejects credential-like filenames, private-key headers, supported token formats and local user-profile paths in the current checkout;
- `validate_git_history_safety.ps1` scans all reachable refs for equivalent high-risk content and filenames;
- a deleted-secret regression fixture proves that content removed from the current tree remains detectable in history;
- non-`noreply` commit addresses are rejected unless explicitly declared as intentionally public.

These repository-owned checks are heuristic safeguards. They complement, rather than replace, GitHub secret scanning or another independently maintained scanner.

### Static checks

`scripts/ci/run_static_checks.ps1` guards architectural contracts that are difficult to express as runtime assertions. Current checks include:

- high-level game/race/lap coordinators must not regain dynamic `call()`/`has_method()` fallback paths;
- gameplay modes are owned by `GameModes`, and player indices and AI variant selection remain explicit rather than falling back;
- opponent spawning must retain prepare-then-commit semantics;
- car catalogs, models, variants and specs must retain authoritative validation paths;
- car specs and variant resources must not regain removed legacy fields;
- the track catalog must use explicit `default_track_id` ownership and must not use per-track boolean or first-entry fallbacks;
- the generated-track pipeline must retain typed config and mesh containers;
- the project and export presets must retain the Windows renderer and both Windows package routes;
- the Windows workflow must use an explicit runner label, full action commit SHAs, complete history, non-persisted checkout credentials and SHA-512 verification for cached/downloaded Godot archives;
- pull-request runs must not publish executable package artifacts;
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

`verify_project.ps1` records preflight cases including:

- export output-directory safety;
- current-snapshot and complete-history repository safety;
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

Diagnostic artifacts are named:

```text
car-game-diagnostics-<commit-sha>
```

Trusted push/manual package artifacts are named:

```text
car-game-windows-<commit-sha>
```

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
3. `build/test-logs/git-history-safety.log` for complete-history findings;
4. `build/test-logs/localization-validation.log` when localization was reached;
5. `build/test-logs/current-command.log` when present;
6. `workflow-runner-failure.log`;
7. the log named after the failed import/script/scene command;
8. packaged startup/export logs.

A green pull request requires the Windows workflow conclusion to be `success` on the current head commit.
