# Ford Transit Connect first generation — research and owner-scope gate

- Model number in Traffic Rider bundle: **08**
- Source GLB: `08_ford_transit_connect_2011.glb`
- Source SHA-256: `e506579960a582b33c7f91c9b3a6086f99cb9e97158f635c4e614de69d5b862b`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents a **North American 2011 Ford Transit Connect XLT Premium Wagon**, first generation and final 2009-style facelift, with the long 114.6-in wheelbase and high roof.

Visible source evidence includes:

- North American front fascia and plate treatment;
- full side and rear glazing rather than cargo-panel inserts;
- two sliding side doors and two rear swing doors;
- five-passenger wagon body;
- `XLT` side badging;
- body-colour grille, front fog-lamp treatment and alloy wheels associated with the XLT Premium Wagon;
- red paint and passenger-oriented exterior finish.

The source is not the short-wheelbase low-roof European van, an unglazed cargo conversion, the pre-2009 front treatment or the second-generation 2014 model.

Identity confidence: **high for North American 2011 XLT Premium Wagon, long wheelbase, high roof and final facelift**.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Wheelbase | 114.6 in / 2.91084 m |
| Overall length | approximately 180.6 in / 4.587 m |
| Width excluding mirrors | approximately 70.7 in / 1.796 m |
| Height | approximately 79.3 in / 2.014 m |
| Source meshes | 3 |
| Body mesh | `AI_Ford_Transit_High_Ford_Transit_Connect_2011_0` |
| Front wheel-pair mesh | `on_teker.007_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.007_wheel_0` |
| Body triangles | 1,074 |
| Front wheel-pair triangles | 288 |
| Rear wheel-pair triangles | 288 |
| Total triangles | 1,650 |
| Source scene AABB | approximately 3.047812 × 2.893176 × 6.592365 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 4.155049 source units |
| Approximate wheelbase-derived scale | 0.700555 |

The wheelbase-derived source length is approximately 4.618 m and is close enough to the official long-body length to support the identification, while final integration must independently validate bumpers, tracks, roof height, tyre radius and ground clearance.

The source GLB remains unchanged. Four independent wheels, collision, catalog, physics, transmission and audio remain deferred by the global research gate.

## Research boundary

The complete candidate research covers the **first-generation Transit Connect / Tourneo Connect produced from 2002 through 2013**, including European combustion powertrains, the North American gasoline automatic and the Azure Dynamics electric derivative.

The generation has three major visual periods:

1. **2002–2005 original front**;
2. **2006–2008 first update**;
3. **2009–2013 final facelift**, represented by the source.

Body families include short-wheelbase low-roof vans, long-wheelbase high-roof vans, cargo bodies, European Tourneo passenger bodies and the North American five-passenger Wagon. Body, seating and roof variants do not automatically duplicate an identical powertrain, but they require distinct mass, centre of gravity, aerodynamics and load calibration when approved.

All first-generation production powertrains are front-engine and front-wheel drive. No factory AWD or rear-wheel-drive row is evidenced.

## Complete candidate powertrain matrix

The table is mechanically consolidated. Exact market and body restrictions must be retained from primary Ford order guides before implementation.

