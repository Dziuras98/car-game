# BMW F32 persistent research datasets

The BMW 4 Series F32 implementation must consume retained structured research data rather than reconstructing parameters from marketing badges or prose.

## Files

- `bmw_f32_variant_matrix.data` — the complete owner-approved 44-row matrix. Every mechanically distinct engine, transmission and drivetrain combination has a stable `candidate_id`.
- `bmw_f32_engines.data` — the 17 distinct engine/calibration records used by the matrix.
- `bmw_f32_verified_dynamics.data` — factory-exact mass, gearing, tyre, aerodynamic and performance data recovered for the eight launch configurations covered by the retained June 2013 BMW technical specification.

## Data-state rules

`implementation_status=planned` means that a combination is approved and retained but must not yet be exposed in the playable catalog. It does not mean that missing values may be synthesized.

`implementation_status=verified_dynamics` means that a complete factory dynamics row is present in `bmw_f32_verified_dynamics.data`. These rows are still not playable until the correct transmission, xDrive, audio, visual and physics implementations exist.

The retained research record did not preserve an exact gearbox suffix/code for the current eight factory-exact rows. The field is deliberately empty and `gearbox_exact_code_status=not_retained_in_research_record`. No 8HP45/8HP50/8HP70 or manual gearbox suffix may be inferred merely from torque capacity, badge or ratio similarity.

## Restoration scope

This commit establishes a durable schema and restores the first factory-exact tranche without replacing previously researched facts with new guesses. The remaining approved combinations must be migrated into the same files as their retained exact mass, gearing, transmission and performance evidence is recovered from PR history and research records.

The automated `bmw_f32_research_data_test.gd` contract prevents:

- loss or duplication of any of the 44 approved candidate IDs;
- references to missing engine calibrations;
- invented drivetrain/transmission combinations;
- partial six- or eight-speed ratio sets in factory-exact rows;
- loss of DIN/EU mass, final drive, tyre, aerodynamic or performance fields;
- silent invention of an exact gearbox suffix.
