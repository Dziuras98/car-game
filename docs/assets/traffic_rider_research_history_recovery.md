# Traffic Rider research-history recovery

## Audit purpose

The user stated that the engine, mass, gearing, transmission and workflow research had already been completed and should remain in PR #107. Before re-researching or inferring any value, the branch history was audited directly with a full-depth Git checkout.

The reproducible audit is implemented by:

- `tools/assets/recover_traffic_rider_research_history.py`;
- `tools/assets/recover_traffic_rider_research_history_full.py`;
- `.github/workflows/recover-traffic-rider-research-history.yml`.

The workflow stores an Actions artifact containing commit metadata, every unique relevant text snapshot and numeric parameter hits. The artifact is evidence for migration work; it is not a runtime input and is retained for 14 days.

## Audited graph

Full-graph recovery at head `79c0897edb22ef70455e24e8a1d6c71ca09a2a21` inspected:

- base: `3743f5e95391b63a97e81b95050984b8240b7f30`;
- **265** non-base commits reachable from the PR head;
- **211** relevant changed paths;
- **210** unique retained text versions;
- **3,933** lines containing both a workflow parameter concept and a numeric value.

The first pass used `--ancestry-path` and inspected only 103 direct descendants of the synchronized `master`. The corrected full-graph pass intentionally includes the original research-side ancestors introduced before synchronization.

## Recovered research

The original research and owner-scope commits were recovered for all 20 included models. They preserve:

- model/body identity and visual constraints;
- the approved engine/transmission/drivetrain matrices;
- model-specific inclusions and exclusions;
- engine-family outputs and broad mechanical architecture;
- source references and evidence classifications;
- required transmission, driveline, physics and audio implementation methods;
- explicit lists of evidence still required before parameter commitment.

These records are therefore sufficient to preserve the approved catalog scope and to prevent use of an incorrect fallback architecture.

## Parameter-retention finding

The history does **not** contain complete runtime-grade parameter tables for all 285 approved configurations.

For BMW F32, the original commits `44c547545d4c` and `8b50fbcb15b3` preserve the 44-row scope, dimensions, engine outputs, validation targets and implementation requirements. They do not contain 44 complete rows of masses, sampled torque curves, exact gearbox/final-drive ratios, tyres, aerodynamics and performance targets.

The only complete factory dynamics table recovered from history is the later eight-row file introduced at `72d1bf877fe9`:

- 428i N20 RWD 6MT;
- 428i N20 RWD 8AT;
- 428i N20 xDrive 8AT;
- 435i N55 RWD 6MT;
- 435i N55 RWD 8AT;
- 435i N55 xDrive 8AT;
- 420d N47 RWD 6MT;
- 420d N47 RWD 8AT.

Even those rows deliberately leave the exact gearbox suffix empty because it was not retained. The history also preserves requirements for ZF 8HP, xDrive and BMW engine-audio families, but not complete evidence-backed control maps or audio calibration profiles.

The later model records similarly preserve their approved matrices and architecture-specific plans, while many explicitly state that exact ratios, masses, curves, tyres, aero or control data remain required before parameter commitment. No hidden complete per-row data files were found under alternate historical paths.

## Implementation consequence

No missing value may be reconstructed from a badge, another gearbox family, a generic body mass or performance tuning. The sequential workflow therefore remains:

1. model 01 stays `integrating`;
2. model 02 stays queued until model 01 reaches `integrated`;
3. architecture work may be shared, but no later model may be exposed out of order;
4. rows lacking retained exact input stay unavailable.

Completing all 20 models requires one of the following evidence-preserving inputs:

- an export or copy of the earlier research conversation/data that was never committed;
- original local files containing the missing tables;
- explicit owner authorization to repeat the missing primary-source research.

Until one of those inputs exists, reporting all 285 configurations as implemented would be false.

## Work completed despite the data gap

Model 01 now has reusable, tested architecture foundations that do not guess vehicle-specific calibration:

- deterministic processed visual with explicit body and four wheel bindings;
- phased planetary torque-converter automatic model with selected versus engaged gear, converter speed ratio, multiplication, progressive lock-up, skip-shift/kickdown and fixed-step determinism;
- dynamic on-demand AWD transfer-clutch model with launch/slip demand, rate/capacity limits, high-speed release and thermal derating;
- typed Traffic Rider controller and definition resource that reject incomplete enabled architectures instead of falling back;
- first-principles inline-three, inline-four and inline-six audio architecture with petrol/diesel and turbo/VGT/sequential states, limiter/turbo semantic continuity and summed-output limiting.

These shared capabilities are not evidence that any incomplete BMW row is catalog-ready. Exact resources, scenes, calibration and vehicle-level validation remain gated by retained per-row input.