| # | Market / period | Powertrain | Transmission | Drivetrain | Evidence state |
|---:|---|---|---|---|---|
| 1 | Europe, approximately 2002–2006 | 1.8L Zetec/Duratec 16-valve naturally aspirated petrol inline-four, approximately 116 PS / 160 Nm | Ford 5-speed manual transaxle, working identification MTX-75 | FWD | `provisional_primary_confirmation_required`; some market summaries label a 2.0L 115-PS petrol instead, so exact displacement/application must be resolved before commitment |
| 2 | Europe, early production | 1.8L Duratorq direct-injection turbo-diesel inline-four, **early 75-PS calibration**, approximately 175 Nm | 5-speed manual transaxle; exact early code pending | FWD | `provisional`; distinct pre-common-rail/direct-injection treatment and changeover need primary Ford evidence |
| 3 | Europe, approximately 2008–2010 | 1.8L Duratorq 75-PS late diesel calibration, approximately 175 Nm | Ford MTX-75-family 5-speed manual transaxle | FWD | `verified_output_family`; exact injection/emissions naming and body restrictions pending |
| 4 | Europe, approximately 2002–2013 | 1.8L Duratorq TDCi 90 PS / approximately 220 Nm | 5-speed manual transaxle; MTX-75 used in later production | FWD | `verified_family`; early gearbox and emissions revisions pending |
| 5 | Europe, approximately 2006–2013 | 1.8L Duratorq TDCi 110 PS / approximately 250 Nm, variable-geometry turbo application | Ford MTX-75-family 5-speed manual transaxle | FWD | `verified_family` |
| 6 | North America, 2010–2013 | 2.0L Duratec DOHC naturally aspirated petrol inline-four, approximately 136 hp / 128 lb-ft (174 Nm) | Ford/Mazda **4F27E** 4-speed planetary torque-converter automatic | FWD | `verified`; this is the strict source-body powertrain |
| 7 | North America and limited European fleets, 2011–2012 | Azure Dynamics Transit Connect Electric: AC induction motor, approximately 100 kW peak / 50–52 kW continuous, 235 Nm; 28-kWh lithium-ion battery | BorgWarner single-speed reduction transaxle, reported 8.28:1 | FWD | `verified_upfit`; Azure Dynamics was manufacturer of record and the derivative was cargo/fleet-oriented rather than a normal Ford factory wagon trim |

**Core candidate total: 7 mechanically distinct powertrain rows.**

If the early and late 75-PS diesel calibrations are merged, the total becomes **6 rows**. Excluding the Azure Dynamics upfit leaves **6 combustion rows**, or **5** with the 75-PS diesels merged. Restricting the project strictly to the represented North American XLT Premium Wagon leaves **1 row: 2.0L Duratec + 4F27E + FWD**.

## Body and trim applicability

### Strict source body

The source-like configuration is:

- long wheelbase and high roof;
- five-passenger fully glazed Wagon;
- XLT Premium exterior;
- two sliding side doors;
- rear 180-degree swing doors;
- North American final-facelift materials and lamps.

The 2.0L Duratec automatic is directly evidenced for this body. European diesel/manual rows require a Tourneo or passenger-body availability check before being placed under the same glazed body.

### Other first-generation bodies

- short-wheelbase low-roof Transit Connect cargo van;
- long-wheelbase high-roof Transit Connect cargo van;
- European Tourneo Connect passenger variants;
- crew/combi and market-specific seating layouts;
- North American XL/XLT cargo conversions;
- taxi and mobility conversions.

These should not create catalog duplicates unless the owner wants the physical body, mass, seating or aerodynamic difference represented.

## Fuel and conversion subdivisions

- the European petrol and North American 2.0L rows are gasoline powertrains;
- the 1.8L diesel rows use diesel fuel and may require year-specific Euro 3/4/5, EGR, oxidation catalyst and DPF treatment;
- LPG or CNG conversions existed in some markets and taxi/fleet programs, but current evidence treats them as conversion/upfit states rather than automatic core factory rows;
- the Azure electric derivative is a separate complete drivetrain, not a fuel toggle on the 2.0L vehicle.

A diesel row with DPF must model regeneration-related exhaust and thermal behaviour. A non-DPF row must not inherit DPF backpressure or regeneration logic.

## Chassis and physics architecture

All combustion rows require:

- transverse front engine and front-wheel drive;
- unit-body compact-commercial structure;
- front MacPherson-strut suspension;
- rear commercial torsion/twist-beam architecture with year/body-correct spring and damper rates;
- body- and payload-specific mass, centre of gravity and axle loading;
- high-roof aerodynamic sensitivity and crosswind response;
- front-drive torque steer, traction limits and load-dependent rear behaviour;
- year-correct steering, ABS and stability-control availability;
- disc/drum or disc-brake details verified by exact year and market before parameter commitment.

