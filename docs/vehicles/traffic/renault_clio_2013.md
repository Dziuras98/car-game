# Renault Clio IV X98 — research and approved scope

- Model number in Traffic Rider bundle: **03**
- Source GLB: `03_renault_clio_2013.glb`
- Source SHA-256: `48081738ea28f0ef1360461c7790dadc4c4acc8547b5ac872dcd3a12606438b4`
- Research date: 2026-07-15
- Owner decision dates: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **10 mechanically distinct non-R.S., non-GT hatchback configurations**
- Physics baseline inspected: `master` at `9d4aa60ec539f6b22211557ebb1ce0659cd7c512`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source mesh represents a **Renault Clio IV (X98) five-door hatchback, Phase 1 / pre-facelift, standard non-R.S. body**. It is not the longer Estate/Grandtour, the Phase 2 facelift, a Renault Sport body or the GT derivative.

The approved scope covers mechanically distinct standard hatchback variants from Phase 1, Phase 2 and late Clio Génération production. Phase 2 variants require an accurate facelift derivative or another correct visual source. The Phase 1 mesh must not be presented as an exact Phase 2 car.

Reference dimensions:

| Parameter | Reference |
|---|---:|
| Overall length | approximately 4.062 m |
| Width excluding mirrors | approximately 1.732 m |
| Width including mirrors | approximately 1.945 m |
| Height | approximately 1.448 m |
| Wheelbase | 2.589 m |

Final scale must use the 2.589 m wheelbase as the primary reference.

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
| Approximate wheelbase-derived scale | 0.684016 |

The source GLB remains unchanged. Wheel separation and every other implementation action remain deferred by the global research gate.

## Owner-directed scope rules

- include every approved mechanically distinct standard non-R.S. engine/transmission combination;
- **exclude GT 120 EDC**;
- exclude every R.S. 200, Cup, Trophy and related Renault Sport configuration;
- include the regional D4F 1.2 16V 65 subject to final primary-document verification;
- exclude every LPG/bi-fuel variant;
- merge torque/emissions revisions when engine architecture and transmission are unchanged;
- include dCi 90 EDC;
- do not create `99 g`, `83 g`, Energy, EcoBusiness or Clio Génération duplicates when mechanics are unchanged;
- all approved variants are FWD.

## Approved engine and powertrain matrix

| # | Generation application | Engine / merged calibration | Transmission architecture | Visual treatment |
|---:|---|---|---|---|
| 1 | regional Phase 1 | D4F 1.2 16V naturally aspirated I4, approximately 65 PS | conventional 5MT; exact suffix pending | standard Phase 1 |
| 2 | Phase 1 and early Phase 2 | D4F-740 1.2 16V naturally aspirated I4, 75 PS / approximately 107 Nm | conventional 5MT | phase-appropriate standard body |
| 3 | late Phase 2 and Clio Génération | H4B/H4Bt 0.9 TCe turbo I3, 75 PS | conventional 5MT | Phase 2 visual required |
| 4 | Phase 1, Phase 2 and Clio Génération | H4B/H4Bt 0.9 TCe turbo I3, 90 PS; 135/140 Nm revisions merged | conventional 5MT | phase-appropriate standard body |
| 5 | Phase 1 and Phase 2 standard hatchback | H5F/H5Ft 1.2 TCe direct-injection turbo I4, 120 PS; 190/205 Nm revisions merged | Renault EDC six-speed dry DCT | phase-appropriate standard body |
| 6 | Phase 2 | H5F/H5Ft 1.2 TCe direct-injection turbo I4, 120 PS / approximately 205 Nm | conventional 6MT | Phase 2 visual required |
| 7 | Phase 1 and Phase 2 | K9K 1.5 dCi turbo-diesel I4, 75 PS; torque/emissions revisions merged | conventional 5MT | phase-appropriate standard body |
| 8 | Phase 1, Phase 2 and late production | K9K 1.5 dCi turbo-diesel I4, 90 PS / approximately 220 Nm | conventional 5MT | phase-appropriate standard body |
| 9 | Phase 1/Phase 2 market availability | K9K 1.5 dCi turbo-diesel I4, 90 PS / approximately 220 Nm | Renault EDC six-speed dry DCT | phase-appropriate standard body |
| 10 | Phase 2 | K9K 1.5 dCi turbo-diesel I4, 110 PS / approximately 260 Nm | conventional 6MT | Phase 2 visual required |

**Approved total: 10 mechanically distinct non-R.S., non-GT configurations.**

Clio Génération does not add another row when it repeats TCe 75 or TCe 90 without a mechanical change.

## Explicit exclusions

- GT 120 EDC;
- every R.S. 200 Sport, R.S. 200 Cup, R.S. 220 Trophy, R.S. 18 and R.S.16 concept configuration;
- D4F 1.2 LPG and H4B 0.9 TCe LPG;
- Estate / Grandtour / Sport Tourer;
- separate torque-revision entries for TCe 90 or TCe 120;
- separate `99 g`, `83 g`, Energy or EcoBusiness entries;
- duplicate Clio Génération entries;
- AWD and RWD.

## Transmission architecture assessment

The D4F, H4B and lower-output K9K rows use conventional driver-operated five-speed manuals. TCe 120 and dCi 110 use separate conventional six-speed manual architectures. Exact gearbox family, suffix, ratios, reverse ratio and final drive remain mandatory per row.

The standard H5F TCe 120 and K9K dCi 90 EDC rows use a **six-speed dry dual-clutch transmission**, commonly associated with the Renault DC4/Getrag 6DCT250 family. It must model two clutch paths, preselection, launch slip, creep, clutch temperature, torque handover, kickdown, rev matching and engine torque intervention. The excluded GT calibration must not be added.

## Chassis and visual subdivisions

- Phase 1 standard rows use the source body most faithfully.
- Phase 2 and Clio Génération rows require an accurate facelift derivative.
- GT and all Renault Sport derivatives are excluded.
- Estate is excluded.

## Performance, physics and audio requirements

Each approved row later requires exact torque curves, gearbox/final-drive ratios, mass, axle loads, tyres, drag, brakes, steering and documented performance targets, validated against current `master`.

Required engine-audio families:

| Engine family | Required treatment |
|---|---|
| D4F | naturally aspirated port-injected inline-four |
| H4B/H4Bt | dedicated turbo inline-three cadence and induction model |
| H5F/H5Ft | direct-injection turbo inline-four |
| K9K | common-rail turbo-diesel inline-four |

## Evidence still required before parameter commitment

Retain primary Renault market documents for the regional 1.2 65, exact dCi 90 EDC introduction date, engine codes, gearbox suffixes and ratios, final drives, mass, tyres and performance. These gaps do not reopen the fixed catalog scope.

## Owner decision recorded

The owner finally decided:

1. Keep all previously approved rows except item 7 from the earlier list, **GT 120 EDC**.
2. Include the regional 1.2 16V 65.
3. Exclude every LPG/bi-fuel and Renault Sport variant.
4. Merge TCe 90 and TCe 120 torque revisions per unchanged transmission architecture.
5. Include dCi 90 EDC.
6. Do not create Energy/EcoBusiness/emissions-label duplicates.
7. Include Phase 2 and Clio Génération standard non-R.S. variants.
8. No additional missing standard configuration was identified.

The individual owner-scope gate remains satisfied. Model 03 is **`approved`** with **10** configurations. Research proceeds to model 04; implementation remains blocked by the global all-model research gate.
