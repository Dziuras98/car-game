# 2016 European Nissan 370Z low-poly visual asset

This directory contains the original simplified visual model used by `scenes/cars/370z.tscn`.
It targets the standard European 2016 coupe rather than the NISMO body kit and intentionally uses opaque black glazing and an early-2000s racing-game level of detail.

## Reference dimensions

The mesh is authored in metres around the vehicle origin and follows the published Z34 coupe dimensions:

- body length: 4.250 m;
- body width excluding mirrors: 1.845 m;
- roof height: approximately 1.310 m;
- wheelbase: 2.550 m;
- front track: 1.550 m;
- rear track: 1.595 m.

The rear wheel instances are widened relative to the front to represent the staggered European wheel and tyre package.

## Composition

- `370z_2016_eu_body_front.obj` — nose, hood and front body volume;
- `370z_2016_eu_body_center.obj` — cabin-side and central body volume;
- `370z_2016_eu_rear_and_details.obj` — rear body, mirrors and factory lip spoiler;
- `370z_2016_eu_glass_lighting_trim.obj` — opaque glazing, boomerang lamps, vertical DRLs, grille, handles, diffuser and exhaust;
- `370z_2016_eu_lamp_mounts.obj` — recessed dark mounting pockets that connect the headlamps and taillamps to the surrounding body surfaces;
- `370z_2016_eu_spoiler_bridge.obj` — body-coloured bridge that integrates the factory rear lip with the rear deck;
- `370z_2016_eu_wheel.obj` — reusable wheel mesh instanced four times;
- `370z_2016_eu_low_poly.mtl` — source material palette retained for interchange and inspection.

The mounting geometry deliberately intersects both the body shell and the underside of the corresponding trim part. This prevents visible air gaps while retaining the intentionally simplified layered low-poly construction.

Godot applies the production body, detail and wheel materials in the base car scene. The model deliberately contains no manufacturer logo or copied third-party game asset.

## Provenance

The geometry was constructed specifically for this repository from public photographic references and published exterior dimensions. It is not extracted from another game, scan or commercial model. The asset is covered by the repository license.