The passenger Wagon, empty cargo van and loaded cargo van cannot share one mass and centre-of-gravity calibration.

The electric row additionally requires battery mass and placement, reduced payload, regenerative braking blending, inverter/motor limits, temperature-dependent power and state-of-charge behaviour.

## Transmission architecture assessment

### European five-speed manual

The manual rows need a conventional driver-operated dry clutch and a real five-speed transaxle. Required data include exact ratios, reverse, final drive, clutch inertia/capacity, engine braking, synchronizer behaviour and differential type. An automatic or automated-clutch approximation is prohibited.

### 4F27E four-speed automatic

The North American 2.0L row uses a conventional planetary automatic with hydrodynamic torque converter. It requires converter multiplication and slip, creep, lock-up, four exact forward ratios, reverse, torque and inertia shift phases, kickdown, grade/load scheduling and thermal protection.

### Electric single-speed transaxle

The Azure row needs the reported single reduction ratio, motor-speed limits, inverter power envelope, regenerative braking, coast behaviour and battery state. It must not use a combustion automatic with fixed gear selection.

## Engine and driveline audio architecture

| Powertrain | Required treatment |
|---|---|
| 1.8/2.0 petrol inline-four | naturally aspirated inline-four firing cadence, intake, exhaust and accessory layers specific to the engine family |
| early 1.8 diesel 75 | older direct-injection diesel combustion and fixed-geometry turbo/mechanical layers |
| 1.8 TDCi 75/90 | common architecture may be shared where hardware is proven, but output, turbo, injection and emissions transients remain calibration-specific |
| 1.8 TDCi 110 | distinct VGT spool, boost and high-output combustion behaviour |
| Azure electric | motor electromagnetic orders, reduction whine, inverter switching, tyre/road and regenerative-load response; no combustion waveform |

The 110-PS diesel may not be produced only by raising the volume or pitch of the 75/90-PS profile.

## Evidence still required before parameter commitment

Before implementation retain primary Ford or manufacturer documentation for:

- the exact European petrol displacement and market years;
- the early-versus-late 75-PS diesel injection architecture and changeover;
- exact gearbox code, ratios and final drive for every manual row;
- 4F27E ratios, converter and calibration;
- engine/body availability across SWB/LWB, cargo and Tourneo bodies;
- year-specific emissions and DPF status;
- exact curb mass, axle loads, tyres, brakes, drag and performance targets;
- Azure motor continuous/peak ratings, reduction ratio, battery usable energy, mass and regenerative limits;
- LPG/CNG conversion hardware if any such row is approved.

These evidence gates prevent guessed parameters but do not block the owner from selecting the catalog scope.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Keep only the strict **2011–2013 North American XLT Premium Wagon** powertrain, or cover the complete 2002–2013 first generation?
2. If the generation is covered, include all six combustion rows listed above?
3. Keep the early and late 75-PS diesels separate, or merge them into one 75-PS diesel row?
4. Include the Azure Dynamics electric derivative despite Azure being manufacturer of record and the vehicle being a fleet cargo upfit?
5. Keep only the long-wheelbase high-roof passenger body represented by the source, or add SWB/low-roof, cargo and Tourneo body configurations?
6. Preserve only the source-like 2009–2013 XLT Premium appearance, or create accurate 2002–2005 and 2006–2008 visual phases?
7. For European powertrains, use one verified representative body/trim per powertrain rather than duplicating identical mechanics across trims?
8. Exclude LPG/CNG and taxi/mobility conversions, or include specific fully documented upfits?
9. For diesel rows, keep separate DPF/non-DPF emissions hardware where physically different, or store it as selected-year metadata inside each engine row?
10. Use one standard final drive and standard differential state per approved powertrain/transmission row?
11. Is any expected engine, transmission, body, fuel or model-year variant missing?

No implementation begins after this individual decision. Research proceeds to model 09 only after the owner fixes model 08 scope, and implementation begins only after every included model has reached `approved`.
