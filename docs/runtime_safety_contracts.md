# Runtime and CI safety contracts

This document records the strict runtime and delivery invariants introduced after the session-start transaction work. These rules are regression contracts, not optional implementation guidance.

## Vehicle physics sampling

`PlayerCarController` samples ground contact exactly once per physics frame, before entering the bounded simulation-substep loop.

- `CarChassisController.sample_ground_contact()` casts the four suspension probes and stores the aggregate contact state.
- `update_tire_dynamics()` may execute multiple times for a hitch-sized frame, but it consumes the same current-frame contact sample.
- `update_skid_marks()` executes once per physics frame.
- The ray-query object and the player-car RID exclusion are retained by the chassis controller instead of being recreated for every probe.

The convenience `update_tires()` entrypoint remains for focused chassis tests. Production vehicle coordination must use the separated sampling, dynamics and effects methods.

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
- race-session configuration rejects non-positive lap counts and negative opponent counts.

## Race lifecycle

`RaceManager` owns the `IDLE -> COUNTDOWN -> RUNNING -> FINISHED` lifecycle and reports every requested mutation through `RaceManager.Result`.

- start is accepted only from `IDLE` with a valid player and `SceneTree`;
- repeated starts during `COUNTDOWN`, `RUNNING` or `FINISHED` return `INVALID_STATE` and emit no duplicate countdown signals;
- finish is accepted only from `RUNNING` with a valid player;
- reset cancels any in-flight countdown and returns to `IDLE`;
- `RaceSessionController` checks lifecycle admission before committing participant runtime.

## Windows CI delivery

The Windows workflow distinguishes replaceable pull-request validation from authoritative branch and manual runs.

- `cancel-in-progress` is enabled only when `github.event_name == 'pull_request'`;
- pushes to `master` and manual workflow dispatches are never cancelled by a newer run;
- diagnostic artifact upload may warn when logs are missing;
- trusted Windows package upload uses `if-no-files-found: error`;
- the Windows platform contract preflight validates both policies using positive and negative fixtures.

These rules ensure that a successful trusted workflow always represents a completed validation and a present Windows package set.
