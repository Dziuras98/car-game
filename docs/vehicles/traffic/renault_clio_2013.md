# Renault Clio IV X98 — research and approved scope

- Model number in Traffic Rider bundle: **03**
- Source GLB: `03_renault_clio_2013.glb`
- Source SHA-256: `48081738ea28f0ef1360461c7790dadc4c4acc8547b5ac872dcd3a12606438b4`
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **11 mechanically distinct non-R.S. hatchback configurations**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source mesh represents a **Renault Clio IV (X98) five-door hatchback, Phase 1 / pre-facelift, standard non-R.S. body**.

It is not:

- the longer Estate / Grandtour / Sport Tourer body;
- the August-2016-and-later Phase 2 facelift;
- an R.S. body with its front blade, rear diffuser and R.S.-specific chassis details;
- an exact GT body with GT-specific bumpers and trim.

The hidden rear-door handles, lamp shapes, grille and bumpers identify the launch body sold from late 2012 until the 2016 facelift. Exact trim and wheel package remain unresolved.

Identity confidence: **high for X98 five-door hatchback and Phase 1; high for standard non-R.S. body; trim unresolved**.

The owner approved mechanically distinct non-R.S. variants from the entire Clio IV generation, including Phase 2 and late Clio Génération production. Phase 2 variants therefore require a separately authored facelift visual derivative or another accurate visual source. The Phase 1 mesh must not be silently reused as a visually exact Phase 2 car.

## Reference dimensions

Primary five-door hatchback reference:

| Parameter | Reference |
|---|---:|
| Overall length | approximately 4.062 m |
| Width excluding mirrors | approximately 1.732 m |
| Width including mirrors | approximately 1.945 m |
| Height | approximately 1.448 m for the standard hatchback |
| Wheelbase | 2.589 m |

Final visual scale must use the 2.589 m wheelbase as the primary reference and cross-check length, width, height, tracks, ground clearance and the approved wheel/tyre size. Phase 2 bumper and lighting changes require separate dimension and visibility cross-checks even though the core wheelbase is retained.

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

The approved boundary is the **five-door Clio IV hatchback across Phase 1, Phase 2 and late Clio Génération production**, excluding Estate and every Renault Sport derivative.

Owner-directed rules:

- include every mechanically distinct non-R.S. engine/transmission combination;
- include the GT 120 EDC as a separate chassis/visual configuration;
- exclude all R.S. 200, Cup, Trophy and related Renault Sport configurations;
- include the regional D4F 1.2 16V 65 subject to final primary-document verification;
- exclude every factory LPG/bi-fuel variant;
- merge torque/emissions revisions under one engine/transmission row when architecture and gearbox are unchanged;
- include dCi 90 EDC;
- do not create separate `99 g`, `83 g`, Energy, EcoBusiness or Clio Génération duplicates when the underlying mechanics are unchanged;
- all approved production variants are FWD.

A different gearbox behind the same engine remains a separate configuration. A genuinely different chassis calibration, as with GT, remains separate even when the engine and transmission are shared with a standard-body row.

## Approved engine and powertrain matrix

| # | Generation application | Engine / merged calibration | Transmission architecture | Visual/chassis treatment | Status |
|---:|---|---|---|---|---|
| 1 | regional Phase 1 | D4F 1.2 16V naturally aspirated I4, approximately 65 PS | conventional 5MT; exact suffix pending | standard Phase 1 body | **approved**, primary regional document still required |
| 2 | Phase 1 and early Phase 2 | D4F-740 1.2 16V naturally aspirated I4, 75 PS / approximately 107 Nm | conventional 5MT | Phase-appropriate standard body | **approved** |
| 3 | late Phase 2 and Clio Génération | H4B/H4Bt 0.9 TCe turbo I3, 75 PS | conventional 5MT | Phase 2 visual required | **approved** |
| 4 | Phase 1, Phase 2 and Clio Génération | H4B/H4Bt 0.9 TCe turbo I3, 90 PS; 135/140 Nm revisions merged | conventional 5MT | Phase-appropriate standard body | **approved** |
| 5 | Phase 1 and Phase 2 standard hatchback | H5F/H5Ft 1.2 TCe direct-injection turbo I4, 120 PS; 190/205 Nm revisions merged | Renault EDC six-speed dry DCT | standard-body configuration, phase-appropriate visual | **approved** |
| 6 | Phase 2 | H5F/H5Ft 1.2 TCe direct-injection turbo I4, 120 PS / approximately 205 Nm | conventional 6MT | Phase 2 visual required | **approved** |
| 7 | Phase 1 GT | H5F/H5Ft 1.2 TCe direct-injection turbo I4, 120 PS; merged GT calibration | GT-calibrated Renault EDC six-speed dry DCT | GT-specific bumpers, trim, steering and chassis | **approved** |
| 8 | Phase 1 and Phase 2 | K9K 1.5 dCi turbo-diesel I4, 75 PS; torque/emissions revisions merged | conventional 5MT | phase-appropriate standard body | **approved** |
| 9 | Phase 1, Phase 2 and late production | K9K 1.5 dCi turbo-diesel I4, 90 PS / approximately 220 Nm | conventional 5MT | phase-appropriate standard body | **approved** |
| 10 | Phase 1/Phase 2 market availability | K9K 1.5 dCi turbo-diesel I4, 90 PS / approximately 220 Nm | Renault EDC six-speed dry DCT | phase-appropriate standard body | **approved**, exact introduction date requires retained official market guide |
| 11 | Phase 2 | K9K 1.5 dCi turbo-diesel I4, 110 PS / approximately 260 Nm | conventional 6MT | Phase 2 visual required | **approved** |

