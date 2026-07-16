# BMW F32 persistent research datasets

The BMW 4 Series F32 implementation must consume retained structured research data rather than reconstructing parameters from marketing badges or prose.

## Files

- `bmw_f32_variant_matrix.data` — the complete owner-approved 44-row matrix. Every mechanically distinct engine, transmission and drivetrain combination has a stable `candidate_id`.
- `bmw_f32_engines.data` — the 17 distinct engine/calibration records used by the matrix. This remains a migration input, not proof that every shared calibration is final.
- `bmw_f32_verified_dynamics.data` — factory-exact mass, gearing, tyre, aerodynamic and performance data recovered for the eight launch configurations covered by the retained June 2013 BMW technical specification.
- `bmw_f32_torque_curve_evidence.data` — curve-specific evidence state for every engine calibration. It distinguishes retained peak/plateau anchors from a complete sampled full-load curve and blocks all 44 candidates while sampled curves are absent.
- `bmw_f32_official_powertrain_support.data` — official BMW 03/2016 F36 and 01/2017 F32 evidence that supports or challenges individual engine/gearing facts without pretending that a different body or later exterior phase supplies exact pre-LCI F32 dynamics.

## Data-state rules

`implementation_status=planned` means that a combination is approved and retained but must not yet be exposed in the playable catalog. It does not mean that missing values may be synthesized.

`implementation_status=verified_dynamics` means that a complete factory dynamics row is present in `bmw_f32_verified_dynamics.data`. These rows are still not playable until the correct transmission, xDrive, audio, visual and physics implementations exist.

`runtime_eligibility=blocked` in the torque-curve table means that no `CarSpecs`, playable scene, AI scene, performance calibration or DPI row may be generated for that engine calibration. Peak torque, peak power and a plateau range are validation anchors; they are not a sampled torque curve.

`runtime_eligibility=support_only` means that an official source can confirm a subset of the powertrain facts but cannot complete the exact pre-LCI F32 runtime row. Such evidence may guide migration and detect conflicts; it may not be copied into mass, aero, performance or control fields that the source does not prove.

The retained research record did not preserve an exact gearbox suffix/code for the current eight factory-exact rows. The field is deliberately empty and `gearbox_exact_code_status=not_retained_in_research_record`. No 8HP45/8HP50/8HP70 or manual gearbox suffix may be inferred merely from torque capacity, badge or ratio similarity.

## Torque-curve gate

The full 265-commit branch audit found no hidden sampled torque-curve tables. The retained BMW data contains:

- peak output and torque for all 17 calibrations;
- official power-RPM and torque-plateau ranges for N20 180 kW, N55 225 kW and N47 135 kW;
- transmission-specific peak torque for the two ZHP calibrations;
- an official-source conflict for the B48 420i calibration.

None of those records is a complete full-load curve. Interpolating from idle to the peak, holding a flat plateau outside its documented range, copying another calibration or tuning a generic curve to the 0–100 km/h target is prohibited.

## Official 420i B48 conflict

The evidence layer deliberately records a calibration conflict rather than hiding it:

- the official F36 Gran Coupé specification valid from 03/2016 lists 270 Nm for the 420i B48 application;
- the official F32 LCI Coupé specification from 01/2017 lists 290 Nm for the six-speed manual and a bracketed 270 Nm for the eight-speed automatic;
- the current retained `b48b20_135` row preserves one historical shared 290-Nm value while remaining conflict-gated.

Before either pre-LCI 420i B48 candidate can become complete, primary F32 evidence valid for 03/2016–02/2017 must establish whether the transmission-specific split already applied before the LCI. The row must then be split or corrected as proven. A convenient common torque curve is prohibited.

## Restoration scope

This dataset suite establishes a durable schema and restores the first factory-exact tranche without replacing previously researched facts with new guesses. The remaining approved combinations must be migrated into the same files as their exact mass, gearing, transmission, torque-curve and performance evidence is recovered or revalidated.

The automated BMW research contracts prevent:

- loss or duplication of any of the 44 approved candidate IDs;
- references to missing engine calibrations;
- invented drivetrain/transmission combinations;
- partial six- or eight-speed ratio sets in factory-exact rows;
- loss of DIN/EU mass, final drive, tyre, aerodynamic or performance fields;
- use of peak/plateau anchors as a fabricated sampled torque curve;
- silent invention of an exact gearbox suffix;
- promotion of F36 or LCI support evidence into exact pre-LCI F32 dynamics;
- concealment of the 420i B48 manual/automatic torque discrepancy.
