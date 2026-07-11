# Game session lifecycle

`GameSessionState` is the authoritative owner of the active gameplay selection and lifecycle phase. `GameManager` coordinates scene objects but does not store independent mode, track or car-variant fields. All gameplay identifiers use `StringName`.

## Phases

```text
MENU -> STARTING -> FREE_DRIVE
                 -> RACE
FREE_DRIVE/RACE -> MENU
STARTING        -> MENU on rollback
```

- `MENU` has no committed mode, track or car variant.
- `STARTING` represents transactional startup after lifecycle admission but before the complete selection is committed.
- `FREE_DRIVE` represents a committed free-drive session. Switching cars may update only the variant ID.
- `RACE` represents a committed race session. Free-drive car switching is rejected.

`GameSessionState.phase_changed` emits only when the phase actually changes. `GameManager` exposes the current phase through `get_session_phase()` and re-emits it as `session_phase_changed`, so UI and tests do not infer lifecycle state from visibility or empty identifiers.

## Typed lifecycle results

State-changing methods return `GameSessionState.Result` rather than a boolean:

- `OK`;
- `INVALID_PHASE`;
- `UNSUPPORTED_MODE`;
- `EMPTY_TRACK_ID`;
- `EMPTY_CAR_VARIANT_ID`.

Rejected operations do not mutate committed IDs and do not emit phase changes. `reset()` is idempotent while already in `MENU`.

## Startup transaction

`GameSessionStartTransaction` owns the prepare-then-commit sequence:

1. Validate the emitted `StringName` mode, track and car-variant IDs without mutating runtime state.
2. Resolve the exact catalog car index and `TrackDefinition`.
3. Ask `GameSessionState` to enter `STARTING`; rejection preserves the currently active runtime and committed selection.
4. Clear player/race runtime objects without resetting `GameSessionState`.
5. Stage the selected track while the previously committed track remains recoverable.
6. Configure detached `CarSpawner` and `RaceSessionController` runtime objects against the staged track.
7. Spawn the exact selected player car.
8. Prepare and start the complete race participant set when race mode was selected.
9. Promote the staged track while retaining the previous track as rollback state.
10. Commit mode, track and variant IDs and transition to the final active phase.
11. Finalize the track replacement and dispose the superseded track.

Validation and lifecycle-admission failures do not invoke destructive cleanup. Failures after entering `STARTING` call one rollback callback that clears partial runtime objects, discards or reverses the staged track replacement and resets the lifecycle to `MENU`.

## Track transaction

`TrackSpawnController` exposes explicit `stage_track()`, `commit_staged_track()`, `finalize_track_commit()` and `rollback_track_transaction()` operations.

- Staging creates and validates `PendingTrack` without replacing `ActiveTrack`.
- Commit promotes the pending track but retains the previous track outside the tree until session commit succeeds.
- Finalization disposes the superseded track.
- Rollback discards an uncommitted pending track or restores the previous active track after provisional promotion.

The immediate `spawn_track()` helper is retained only for startup paths that do not have additional runtime stages; it performs stage, commit and finalize as one operation.

## Ownership rules

- `GameModes` owns supported `StringName` mode identifiers.
- `GameSessionState` owns lifecycle phase, committed selection IDs and transition result codes.
- `GameSessionStartTransaction` owns validation, stage ordering, commit and rollback for session startup.
- `TrackSpawnController` owns reversible track replacement state.
- `GameManager` owns scene orchestration, public read-only lifecycle access and menu/pause wiring.
- `RaceSessionController` owns race participant, tracking, race-manager and race-UI cleanup.
- `CarSpawner` owns player-car and opponent disposal.

Do not reintroduce parallel selected-mode/track/variant fields in `GameManager`, detailed startup sequencing in `GameManager`, phase inference from UI visibility, boolean-only lifecycle errors, destructive cleanup before lifecycle admission or irreversible track replacement before session commit.
