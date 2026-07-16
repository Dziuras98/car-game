# Renault Maxity F24 single-cab box truck — research and approved scope

- Model number in Traffic Rider bundle: **12**
- Source GLB: `12_renault_maxity_2008.glb`
- Source SHA-256: `37dd295636b56ebaecee37c1d461ee64349ee0c0bb697dfb484e94e49b0132f3`
- Research date: 2026-07-15
- Owner decision date: 2026-07-15
- Workflow status: **`approved`**
- Approved implementation scope: **6 mechanically consolidated Renault Maxity powertrain configurations**
- Physics baseline inspected during research: `master` at `56f6ce9ca13f7fc8fb268493bff5d142d353bb53`
- Global implementation gate: no geometry, catalog, physics, transmission or audio implementation begins until every included model has reached `approved`.

## Visual identity and body policy

The source represents an original-body Nissan F24-derived Renault Maxity with a single cab, enclosed white box body, rear double doors, side access door and dual rear wheels. The geometry is provisionally matched to the short 2,500-mm wheelbase and approximately 3.5-tonne road-chassis class.

The owner approved the same source-like body for every powertrain:

- single cab;
- provisional 2,500-mm wheelbase;
- enclosed source box body;
- dual rear wheels;
- original 2007–early-2010s cab exterior;
- no crew cab, platform, tipper, bare chassis-cab, longer wheelbase or alternative GVW catalog rows.

## Reference dimensions and source inspection

| Parameter | Reference / source result |
|---|---:|
| Provisional source wheelbase | 2,500 mm / 2.500 m |
| Cab width | approximately 1,870 mm / 1.870 m |
| Body mesh | `AI_Maxity_High_Renault_Maxity_2008_0` |
| Front wheel-pair mesh | `on_teker.011_wheel_0` |
| Rear dual-wheel mesh | `arka_teker.012_wheel_0` |
| Body triangles | 1,022 |
| Front wheel assembly triangles | 396 |
| Rear dual-wheel assembly triangles | 684 |
| Total triangles | 2,102 |
| Source wheelbase | approximately 3.912804 source units |
| Provisional wheelbase-derived scale | approximately 0.638928 |

The source rear mesh contains four physical tyres. Integration must retain two front wheels and four physical rear tyres, with explicitly bound tyre/contact behaviour.

## Owner-directed scope rules

- include exactly the six researched powertrain rows;
- retain 110, 120, 130, 140 and 150-PS diesel calibrations separately;
- include Maxity Electric as a complete dedicated electric drivetrain;
- use one representative body, kerb/payload state and axle-loading target per row;
- use one verified standard final-drive ratio and one standard differential state per row;
- exclude optional gearing, body, cab, wheelbase, GVW and payload-state duplicates;
- omit DPF, Euro-standard, catalyst and EGR subdivisions from catalog rows and selectable metadata;
- exclude LPG, CNG, 4x4 and other aftermarket conversions;
- no additional variant was requested by the owner.

## Approved configuration matrix

| # | Powertrain | Transmission | Drivetrain | Status |
|---:|---|---|---|---|
| 1 | DXi2.5 / Nissan YD25DDTi 2.5L common-rail turbo-diesel, approximately 110 PS | 5-speed conventional manual gearbox | RWD, live rear axle; one standard final drive and differential | **approved** |
| 2 | DXi2.5 / Nissan YD25DDTi 2.5L common-rail turbo-diesel, approximately 130 PS | 6-speed conventional manual gearbox | RWD, live rear axle; one standard final drive and differential | **approved** |
| 3 | DXi3 / Nissan ZD30DDTi 3.0L common-rail turbo-diesel, approximately 150 PS / 350 Nm | 6-speed conventional manual gearbox | RWD, live rear axle; one standard final drive and differential | **approved** |
| 4 | later DXi2.5 / YD25-family 2.5L common-rail turbo-diesel, approximately 120 PS / 250 Nm | 5-speed conventional manual gearbox | RWD, live rear axle; one standard final drive and differential | **approved** |
| 5 | later DXi2.5 / YD25-family 2.5L common-rail turbo-diesel, approximately 140 PS / 270 Nm | 6-speed conventional manual gearbox | RWD, live rear axle; one standard final drive and differential | **approved** |
| 6 | Renault Maxity Electric by PVI, approximately 47 kW / 270 Nm with approximately 40-kWh lithium-ion battery | dedicated single-speed fixed-reduction electric driveline | RWD electric drive to live rear axle; one fixed reduction and differential | **approved** |

**Approved total: 5 diesel + 1 electric = 6 mechanically consolidated configurations.**

## Chassis and transmission requirements

Every diesel row requires the ladder frame, longitudinal front engine, dry clutch, exact five- or six-speed manual gearbox, prop shaft, live rear axle, leaf-sprung dual rear wheels and box-body-correct mass, drag and crosswind behaviour.

Maxity Electric requires a complete motor, inverter, battery, state-of-charge, voltage-sag, thermal, regenerative-braking, auxiliary-load and fixed-reduction model. It must not use a diesel gearbox locked in one gear.

## Engine and driveline audio architecture

The five diesel rows require two related but mechanically distinct commercial-diesel families:

- **YD25DDTi / DXi2.5 2.5L inline-four** — dedicated common-rail four-cylinder commercial-diesel cadence with injection transients, turbo spool, governor, engine-braking and low-speed/high-load response. The 110, 120, 130 and 140-PS rows may share the first-principles YD25 timing architecture, but each retained calibration requires its own boost, injection, governor, intake/exhaust and load-response profile;
- **ZD30DDTi / DXi3 3.0L inline-four** — separate larger-displacement commercial-diesel family with its own combustion pulse, turbo, mechanical, intake/exhaust and engine-brake character. It must not be created only by pitch-shifting the YD25 waveform.

Both diesel families require body/driveline layers for dry-clutch launch and shifts, five- versus six-speed gear whine, prop shaft, live axle, dual rear tyres and enclosed-box resonance. Those layers must respond to truthful clutch, selected/engaged gear, load and wheel-speed telemetry.

**Maxity Electric** requires a non-combustion backend derived from motor speed/torque, inverter switching, fixed-reduction gear mesh, live axle, regenerative braking, auxiliary systems, dual rear tyres and box-body resonance. It must not play an idling diesel loop or simulate motor speed from a fake combustion RPM range.

Every player row uses an explicit architecture-correct live backend. The AI backend must be selected and tested explicitly as a committed baked bank or a live synthesizer with a representative fleet budget, following `traffic_rider_engine_audio_implementation_contract.md`.

## Evidence still required before parameter commitment

Before implementation retain primary Renault Trucks, Nissan or PVI documentation for exact engine outputs and dates, gearbox codes and ratios, clutch capacities, one standard final drive per row, source GVW/kerb/payload/axle ratings, tyre and brake hardware, box dimensions and drag, and the complete electric motor/inverter/battery/reduction data. Audio parameter commitment additionally requires engine idle/governor/engine-brake evidence, turbo/injection behaviour and motor/inverter/reduction operating data. These evidence gaps do not reopen the approved six-row catalog scope and do not authorize guessed parameters.

## Owner decision recorded

The owner approved exactly the six presented configurations and requested progression to model 13. No further body, conversion, emissions or drivetrain variant is added.

Model 12 is **`approved`** with **6** configurations. Implementation remains blocked by the global all-model research gate. Research proceeds to model 13.
