#!/usr/bin/env python3
"""Inspect every approved Traffic Rider source GLB deterministically.

The script does not modify source assets. It records the geometry hierarchy,
materials, axle-pair split feasibility and measured wheel locations needed by
the per-model visual-derivative stage.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

import numpy as np
import trimesh

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
REPORT_PATH = REPOSITORY_ROOT / "docs/assets/traffic_rider_source_inspection_all.json"

SOURCES: tuple[tuple[int, str, str], ...] = (
    (1, "bmw_4_series_f32", "assets/third_party/sketchfab/traffic_rider_npc_vehicles/bmw_4_series_f32/source/01_bmw_4_series_2014.glb"),
    (2, "chevrolet_silverado_2014", "02_chevrolet_silverado_2014.glb"),
    (3, "renault_clio_2013", "03_renault_clio_2013.glb"),
    (4, "chevrolet_cruze_2011", "04_chevrolet_cruze_2011.glb"),
    (5, "ford_e150_2012", "05_ford_e150_2012.glb"),
    (6, "ford_excursion_2000", "06_ford_excursion_2000.glb"),
    (7, "ford_f150_limited_2013", "07_ford_f150_limited_2013.glb"),
    (8, "ford_transit_connect_2011", "08_ford_transit_connect_2011.glb"),
    (9, "land_rover_freelander_2_2012", "09_land_rover_freelander_2_2012.glb"),
    (10, "volkswagen_golf_vii_2013", "10_volkswagen_golf_vii_2013.glb"),
    (11, "kia_ceed_2012", "11_kia_ceed_2012.glb"),
    (12, "renault_maxity_2008", "12_renault_maxity_2008.glb"),
    (13, "mazda_2_2011", "13_mazda_2_2011.glb"),
    (14, "mazda_3_2014", "14_mazda_3_2014.glb"),
    (15, "mercedes_benz_sprinter_2014", "15_mercedes_benz_sprinter_2014.glb"),
    (16, "mercedes_benz_unimog_u5023_2013", "16_mercedes_benz_unimog_u5023_2013.glb"),
    (17, "nissan_atlas_2007", "17_nissan_atlas_2007.glb"),
    (18, "nissan_atleon_2004", "18_nissan_atleon_2004.glb"),
    (20, "skoda_octavia_combi_2013", "20_skoda_octavia_combi_2013.glb"),
    (23, "volkswagen_amarok_2010", "23_volkswagen_amarok_2010.glb"),
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source_file:
        for chunk in iter(lambda: source_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def world_mesh(scene: trimesh.Scene, node_name: str) -> trimesh.Trimesh:
    transform, geometry_name = scene.graph[node_name]
    mesh = scene.geometry[geometry_name].copy()
    mesh.apply_transform(transform)
    return mesh


def material_summary(mesh: trimesh.Trimesh) -> dict[str, Any]:
    visual = mesh.visual
    material = getattr(visual, "material", None)
    texture = getattr(material, "baseColorTexture", None)
    uv = getattr(visual, "uv", None)
    return {
        "visual_kind": visual.kind,
        "uv_count": int(len(uv)) if uv is not None else 0,
        "material_type": type(material).__name__ if material is not None else None,
        "material_name": getattr(material, "name", None),
        "base_color_texture": list(texture.size) if texture is not None else None,
    }


def split_summary(mesh: trimesh.Trimesh) -> dict[str, Any]:
    split_x = float(mesh.bounds.mean(axis=0)[0])
    triangles = mesh.triangles
    centers = mesh.triangles_center
    negative_faces = np.flatnonzero(centers[:, 0] < split_x)
    positive_faces = np.flatnonzero(centers[:, 0] >= split_x)
    crossing = np.logical_and(
        triangles[:, :, 0].min(axis=1) < split_x - 1e-8,
        triangles[:, :, 0].max(axis=1) > split_x + 1e-8,
    )
    negative = mesh.submesh([negative_faces], append=True, repair=False)
    positive = mesh.submesh([positive_faces], append=True, repair=False)
    if not isinstance(negative, trimesh.Trimesh) or not isinstance(positive, trimesh.Trimesh):
        raise RuntimeError("wheel-pair split did not produce two meshes")
    negative_center = negative.bounds.mean(axis=0)
    positive_center = positive.bounds.mean(axis=0)
    return {
        "split_x": split_x,
        "crossing_faces": int(crossing.sum()),
        "negative_faces": int(len(negative_faces)),
        "positive_faces": int(len(positive_faces)),
        "negative_center": negative_center.tolist(),
        "positive_center": positive_center.tolist(),
        "negative_bounds": negative.bounds.tolist(),
        "positive_bounds": positive.bounds.tolist(),
    }


def classify_nodes(scene: trimesh.Scene) -> tuple[str, list[str]]:
    face_counts: list[tuple[int, str]] = []
    for node_name in scene.graph.nodes_geometry:
        mesh = world_mesh(scene, node_name)
        face_counts.append((int(len(mesh.faces)), node_name))
    face_counts.sort(reverse=True)
    if len(face_counts) < 3:
        raise RuntimeError(f"expected at least three geometry nodes, found {face_counts}")
    body_node = face_counts[0][1]
    remaining = [node_name for _faces, node_name in face_counts[1:]]

    named_wheels = [
        node_name
        for node_name in remaining
        if any(token in node_name.lower() for token in ("teker", "wheel", "tyre", "tire"))
    ]
    wheel_nodes = named_wheels if len(named_wheels) >= 2 else remaining[:2]
    wheel_nodes = sorted(wheel_nodes, key=lambda name: float(world_mesh(scene, name).bounds.mean(axis=0)[2]))
    return body_node, wheel_nodes[:2]


def inspect_source(model_number: int, vehicle_id: str, relative_path: str) -> dict[str, Any]:
    source_path = REPOSITORY_ROOT / relative_path
    if not source_path.is_file():
        raise FileNotFoundError(relative_path)

    loaded = trimesh.load(source_path, force="scene", process=False, maintain_order=True)
    scene = loaded if isinstance(loaded, trimesh.Scene) else trimesh.Scene(loaded)
    body_node, axle_nodes = classify_nodes(scene)
    body_mesh = world_mesh(scene, body_node)
    axle_meshes = [world_mesh(scene, node_name) for node_name in axle_nodes]
    axle_splits = [split_summary(mesh) for mesh in axle_meshes]

    axle_centers_z = [
        float((split["negative_center"][2] + split["positive_center"][2]) * 0.5)
        for split in axle_splits
    ]
    measured_wheelbase = abs(axle_centers_z[1] - axle_centers_z[0])
    geometry: dict[str, Any] = {}
    total_faces = 0
    for node_name in sorted(scene.graph.nodes_geometry):
        mesh = world_mesh(scene, node_name)
        faces = int(len(mesh.faces))
        total_faces += faces
        geometry[node_name] = {
            "geometry_name": scene.graph[node_name][1],
            "faces": faces,
            "vertices": int(len(mesh.vertices)),
            "bounds": mesh.bounds.tolist(),
            "center": mesh.bounds.mean(axis=0).tolist(),
            "material": material_summary(mesh),
        }

    return {
        "model_number": model_number,
        "vehicle_id": vehicle_id,
        "source_path": relative_path,
        "source_sha256": sha256(source_path),
        "scene_bounds": scene.bounds.tolist(),
        "geometry_node_count": len(scene.graph.nodes_geometry),
        "total_faces": total_faces,
        "body_node": body_node,
        "body_faces": int(len(body_mesh.faces)),
        "axle_nodes_low_to_high_z": axle_nodes,
        "axle_splits_low_to_high_z": axle_splits,
        "measured_source_wheelbase": measured_wheelbase,
        "all_geometry": geometry,
    }


def main() -> None:
    records: list[dict[str, Any]] = []
    failures: list[dict[str, str]] = []
    for model_number, vehicle_id, relative_path in SOURCES:
        try:
            record = inspect_source(model_number, vehicle_id, relative_path)
            records.append(record)
            print(
                f"[PASS] model {model_number:02d} {vehicle_id}: "
                f"{record['total_faces']} faces, wheelbase {record['measured_source_wheelbase']:.9f}"
            )
        except Exception as error:  # noqa: BLE001 - aggregate every source failure
            failures.append({
                "model_number": str(model_number),
                "vehicle_id": vehicle_id,
                "source_path": relative_path,
                "error": f"{type(error).__name__}: {error}",
            })
            print(f"[FAIL] model {model_number:02d} {vehicle_id}: {error}")

    report = {
        "generator": "tools/assets/inspect_traffic_rider_sources.py",
        "model_count": len(records),
        "expected_model_count": len(SOURCES),
        "failure_count": len(failures),
        "records": records,
        "failures": failures,
    }
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
