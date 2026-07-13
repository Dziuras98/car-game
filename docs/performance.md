# Performance baseline

The current performance strategy combines deterministic operation-count contracts with focused wall-clock diagnostics for the engine-audio production fixture. Generic frame-time thresholds are avoided where GitHub-hosted runner variance would make them unreliable.

## AI runtime contracts

`OpponentParticipantSpawner` creates typed `AiRaceDriver` instances and configures each one before it enters the scene tree with:

- one `PlayerCarController`;
- the committed `GeneratedTrack`;
- one validated `AiDriverProfile`.

The spawner does not use dynamic `set`, `call` or method probing. Invalid dependencies prevent opponent creation instead of leaving an unconfigured car in the race. Opponent preparation is all-or-nothing. Removing, finishing or disabling a driver clears/neutralizes external inputs so the car cannot retain stale throttle or steering.

`CarSpawner` accepts an optional opponent session seed. `-1` randomizes the session; a non-negative value reproduces variant selection, paint randomization and AI profiles. `OpponentAiProfileFactory` derives each speed profile from the session seed and opponent index, keeping profile generation independent from unrelated random draws.

Manual AI variants add one-shot gear requests with shift-in-progress suppression. Conventional automatic and CVT variants remain on the same external throttle/brake/steering channel and manage their own gear/ratio state.

## AI racing-line lookup

`AiRaceDriver` uses `RacingLineIndexSearch`.

Normal updates inspect a bounded window around the previous racing-line index:

- 4 points behind;
- the current point;
- 14 points ahead.

For the 108-point simple-oval benchmark fixture, this reduces the normal lookup to at most 19 distance checks per AI driver. The bound is independent of the complete line size. A full scan remains available when:

- the car has no previous index;
- the nearest local point is farther than the recovery distance;
- the periodic recovery interval is reached;
- committed geometry is replaced.

The recovery path keeps resets, teleports and large deviations from permanently desynchronizing the AI. Geometry rebuild notifications replace the cached racing line and resume processing only after the refreshed line passes validation.

## Vehicle hot path

The car runtime avoids per-substep temporary arrays in its four-probe ground-contact loop. Probe origins are cached and rebuilt only when `CarDriveConfig` changes. Contact count, normal, grip and suspension support use running aggregates.

The bounded substep schedule is shared by:

- contact sampling;
- lateral tire recovery;
- transmission/engine/longitudinal tire updates;
- steering;
- gravity and suspension support.

Longitudinal grip and slip do not add per-wheel bodies or iterative solvers. The current car-level model uses scalar calculations and a `Vector2` response from `TireModel.resolve_longitudinal_acceleration()`.

## Vehicle visual LOD

Current car visual wrappers use `CarVisualController` with:

- a detailed imported-model root;
- a model-specific low-detail root;
- a `VisibleOnScreenNotifier3D` covering the car bounds;
- explicit detailed-wheel bindings.

Cars start conservatively in low detail. Detailed visuals and detailed-wheel animation are enabled while the notifier is visible to the active camera. This avoids per-frame distance loops in GDScript.

Both roots remain instantiated, so this is a render/animation optimization rather than a detailed-asset memory streaming system. Frustum visibility is approximate and does not imply occlusion behind other geometry.

## Engine-audio backends

Engine audio has scene-specific performance contracts:

- Nissan player scenes use protected full live synthesis;
- Nissan AI scenes use committed WAV banks through `BakedEngineAudioPlayer`;
- Shelby player scenes use full live cross-plane V8 synthesis and are not AI-eligible;
- Fiat player and AI variants currently share full live procedural scenes.

`ProceduralAudioPlayer3D` still provides throttled listener-distance and voice-budget logic for procedural nodes that use it. However, current player engine scenes and shared Fiat scenes set `force_full_runtime_generation`, bypassing engine distance/budget suspension. Documentation must not claim that all engine synthesis is skipped outside an audible radius.

Tire procedural audio continues to use distance checks and slip-threshold suppression. `AudioStreamPlayer3D` attenuation remains responsible for final spatial volume.

The Nissan production audio benchmark is documented in `docs/baked_engine_audio.md`. It measures one live Nissan player synthesizer plus three baked Nissan AI players and writes:

```text
build/test-logs/engine-audio-fleet-benchmark.json
```

Its wall-clock budgets protect that explicit fixture. They do not establish a cost bound for live Fiat opponent fleets or future Shelby AI scenes.

## UI update rates

Dynamic UI avoids frame-rate-dependent work:

- the speedometer samples telemetry at 30 Hz;
- the minimap redraws at 20 Hz;
- minimap track coordinates are cached until the committed track or control size changes;
- lap and position labels are rewritten only when their values change;
- the tachometer redraws only after a meaningful RPM change;
- the active-car label changes only when the committed variant changes;
- loading progress is monotonic and updated only at startup stage boundaries.

## Generated-track rebuilds

`GeneratedTrack` computes a generation signature from layout, road, checkpoint and decoration data.

Repeated rebuild requests are deferred and coalesced. A rebuild is skipped when the signature is unchanged. Multiple `TrackLayoutResource.changed` notifications in one frame therefore produce at most one mesh, collision, decoration and checkpoint regeneration.

Generated content is prepared in detached staged containers and committed only after validation. During an active gameplay session, mutation is locked; requested layout changes are deferred until the session releases that lock.

Repeated trackside objects use bounded `MultiMesh` groups. Tor Poznań uses batched forest and curb content in addition to the generic marker/barrier batching.

## Regression benchmarks

The required Windows suite runs deterministic performance coverage including:

```text
scenes/tests/performance_regression_test.tscn
scripts/tests/runtime_component_benchmark.gd
scripts/tests/engine_audio_fleet_benchmark_test.gd
```

The general performance regression simulates 180 updates for 1, 4, 8 and 12 AI drivers and requires the average racing-line lookup to remain at or below 22 point checks per update. It records elapsed microseconds for diagnostics but gates the generic AI/UI/track checks on deterministic operation counts.

It also verifies:

- full-scan recovery after a large position jump;
- procedural-audio distance and voice-budget boundaries where those controls apply;
- suppression of unchanged HUD and tachometer updates;
- skipping unchanged track rebuild requests;
- coalescing repeated resource-change notifications.

Runtime component benchmarks exercise production-style vehicle/track components without changing gameplay behavior. The engine-audio fleet benchmark separately uses median wall-clock timings because audio synthesis cost cannot be represented by a useful operation count alone.

AI contract tests additionally verify profile validation, seeded replay, typed enable/disable propagation, manual shift behavior and racing-line refresh after committed geometry rebuilds.

## Interpretation rules

- A green operation-count benchmark proves bounded work for its fixture; it is not a universal frame-rate guarantee.
- A green Nissan audio benchmark does not cover live Fiat AI fleets.
- Visual LOD reduces render and wheel-animation work but does not unload the imported model from memory.
- Headless suppression avoids real-time audio allocation/playback but deterministic offline synthesis remains testable.
- New cars, tracks, AI behavior or audio backends must extend the representative fixtures rather than relying on unrelated existing budgets.
