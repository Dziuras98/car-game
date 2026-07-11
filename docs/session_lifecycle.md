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
- `STARTING` represents transactional startup after previous runtime state has been cleared but before the complete selection is committed.
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

1. Validate the emitted `StringName` mode, track and car-variant IDs.
2. Resolve the exact catalog car index and `TrackDefinition`.
3. Clear the previous race/player runtime and reset the lifecycle to `MENU`.
4. Enter `STARTING`.
5. Activate the selected track.
6. Configure detached `CarSpawner` and `RaceSessionController` runtime objects.
7. Spawn the exact selected player car.
8. Prepare and start the complete race participant set when race mode was selected.
9. Commit mode, track and variant IDs and transition to the final active phase.

Each failure class has a dedicated `GameSessionStartTransaction.Result`. Any failure calls the same runtime-reset callback used before preparation, so partially spawned cars, opponents, selections and driving UI are cleared together.

## Ownership rules

- `GameModes` owns supported `StringName` mode identifiers.
- `GameSessionState` owns lifecycle phase, committed selection IDs and transition result codes.
- `GameSessionStartTransaction` owns validation, stage ordering, commit and rollback for session startup.
- `GameManager` owns scene orchestration, public read-only lifecycle access and menu/pause wiring.
- `RaceSessionController` owns race participant, tracking, race-manager and race-UI cleanup.
- `CarSpawner` owns player-car and opponent disposal.

Do not reintroduce parallel selected-mode/track/variant fields in `GameManager`, detailed startup sequencing in `GameManager`, phase inference from UI visibility, boolean-only lifecycle errors or separate rollback and normal-return cleanup sequences.
