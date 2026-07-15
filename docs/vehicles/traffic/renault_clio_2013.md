# Renault Clio IV X98 Phase 1 — research and owner-scope gate

- Model number in Traffic Rider bundle: **03**
- Source GLB: `03_renault_clio_2013.glb`
- Source SHA-256: `48081738ea28f0ef1360461c7790dadc4c4acc8547b5ac872dcd3a12606438b4`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source mesh represents a **Renault Clio IV (X98) five-door hatchback, Phase 1 / pre-facelift, standard non-R.S. body**.

It is not:

- the longer Estate / Grandtour / Sport Tourer body;
- the August-2016-and-later Phase 2 facelift;
- an R.S. body with its front blade, rear diffuser and R.S.-specific chassis details;
- an exact GT body with GT-specific bumpers and trim.

The hidden rear-door handles, lamp shapes, grille and bumpers identify the launch body sold from late 2012 until the 2016 facelift. The texture represents a normal road Clio rather than a visibly badged GT or R.S. derivative. Exact trim and wheel package remain unresolved.

Identity confidence: **high for X98 five-door hatchback and Phase 1; high for standard non-R.S. body; trim unresolved**.

## Reference dimensions

Primary Phase 1 hatchback reference:

| Parameter | Reference |
|---|---:|
| Overall length | approximately 4.062 m |
| Width excluding mirrors | approximately 1.732 m |
| Width including mirrors | approximately 1.945 m |
| Height | approximately 1.448 m for the standard hatchback |
| Wheelbase | 2.589 m |

Final visual scale must use the 2.589 m wheelbase as the primary reference and cross-check length, width, height, tracks, ground clearance and the approved wheel/tyre size.

## Source inspection

| Item | Result |
|---|---|
| Source meshes | 3 |
| Body mesh | `AI_Clio_High_Renault_Clio_2013_0` |
| Front wheel-pair mesh | `on_teker.002_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.002_wheel_0` |
| Body triangles | 1,398 |
| Front wheel-pair triangles | 360 |
| Rear wheel-pair triangles | 360 |
| Total triangles | 2,118 |
| Source scene AABB | approximately 2.862926 × 2.094841 × 5.847640 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 3.784997 source units |
| Approximate wheelbase-derived scale | 0.684016 for a 2.589 m real wheelbase |

The source GLB remains unchanged. A future derivative must split both paired axle meshes into four independent hub-centred wheel nodes, but that work is deferred until all model scopes are approved.

## Research boundary and deduplication

The research boundary is the **Phase 1 five-door hatchback from launch through the August 2016 facelift**, across European markets. Estate body variants are excluded. GT and R.S. derivatives are listed separately because their visible body details and chassis behaviour differ from the source model.

The matrix distinguishes:

- genuinely different engine calibrations;
- conventional five-speed manuals from six-speed EDC dual-clutch transmissions;
- materially different Sport, Cup and Trophy chassis configurations;
- standard fuel from factory LPG/bi-fuel variants;
- low-CO2 packages only when official evidence shows different gearing, tyres, aero or control calibration.

A marketing trim with identical mechanics must not create a duplicate catalog entry.

Evidence states:

- `strongly_supported`: consistent Renault-era material and technical data;
- `provisional_regional`: documented market occurrence, but an official market price list/order guide still needs to be retained;
- `disputed_timing`: sources disagree on whether the combination entered before or with the Phase 2 facelift;
- `rejected/not_factory`: no factory evidence for the Phase 1 hatchback.

## Candidate engine and powertrain matrix

All production road cars below are FWD. No AWD or rear-wheel-drive Clio IV road variant belongs in this matrix.

