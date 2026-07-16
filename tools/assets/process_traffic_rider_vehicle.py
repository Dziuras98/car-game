#!/usr/bin/env python3
"""Build a canonical four-wheel Traffic Rider visual derivative.

The processor is parameterized by the inspected source record and a target
wheelbase. It preserves the source body's geometry/material/UV data, splits the
front and rear axle-pair meshes at their measured lateral centre, gives each
wheel a hub-centred pivot, converts source +Z front to project -Z front, centres
the chassis between the axles and grounds it at the tyre contact plane.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

import numpy as np
import trimesh


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source_file:
        for chunk in iter(lambda: source_file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def world_mesh(scene: trimesh.Scene, node_name: str) -> trimesh.Trimesh:
    if node_name not in scene.graph.nodes_geometry:
        raise RuntimeError(f"Geometry node not found: {node_name}")
    transform, geometry_name = scene.graph[node_name]
    mesh = scene.geometry[geometry_name].copy()
    mesh.apply_transform(transform)
    return mesh


def classify_nodes(scene: trimesh.Scene) -> tuple[str, str, str]:
    face_counts: list[tuple[int, str]] = []
    for node_name in scene.graph.nodes_geometry:
        face_counts.append((int(len(world_mesh(scene, node_name).faces)), node_name))
    face_counts.sort(reverse=True)
    if len(face_counts) != 3:
        raise RuntimeError(f"Expected exactly three geometry nodes, found {face_counts}")
    body_node = face_counts[0][1]
    wheel_nodes = [node for _faces, node in face_counts[1:]]
    wheel_nodes.sort(key=lambda name: float(world_mesh(scene, name).bounds.mean(axis=0)[2]))
    return body_node, wheel_nodes[0], wheel_nodes[1]


def split_pair(mesh: trimesh.Trimesh) -> tuple[trimesh.Trimesh, trimesh.Trimesh, dict[str, Any]]:
    split_x = float(mesh.bounds.mean(axis=0)[0])
    centroids = mesh.triangles_center
    negative_faces = np.flatnonzero(centroids[:, 0] < split_x)
    positive_faces = np.flatnonzero(centroids[:, 0] >= split_x)
    crossing = np.logical_and(
        mesh.triangles[:, :, 0].min(axis=1) < split_x - 1e-8,
        mesh.triangles[:, :, 0].max(axis=1) > split_x + 1e-8,
    )
    if int(crossing.sum()):
        raise RuntimeError(f"Wheel pair has {int(crossing.sum())} crossing triangles")
    negative = mesh.submesh([negative_faces], append=True, repair=False)
    positive = mesh.submesh([positive_faces], append=True, repair=False)
    if not isinstance(negative, trimesh.Trimesh) or not isinstance(positive, trimesh.Trimesh):
        raise RuntimeError("Wheel split did not return Trimesh objects")
    return negative, positive, {
        "split_x": split_x,
        "negative_faces": int(len(negative_faces)),
        "positive_faces": int(len(positive_faces)),
        "crossing_faces": int(crossing.sum()),
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
    uv = getattr(visual, "uv", None)
    return {
        "visual_kind": visual.kind,
        "uv_count": int(len(uv)) if uv is not None else 0,
        "material_type": type(material).__name__ if material is not None else None,
        "material_name": getattr(material, "name", None),
        "base_color_texture": list(texture.size) if texture is not None else None,
    }


def build(
    source: Path,
    output: Path,
    report_path: Path,
    vehicle_id: str,
    target_wheelbase_m: float,
    expected_source_sha256: str,
    expected_total_faces: int,
) -> None:
    source_sha = sha256(source)
    if source_sha != expected_source_sha256:
        raise RuntimeError(f"Source SHA mismatch: expected {expected_source_sha256}, got {source_sha}")
    loaded = trimesh.load(source, force="scene", process=False, maintain_order=True)
    source_scene = loaded if isinstance(loaded, trimesh.Scene) else trimesh.Scene(loaded)
    body_node, front_node, rear_node = classify_nodes(source_scene)
    body_world = world_mesh(source_scene, body_node)
    front_pair_world = world_mesh(source_scene, front_node)
    rear_pair_world = world_mesh(source_scene, rear_node)
    source_faces = int(len(body_world.faces) + len(front_pair_world.faces) + len(rear_pair_world.faces))
    if source_faces != expected_total_faces:
        raise RuntimeError(f"Face count mismatch: expected {expected_total_faces}, got {source_faces}")

    front_negative, front_positive, front_split = split_pair(front_pair_world)
    rear_negative, rear_positive, rear_split = split_pair(rear_pair_world)
    front_negative_local, front_negative_center = center_mesh(front_negative)
    front_positive_local, front_positive_center = center_mesh(front_positive)
    rear_negative_local, rear_negative_center = center_mesh(rear_negative)
    rear_positive_local, rear_positive_center = center_mesh(rear_positive)

    front_axle_z = float((front_negative_center[2] + front_positive_center[2]) * 0.5)
    rear_axle_z = float((rear_negative_center[2] + rear_positive_center[2]) * 0.5)
    source_wheelbase = abs(front_axle_z - rear_axle_z)
    if source_wheelbase <= 0.0:
        raise RuntimeError("Measured source wheelbase is not positive")
    scale = target_wheelbase_m / source_wheelbase
    source_ground_y = float(min(front_pair_world.bounds[0, 1], rear_pair_world.bounds[0, 1]))
    source_center_x = float(np.mean([
        front_negative_center[0], front_positive_center[0],
        rear_negative_center[0], rear_positive_center[0],
    ]))
    source_axle_midpoint_z = (front_axle_z + rear_axle_z) * 0.5
    source_origin = np.array([source_center_x, source_ground_y, source_axle_midpoint_z], dtype=float)

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
        "FrontLeftWheel": (front_positive_local, front_positive_center),
        "FrontRightWheel": (front_negative_local, front_negative_center),
        "RearLeftWheel": (rear_positive_local, rear_positive_center),
        "RearRightWheel": (rear_negative_local, rear_negative_center),
    }
    output_scene = trimesh.Scene(base_frame=f"{vehicle_id}Processed")
    output_scene.add_geometry(body, node_name="Body", geom_name="BodyMesh", transform=np.eye(4))
    canonical_centers: dict[str, list[float]] = {}
    for node_name, (wheel_local, center_source) in wheel_specs.items():
        wheel = wheel_local.copy()
        wheel.apply_transform(canonical_basis)
        center_canonical = trimesh.transform_points(np.asarray([center_source]), canonical)[0]
        node_transform = np.eye(4)
        node_transform[:3, 3] = center_canonical
        output_scene.add_geometry(wheel, node_name=node_name, geom_name=f"{node_name}Mesh", transform=node_transform)
        canonical_centers[node_name] = center_canonical.tolist()

    output.parent.mkdir(parents=True, exist_ok=True)
    exported = output_scene.export(file_type="glb")
    if not isinstance(exported, (bytes, bytearray)):
        raise RuntimeError("GLB export did not return bytes")
    output.write_bytes(exported)

    generated_loaded = trimesh.load(output, force="scene", process=False, maintain_order=True)
    generated = generated_loaded if isinstance(generated_loaded, trimesh.Scene) else trimesh.Scene(generated_loaded)
    generated_faces = int(sum(len(mesh.faces) for mesh in generated.geometry.values()))
    if generated_faces != expected_total_faces:
        raise RuntimeError(f"Generated face count changed: {generated_faces}")
    expected_nodes = {"Body", "FrontLeftWheel", "FrontRightWheel", "RearLeftWheel", "RearRightWheel"}
    actual_nodes = set(generated.graph.nodes_geometry)
    if not expected_nodes.issubset(actual_nodes):
        raise RuntimeError(f"Generated GLB missing nodes: {sorted(expected_nodes - actual_nodes)}")
    front_z = (canonical_centers["FrontLeftWheel"][2] + canonical_centers["FrontRightWheel"][2]) * 0.5
    rear_z = (canonical_centers["RearLeftWheel"][2] + canonical_centers["RearRightWheel"][2]) * 0.5
    generated_wheelbase = abs(front_z - rear_z)
    if not np.isclose(generated_wheelbase, target_wheelbase_m, atol=1e-6):
        raise RuntimeError(f"Generated wheelbase mismatch: {generated_wheelbase}")
    if not (front_z < 0.0 < rear_z):
        raise RuntimeError(f"Front/rear orientation invalid: front={front_z}, rear={rear_z}")

    report = {
        "generator": "tools/assets/process_traffic_rider_vehicle.py",
        "vehicle_id": vehicle_id,
        "source_sha256": source_sha,
        "output_sha256": sha256(output),
        "selected_nodes": {"body": body_node, "front_pair": front_node, "rear_pair": rear_node},
        "source_face_count": source_faces,
        "generated_face_count": generated_faces,
        "source_wheelbase": source_wheelbase,
        "target_wheelbase_m": target_wheelbase_m,
        "generated_wheelbase_m": generated_wheelbase,
        "scale": scale,
        "source_origin": source_origin.tolist(),
        "canonical_centers": canonical_centers,
        "front_split": front_split,
        "rear_split": rear_split,
        "source_bounds": source_scene.bounds.tolist(),
        "generated_bounds": generated.bounds.tolist(),
        "source_materials": {
            "body": material_summary(body_world),
            "front_pair": material_summary(front_pair_world),
            "rear_pair": material_summary(rear_pair_world),
        },
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("report", type=Path)
    parser.add_argument("--vehicle-id", required=True)
    parser.add_argument("--target-wheelbase-m", type=float, required=True)
    parser.add_argument("--expected-source-sha256", required=True)
    parser.add_argument("--expected-total-faces", type=int, required=True)
    args = parser.parse_args()
    build(
        args.source, args.output, args.report, args.vehicle_id,
        args.target_wheelbase_m, args.expected_source_sha256, args.expected_total_faces,
    )


if __name__ == "__main__":
    main()
