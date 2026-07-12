#!/usr/bin/env python3
"""Inspect third-party 370Z GLB assets using only the Python standard library."""

from __future__ import annotations

import json
import math
import struct
import sys
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[2]
MODEL_PATHS = (
    ROOT / "third_party_sources/2013_nissan_370z.glb",
    ROOT / "third_party_sources/2015_nissan_370z_nismo_z34.glb",
)
MARKER_TOKENS = (
    "BRAKE_FL",
    "BRAKE_FR",
    "BRAKE_RL",
    "BRAKE_RR",
    "BRAKE_CALIPER_FRONT_LEFT",
    "BRAKE_CALIPER_FRONT_RIGHT",
    "BRAKE_CALIPER_REAR_LEFT",
    "BRAKE_CALIPER_REAR_RIGHT",
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
        [sum(a[row][index] * b[index][column] for index in range(4)) for column in range(4)]
        for row in range(4)
    ]


def transform_point(matrix: Matrix, point: Vector3) -> Vector3:
    values = (point[0], point[1], point[2], 1.0)
    result = [sum(matrix[row][index] * values[index] for index in range(4)) for row in range(4)]
    if not math.isclose(result[3], 0.0) and not math.isclose(result[3], 1.0):
        return (result[0] / result[3], result[1] / result[3], result[2] / result[3])
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
    while offset + 8 <= len(payload):
        chunk_length, chunk_type = struct.unpack_from("<II", payload, offset)
        offset += 8
        chunk = payload[offset : offset + chunk_length]
        offset += chunk_length
        if chunk_type == 0x4E4F534A:
            return json.loads(chunk.rstrip(b" \t\r\n\x00").decode("utf-8")), len(payload)
    raise ValueError("GLB does not contain a JSON chunk")


def scene_roots(document: dict) -> list[int]:
    nodes = document.get("nodes", [])
    scenes = document.get("scenes", [])
    scene_index = int(document.get("scene", 0)) if scenes else -1
    if 0 <= scene_index < len(scenes):
        return [int(index) for index in scenes[scene_index].get("nodes", [])]
    children = {int(child) for node in nodes for child in node.get("children", [])}
    return [index for index in range(len(nodes)) if index not in children]


def world_matrices(document: dict) -> dict[int, Matrix]:
    nodes = document.get("nodes", [])
    result: dict[int, Matrix] = {}

    def visit(node_index: int, parent: Matrix) -> None:
        world = multiply(parent, node_matrix(nodes[node_index]))
        result[node_index] = world
        for child in nodes[node_index].get("children", []):
            visit(int(child), world)

    for root in scene_roots(document):
        visit(root, identity())
    return result


def accessor_bounds(document: dict, mesh_index: int) -> Iterable[tuple[Vector3, Vector3]]:
    accessors = document.get("accessors", [])
    mesh = document.get("meshes", [])[mesh_index]
    for primitive in mesh.get("primitives", []):
        position_index = primitive.get("attributes", {}).get("POSITION")
        if position_index is None:
            continue
        accessor = accessors[int(position_index)]
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


def world_bounds(document: dict, matrices: dict[int, Matrix]) -> tuple[Vector3, Vector3] | None:
    minimum = [math.inf, math.inf, math.inf]
    maximum = [-math.inf, -math.inf, -math.inf]
    found = False
    for node_index, world in matrices.items():
        node = document.get("nodes", [])[node_index]
        if "mesh" not in node:
            continue
        for local_minimum, local_maximum in accessor_bounds(document, int(node["mesh"])):
            for point in corners(local_minimum, local_maximum):
                transformed = transform_point(world, point)
                for axis in range(3):
                    minimum[axis] = min(minimum[axis], transformed[axis])
                    maximum[axis] = max(maximum[axis], transformed[axis])
                found = True
    if not found:
        return None
    return (tuple(minimum), tuple(maximum))  # type: ignore[return-value]


def inspect(path: Path) -> None:
    document, byte_size = load_glb_json(path)
    nodes = document.get("nodes", [])
    meshes = document.get("meshes", [])
    materials = document.get("materials", [])
    matrices = world_matrices(document)
    bounds = world_bounds(document, matrices)

    print(f"GLB_FILE={path.relative_to(ROOT).as_posix()}")
    print(f"GLB_BYTES={byte_size}")
    print(f"GLB_GENERATOR={document.get('asset', {}).get('generator', '<unspecified>')}")
    print(f"GLB_NODES={len(nodes)}")
    print(f"GLB_MESHES={len(meshes)}")
    print(f"GLB_PRIMITIVES={sum(len(mesh.get('primitives', [])) for mesh in meshes)}")
    print(f"GLB_MATERIALS={len(materials)}")
    print(f"GLB_IMAGES={len(document.get('images', []))}")
    print(f"GLB_ANIMATIONS={len(document.get('animations', []))}")

    if bounds is None:
        print("GLB_BOUNDS=<unavailable>")
    else:
        minimum, maximum = bounds
        dimensions = tuple(maximum[index] - minimum[index] for index in range(3))
        center = tuple((minimum[index] + maximum[index]) * 0.5 for index in range(3))
        axis_names = ("X", "Y", "Z")
        print("GLB_MIN=" + ",".join(f"{value:.6f}" for value in minimum))
        print("GLB_MAX=" + ",".join(f"{value:.6f}" for value in maximum))
        print("GLB_DIMENSIONS=" + ",".join(f"{value:.6f}" for value in dimensions))
        print("GLB_CENTER=" + ",".join(f"{value:.6f}" for value in center))
        print(f"GLB_LONGITUDINAL_AXIS={axis_names[max(range(3), key=lambda index: dimensions[index])]}")

    for node_index, node in enumerate(nodes):
        name = str(node.get("name", ""))
        upper_name = name.upper()
        if not any(token in upper_name for token in MARKER_TOKENS):
            continue
        origin = transform_point(matrices[node_index], (0.0, 0.0, 0.0))
        print(f"GLB_MARKER={name}@" + ",".join(f"{value:.6f}" for value in origin))

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
