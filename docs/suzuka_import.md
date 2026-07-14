# Suzuka import from AssettoWorld

This track package was generated from `ac_suzuka_v.1.0.rar` supplied by the project owner and sourced from AssettoWorld:

https://www.assettoworld.com/track/suzuka

The project owner reports that AssettoWorld's operators permitted files distributed through their site to be used, modified and redistributed for noncommercial purposes.

The source and converted track assets are third-party materials. They are not original project assets, are excluded from the repository root license, and may not be used commercially. Redistributed copies must retain attribution to AssettoWorld, the source link and the noncommercial restriction recorded in `assets/tracks/suzuka/NOTICE.md`.

Technical conversion:

- KN5 visual meshes converted to split glTF 2.0 files with external PNG textures;
- Assetto Corsa collision meshes merged by `TARMAC`, `PITLANE`, `KERB`, `SAND`, `GRASS`, `OFFTRACK`, `CONCRETE`, and `WALL`;
- `fast_lane.ai` resampled to approximately 2.5 m spacing;
- the complete track translated and yaw-rotated so the start of the AI line is at the project origin and points toward Godot forward (`-Z`);
- runtime collision bodies expose `surface_grip_multiplier` metadata consumed by `CarChassisController`.

Copy the contents of `car-game-overlay` over a checkout of `Dziuras98/car-game`, allow Godot 4.7 to import the glTF files, then run the project and select **Suzuka**. Initial import and collision construction are expected to take longer than generated tracks.
