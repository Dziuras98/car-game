#!/usr/bin/env python3
"""Inspect third-party 370Z GLB assets using only the Python standard library.

The script reports scene hierarchy, material counts and world-space bounds. It is
kept dependency-free so it can run in GitHub Actions before Godot imports the
models.
"""

from __future__ import annotations

import json
import math
import struct
import sys
from pathlib import Path
from typing import Iterable, Sequence

ROOT = Path(__file__).resolve().parents[2]
MODEL_PATHS = (
    ROOT / "third_party_sources/2013_nissan_370z.glb",
    ROOT / "third_party_sources/2015_nissan_370z_nismo_z34.glb",
)

Matrix = list[list[float]]
Vector3 = tuple[float, float, float]


def identity() -> Matrix:
    return [
        [1.0, 0.0, 0.0, 0.0],
        [0.0, 1.0, 0.0, 0.0],
        [0.0, 0.0, 1.0, 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]


def multiply(a: Matrix, b: Matrix) -> Matrix:
    return [
        [sum(a[row][k] * b[k][column] for k in range(4)) for column in range(4)]
        for row in range(4)
    ]


def transform_point(matrix: Matrix, point: Vector3) -> Vector3:
    x, y, z = point
    values = (x, y, z, 1.0)
    result = [sum(matrix[row][k] * values[k] for k in range(4)) for row in range(4)]
    w = result[3]
    if not math.isclose(w, 0.0) and not math.isclose(w, 1.0):
        return (result[0] / w, result[1] / w, result[2] / w)
    return (result[0], result[1], result[2])


def node_matrix(node: dict) -> Matrix:
    if "matrix" in node:
        values = [float(value) for value in node["matrix"]]
        return [[values[column * 4 + row] for column in range(4)] for row in range(4)]

    translation = [float(value) for value in node.get("translation", (0.0, 0.0, 0.0))]
    scale = [float(value) for value in node.get("scale", (1.0, 1.0, 1.0))]
    x, y, z, w = [float(value) for value in node.get("rotation", (0.0, 0.0, 0.0, 1.0))]

    length = math.sqrt(x * x + y * y + z * z + w * w)
    if length > 0.0:
        x, y, z, w = x / length, y / length, z / length, w / length

    rotation = [
        [1.0 - 2.0 * (y * y + z * z), 2.0 * (x * y - z * w), 2.0 * (x * z + y * w), 0.0],
        [2.0 * (x * y + z * w), 1.0 - 2.0 * (x * x + z * z), 2.0 * (y * z - x * w), 0.0],
        [2.0 * (x * z - y * w), 2.0 * (y * z + x * w), 1.0 - 2.0 * (x * x + y * y), 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ]
    scaling = identity()
    scaling[0][0], scaling[1][1], scaling[2][2] = scale
    translation_matrix = identity()
    translation_matrix[0][3], translation_matrix[1][3], translation_matrix[2][3] = translation
    return multiply(translation_matrix, multiply(rotation, scaling))


def load_glb_json(path: Path) -> tuple[dict, int]:
    payload = path.read_bytes()
    if len(payload) < 20:
        raise ValueError("file is too small to be a GLB")
    magic, version, declared_length = struct.unpack_from("<III", payload, 0)
    if magic != 0x46546C67:
        raise ValueError("invalid GLB magic")
    if version != 2:
        raise ValueError(f"unsupported GLB version: {version}")
    if declared_length != len(payload):
        raise ValueError(f"declared length {declared_length} differs from actual {len(payload)}")

    offset = 12
    document = None
    while offset + 8 <= len(payload):
        chunk_length, chunk_type = struct.unpack_from("<II", payload, offset)
        offset += 8
        chunk = payload[offset : offset + chunk_length]
        offset += chunk_length
        if chunk_type == 0x4E4F534A:
            document = json.loads(chunk.rstrip(b" \t\r\n\x00").decode("utf-8"))
            break
    if document is None:
        raise ValueError("GLB does not contain a JSON chunk")
    return document, len(payload)


def accessor_bounds(document: dict, mesh_index: int) -> Iterable[tuple[Vector3, Vector3]]:
    accessors = document.get("accessors", [])
    mesh = document.get("meshes", [])[mesh_index]
    for primitive in mesh.get("primitives", []):
        position_accessor_index = primitive.get("attributes", {}).get("POSITION")
        if position_accessor_index is None:
            continue
        accessor = accessors[position_accessor_index]
        minimum = accessor.get("min")
        maximum = accessor.get("max")
        if minimum is None or maximum is None or len(minimum) < 3 or len(maximum) < 3:
            continue
        yield (
            (float(minimum[0]), float(minimum[1]), float(minimum[2])),
            (float(maximum[0]), float(maximum[1]), float(maximum[2])),
        )


def corners(minimum: Vector3, maximum: Vector3) -> Iterable[Vector3]:
    for x in (minimum[0], maximum[0]):
        for y in (minimum[1], maximum[1]):
            for z in (minimum[2], maximum[2]):
                yield (x, y, z)


def world_bounds(document: dict) -> tuple[Vector3, Vector3] | None:
    nodes = document.get("nodes", [])
    scenes = document.get("scenes", [])
    scene_index = int(document.get("scene", 0)) if scenes else -1
    if 0 <= scene_index < len(scenes):
        roots = scenes[scene_index].get("nodes", [])
    else:
        child_indices = {int(child) for node in nodes for child in node.get("children", [])}
        roots = [index for index in range(len(nodes)) if index not in child_indices]

    minimum = [math.inf, math.inf, math.inf]
    maximum = [-math.inf, -math.inf, -math.inf]
    found = False

    def visit(node_index: int, parent: Matrix) -> None:
        nonlocal found
        node = nodes[node_index]
        world = multiply(parent, node_matrix(node))
        if "mesh" in node:
            for local_minimum, local_maximum in accessor_bounds(document, int(node["mesh"])):
                for point in corners(local_minimum, local_maximum):
                    transformed = transform_point(world, point)
                    for axis in range(3):
                        minimum[axis] = min(minimum[axis], transformed[axis])
                        maximum[axis] = max(maximum[axis], transformed[axis])
                    found = True
        for child_index in node.get("children", []):
            visit(int(child_index), world)

    for root_index in roots:
        visit(int(root_index), identity())

    if not found:
        return None
    return (tuple(minimum), tuple(maximum))  # type: ignore[return-value]


def names(items: Sequence[dict], unnamed_prefix: str) -> list[str]:
    return [str(item.get("name") or f"<{unnamed_prefix}-{index}>") for index, item in enumerate(items)]


def inspect(path: Path) -> None:
    document, byte_size = load_glb_json(path)
    nodes = document.get("nodes", [])
    meshes = document.get("meshes", [])
    materials = document.get("materials", [])
    images = document.get("images", [])
    animations = document.get("animations", [])
    primitives = sum(len(mesh.get("primitives", [])) for mesh in meshes)
    asset = document.get("asset", {})

    print(f"GLB_FILE={path.relative_to(ROOT).as_posix()}")
    print(f"GLB_BYTES={byte_size}")
    print(f"GLB_GENERATOR={asset.get('generator', '<unspecified>')}")
    print(f"GLB_SCENES={len(document.get('scenes', []))}")
    print(f"GLB_NODES={len(nodes)}")
    print(f"GLB_MESHES={len(meshes)}")
    print(f"GLB_PRIMITIVES={primitives}")
    print(f"GLB_MATERIALS={len(materials)}")
    print(f"GLB_IMAGES={len(images)}")
    print(f"GLB_ANIMATIONS={len(animations)}")
    print("GLB_NODE_NAMES=" + " | ".join(names(nodes, "node")[:120]))
    print("GLB_MESH_NAMES=" + " | ".join(names(meshes, "mesh")[:120]))
    print("GLB_MATERIAL_NAMES=" + " | ".join(names(materials, "material")[:120]))

    bounds = world_bounds(document)
    if bounds is None:
        print("GLB_BOUNDS=<unavailable>")
    else:
        minimum, maximum = bounds
        dimensions = tuple(maximum[index] - minimum[index] for index in range(3))
        center = tuple((minimum[index] + maximum[index]) * 0.5 for index in range(3))
        axis_names = ("X", "Y", "Z")
        longitudinal_axis = axis_names[max(range(3), key=lambda index: dimensions[index])]
        print("GLB_MIN=" + ",".join(f"{value:.6f}" for value in minimum))
        print("GLB_MAX=" + ",".join(f"{value:.6f}" for value in maximum))
        print("GLB_DIMENSIONS=" + ",".join(f"{value:.6f}" for value in dimensions))
        print("GLB_CENTER=" + ",".join(f"{value:.6f}" for value in center))
        print(f"GLB_LONGITUDINAL_AXIS={longitudinal_axis}")
    print("GLB_EXTENSIONS_USED=" + ",".join(document.get("extensionsUsed", [])))
    print("GLB_END")


def main() -> int:
    failed = False
    for model_path in MODEL_PATHS:
        try:
            inspect(model_path)
        except Exception as exc:  # noqa: BLE001 - CI diagnostic should report all model failures.
            failed = True
            print(f"GLB_ERROR={model_path.relative_to(ROOT).as_posix()}: {exc}", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
