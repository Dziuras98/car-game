# Tor Poznań reconstruction

## Scope

The production `tor_poznan` track is an original procedural reconstruction prepared for this project. It does not contain geometry, textures, or other assets extracted from a commercial simulation or third-party mod.

The current implementation includes:

- a closed centerline traced from the supplied high-resolution circuit plan;
- a generated lap length calibrated to 4083 metres;
- the nominal 12-metre road width;
- 240 source control points and 480 generated road samples;
- progress-based shoulder, barrier, racing-line, and banking profiles;
- twelve intermediate checkpoint gates plus start/finish;
- a drivable pit entry, pit lane, pit exit, and paddock;
- pit buildings, control tower, start gantry, grandstands, trackside forest, and generated inside curbs;
- a pit-lane opening in the otherwise procedural barrier system.

## Coordinate convention

The start/finish line is anchored at the world origin. The start straight points along Godot's `Vector3.FORWARD` direction (`-Z`). This keeps the track compatible with the existing player spawn and opponent-grid logic.

## Accuracy

The horizontal centerline is calibrated against the official published lap length. The nominal width is authoritative, while the local shoulder widths, barrier offsets, preliminary racing-line offsets, banking, and trackside object placement are reconstructed from the available plan and visual references.

The current model must not be described as a survey-grade or laser-scanned replica. In particular:

- the vertical profile is still effectively flat except for small crossfall values;
- pit buildings and grandstands use simplified project-owned primitive geometry;
- curbs are generated from local centerline curvature rather than a surveyed curb inventory;
- safety zones and barrier types are approximated by the current generic surface and barrier systems;
- the pit lane follows the correct functional side of the main straight but is not based on geodetic pit-lane measurements.

## Acceptance checks

Automated tests require:

- valid non-self-intersecting generated road geometry;
- lap length within 1 metre of 4083 metres;
- constant 12-metre road width;
- correct start orientation and origin;
- complete AI racing-line publication;
- complete checkpoint generation;
- production catalog and localization integration;
- collidable pit-lane and building surfaces;
- batched forest and curb rendering;
- a verified opening in the generated pit-side barrier.

Further accuracy work should prioritize surveyed elevation data, asymmetric left/right runoff profiles, explicit curb inventories, and georeferenced pit and building outlines.
