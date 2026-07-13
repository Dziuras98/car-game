# Runtime audit fixes

This change set addresses the runtime defects identified during the July 2026 repository audit.

## Fixed contracts

- Player input, driving HUD and pause handling remain disabled while a session is in `STARTING`.
- Session-start transactions reject concurrent execution without rolling back the active startup.
- Finished opponents have their matching AI driver disabled before stop inputs are applied.
- Opponent grid columns use symmetric offsets and are validated against start-line track width.
- Track progress profiles with explicit `0` and `1` samples require matching endpoint values.
- Tor Poznań rebuilds geometry-dependent curbs and reapplies pit-lane barrier changes after generated geometry changes.

## Regression coverage

- `scripts/tests/session_runtime_regression_test.gd`
- `scripts/tests/track_and_grid_regression_test.gd`
