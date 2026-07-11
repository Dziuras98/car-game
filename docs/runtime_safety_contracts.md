# Runtime and delivery safety contracts

This document records the strict runtime and delivery invariants established by the session-start and complete audit remediation work. These rules are regression contracts, not optional implementation guidance.

## Vehicle physics sampling

`PlayerCarController` samples ground contact exactly once per physics frame, before entering the bounded simulation-substep loop.

- `CarChassisController.sample_ground_contact()` casts the four suspension probes and stores the aggregate contact state.
- `update_tire_dynamics()` may execute multiple times for a hitch-sized frame, but it consumes the same current-frame contact sample.
- `update_skid_marks()` executes once per physics frame.
- The ray-query object and the player-car RID exclusion are retained by the chassis controller instead of being recreated for every probe.
- Probe queries use `CarSpecs.ground_probe_collision_mask`, not the car body collision mask.
- Only `TrackSurfaceBody` colliders may provide suspension support or grip.
- Normals below `minimum_ground_normal_dot` are rejected so walls, other cars and inverted geometry cannot become ground.

The convenience `update_tires()` entrypoint remains for focused chassis tests. Production vehicle coordination uses the separated sampling, dynamics and effects methods.

## Runtime car specifications and telemetry

- Runtime replacement uses `PlayerCarController.try_apply_car_specs()` and a typed result.
- Candidate specifications are validated and converted to `CarDriveConfig` before any committed runtime field changes.
- A rejected replacement preserves the prior resource, configuration, motion state and physics processing.
- `CarTelemetrySnapshot` is an immutable captured view used by UI and regression tests; mutable `CarRuntimeState` ownership stays inside the vehicle coordinator.

## Participant identity

`RaceParticipant` identity is immutable after construction.

- participant ID, kind, car reference and ordinal are private;
- consumers use read-only getters;
- only the optional display name has a controlled setter;
- player creation rejects an invalid car reference;
- opponent creation rejects missing cars and ordinals less than one;
- generated labels never infer identity from node names.

A copied participant array may safely share participant records because callers cannot mutate identity fields.

## Strict selection and count handling

Invalid inputs are rejected rather than corrected:

- unavailable car variants resolve to `-1`;
- invalid car indices resolve to an empty variant ID;
- the former clamping car-index helper does not exist;
- negative opponent counts produce `OpponentParticipantSpawner.Result.INVALID_COUNT` without clearing an existing valid participant set;
- zero opponents remains an explicit valid request that clears the current opponents;
- race-session configuration rejects non-positive lap counts and negative opponent counts;
- `GameManager` does not clamp an invalid configured lap count to one.

## Session and track transactions

- `GameSessionState.begin_start()` admits startup before prior runtime is cleared.
- Lifecycle rejection preserves the complete active session.
- Same-ID track-definition replacement is provisionally committed and fully reversible.
- `TrackGeometryData.validate()` checks finite values, array consistency, segment lengths, vectors, widths, edge orientation and loop length before commit.
- `GeneratedTrack.get_racing_line_points()` returns only committed geometry and has no generation side effect.
- Active sessions lock generated-track rebuilds; requested changes are coalesced until the lock is released.
- Every committed geometry revision resets unfinished checkpoint sequences before projection is reacquired.

## Race lifecycle and faults

`RaceManager` owns the `IDLE -> COUNTDOWN -> RUNNING -> FINISHED` lifecycle and reports every requested mutation through `RaceManager.Result`.

- start is accepted only from `IDLE` with a valid player and `SceneTree`;
- repeated starts during `COUNTDOWN`, `RUNNING` or `FINISHED` return `INVALID_STATE` and emit no duplicate countdown signals;
- finish is accepted only from `RUNNING` with a valid player;
- reset cancels any in-flight countdown and returns to `IDLE`;
- `RaceSessionController` checks lifecycle admission before committing participant runtime;
- unknown cars return absent lap/position telemetry instead of plausible first-place defaults;
- mutable `RaceManager` and `LapTracker` references are not exposed through the session facade;
- failed opponent preparation restores RNG state so seeded retries remain deterministic;
- AI faults apply controlled braking and emit one typed fault;
- AI or lap-tracking contract faults reset the complete session through `GameManager`.

## Fatal initialization

- Scene, content, pause UI and runtime coordinator construction share one fatal-initialization path.
- Fatal initialization disables processing and input, clears partial runtime and displays a localized blocking error.
- Packaged regression builds exit non-zero on fatal initialization.

## Windows CI delivery

The Windows workflow distinguishes replaceable pull-request validation from authoritative branch and manual runs.

- `cancel-in-progress` is enabled only when `github.event_name == 'pull_request'`;
- pushes to `master` and manual workflow dispatches are never cancelled by a newer run;
- diagnostic artifact upload may warn when logs are missing;
- trusted Windows package upload uses `if-no-files-found: error`;
- the Windows platform contract preflight validates both policies using positive and negative fixtures.

## Supply-chain and package identity

- Godot editor and export-template archives are verified against `scripts/ci/godot_4_7_sha512.txt`.
- CI does not download its trust checksum file from the same release endpoint as the archives.
- Archive-name or engine-version changes require an explicit reviewed manifest update.
- Tagged packages use the semantic tag; untagged packages include the short source SHA.
- Numeric Windows file versions include the workflow run number.
- `export_presets.cfg` is restored exactly after export success or failure.

These rules ensure that a successful trusted workflow represents a completed validation, reviewed dependencies, identifiable source code and a present Windows package set.
