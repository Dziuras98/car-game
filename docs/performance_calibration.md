# Vehicle performance and DPI calibration

Last recalibrated: 2026-07-15

## Scope

The production vehicle data and `CarPerformanceIndexCalculator` are calibrated against published factory specifications and period/independent road tests. The game runtime remains a deterministic arcade simulation, so the target is a reproducible envelope rather than reproducing one magazine run to the hundredth of a second.

DPI v3 uses three idealized courses:

- technical: short straights and low/medium-radius corners;
- mixed: balanced acceleration, braking and cornering;
- fast: long straights and high-speed corners.

The 2016 Nissan 370Z 7AT is the rolling 1000-point reference. Reference course times are calculated from the current authoritative resource instead of frozen constants. A sourced correction to the reference car therefore moves the whole catalog consistently without changing its own 1000-point anchor.

## Measurement conventions

- Game acceleration tests use 0–100 km/h from a stationary start without rollout.
- US 0–60 mph magazine times may include rollout and are treated as a range, not directly copied as 0–100 km/h.
- Top speed targets distinguish measured, manufacturer-limited and gearing-limited values where the source makes that distinction.
- Period cars receive wider tolerance bands because tires, fuel, weather and test methods varied substantially.
- Driver aids may improve repeatability and prevent post-peak loss, but do not add engine power in DPI.

## Authoritative runtime assumptions represented by DPI v3

- engine torque curve, gearing, final drive and rev limiter;
- explicit or estimated wheel and engine rotational inertia;
- transmission-specific shift delay and torque converter multiplication;
- configured CVT minimum ratio; `0.0` means no physical longest-ratio stop and only the numerical epsilon remains;
- FWD/RWD/AWD torque split;
- two-pass load transfer based on achievable rather than requested acceleration;
- front brake bias, ABS and traction-control intervention;
- front/rear tire width, axle grip balance and combined-slip reserve;
- aerodynamic drag and rolling resistance.

Differential locking is simulated by the runtime. It is intentionally not awarded a flat DPI bonus on an ideal equal-grip course; its advantage appears under wheel-speed/load asymmetry and is validated separately.

## Calibration targets

### Fiat Punto 176 (1993–1999)

| Variant | 0–100 km/h target | Top-speed target |
|---|---:|---:|
| 55 5MT | 17.0–18.0 s | 148–152 km/h |
| 55 6MT | 15.5–17.0 s | 148–152 km/h |
| 60 5MT | 14.0–15.5 s | 157–162 km/h |
| 60 CVT | 16.0–18.0 s | 147–152 km/h |
| 75 5MT | 11.5–12.8 s | 168–172 km/h |
| 90 5MT | 10.3–11.5 s | 176–180 km/h |
| GT 5MT | 7.7–8.4 s | 198–202 km/h |
| 1.7 D 5MT | 19.5–21.5 s | 147–152 km/h |
| 1.7 TD70 5MT | 14.2–15.6 s | 160–165 km/h |

Sources:

- Fiat Punto first-generation engine/performance tables: https://es.wikipedia.org/wiki/Fiat_Punto
- Cross-check of measured/catalog acceleration and top speed: https://www.zeperfs.com/en/fiche-fiat-punto.htm
- Cross-check of model/engine specifications: https://www.ultimatespecs.com/car-specs/Fiat-models/Fiat-Punto-I

### FSO Polonez Caro MR'93

| Variant | 0–100 km/h target | Top-speed target |
|---|---:|---:|
| 1.4 GLI 16V | 14.6–15.6 s | 174–178 km/h |
| 1.5 GLE | 17.1–18.2 s | 153–157 km/h |
| 1.5 GLI | 16.6–17.7 s | 156–160 km/h |
| 1.6 GLE | 15.6–16.7 s | 158–162 km/h |
| 1.6 GLI | 15.7–16.8 s | 161–165 km/h |
| 2.0 GLE Ford | 12.9–14.0 s | 177–181 km/h |
| 1.9 GLD | 19.0–20.5 s | 151–155 km/h |

Sources:

- Consolidated Caro engine and top-speed table: https://en.wikipedia.org/wiki/FSO_Polonez
- Polish historical/model cross-check: https://pl.wikipedia.org/wiki/FSO_Polonez