| # | Phase 1 application | Engine / calibration | Transmission architecture | Visual/chassis relationship | Evidence |
|---:|---|---|---|---|---|
| 1 | regional 2014–2015 | D4F 1.2 16V naturally aspirated I4, approximately 65 PS | conventional 5MT; exact JH-family suffix pending | standard source body | `provisional_regional` |
| 2 | launch–facelift | D4F-740 1.2 16V naturally aspirated I4, 75 PS / approximately 107 Nm | conventional 5MT; exact suffix pending | standard source body | `strongly_supported` |
| 3 | approximately 2013–mid-2016 | D4F-740 1.2 16V factory petrol/LPG, approximately 72 PS / 107 Nm | conventional 5MT | standard source body; distinct fuel system and mass | `provisional_regional` |
| 4 | launch–facelift, early calibration | H4Bt/H4B 0.9 Energy TCe turbo I3, 90 PS / approximately 135 Nm | conventional 5MT | standard source body | `strongly_supported`; calibration split needs primary confirmation |
| 5 | later Phase 1 calibration | H4Bt/H4B 0.9 Energy TCe turbo I3, 90 PS / approximately 140 Nm | conventional 5MT | standard source body | `provisional_regional`; do not merge with row 4 without proof |
| 6 | launch–facelift | K9K-612 1.5 dCi turbo-diesel I4, 75 PS / approximately 200 Nm | conventional 5MT | standard source body | `strongly_supported` |
| 7 | launch–facelift | K9K-608 1.5 Energy dCi turbo-diesel I4, 90 PS / approximately 220 Nm | conventional 5MT | standard source body | `strongly_supported` |
| 8 | reported from 2013 in some markets; other data places it at facelift | K9K 1.5 dCi turbo-diesel I4, 90 PS / approximately 220 Nm | Renault EDC six-speed dry dual-clutch transmission | standard source body | `disputed_timing`; official Phase 1 order guide required |
| 9 | GT, approximately 2013–2016 | H5Ft/H5F 1.2 TCe direct-injection turbo I4, 120 PS / approximately 190 Nm | Renault EDC six-speed dry DCT | GT-specific body details and chassis | `strongly_supported` |
| 10 | later Phase 1 market/calibration candidate | H5Ft/H5F 1.2 TCe turbo I4, 120 PS / approximately 205 Nm | Renault EDC six-speed dry DCT | exact standard/GT/Initiale application pending | `provisional_regional`; separate from row 9 if confirmed |
| 11 | R.S. 200 EDC | M5Mt/MR16DDT 1.6 direct-injection turbo I4, 200 PS / 240 Nm | R.S.-calibrated six-speed EDC DCT | R.S. body; **Sport and Cup chassis are materially separate configurations** | `strongly_supported` |
| 12 | R.S. 220 EDC Trophy, 2015–pre-facelift 2016 | M5Mt/MR16DDT 1.6 turbo I4, 220 PS; approximately 260 Nm with approximately 280 Nm overboost | faster R.S.-calibrated six-speed EDC DCT | Trophy-specific lowered/stiffer chassis and visual details | `strongly_supported` |

### Candidate totals

- **12 candidate engine/calibration/transmission rows** before owner exclusions;
- row 11 expands into separate R.S. 200 Sport and Cup chassis configurations;
- therefore **13 candidate physical catalog configurations** before any low-CO2 package subdivisions;
- rows 5, 8 and 10 remain provisional/disputed and require retained primary market documentation before implementation parameters can be committed.

## Efficiency-package subdivisions

Period Clio data lists low-CO2 derivatives such as TCe 90 `99 g`, dCi 90 `83 g` and other Energy/EcoBusiness configurations. They must not become duplicate vehicles solely because of an emissions label.

A separate physical configuration is justified only when official documentation confirms a material difference such as:

- gearbox or final-drive ratios;
- tyre size or low-rolling-resistance construction;
- ride height or aero equipment;
- ECU torque/control calibration;
- mass or equipment deletion.

Otherwise one standard engine/transmission row is retained.

## Transmission architecture assessment

### Conventional five-speed manuals

The D4F, H4B and K9K rows use conventional driver-operated clutch/manual transmissions. Exact JH/JR gearbox family and suffix, forward/reverse ratios and final drive must be established per approved row. A shared generic ratio set is not acceptable.

### Renault EDC six-speed dual-clutch transmission

The H5F, disputed dCi EDC and M5Mt rows use a **six-speed dry dual-clutch transmission**, commonly associated with the Renault DC4/Getrag 6DCT250 family. It is not a torque-converter automatic and must not use the existing classic-automatic model.

A later implementation requires a dedicated DCT model with:

- two clutch paths for odd and even gears;
- gear preselection;
- launch clutch slip and creep strategy;
- clutch-temperature and protection behaviour where relevant;
- torque handover during upshifts/downshifts rather than a generic full torque cut;
- kickdown and multi-gear selection;
- engine torque intervention and rev matching;
- distinct normal, GT and R.S./Trophy shift calibrations;
- launch control for the R.S. variants.

