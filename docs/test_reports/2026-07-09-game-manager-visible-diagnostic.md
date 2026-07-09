# GameManager visible diagnostic API

Date: 2026-07-09

## Scope

- Added `GameManager.is_child_visible_for_test(node_name: String) -> bool`.
- Moved the existing child visibility diagnostic behavior out of `GameTestAdapter.is_child_visible(...)`.
- Updated `GameTestAdapter.is_child_visible(...)` to delegate to `GameManager.is_child_visible_for_test(...)`.

## Gameplay impact

- No gameplay, physics, tuning, menu flow, car catalog, AI, track, or smoke test flow changes.
- This change only relocates test diagnostic logic and preserves the existing visibility fallback order:
  missing child returns `false`, boolean `visible` property returns that value, `CanvasItem` falls back to `is_visible_in_tree()`, and all other nodes return `false`.

## Validation

- Passed: `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`
  - Result: `[SMOKE] Extended full program smoke test passed: 79 checks`
  - Note: the sandboxed Godot run crashed natively before test logs; the same command passed outside the sandbox.
- Passed: `git diff --check`