The Polonez acceleration targets retain wider tolerances than the top-speed targets because period test results and curb-mass/equipment differences vary more strongly than factory maximum-speed data.

### BMW 3 Series E46

The game generates transmission and AWD derivatives from model-level base data. Manual RWD values are the primary source anchors; automatic and AWD penalties are generated from real mass, gearing and transmission characteristics rather than hard-coded badge multipliers.

Representative anchors:

| Variant | 0–100 km/h target | Top-speed target |
|---|---:|---:|
| 316i 105 PS | 11.5–12.5 s | 198–202 km/h |
| 318i 118 PS | 10.0–10.8 s | 204–208 km/h |
| 318i 143 PS | 8.8–9.4 s | 216–220 km/h |
| 320i 150 PS | 9.5–10.2 s | 218–222 km/h |
| 320i 170 PS | 7.9–8.5 s | 224–228 km/h |
| 325i 192 PS | 7.0–7.5 s | 238–242 km/h |
| 328i 193 PS | 6.8–7.3 s | 238–242 km/h |
| 330i 231 PS | 6.3–6.7 s | 250 km/h limited |
| 318d 115 PS | 10.4–11.2 s | 201–205 km/h |
| 320d 136 PS | 9.5–10.2 s | 205–209 km/h |
| 320d 150 PS | 8.6–9.2 s | 214–218 km/h |
| 330d 184 PS | 7.6–8.2 s | 225–229 km/h |
| 330d 204 PS | 7.0–7.5 s | 240–244 km/h |

Sources:

- BMW Group Classic E46 archive: https://www.bmwgroup-classic.com/en/models/bmw-classics/product-description-page.ad-90-1.bmw-3-series-e46.html
- Period BMW technical brochure archive: https://www.auto-brochures.com/bmw.html
- Detailed model/transmission performance table cross-check: https://de.wikipedia.org/wiki/BMW_E46

### Nissan 370Z and 370Z Nismo

| Variant | 0–100 km/h target | Quarter mile target | Top-speed target |
|---|---:|---:|---:|
| 370Z 6MT | 4.9–5.4 s | 13.4–13.9 s | 250 km/h limited |
| 370Z 7AT | 4.8–5.3 s | 13.3–13.8 s | 250 km/h limited |
| Nismo 6MT | 4.8–5.2 s | 13.3–13.7 s | 250 km/h limited |
| Nismo 7AT | 4.7–5.1 s | 13.2–13.6 s | 250 km/h limited |

Sources:

- Official 2016 Nissan/NHTSA specification data: https://www.nhtsa.gov/sites/nhtsa.gov/files/2016_nissan_370z.pdf
- Car and Driver Nismo automatic instrumented test: https://www.caranddriver.com/reviews/a15107369/2015-nissan-370z-nismo-automatic-test-review/
- Edmunds 370Z manual instrumented test: https://www.edmunds.com/nissan/370z/2009/road-test.html

### 1967 Shelby GT500

Period test cars differed in axle ratio, transmission, tune and tire condition. The game therefore calibrates to bands rather than a single modern-restoration result.

| Variant | 0–60 mph target | Quarter mile target | Trap-speed target | Top-speed envelope |
|---|---:|---:|---:|---:|
| 428 4MT | 6.0–7.8 s | 14.0–16.5 s | 90–108 mph | 190–207 km/h |
| 428 3AT | 6.2–8.5 s | 14.4–17.2 s | 87–108 mph | 188–207 km/h |

Sources:

- Car and Driver period road-test archive: https://www.caranddriver.com/reviews/a15142900/1967-ford-mustang-shelby-gt500-archived-instrumented-test/
- MotorTrend retrospective compilation of period tests: https://www.motortrend.com/vehicle-genres/1967-ford-mustang-road-tests/

## Regression policy

A production calibration change must pass all of the following:

1. `CarSpecs.validate()` for the complete catalog.
2. Full runtime physics tests at bounded substeps.
3. Model-specific acceleration/top-speed bands.
4. DPI ordering and sensitivity tests.
5. A catalog report containing DPI v3 and technical/mixed/fast course times.
6. Manual review of large DPI movements; a physics correction may legitimately move scores, but arbitrary compensating multipliers are not accepted.
