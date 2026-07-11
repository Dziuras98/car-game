# Game session lifecycle

`GameSessionState` is the authoritative owner of the active gameplay selection and lifecycle phase. `GameManager` coordinates scene objects but does not store independent mode, track or car-variant fields.

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

## Startup contract

1. Validate the emitted mode, track and car IDs.
2. Clear the previous race/player runtime and reset the lifecycle to `MENU`.
3. Enter `STARTING`.
4. Activate the selected track and configure detached runtime controllers.
5. Spawn the exact selected player car.
6. Prepare and start the complete race participant set when race mode was selected.
7. Commit mode, track and variant IDs and transition to the final active phase.

Any failure after startup begins uses the same teardown path as a normal return to the menu. Partial cars, opponents, selections and driving UI are cleared together.

## Ownership rules

- `GameModes` owns supported mode identifiers.
- `GameSessionState` owns lifecycle phase and committed selection IDs.
- `GameManager` owns scene orchestration and calls the lifecycle API.
- `RaceSessionController` owns race participant and race-manager cleanup.
- `CarSpawner` owns player-car disposal.

Do not reintroduce parallel selected-mode/track/variant fields in `GameManager`, infer lifecycle phase from UI visibility, or create separate rollback and normal-return cleanup sequences.
