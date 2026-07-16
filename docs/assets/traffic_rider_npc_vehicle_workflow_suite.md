# Traffic Rider workflow document suite

The Traffic Rider integration workflow is a document suite. No single abbreviated stage summary may replace the detailed contracts below.

## Canonical documents

1. `traffic_rider_npc_vehicle_import_workflow.md`
   - model order, research gates, source/visual processing, catalog, physics, traffic, LOD and final validation;
2. `traffic_rider_npc_vehicle_research_data_contract.md`
   - retention of previously researched engines, curves, masses, ratios, transmission identities, tyres, aerodynamics and targets;
3. `traffic_rider_transmission_implementation_contract.md`
   - exact procedure for implementing or extending manual, torque-converter automatic, automated-manual, DCT, CVT, electric fixed-reduction, transfer-case and AWD/e-axle architectures;
4. `traffic_rider_engine_audio_implementation_contract.md`
   - exact procedure for researching, synthesizing, profiling, baking, binding, level-normalizing and validating every engine/motor audio family;
5. `traffic_rider_npc_vehicle_physics_v3_baseline.md`
   - reviewed interfaces and constraints inherited from the authoritative physics baseline;
6. `traffic_rider_npc_vehicle_research_data_manifest.data`
   - per-model migration state and approved count.

## Authority and precedence

- The owner-approved model records define catalog scope.
- Structured evidence defines implementation parameters.
- The transmission and engine-audio contracts define how missing shared capabilities must be added.
- The current `master` physics interfaces define runtime integration.
- Evidence-blocked facts remain blocked; no workflow document authorizes guessing.

A model-specific note may add stricter requirements. It may not weaken these common contracts.

## Required per-model completion record

Before a model becomes `integrated`, its record must link or identify:

- canonical source and processed visual evidence;
- complete structured variant/engine/dynamics data;
- transmission architecture decision for every exposed row;
- new/extended transmission model and deterministic tests where required;
- drivetrain/AWD/transfer-case implementation and tests;
- engine-audio architecture decision for every engine family;
- live player and explicit AI audio backend;
- loudness, limiter/turbo, signal-safety and perceptual tests;
- physics/performance calibration against retained targets;
- catalog, scene, traffic, LOD, export and smoke-test results;
- unresolved rows that remain unavailable.

## Change policy

Any change to a shared transmission, AWD, audio or baking architecture must:

1. update the relevant detailed contract when semantics change;
2. update affected model records and structured data;
3. add deterministic architecture tests;
4. add affected vehicle-level tests;
5. rerun existing catalog-wide regressions;
6. keep unsupported rows unavailable rather than introducing fallback behaviour.
