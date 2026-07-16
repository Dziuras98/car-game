# Ford Transit Connect first generation — research and approved scope

- Model number in Traffic Rider bundle: **08**
- Source GLB: `08_ford_transit_connect_2011.glb`
- Source SHA-256: `e506579960a582b33c7f91c9b3a6086f99cb9e97158f635c4e614de69d5b862b`
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **6 mechanically consolidated first-generation powertrain configurations**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity and common body policy

The source represents a **North American 2011 Ford Transit Connect XLT Premium Wagon**, first generation and final 2009-style facelift, with the long 114.6-in wheelbase and high roof.

Visible source evidence includes full side and rear glazing, two sliding side doors, two rear swing doors, five-passenger Wagon construction, `XLT` badging, body-colour grille, front fog-lamp treatment and alloy wheels associated with the XLT Premium Wagon.

The owner approved one common source-like body and appearance for every powertrain:

- long-wheelbase, high-roof five-passenger Wagon body;
- final 2009–2013 facelift only;
- XLT Premium exterior, glazing, doors, wheels and materials;
- no short-wheelbase, low-roof, cargo, Tourneo, taxi or mobility body derivative.

This is an explicit owner-directed body homogenization. It is not a claim that every European engine or the Azure electric derivative was factory-sold as a North American XLT Premium Wagon. The catalog must preserve the real engine and model-year availability while using the common source body.

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
| Source wheelbase | approximately 4.155049 source units |
| Approximate wheelbase-derived scale | 0.700555 |

The source GLB remains unchanged. Four independent wheels, collision, catalog, physics, transmission and audio remain deferred by the global research gate.

## Owner-directed scope rules

- cover all researched first-generation combustion powertrain families;
- merge the early and late 75-PS diesel calibrations into one 75-PS row;
- include the Azure Dynamics electric derivative as a separate complete drivetrain;
- use the common source-like long-wheelbase high-roof XLT Premium Wagon appearance for every row;
- exclude all LPG, CNG, taxi, mobility and other conversion/upfit rows except the specifically approved Azure electric derivative;
- merge DPF and non-DPF emissions hardware into selected-year metadata inside the applicable diesel row;
- use one verified standard final-drive ratio and one standard differential state per powertrain/transmission row;
- do not create trim, body, final-drive, differential or emissions-state duplicates.

The original seven-row research matrix contained two separate 75-PS diesel calibrations. Merging those two rows produces **five combustion rows**; adding Azure Electric produces the final **six-row approved scope**.

## Approved configuration matrix

| # | Market / application | Powertrain | Transmission | Drivetrain and final-drive policy | Status |
|---:|---|---|---|---|---|
| 1 | Europe, approximately 2002–2006 | 1.8L Zetec/Duratec 16-valve naturally aspirated petrol inline-four, approximately 116 PS / 160 Nm; exact displacement/application still requires primary confirmation | Ford five-speed manual transaxle, working identification MTX-75 | FWD; one verified standard final drive and standard differential | **approved provisional** |
| 2 | Europe, first-generation 75-PS diesel applications | 1.8L Duratorq diesel inline-four, **merged 75-PS early/late row**, approximately 175 Nm; year-selected injection, turbo and emissions metadata | five-speed manual transaxle; exact early/late code pending | FWD; one verified standard final drive and standard differential | **approved provisional** |
| 3 | Europe, approximately 2002–2013 | 1.8L Duratorq TDCi 90 PS / approximately 220 Nm | five-speed manual transaxle; MTX-75-family in later production | FWD; one verified standard final drive and standard differential | **approved** |
| 4 | Europe, approximately 2006–2013 | 1.8L Duratorq TDCi 110 PS / approximately 250 Nm with variable-geometry turbo application | Ford MTX-75-family five-speed manual transaxle | FWD; one verified standard final drive and standard differential | **approved** |
| 5 | North America, 2010–2013 | 2.0L Duratec DOHC naturally aspirated petrol inline-four, approximately 136 hp / 128 lb-ft (174 Nm) | Ford/Mazda 4F27E four-speed planetary torque-converter automatic | FWD; one verified standard final drive and standard differential | **approved** |
| 6 | Azure Dynamics, 2011–2012 fleet derivative | AC induction motor, approximately 100 kW peak / 50–52 kW continuous and 235 Nm; approximately 28-kWh lithium-ion battery | dedicated BorgWarner single-speed fixed-reduction transaxle; reported reduction approximately 8.28:1 pending retained primary evidence | FWD; one fixed reduction and standard differential | **approved** |

**Approved total: 6 mechanically consolidated Ford Transit Connect first-generation configurations.**

## Explicit exclusions

- separate early and late 75-PS diesel catalog rows;
- separate DPF and non-DPF vehicles;
- LPG, CNG and other combustion-fuel conversions;
- taxi, mobility, crew/combi and camper conversions;
- short-wheelbase, low-roof, cargo and alternative Tourneo body rows;
- 2002–2005 and 2006–2008 visual derivatives;
- trim and seating duplicates;
- optional final-drive and differential duplicates;
- AWD and RWD configurations, which were not factory production layouts for the researched first-generation powertrains.

## Combustion chassis and transmission requirements