Exact DC4/Getrag suffix and ratios remain mandatory per approved engine.

## Chassis and visual subdivisions

- Standard Clio rows use the source body most faithfully.
- GT requires GT-specific bumpers, trim, steering/chassis calibration and potentially different wheels; it cannot be represented as a badge-only duplicate.
- R.S. 200 requires an R.S.-specific visual derivative. Sport and Cup chassis must remain distinct if approved because spring/damper rates, ride height and handling targets differ materially.
- R.S. 220 Trophy requires its own visual/chassis configuration and faster transmission calibration.
- Estate/Grandtour is excluded because the body, mass and aero differ materially.
- The R.S.16 was a concept, not a normal production variant, and is excluded.

## Performance and physics requirements

For every approved configuration, later parameter research must establish:

- sampled full-load torque curve and transient turbo behaviour;
- exact gearbox ratios and final drive;
- clutch and DCT control behaviour;
- exact kerb mass, axle loads and centre of mass;
- tyre dimensions and rolling radius;
- drag coefficient and frontal area;
- braking and steering targets;
- documented 0–100 km/h, in-gear and top-speed targets;
- Sport/Cup/Trophy suspension and grip differences;
- validation against the current `master` physics baseline at implementation time.

Representative published targets range from approximately 14.5 s to 100 km/h for the 1.2 75 to approximately 6.7 s for R.S. 200 and 6.6 s for R.S. 220 Trophy. These are validation anchors, not direct tuning values, and must be replaced by exact factory values for each approved row.

## Engine-audio architecture assessment

| Engine family | Required treatment |
|---|---|
| D4F | naturally aspirated inline-four with port injection and belt-driven valvetrain; LPG state needs its own combustion/transient profile if approved |
| H4B/H4Bt | dedicated turbo inline-three firing cadence, collector, induction and small-turbo transient model |
| H5F/H5Ft | direct-injection turbo inline-four, distinct from H4B and naturally aspirated D4F |
| K9K | common-rail turbo-diesel inline-four with calibration-specific injection, combustion and turbo layers |
| M5Mt/MR16DDT | high-output direct-injection turbo inline-four with R.S.-specific intake, exhaust, turbo, limiter and overrun behaviour |

The H4B inline-three must not be generated by pitch-shifting an inline-four. The D4F, H5F, K9K and M5Mt must not collapse into one generic four-cylinder waveform.

## Evidence retained and unresolved work

Primary-source references retained for final verification include:

- Renault, *New Renault Clio: love-at-first-sight styling, and packed with innovations*, 3 July 2012 (archived official Renault media release);
- official Renault Clio brochures and market price lists for Phase 1;
- Renault UK official Clio Renault Sport model material;
- Renault/Renault Sport official R.S. 200, GT 120 EDC and R.S. 220 Trophy press material;
- market-specific homologation/order data for the 1.2 65, LPG, dCi 90 EDC and torque-revision rows.

Before implementation, retain exact primary documentation for every approved row's engine code, torque revision, gearbox suffix/ratios, final drive, mass, tyres and performance.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Approve all **13 candidate physical configurations**, or restrict the scope to standard-body variants that closely match the source mesh?
2. Include the regional 1.2 16V 65 and factory 1.2 LPG variants, subject to final primary-document verification?
3. Include GT 120 EDC, R.S. 200 Sport, R.S. 200 Cup and R.S. 220 Trophy even though they require distinct visual and chassis derivatives?
4. Keep the 135/140 Nm TCe 90 and 190/205 Nm TCe 120 revisions separate when final Renault documentation confirms different factory calibrations?
5. Include the disputed Phase 1 dCi 90 EDC only if an official pre-facelift order guide confirms it?
6. For 99 g / 83 g Energy or EcoBusiness derivatives, create a separate configuration only when gearing, tyres, aero or calibration materially differ, or always choose one standard configuration per powertrain?
7. Keep the visual and mechanical scope strictly Phase 1, excluding Phase 2-only dCi 110, TCe 120 6MT, 0.9 TCe LPG and later variants?
8. Is any expected engine, transmission, chassis or Phase 1 model-year variant missing from this matrix?

No implementation begins after this individual decision. Research proceeds to model 04 only after the owner answers, and implementation begins only after every included model has reached `approved`.
