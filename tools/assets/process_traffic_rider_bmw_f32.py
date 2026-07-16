#!/usr/bin/env python3
"""Build the canonical BMW F32 visual derivative from the unchanged source GLB.

The processor is intentionally model-specific. It preserves source geometry,
UVs and embedded materials, separates each paired axle mesh by triangle
centroid across the source X=0 plane, moves the four wheel meshes to
hub-centred pivots, converts source +Z front to project -Z front, centres the
vehicle between axle centres, grounds it at the tyre contact plane and scales
the measured source wheelbase to the verified 2.810 m reference.

Pinned generation environment used by CI:
- Python 3.13
- numpy 2.3.5
- Pillow 12.2.0
- trimesh 4.11.1
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

import numpy as np
import trimesh

TARGET_WHEELBASE_M = 2.810
EXPECTED_SOURCE_SHA256 = "fab5af5379c45f780f2ccc608560b99cb441ebf0f66c06e8eef0cb7fcd28d510"
EXPECTED_OUTPUT_SHA256 = "bd0dc99b51e9756b800aeece83e2cea794b69aa182b583487fccf50e53237369"
EXPECTED_TOTAL_FACES = 1780


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source_file:
        for chunk in iter(lambda: source_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def find_geometry_node(scene: trimesh.Scene, *needles: str) -> str:
    candidates: list[str] = []
    for node_name in scene.graph.nodes_geometry:
        _transform, geometry_name = scene.graph[node_name]
        searchable = f"{node_name} {geometry_name}".lower()
        if all(needle.lower() in searchable for needle in needles):
            candidates.append(node_name)
    if len(candidates) != 1:
        raise RuntimeError(f"Expected one geometry node for {needles}, found {candidates}")
    return candidates[0]


def world_mesh(scene: trimesh.Scene, node_name: str) -> trimesh.Trimesh:
    transform, geometry_name = scene.graph[node_name]
    mesh = scene.geometry[geometry_name].copy()
    mesh.apply_transform(transform)
    return mesh


def split_pair(mesh: trimesh.Trimesh) -> tuple[trimesh.Trimesh, trimesh.Trimesh, dict[str, Any]]:
    split_x = float(mesh.bounds.mean(axis=0)[0])
    centroids = mesh.triangles_center
    negative_faces = np.flatnonzero(centroids[:, 0] < split_x)
    positive_faces = np.flatnonzero(centroids[:, 0] >= split_x)
    crossing = np.logical_and(
        mesh.triangles[:, :, 0].min(axis=1) < split_x - 1e-8,
        mesh.triangles[:, :, 0].max(axis=1) > split_x + 1e-8,
    )
    crossing_count = int(crossing.sum())
    if crossing_count:
        raise RuntimeError(f"Wheel pair has {crossing_count} triangles crossing the lateral split plane")

    negative = mesh.submesh([negative_faces], append=True, repair=False)
    positive = mesh.submesh([positive_faces], append=True, repair=False)
    if not isinstance(negative, trimesh.Trimesh) or not isinstance(positive, trimesh.Trimesh):
        raise RuntimeError("Wheel split did not return Trimesh objects")
    return negative, positive, {
        "split_x": split_x,
        "negative_faces": int(len(negative_faces)),
        "positive_faces": int(len(positive_faces)),
        "crossing_faces": crossing_count,
    }


def center_mesh(mesh: trimesh.Trimesh) -> tuple[trimesh.Trimesh, np.ndarray]:
    center = mesh.bounds.mean(axis=0)
    result = mesh.copy()
    result.apply_translation(-center)
    return result, center


def material_summary(mesh: trimesh.Trimesh) -> dict[str, Any]:
    visual = mesh.visual
    material = getattr(visual, "material", None)
    texture = getattr(material, "baseColorTexture", None)
    return {
        "visual_kind": visual.kind,
        "uv_count": int(len(getattr(visual, "uv", []))) if getattr(visual, "uv", None) is not None else 0,
        "material_type": type(material).__name__ if material is not None else None,
        "material_name": getattr(material, "name", None),
        "base_color_texture": list(texture.size) if texture is not None else None,
    }


def transform_points(matrix: np.ndarray, points: np.ndarray) -> np.ndarray:
    return trimesh.transform_points(np.asarray(points, dtype=float), matrix)


def build(source: Path, output: Path, report_path: Path) -> None:
    actual_source_sha = sha256(source)
    if actual_source_sha != EXPECTED_SOURCE_SHA256:
        raise RuntimeError(f"Source SHA-256 mismatch: {actual_source_sha}")

    loaded = trimesh.load(source, force="scene", process=False, maintain_order=True)
    source_scene = loaded if isinstance(loaded, trimesh.Scene) else trimesh.Scene(loaded)

    body_node = find_geometry_node(source_scene, "BMW_4_Series_2014")
    front_node = find_geometry_node(source_scene, "on_teker")
    rear_node = find_geometry_node(source_scene, "arka_teker")

    body_world = world_mesh(source_scene, body_node)
    front_pair_world = world_mesh(source_scene, front_node)
    rear_pair_world = world_mesh(source_scene, rear_node)

    source_faces = int(len(body_world.faces) + len(front_pair_world.faces) + len(rear_pair_world.faces))
    if source_faces != EXPECTED_TOTAL_FACES:
        raise RuntimeError(f"Expected {EXPECTED_TOTAL_FACES} source faces, got {source_faces}")

    front_negative, front_positive, front_split = split_pair(front_pair_world)
    rear_negative, rear_positive, rear_split = split_pair(rear_pair_world)

    front_negative_local, front_negative_center = center_mesh(front_negative)
    front_positive_local, front_positive_center = center_mesh(front_positive)
    rear_negative_local, rear_negative_center = center_mesh(rear_negative)
    rear_positive_local, rear_positive_center = center_mesh(rear_positive)

    front_axle_z = float((front_negative_center[2] + front_positive_center[2]) * 0.5)
    rear_axle_z = float((rear_negative_center[2] + rear_positive_center[2]) * 0.5)
    source_wheelbase = abs(front_axle_z - rear_axle_z)
    scale = TARGET_WHEELBASE_M / source_wheelbase
    source_ground_y = float(min(front_pair_world.bounds[0, 1], rear_pair_world.bounds[0, 1]))
    source_center_x = float(np.mean([
        front_negative_center[0],
        front_positive_center[0],
        rear_negative_center[0],
        rear_positive_center[0],
    ]))
    source_axle_midpoint_z = (front_axle_z + rear_axle_z) * 0.5
    source_origin = np.array([source_center_x, source_ground_y, source_axle_midpoint_z], dtype=float)

    # Uniform scale plus 180-degree Y rotation converts source +Z front to project -Z front.
    canonical = np.eye(4)
    canonical[0, 0] = -scale
    canonical[1, 1] = scale
    canonical[2, 2] = -scale
    canonical[:3, 3] = -(canonical[:3, :3] @ source_origin)
    canonical_basis = canonical.copy()
    canonical_basis[:3, 3] = 0.0

    body = body_world.copy()
    body.apply_transform(canonical)

    wheel_specs = {
        # Source +X becomes project -X after the 180-degree Y rotation: project left.
        "FrontLeftWheel": (front_positive_local, front_positive_center),
        "FrontRightWheel": (front_negative_local, front_negative_center),
        "RearLeftWheel": (rear_positive_local, rear_positive_center),
        "RearRightWheel": (rear_negative_local, rear_negative_center),
    }

    output_scene = trimesh.Scene(base_frame="Bmw4SeriesF32Processed")
    output_scene.add_geometry(body, node_name="Body", geom_name="BodyMesh", transform=np.eye(4))

    canonical_centers: dict[str, list[float]] = {}
    wheel_face_total = 0
    for node_name, (wheel_local_source, center_source) in wheel_specs.items():
        wheel = wheel_local_source.copy()
        wheel.apply_transform(canonical_basis)
        center_canonical = transform_points(canonical, np.asarray([center_source]))[0]
        node_transform = np.eye(4)
        node_transform[:3, 3] = center_canonical
        output_scene.add_geometry(
            wheel,
            node_name=node_name,
            geom_name=f"{node_name}Mesh",
            transform=node_transform,
        )
        canonical_centers[node_name] = center_canonical.tolist()
        wheel_face_total += int(len(wheel.faces))

    output.parent.mkdir(parents=True, exist_ok=True)
    exported = output_scene.export(file_type="glb")
    if not isinstance(exported, (bytes, bytearray)):
        raise RuntimeError("Trimesh GLB export did not return bytes")
    output.write_bytes(exported)

    generated_loaded = trimesh.load(output, force="scene", process=False, maintain_order=True)
    generated = generated_loaded if isinstance(generated_loaded, trimesh.Scene) else trimesh.Scene(generated_loaded)
    generated_faces = int(sum(len(mesh.faces) for mesh in generated.geometry.values()))
    if generated_faces != EXPECTED_TOTAL_FACES:
        raise RuntimeError(f"Generated face count changed: {generated_faces}")

    generated_nodes = sorted(generated.graph.nodes_geometry)
    expected_nodes = {"Body", "FrontLeftWheel", "FrontRightWheel", "RearLeftWheel", "RearRightWheel"}
    missing_nodes = expected_nodes.difference(generated_nodes)
    if missing_nodes:
        raise RuntimeError(f"Generated GLB missing nodes: {sorted(missing_nodes)}; actual={generated_nodes}")

    front_z = (canonical_centers["FrontLeftWheel"][2] + canonical_centers["FrontRightWheel"][2]) * 0.5
    rear_z = (canonical_centers["RearLeftWheel"][2] + canonical_centers["RearRightWheel"][2]) * 0.5
    generated_wheelbase = abs(front_z - rear_z)
    if not np.isclose(generated_wheelbase, TARGET_WHEELBASE_M, atol=1e-6):
        raise RuntimeError(f"Generated wheelbase mismatch: {generated_wheelbase}")
    if not (front_z < 0.0 < rear_z):
        raise RuntimeError(f"Project front/rear orientation invalid: front_z={front_z}, rear_z={rear_z}")
    if not (
        canonical_centers["FrontLeftWheel"][0] < 0.0
        and canonical_centers["RearLeftWheel"][0] < 0.0
        and canonical_centers["FrontRightWheel"][0] > 0.0
        and canonical_centers["RearRightWheel"][0] > 0.0
    ):
        raise RuntimeError(f"Left/right wheel orientation invalid: {canonical_centers}")

    output_sha = sha256(output)
    if output_sha != EXPECTED_OUTPUT_SHA256:
        raise RuntimeError(f"Processed GLB is not deterministic: expected {EXPECTED_OUTPUT_SHA256}, got {output_sha}")

    report = {
        "generator": "tools/assets/process_traffic_rider_bmw_f32.py",
        "source_sha256": actual_source_sha,
        "output_sha256": output_sha,
        "source_nodes_geometry": sorted(source_scene.graph.nodes_geometry),
        "selected_nodes": {"body": body_node, "front_pair": front_node, "rear_pair": rear_node},
        "source_face_count": source_faces,
        "generated_face_count": generated_faces,
        "body_face_count": int(len(body.faces)),
        "wheel_face_count": wheel_face_total,
        "source_wheelbase": source_wheelbase,
        "target_wheelbase_m": TARGET_WHEELBASE_M,
        "scale": scale,
        "source_origin": source_origin.tolist(),
        "canonical_centers": canonical_centers,
        "generated_wheelbase_m": generated_wheelbase,
        "source_bounds": source_scene.bounds.tolist(),
        "generated_bounds": generated.bounds.tolist(),
        "front_split": front_split,
        "rear_split": rear_split,
        "source_materials": {
            "body": material_summary(body_world),
            "front_pair": material_summary(front_pair_world),
            "rear_pair": material_summary(rear_pair_world),
        },
        "generated_nodes_geometry": generated_nodes,
        "generated_geometry": {
            name: {
                "faces": int(len(mesh.faces)),
                "vertices": int(len(mesh.vertices)),
                "bounds": mesh.bounds.tolist(),
                "material": material_summary(mesh),
            }
            for name, mesh in generated.geometry.items()
        },
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")


if __name__ == "__main__":
    argument_parser = argparse.ArgumentParser()
    argument_parser.add_argument("source", type=Path)
    argument_parser.add_argument("output", type=Path)
    argument_parser.add_argument("report", type=Path)
    arguments = argument_parser.parse_args()
    build(arguments.source, arguments.output, arguments.report)