**Approved total: 11 mechanically distinct non-R.S. configurations.**

Clio Génération marketing does not add a twelfth row when it repeats the approved H4B TCe 75 or TCe 90 powertrain without a mechanical change.

## Explicit exclusions

The following are outside the approved scope:

- every R.S. 200 Sport, R.S. 200 Cup, R.S. 220 Trophy, R.S. 18 and R.S.16 concept configuration;
- D4F 1.2 LPG;
- H4B 0.9 TCe LPG;
- Estate / Grandtour / Sport Tourer bodies;
- separate torque-revision entries for TCe 90 or TCe 120;
- separate low-emission `99 g`, `83 g`, Energy or EcoBusiness duplicates;
- duplicate Clio Génération catalog rows when mechanics match an existing approved row;
- AWD or RWD, because production Clio IV road variants in this scope are FWD.

## Transmission architecture assessment

### Conventional five-speed manuals

The D4F, H4B and lower-output K9K rows use conventional driver-operated clutch/manual transmissions. Exact JH/JR gearbox family and suffix, forward/reverse ratios and final drive must be established per approved row. A shared generic ratio set is not acceptable.

### Conventional six-speed manuals

The Phase 2 H5F TCe 120 and K9K dCi 110 use conventional six-speed manual gearboxes. Their exact family, suffix, ratios, final drive, clutch capacity and rotating inertia must be researched independently from the five-speed units.

### Renault EDC six-speed dual-clutch transmission

The H5F TCe 120, GT 120 and K9K dCi 90 EDC rows use a **six-speed dry dual-clutch transmission**, commonly associated with the Renault DC4/Getrag 6DCT250 family. It is not a torque-converter automatic and must not use the classic-automatic model.

A later implementation requires a dedicated DCT model with:

- two clutch paths for odd and even gears;
- gear preselection;
- launch clutch slip and creep strategy;
- clutch-temperature and protection behaviour;
- torque handover during upshifts/downshifts rather than a generic full torque cut;
- kickdown and multi-gear selection;
- engine torque intervention and rev matching;
- distinct standard petrol, diesel and GT shift calibrations.

Exact DC4/Getrag suffix and ratios remain mandatory per approved engine.

## Chassis and visual subdivisions

- Standard Phase 1 rows use the source body most faithfully.
- Standard Phase 2 and Clio Génération rows require an accurate facelift visual derivative; the source Phase 1 bumper/lamp set is not sufficient.
- GT requires GT-specific bumpers, trim, steering/chassis calibration and potentially different wheels; it cannot be represented as a badge-only duplicate.
- Estate is excluded because its body, mass and aerodynamics differ materially.
- All Renault Sport derivatives are excluded by owner decision.

## Performance and physics requirements

For every approved configuration, later parameter research must establish:

- sampled full-load torque curve and transient turbo behaviour;
- exact gearbox ratios and final drive;
- clutch and DCT control behaviour;
- exact kerb mass, axle loads and centre of mass for the relevant phase and trim;
- tyre dimensions and rolling radius;
- drag coefficient and frontal area;
- braking and steering targets;
- documented 0–100 km/h, in-gear and top-speed targets;
- GT suspension, steering and grip differences;
- validation against the current `master` physics baseline at implementation time.

Performance may not be matched with false torque, wrong mass, incorrect gearbox architecture or an arbitrary hidden cap.

## Engine-audio architecture assessment

| Engine family | Required treatment |
|---|---|
| D4F | naturally aspirated inline-four with port injection and belt-driven valvetrain |
| H4B/H4Bt | dedicated turbo inline-three firing cadence, collector, induction and small-turbo transient model |
| H5F/H5Ft | direct-injection turbo inline-four, distinct from H4B and naturally aspirated D4F; GT receives a separate intake/exhaust/load profile |
| K9K | common-rail turbo-diesel inline-four with calibration-specific injection, combustion and turbo layers |

The H4B inline-three must not be generated by pitch-shifting an inline-four. The D4F, H5F and K9K must not collapse into one generic four-cylinder waveform.

## Evidence retained and unresolved implementation research

Primary-source references retained or identified for final verification include:

- Renault, *New Renault Clio: love-at-first-sight styling, and packed with innovations*, 3 July 2012, archived official Renault media release;
- archived official Renault Clio Phase 2 brochure captured on 7 November 2017;
- official Renault Clio market price lists and homologation material for Phase 1, Phase 2 and Clio Génération;
- Renault official GT 120 EDC material;
- market-specific documentation for the 1.2 65 and the exact dCi 90 EDC introduction date.

Before implementation, retain exact primary documentation for every approved row's engine code, gearbox suffix and ratios, final drive, mass, tyres, emissions-generation changes and performance. These evidence requirements may refine parameters but do not reopen the owner-approved catalog scope.

## Owner decision recorded

The owner decided:

1. Include all researched non-R.S. Clio IV hatchback configurations.
2. Include the regional 1.2 16V 65, but exclude every LPG/bi-fuel variant.
3. Include GT 120 EDC; exclude every Renault Sport configuration.
4. Merge TCe 90 135/140 Nm and TCe 120 190/205 Nm revisions into one row per transmission/chassis architecture.
5. Include dCi 90 EDC.
6. Do not create separate Energy, EcoBusiness, `99 g` or `83 g` entries.
7. Expand beyond Phase 1 to Phase 2 and later Clio Génération non-R.S. variants, including TCe 75, TCe 120 6MT and dCi 110 6MT.
8. Missing expected variants were the non-R.S. later-generation rows now included above; no additional missing configuration was identified.

The individual owner-scope gate is satisfied. Model 03 is **`approved`**, but implementation remains blocked by the global all-model research gate. Research proceeds to model 04.
