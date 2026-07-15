# Mercedes-Benz Unimog U4023 / U5023 extreme-off-road truck — research and owner-scope gate

- Model number in Traffic Rider bundle: **16**
- Source GLB: `16_mercedes_benz_unimog_u5023_2013.glb`
- Source SHA-256: `d935aeb5e9aad2e60f0ffcadc28e14edd9902302fc038cd35ef67f01da4f8966`
- Research date: 2026-07-15
- Workflow status: **`awaiting_owner_scope`**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity

The source represents a **Mercedes-Benz Unimog U5023 extreme-off-road truck from the initial 2013/2014 U4023/U5023 phase**, with a single cab and open dropside cargo platform.

Visible source evidence includes:

- post-2013 extreme-off-road Unimog cab and bumper treatment;
- `U 5023`-family heavy chassis proportions;
- single-row two-door cab rather than a crew cab;
- open steel dropside platform with front bulkhead and tailgate;
- four equal-size single off-road tyres;
- portal-axle ground clearance and short overhangs;
- no fire-service body, expedition camper, armoured body, crane or enclosed specialist module;
- white civilian/demo-style finish rather than military camouflage.

The source filename, texture and scaled dimensions agree most strongly with **U5023**, not the lighter U4023. Identity confidence is **high for U5023 single-cab dropside truck and high for the 3,850-mm wheelbase**.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Wheelbase | 3,850 mm / 3.850 m |
| Factory chassis length family | approximately 6,000 mm before body-specific overhang differences |
| Factory width family | approximately 2,480–2,490 mm |
| U5023 height family | approximately 2,873 mm before body/load variation |
| Source meshes | 3 |
| Body mesh | `AI_Mb_Unimog_High_MB_Unimog_U5023_2013_0` |
| Front wheel-pair mesh | `on_teker.015_wheel_0` |
| Rear wheel-pair mesh | `arka_teker.016_wheel_0` |
| Body triangles | 1,384 |
| Front wheel-pair triangles | 324 |
| Rear wheel-pair triangles | 324 |
| Total triangles | 2,032 |
| Source scene AABB | approximately 4.135439 × 4.289601 × 8.698065 source units |
| Source front | positive source Z before canonical conversion |
| Source wheelbase | approximately 5.474725 source units |
| Approximate 3,850-mm-wheelbase scale | 0.703232 |
| Scaled source envelope | approximately 2.908 × 3.017 × 6.117 m including mirrors/outer geometry and platform |

The scaled wheel track/width and length are consistent with the official 2.48-m-wide, 6.0-m-long chassis family. The committed GLB remains unchanged. Integration must create four independent wheel nodes and project-authored collision, with portal-hub, tyre-pressure and axle-articulation behaviour represented by physics rather than baked into the mesh.

## Research boundary

The candidate scope covers the **Euro-VI-era extreme-off-road Unimog 437.4 models introduced as U4023 and U5023**, not the earlier U3000/U4000/U5000 OM904/OM924 variants and not the implement-carrier U2xx/U3xx/U4xx/U5xx family.

Both U4023 and U5023 use the same core powertrain family:

- Mercedes-Benz OM934 LA 5.132L turbocharged common-rail diesel inline-four;
- approximately 170 kW / 231 PS;
- 900 Nm in the 1,200–1,600-rpm range;
- UG 100E-8 / UG100-series eight-speed synchronized EPS gearbox;
- off-road gear group and reversing unit;
- Electronic AutomaticShift / EAS control state in the current documented configuration;
- permanently driven rear axle with engageable front drive;
- three selectable differential locks;
- portal axles and torque-tube driveline.

The model distinction is mechanically significant. U4023 uses the lighter axle/GVW package and a different overall axle reduction, while U5023 uses heavier portal axles, higher axle ratings and a different final-drive reduction. They therefore remain separate rows even though engine output and gearbox family are shared.

## Mechanically consolidated candidate matrix

| # | Model / chassis | Engine | Transmission | Drivetrain and axle state | Evidence state |
|---:|---|---|---|---|---|
| 1 | Unimog U4023, 3,850-mm wheelbase, standard approximately 8.0-t configuration | OM934 LA 5.132L turbo-diesel inline-four, 170 kW / 231 PS, 900 Nm | UG 100E-8-family 8-speed EPS synchronized manual/automated-manual gearbox with off-road group, reversing unit and EAS control | rear axle driven in road state, engageable front drive, portal axles, three differential locks; lighter U4023 axle package and one representative approximately 6.53 total axle reduction | `verified_model_family`; historical 2014 gearbox/clutch-control and axle-code document must be retained |
| 2 | Unimog U5023, 3,850-mm wheelbase, standard approximately 13.0-t configuration | OM934 LA 5.132L turbo-diesel inline-four, 170 kW / 231 PS, 900 Nm | UG 100E-8-family 8-speed EPS synchronized manual/automated-manual gearbox with off-road group, reversing unit and EAS control | rear axle driven in road state, engageable front drive, portal axles, three differential locks; heavy U5023 axle package and one representative approximately 6.94 total axle reduction | `verified`; strict source model, historical transmission/axle codes still require primary retention |

