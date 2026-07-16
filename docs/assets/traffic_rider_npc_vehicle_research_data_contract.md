# Traffic Rider research-data retention contract

## Purpose

All 20 approved Traffic Rider vehicles were researched before implementation began. Their approved scopes and evidence classifications are recorded under `docs/vehicles/traffic/`. Implementation must consume retained research data; it must not reconstruct masses, ratios, gearbox identities, torque curves or other parameters from badges, generic family assumptions or runtime tuning.

The machine-readable migration state is recorded in:

`docs/assets/traffic_rider_npc_vehicle_research_data_manifest.data`

## Required structured datasets

Before a model may expose a playable, AI or traffic powertrain configuration, its canonical data root must contain machine-readable records for:

1. the complete owner-approved variant matrix with stable candidate IDs;
2. all distinct engine and motor calibrations;
3. sampled torque or motor-force curves and their evidence state;
4. exact transmission architecture, marketing identity and code/suffix when proven;
5. every forward ratio, reverse ratio and final drive;
6. drivetrain layout, coupling and differential data;
7. DIN/EU/kerb mass, axle loads and applicable body/chassis state;
8. tyre size and rolling radius;
9. drag coefficient and frontal area;
10. braking, acceleration, in-gear and maximum-speed validation targets;
11. source identifiers and confidence classification for each retained value.

An empty field is permitted only when the research record explicitly states that the value is evidence-blocked or was not retained. It must carry a corresponding status field. A blank value must never be silently replaced by a family proxy, convenient ratio, guessed mass or inferred gearbox suffix.

## Status meanings

- `research_record_only` — the approved scope and researched facts remain in the model record, but they have not yet been migrated into canonical machine-readable tables. The model may not expose runtime variants.
- `partial_verified` — canonical tables exist for the full approved matrix and at least one fully evidenced dynamics tranche, but some approved rows still lack complete machine-readable parameters. Only rows independently satisfying every runtime gate may proceed further.
- `complete_verified` — every approved row has complete machine-readable engine, transmission, mass, tyre, aero and validation data, with evidence state and no prohibited fallback.

A model may be marked `integrated` only when its manifest row is `complete_verified`, its catalog count exactly matches the approved count, and all visual, transmission, drivetrain, audio, physics and performance tests pass.

## Current migration state

BMW F32 is the first migrated model. Its canonical root contains:

- 44 stable approved candidate IDs;
- 17 engine/calibration rows;
- eight factory-exact launch dynamics rows with complete mass, ratios, reverse, final drive, tyre, rolling radius, drag, frontal area and performance targets;
- an explicit `not_retained_in_research_record` state for gearbox suffixes that must not be invented.

The remaining BMW rows and models 02–23 remain blocked from runtime exposure until their previously researched values are migrated from the PR records/history into equivalent canonical datasets.

## Regression policy

Automated tests must verify:

- exactly 20 manifest rows and a combined approved count of 285;
- unique model and candidate IDs;
- readable model research records;
- valid structured-data roots for every non-`research_record_only` row;
- no model with incomplete structured data is described as integrated;
- exact counts and cross-references between variant, engine and dynamics tables;
- explicit evidence states for absent exact values.
