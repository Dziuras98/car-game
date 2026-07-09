# Follow camera shutdown guard

Date: 2026-07-09

## Scope

- Updated `scripts/camera/follow_camera.gd` only.
- Added shutdown-safe guards before resolving node paths or reading transforms when the camera or its target is no longer inside the scene tree.
- Did not change gameplay, physics, tuning, menu flow, car catalog, AI, track generation, smoke test logic, or camera parameters.

## Cause

The smoke test passed, but during shutdown the follow camera could still run `_process` while its tracked car target was already removed from the tree. The target object was still instance-valid, so the previous null/validity check allowed `_target.global_transform` to run and Godot reported `!is_inside_tree()` after the PASS line.

`set_target_node` also updated `target_path` through `get_path_to(...)` whenever the camera was in the tree and the target was non-null. That path calculation is now limited to valid targets that are also inside the tree.

## Gameplay impact

Normal camera behavior was not changed. While the camera and target are in the tree, the existing follow distance, height, look-ahead, smoothing, interpolation, and `look_at` behavior are unchanged.

## Validation

- Initial sandboxed run of `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn` timed out and Godot crashed before producing a smoke-test result.
- Passed outside the sandbox: `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`
  - Result: `[SMOKE] Extended full program smoke test passed: 79 checks`
  - Follow camera shutdown errors after PASS: none observed.
- Passed: `git diff --check`
