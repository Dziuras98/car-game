# Performance baseline

The current performance pass focuses on deterministic per-frame work rather than platform-specific frame-time thresholds.

## AI runtime contracts

`OpponentParticipantSpawner` creates typed `AiRaceDriver` instances and configures each one before it enters the scene tree with:

- one `PlayerCarController`;
- the committed `GeneratedTrack`;
- one validated `AiDriverProfile`.

The spawner does not use dynamic `set`, `call` or method probing. Invalid dependencies prevent opponent creation instead of leaving an unconfigured car in the race. Removing or disabling a driver clears its external inputs, so the car cannot retain stale throttle or steering.

`CarSpawner` accepts an optional opponent session seed. `-1` randomizes the session; a non-negative value reproduces variant selection, paint randomization and AI profiles. `OpponentAiProfileFactory` derives each speed profile from the session seed and opponent index, keeping profile generation independent from unrelated random draws.

## AI racing-line lookup

`AiRaceDriver` uses `RacingLineIndexSearch`.

Normal updates inspect a bounded window around the previous racing-line index:

- 4 points behind;
- the current point;
- 14 points ahead.

This reduces the normal lookup from all 108 simple-oval points to at most 19 distance checks per AI driver. A full scan remains available when:

- the car has no previous index;
- the nearest local point is farther than the recovery distance;
- the periodic recovery interval is reached.

The recovery path keeps resets, teleports and large deviations from permanently desynchronizing the AI. Geometry rebuild notifications replace the cached racing line and only resume physics processing after the refreshed line passes validation.

## Procedural audio LOD

Engine and tire procedural audio use `ProceduralAudioPlayer3D` distance checks against the active 3D camera.

- engine sample generation is skipped outside its audible range;
- tire sample generation is skipped outside its range;
- tire sample generation is also skipped while slip remains below the audible threshold;
- distance checks are throttled rather than executed for every generated sample.

The existing `AudioStreamPlayer3D` attenuation remains responsible for final spatial volume.

## UI update rates

Dynamic UI avoids frame-rate-dependent work:

- the speedometer samples telemetry at 30 Hz;
- the minimap redraws at 20 Hz;
- minimap track coordinates are cached until the track or control size changes;
- lap and position labels are rewritten only when their values change;
- the tachometer redraws only after a meaningful RPM change.

## Generated-track rebuilds

`GeneratedTrack` computes a generation signature from layout, road, checkpoint and decoration data.

Repeated rebuild requests are deferred and coalesced. A rebuild is skipped when the signature is unchanged. Multiple `TrackLayoutResource.changed` notifications in one frame therefore produce at most one mesh, collision, decoration and checkpoint regeneration.

## Regression benchmark

The required Windows test suite runs:

```text
scenes/tests/performance_regression_test.tscn
```

The test records elapsed microseconds for diagnostics but gates CI on deterministic operation counts. It simulates 180 updates for 1, 4, 8 and 12 AI drivers and requires the average racing-line lookup to remain at or below 22 point checks per update.

It also verifies:

- full-scan recovery after a large position jump;
- procedural-audio distance boundaries;
- suppression of unchanged HUD and tachometer updates;
- skipping unchanged track rebuild requests;
- coalescing repeated Resource change notifications.

AI contract tests additionally verify profile validation, seeded replay, typed enable/disable propagation and racing-line refresh after committed geometry rebuilds.

Wall-clock values are intentionally not pass/fail thresholds because GitHub-hosted runner load is variable.