**Mechanically consolidated candidate total: 2 configurations.**

The current factory technical data shows different standard speeds for U4023 and U5023 in every basic and off-road gear, confirming that the two chassis cannot share one final-drive calibration. Engine-emissions revisions from initial Euro VI to later Euro VIe do not create extra rows unless primary service data proves a materially different engine or transmission architecture.

## Body and equipment policy candidates

### Strict source body

The exact visual anchor is:

- U5023 heavy chassis;
- single cab;
- 3,850-mm wheelbase;
- open dropside cargo platform;
- four single off-road tyres;
- white road/demo finish;
- one representative unladen/light-payload state.

### Other production bodies and options

Factory and body-builder applications include crew cabs, fire engines, rescue vehicles, expedition bodies, cranes, enclosed boxes and military/special-purpose bodies. These alter mass, centre of gravity, drag, articulation and axle loads and should not become duplicate catalog rows unless explicitly requested.

Tyre sizes, central tyre-pressure control, winches, PTOs, additional fuel tanks, crawler/work gearing, body interfaces and differential-lock selections are equipment or operating states. They should use one evidence-backed standard state per approved row rather than duplicate catalog entries.

## Chassis and drivetrain architecture

Each row requires:

- flexible ladder frame with three-point-mounted assemblies/body;
- longitudinal front engine;
- UG100-series gearset and source-era clutch/actuator logic;
- torque tubes and thrust-ball axle connections;
- rear drive as normal road state and engageable front drive;
- portal reduction at every wheel;
- front, rear and inter-axle/longitudinal lock logic matching the real lock sequence;
- coil-sprung live axles with very high articulation;
- large deformable off-road tyres and selectable pressure state;
- axle-load, brake and steering calibration specific to U4023 or U5023.

The portal hubs must alter effective wheel torque, wheel speed and unsprung rotational inertia. They may not be represented only by increasing ride height. Differential locks must change driveline constraints rather than applying a generic traction multiplier.

## Transmission architecture assessment

The UG100/EPS system is not a planetary automatic and must not use a torque-converter automatic fallback. The underlying transmission is a synchronized stepped manual gearset with electro-pneumatic selection. EAS automates shift and clutch control where fitted, but retains the manual gearset and torque interruption.

The off-road group and reversing unit create multiple forward and reverse speed ranges. Exact source-era available reverse gears, EAS/manual-clutch state, shift sequence, gear ratios, off-road reduction and optional crawler/work group must be taken from the retained 2014 technical information. Optional lower gearing does not create a catalog row unless the owner requests a separate hardware configuration.

## Engine and driveline audio architecture

The OM934 requires a dedicated large-displacement four-cylinder commercial-diesel sound model with common-rail combustion, turbocharger, engine brake and low-speed high-load response. Additional layers are required for the UG100 geartrain, torque tubes, portal hubs, tyre deformation and locked/unlocked driveline states. It must not be represented by pitch-shifting a passenger-car four-cylinder diesel.

## Evidence still required before parameter commitment

Before implementation retain primary Mercedes-Benz `Technical Information U 4023 / U 5023` and service/body-builder data for:

- exact initial-production OM934 code, torque curve, rev limit and engine-brake behaviour;
- UG100E-8 code, all basic/off-road/reverse ratios and source-era EAS/clutch actuation;
- U4023 and U5023 axle codes, portal ratios and confirmed standard final-drive reductions;
- differential-lock sequence and torque limits;
- standard tyre size and TireControl pressure ranges;
- source U5023 kerb mass, platform mass/payload, axle loads and centre of gravity;
- suspension rates, articulation limits, steering, pneumatic disc brakes and off-road ABS;
- drag/frontal area and documented road/off-road performance targets.

Current official Mercedes-Benz technical data confirms the two chassis, common 170-kW/900-Nm engine, 3,850-mm wheelbase, EPS/EAS gearbox family, portal axles and distinct gear-speed tables. Historical 2014 technical information remains mandatory for exact source-era calibration.

## Owner scope decision — required before implementation

Status remains **`awaiting_owner_scope`**.

Please decide:

1. Include both mechanically distinct rows — U4023 and U5023 — or only the strict source U5023?
2. Use the source-like U5023 single-cab dropside body for both rows, accepting visual homogenization of the lighter U4023 chassis?
3. Keep one standard UG100/EPS/EAS transmission state per row, with optional crawler/work gearing omitted as duplicate equipment?
4. Use one standard axle reduction, tyre specification and differential-lock configuration per row?
5. Use one representative unladen/light-payload state per row rather than separate payload catalog entries?
6. Exclude crew cab, fire, camper, military, crane, box and other specialist body derivatives?
7. Omit Euro VI/VIe, DPF/SCR, TireControl modes, PTOs, winches and auxiliary tanks as catalog rows or selectable metadata?
8. Is any expected engine, transmission, axle or factory chassis variant missing?

No implementation begins after this individual decision. Research proceeds to model 17 only after the owner fixes model 16 scope, and implementation begins only after every included model has reached `approved`.