Every combustion row must use a transverse front engine, front-wheel drive, unit-body compact-commercial structure, MacPherson-strut front suspension and commercial rear twist/torsion-beam architecture. Mass, centre of gravity, axle loading, damping and aerodynamics must match the owner-approved high-roof passenger body rather than an empty or loaded cargo van.

The manual rows require a conventional driver-operated dry clutch and real five-speed transaxle with exact forward ratios, reverse, final drive, clutch capacity/inertia, synchronizer behaviour and engine braking.

The North American 2.0L uses a genuine 4F27E planetary automatic with hydrodynamic converter multiplication and slip, creep, progressive lock-up, four exact forward ratios, reverse, torque and inertia shift phases, kickdown, load scheduling and thermal protection.

## Azure electric architecture requirement

The Azure row requires a complete dedicated electric drivetrain model rather than a combustion vehicle with zero fuel consumption. Implementation must include:

- AC induction motor torque and speed envelope;
- inverter current, voltage, power and thermal limits;
- battery gross and usable energy, state of charge, voltage sag, temperature and power limits;
- motor and battery cooling behaviour;
- regenerative braking and friction-brake blending;
- coast and creep policy appropriate to the original calibration;
- auxiliary electrical load;
- the physical single-speed fixed-reduction transaxle, motor-speed limit, final drive and differential;
- electric motor electromagnetic orders, inverter switching and reduction-gear whine audio instead of a combustion waveform.

The owner requested a direct single-speed drivetrain. This is represented as a direct motor-to-fixed-reduction transaxle path with no gear changes; it must not be interpreted as an arbitrary 1:1 ratio when the evidenced vehicle uses a reduction gear.

## Engine and driveline audio architecture

The combustion rows require three model-specific families:

- **European 1.8L Zetec/Duratec petrol** — naturally aspirated port-injected inline-four combustion, intake, exhaust and valvetrain layers calibrated for the compact-commercial intake/exhaust system and high-roof body rather than a passenger-car donor;
- **North-American 2.0L Duratec petrol** — separate DOHC inline-four displacement/calibration and 4F27E converter/transaxle profile. It may share valid low-level Duratec utilities but must not reuse the 1.8 primary waveform without evidence that firing, intake/exhaust and calibration are equivalent;
- **1.8L Duratorq/TDCi diesel** — common-rail/compression-ignition inline-four architecture with injection, diesel mechanical orders, turbo, engine-braking and high-load response. The merged 75-PS row, 90-PS row and 110-PS VGT row require separate profiles; the VGT calibration needs an actual variable-geometry turbo state model rather than generic turbo noise.

Selected-year DPF/non-DPF and emissions hardware affect exhaust filtering, backpressure/regeneration and thermal/transient audio metadata without creating duplicate catalog rows. A non-DPF representative must not inherit regeneration events.

Manual rows require clutch, synchronizer and MTX-75-family geartrain layers. The 4F27E row requires converter slip/lock-up and planetary shift-event layers driven by real transmission telemetry. The high-roof passenger body requires its own cabin/body resonance, tyre and load response.

The Azure Electric row uses the non-combustion motor/inverter/fixed-reduction/regeneration backend described above and must not play petrol or diesel idle. Player rows use explicit live synthesis; AI uses the correct committed baked family or live synthesis with a representative fleet budget.

## Diesel emissions metadata

DPF, non-DPF, EGR, catalyst and emissions-standard differences remain mandatory selected-year metadata. They do not create separate catalog vehicles. A DPF-equipped calibration must still model backpressure, regeneration and thermal behaviour, while a non-DPF calibration must not inherit those effects.

## Evidence still required before parameter commitment

Before implementation retain primary Ford or manufacturer evidence for:

- exact European petrol displacement, output, years and body availability;
- early/late 75-PS diesel injection and turbo hardware;
- exact manual gearbox codes, ratios, clutch and final drives;
- 4F27E ratios, converter and calibration;
- one standard final drive and differential state per approved row;
- selected-year DPF and emissions hardware;
- body-correct mass, axle loads, tyres, brakes, drag and performance;
- Azure motor continuous/peak curves, inverter limits, usable battery energy, battery mass, fixed reduction and regenerative limits;
- firing/order, intake/exhaust, injection, VGT, limiter/governor and drivetrain-audio evidence for every combustion family.

These evidence gaps do not reopen the six-row approved catalog scope and do not authorize guessed parameters.

## Owner decision recorded

The owner decided:

1. Include every researched combustion powertrain family.
2. Merge the early and late 75-PS diesels into one row.
3. Preserve only the source-like final-facelift long-wheelbase high-roof XLT Premium Wagon body and appearance.
4. Exclude LPG, CNG, taxi, mobility and other conversion rows.
5. Merge DPF and non-DPF states into selected-year metadata.
6. Use one standard final drive and one standard differential state per row.
7. Include Azure Dynamics Electric.
8. Build the Azure motor, inverter, battery, regenerative braking and single-speed fixed-reduction transaxle as a complete dedicated drivetrain architecture.

Model 08 is **`approved`** with **6** configurations. Implementation remains blocked by the global all-model research gate. Research proceeds to model 09.
