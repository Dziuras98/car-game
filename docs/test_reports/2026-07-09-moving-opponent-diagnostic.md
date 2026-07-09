# Moving opponent diagnostic refactor

Date: 2026-07-09

## Scope

- Added `GameManager.get_moving_opponent_count_for_test()` as the public test diagnostic API for counting moving opponents.
- Moved the existing moving-opponent count logic from `GameTestAdapter.get_moving_opponent_count()` into `GameManager`.
- Updated `GameTestAdapter.get_moving_opponent_count()` to delegate to `GameManager.get_moving_opponent_count_for_test()`.

## Gameplay impact

- No gameplay, physics, tuning, menu flow, car catalog, AI, track, or smoke test flow changes.
- The refactor only moves existing diagnostic counting logic behind a `GameManager` test API.
- `GameTestAdapter.has_moving_opponent()` keeps the same semantics by checking whether the delegated count is greater than zero.

## Validation

- Passed: `C:\Dev\Tools\Godot\Godot_v4.7-stable_win64_console.exe --headless --path . --scene res://scenes/tests/full_program_smoke_test.tscn`
  - Result: `[SMOKE] Extended full program smoke test passed: 79 checks`
  - Note: the first sandboxed run crashed inside the Godot executable before the smoke test produced results; the same command passed when rerun outside the sandbox.
- Passed: `git diff --check`
