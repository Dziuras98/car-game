#!/usr/bin/env python3
"""Split the Sketchfab Race Track Map GLB into Godot-friendly scene groups.

Usage:
    python tools/track_import/split_short_desert_track.py path/to/race_track_map.glb

Requires Python 3.10+ and trimesh. The generated files belong under
assets/tracks/short_desert_track/models/.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil

import trimesh

GROUPS: dict[str, set[str]] = {
    "track_surface": {"ROAD", "Lines", "Kerbs", "GROUND", "Material.001"},
    "fences": {"Track_Fence"},
    "barriers": {"surface.Lim_Ograda", "Bankina_Default"},
    "buildings": {
        "building1",
        "building3",
        "building4",
        "building5",
        "building6",
        "Scene_-_Root",
        "Material.002",
        "Steal",
        "Start",
        "Finish",
    },
    "vehicles": {"car_0", "material"},
    "vegetation": {"Pine", "Base"},
}

DEFAULT_OUTPUT = Path("assets/tracks/short_desert_track/models")
MAX_EXPECTED_PART_BYTES = 15 * 1024 * 1024


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def material_name(geometry: trimesh.Trimesh) -> str:
    material = getattr(geometry.visual, "material", None)
    return str(getattr(material, "name", ""))


def split_model(source: Path, output: Path) -> dict[str, object]:
    if not source.is_file():
        raise FileNotFoundError(source)
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    source_scene = trimesh.load(source, force="scene", process=False)
    assigned_geometry: set[str] = set()
    parts: list[dict[str, object]] = []

    for group_name, accepted_materials in GROUPS.items():
        target_scene = trimesh.Scene(base_frame=source_scene.graph.base_frame)
        object_count = 0
        vertex_count = 0
        triangle_count = 0
        used_materials: set[str] = set()

        for node_name in source_scene.graph.nodes_geometry:
            transform, geometry_name = source_scene.graph.get(node_name)
            geometry = source_scene.geometry[geometry_name]
            current_material = material_name(geometry)
            if current_material not in accepted_materials:
                continue

            optimized = geometry.copy()
            optimized.merge_vertices(merge_tex=False, merge_norm=False)
            optimized.remove_unreferenced_vertices()
            target_scene.add_geometry(
                optimized,
                node_name=node_name,
                geom_name=geometry_name,
                transform=transform,
            )
            assigned_geometry.add(geometry_name)
            used_materials.add(current_material)
            object_count += 1
            vertex_count += len(optimized.vertices)
            triangle_count += len(optimized.faces)

        target_path = output / f"{group_name}.glb"
        target_scene.export(target_path)
        validation_scene = trimesh.load(target_path, force="scene", process=False)
        if len(validation_scene.graph.nodes_geometry) != object_count:
            raise RuntimeError(f"{target_path}: node-count validation failed")
        if target_path.stat().st_size > MAX_EXPECTED_PART_BYTES:
            raise RuntimeError(f"{target_path}: exceeds the 15 MiB split-file target")

        parts.append(
            {
                "path": target_path.name,
                "sha256": sha256(target_path),
                "bytes": target_path.stat().st_size,
                "objects": object_count,
                "vertices": vertex_count,
                "triangles": triangle_count,
                "materials": sorted(used_materials),
            }
        )

    unassigned = sorted(set(source_scene.geometry) - assigned_geometry)
    if unassigned:
        raise RuntimeError(f"Unassigned source geometry: {unassigned}")

    manifest: dict[str, object] = {
        "format_version": 1,
        "source_file": source.name,
        "source_sha256": sha256(source),
        "source_bytes": source.stat().st_size,
        "parts": parts,
    }
    manifest_path = output.parent / "split_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    print(json.dumps(split_model(args.source, args.output), indent=2))


if __name__ == "__main__":
    main()
