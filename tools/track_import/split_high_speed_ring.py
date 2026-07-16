#!/usr/bin/env python3
"""Split the Sketchfab High Speed Ring GLB into small, exact glTF subsets.

The source contains opaque object names and almost one material per object, so a
semantic split would be guesswork. This tool groups nodes by their material set,
then deterministically bin-packs those groups by the exact buffer/image payload
needed by each part. Geometry accessors are compacted out of the source's shared
buffer views, avoiding duplicated unused mesh data.

Usage:
    python tools/track_import/split_high_speed_ring.py path/to/high_speed_ring.glb

No third-party Python packages are required.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
import struct
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

DEFAULT_OUTPUT = Path("assets/tracks/high_speed_ring")
DEFAULT_TARGET_PART_BYTES = 4 * 1024 * 1024
MAX_PART_BYTES = 5 * 1024 * 1024
JSON_CHUNK_TYPE = 0x4E4F534A
BIN_CHUNK_TYPE = 0x004E4942
COMPONENT_BYTES = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
TYPE_COMPONENTS = {
    "SCALAR": 1,
    "VEC2": 2,
    "VEC3": 3,
    "VEC4": 4,
    "MAT2": 4,
    "MAT3": 9,
    "MAT4": 16,
}


@dataclass(frozen=True)
class GlbSource:
    document: dict[str, Any]
    binary: bytes


@dataclass(frozen=True)
class NodeGroup:
    key: tuple[int, ...]
    nodes: tuple[int, ...]
    dependency_bytes: int


def align4(value: int) -> int:
    return (value + 3) & ~3


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_glb(path: Path) -> GlbSource:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError(f"{path}: file is too short to be a GLB")
    magic, version, declared_length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or declared_length != len(data):
        raise ValueError(f"{path}: invalid glTF 2.0 binary header")

    offset = 12
    document: dict[str, Any] | None = None
    binary = b""
    while offset < len(data):
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset : offset + chunk_length]
        offset += chunk_length
        if chunk_type == JSON_CHUNK_TYPE:
            document = json.loads(chunk.decode("utf-8").rstrip("\x00 "))
        elif chunk_type == BIN_CHUNK_TYPE:
            binary = chunk
    if document is None:
        raise ValueError(f"{path}: missing JSON chunk")
    if len(document.get("buffers", [])) != 1:
        raise ValueError("Only single-buffer GLBs are supported")
    return GlbSource(document=document, binary=binary)


def material_indices_for_mesh(mesh: dict[str, Any]) -> tuple[int, ...]:
    return tuple(
        sorted(
            {
                int(primitive["material"])
                for primitive in mesh.get("primitives", [])
                if "material" in primitive
            }
        )
    )


def accessor_byte_length(document: dict[str, Any], accessor_index: int) -> int:
    accessor = document["accessors"][accessor_index]
    count = int(accessor.get("count", 0))
    if count == 0 or "bufferView" not in accessor:
        return 0
    element_bytes = COMPONENT_BYTES[int(accessor["componentType"])] * TYPE_COMPONENTS[accessor["type"]]
    view = document["bufferViews"][int(accessor["bufferView"])]
    stride = int(view.get("byteStride", element_bytes))
    return (count - 1) * stride + element_bytes


def collect_texture_indices(value: Any, parent_key: str = "") -> set[int]:
    found: set[int] = set()
    if isinstance(value, dict):
        if parent_key.lower().endswith("texture") and isinstance(value.get("index"), int):
            found.add(int(value["index"]))
        for key, child in value.items():
            found.update(collect_texture_indices(child, str(key)))
    elif isinstance(value, list):
        for child in value:
            found.update(collect_texture_indices(child, parent_key))
    return found


def collect_dependencies(document: dict[str, Any], direct_nodes: Iterable[int]) -> dict[str, set[int]]:
    nodes = document.get("nodes", [])
    meshes = document.get("meshes", [])
    selected_nodes = set(int(index) for index in direct_nodes)

    parent_of: dict[int, int] = {}
    for parent_index, node in enumerate(nodes):
        for child_index in node.get("children", []):
            parent_of[int(child_index)] = parent_index
    for node_index in tuple(selected_nodes):
        current = node_index
        while current in parent_of:
            current = parent_of[current]
            selected_nodes.add(current)

    selected_meshes = {
        int(nodes[node_index]["mesh"])
        for node_index in selected_nodes
        if "mesh" in nodes[node_index]
    }
    selected_accessors: set[int] = set()
    selected_materials: set[int] = set()
    for mesh_index in selected_meshes:
        for primitive in meshes[mesh_index].get("primitives", []):
            if "indices" in primitive:
                selected_accessors.add(int(primitive["indices"]))
            selected_accessors.update(int(index) for index in primitive.get("attributes", {}).values())
            for target in primitive.get("targets", []):
                selected_accessors.update(int(index) for index in target.values())
            if "material" in primitive:
                selected_materials.add(int(primitive["material"]))

    selected_textures: set[int] = set()
    for material_index in selected_materials:
        selected_textures.update(collect_texture_indices(document["materials"][material_index]))

    selected_images = {
        int(document["textures"][texture_index]["source"])
        for texture_index in selected_textures
        if "source" in document["textures"][texture_index]
    }
    selected_samplers = {
        int(document["textures"][texture_index]["sampler"])
        for texture_index in selected_textures
        if "sampler" in document["textures"][texture_index]
    }
    selected_image_views = {
        int(document["images"][image_index]["bufferView"])
        for image_index in selected_images
        if "bufferView" in document["images"][image_index]
    }

    return {
        "nodes": selected_nodes,
        "meshes": selected_meshes,
        "accessors": selected_accessors,
        "materials": selected_materials,
        "textures": selected_textures,
        "images": selected_images,
        "samplers": selected_samplers,
        "image_buffer_views": selected_image_views,
    }


def dependency_payload_bytes(document: dict[str, Any], dependencies: dict[str, set[int]]) -> int:
    total = 0
    for accessor_index in dependencies["accessors"]:
        total += align4(accessor_byte_length(document, accessor_index))
        accessor = document["accessors"][accessor_index]
        sparse = accessor.get("sparse")
        if sparse:
            for key in ("indices", "values"):
                view_index = int(sparse[key]["bufferView"])
                total += align4(int(document["bufferViews"][view_index]["byteLength"]))
    for view_index in dependencies["image_buffer_views"]:
        total += align4(int(document["bufferViews"][view_index]["byteLength"]))
    return total


def build_node_groups(document: dict[str, Any]) -> list[NodeGroup]:
    grouped: dict[tuple[int, ...], list[int]] = defaultdict(list)
    for node_index, node in enumerate(document.get("nodes", [])):
        if "mesh" not in node:
            continue
        mesh_index = int(node["mesh"])
        key = material_indices_for_mesh(document["meshes"][mesh_index])
        grouped[key].append(node_index)

    result: list[NodeGroup] = []
    for key, nodes in grouped.items():
        dependencies = collect_dependencies(document, nodes)
        result.append(
            NodeGroup(
                key=key,
                nodes=tuple(sorted(nodes)),
                dependency_bytes=dependency_payload_bytes(document, dependencies),
            )
        )
    return result


def pack_groups(document: dict[str, Any], groups: list[NodeGroup], target_bytes: int) -> list[list[NodeGroup]]:
    bins: list[list[NodeGroup]] = []
    for group in sorted(groups, key=lambda item: (-item.dependency_bytes, item.key)):
        best_index: int | None = None
        best_size: int | None = None
        for index, current in enumerate(bins):
            nodes = [node for item in current for node in item.nodes] + list(group.nodes)
            deps = collect_dependencies(document, nodes)
            estimated = dependency_payload_bytes(document, deps) + 96 * 1024
            if estimated <= target_bytes and (best_size is None or estimated > best_size):
                best_index = index
                best_size = estimated
        if best_index is None:
            bins.append([group])
        else:
            bins[best_index].append(group)
    return bins


def subset_mapping(indices: set[int]) -> tuple[list[int], dict[int, int]]:
    ordered = sorted(indices)
    return ordered, {old: new for new, old in enumerate(ordered)}


def remap_texture_refs(value: Any, texture_map: dict[int, int], parent_key: str = "") -> Any:
    result = copy.deepcopy(value)
    if isinstance(result, dict):
        if parent_key.lower().endswith("texture") and isinstance(result.get("index"), int):
            result["index"] = texture_map[int(result["index"])]
        for key in list(result):
            result[key] = remap_texture_refs(result[key], texture_map, str(key))
    elif isinstance(result, list):
        result = [remap_texture_refs(item, texture_map, parent_key) for item in result]
    return result


def append_segment(binary_out: bytearray, source_binary: bytes, offset: int, length: int) -> int:
    while len(binary_out) % 4:
        binary_out.append(0)
    new_offset = len(binary_out)
    binary_out.extend(source_binary[offset : offset + length])
    while len(binary_out) % 4:
        binary_out.append(0)
    return new_offset


def build_subset(source: GlbSource, direct_nodes: Iterable[int]) -> bytes:
    document = source.document
    deps = collect_dependencies(document, direct_nodes)

    node_ids, node_map = subset_mapping(deps["nodes"])
    mesh_ids, mesh_map = subset_mapping(deps["meshes"])
    accessor_ids, accessor_map = subset_mapping(deps["accessors"])
    material_ids, material_map = subset_mapping(deps["materials"])
    texture_ids, texture_map = subset_mapping(deps["textures"])
    image_ids, image_map = subset_mapping(deps["images"])
    sampler_ids, sampler_map = subset_mapping(deps["samplers"])

    output: dict[str, Any] = {
        "asset": copy.deepcopy(document["asset"]),
        "scene": 0,
        "scenes": [{"name": document.get("scenes", [{}])[document.get("scene", 0)].get("name", "Scene")}],
    }
    for key in ("extensionsUsed", "extensionsRequired"):
        if key in document:
            output[key] = copy.deepcopy(document[key])

    binary_out = bytearray()
    new_views: list[dict[str, Any]] = []
    new_accessors: list[dict[str, Any]] = []

    for old_accessor_index in accessor_ids:
        accessor = copy.deepcopy(document["accessors"][old_accessor_index])
        if "bufferView" in accessor:
            old_view = document["bufferViews"][int(accessor["bufferView"])]
            element_length = accessor_byte_length(document, old_accessor_index)
            source_offset = int(old_view.get("byteOffset", 0)) + int(accessor.get("byteOffset", 0))
            new_offset = append_segment(binary_out, source.binary, source_offset, element_length)
            new_view = {
                key: copy.deepcopy(value)
                for key, value in old_view.items()
                if key not in {"byteOffset", "byteLength", "name"}
            }
            new_view.update({"buffer": 0, "byteOffset": new_offset, "byteLength": element_length})
            if "name" in old_view:
                new_view["name"] = f"accessor_{old_accessor_index}_{old_view['name']}"
            accessor["bufferView"] = len(new_views)
            accessor.pop("byteOffset", None)
            new_views.append(new_view)
        sparse = accessor.get("sparse")
        if sparse:
            for sparse_key in ("indices", "values"):
                sparse_ref = sparse[sparse_key]
                old_view = document["bufferViews"][int(sparse_ref["bufferView"])]
                length = int(old_view["byteLength"])
                source_offset = int(old_view.get("byteOffset", 0))
                new_offset = append_segment(binary_out, source.binary, source_offset, length)
                new_view = copy.deepcopy(old_view)
                new_view.update({"buffer": 0, "byteOffset": new_offset, "byteLength": length})
                sparse_ref["bufferView"] = len(new_views)
                new_views.append(new_view)
        new_accessors.append(accessor)

    new_images: list[dict[str, Any]] = []
    for old_image_index in image_ids:
        image = copy.deepcopy(document["images"][old_image_index])
        if "bufferView" in image:
            old_view = document["bufferViews"][int(image["bufferView"])]
            length = int(old_view["byteLength"])
            source_offset = int(old_view.get("byteOffset", 0))
            new_offset = append_segment(binary_out, source.binary, source_offset, length)
            new_view = copy.deepcopy(old_view)
            new_view.update({"buffer": 0, "byteOffset": new_offset, "byteLength": length})
            image["bufferView"] = len(new_views)
            new_views.append(new_view)
        new_images.append(image)

    new_materials = [
        remap_texture_refs(document["materials"][old], texture_map)
        for old in material_ids
    ]
    new_textures: list[dict[str, Any]] = []
    for old in texture_ids:
        texture = copy.deepcopy(document["textures"][old])
        if "source" in texture:
            texture["source"] = image_map[int(texture["source"])]
        if "sampler" in texture:
            texture["sampler"] = sampler_map[int(texture["sampler"])]
        new_textures.append(texture)

    new_meshes: list[dict[str, Any]] = []
    for old in mesh_ids:
        mesh = copy.deepcopy(document["meshes"][old])
        for primitive in mesh.get("primitives", []):
            if "indices" in primitive:
                primitive["indices"] = accessor_map[int(primitive["indices"])]
            primitive["attributes"] = {
                semantic: accessor_map[int(index)]
                for semantic, index in primitive.get("attributes", {}).items()
            }
            for target in primitive.get("targets", []):
                for semantic, index in list(target.items()):
                    target[semantic] = accessor_map[int(index)]
            if "material" in primitive:
                primitive["material"] = material_map[int(primitive["material"])]
        new_meshes.append(mesh)

    new_nodes: list[dict[str, Any]] = []
    for old in node_ids:
        node = copy.deepcopy(document["nodes"][old])
        if "mesh" in node:
            node["mesh"] = mesh_map[int(node["mesh"])]
        if "children" in node:
            node["children"] = [node_map[int(child)] for child in node["children"] if int(child) in node_map]
            if not node["children"]:
                node.pop("children")
        new_nodes.append(node)

    scene_index = int(document.get("scene", 0))
    original_roots = document.get("scenes", [{}])[scene_index].get("nodes", [])
    output["scenes"][0]["nodes"] = [node_map[int(root)] for root in original_roots if int(root) in node_map]
    output["nodes"] = new_nodes
    output["meshes"] = new_meshes
    output["accessors"] = new_accessors
    output["bufferViews"] = new_views
    output["buffers"] = [{"byteLength": len(binary_out)}]
    if new_materials:
        output["materials"] = new_materials
    if new_textures:
        output["textures"] = new_textures
    if new_images:
        output["images"] = new_images
    if sampler_ids:
        output["samplers"] = [copy.deepcopy(document["samplers"][old]) for old in sampler_ids]

    json_bytes = json.dumps(output, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    json_padded = json_bytes + b" " * ((-len(json_bytes)) % 4)
    bin_bytes = bytes(binary_out)
    bin_padded = bin_bytes + b"\x00" * ((-len(bin_bytes)) % 4)
    total_length = 12 + 8 + len(json_padded) + 8 + len(bin_padded)
    return b"".join(
        [
            struct.pack("<4sII", b"glTF", 2, total_length),
            struct.pack("<II", len(json_padded), JSON_CHUNK_TYPE),
            json_padded,
            struct.pack("<II", len(bin_padded), BIN_CHUNK_TYPE),
            bin_padded,
        ]
    )


def split_oversized(source: GlbSource, groups: list[NodeGroup]) -> list[tuple[list[NodeGroup], bytes]]:
    nodes = [node for group in groups for node in group.nodes]
    payload = build_subset(source, nodes)
    if len(payload) <= MAX_PART_BYTES:
        return [(groups, payload)]
    if len(groups) == 1:
        raise RuntimeError(f"One material group exceeds {MAX_PART_BYTES} bytes: {groups[0].key}")
    ordered = sorted(groups, key=lambda item: (-item.dependency_bytes, item.key))
    left: list[NodeGroup] = []
    right: list[NodeGroup] = []
    left_size = right_size = 0
    for group in ordered:
        if left_size <= right_size:
            left.append(group)
            left_size += group.dependency_bytes
        else:
            right.append(group)
            right_size += group.dependency_bytes
    return split_oversized(source, left) + split_oversized(source, right)


def split_model(source_path: Path, output: Path, target_part_bytes: int) -> dict[str, Any]:
    if not source_path.is_file():
        raise FileNotFoundError(source_path)
    if not 1 <= target_part_bytes <= MAX_PART_BYTES:
        raise ValueError(f"target size must be between 1 and {MAX_PART_BYTES}")

    source = read_glb(source_path)
    groups = build_node_groups(source.document)
    packed = pack_groups(source.document, groups, target_part_bytes)
    final_parts: list[tuple[list[NodeGroup], bytes]] = []
    for candidate in packed:
        final_parts.extend(split_oversized(source, candidate))

    output.mkdir(parents=True, exist_ok=True)
    for old_part in output.glob("part_*.glb"):
        old_part.unlink()

    material_names = [material.get("name", f"material_{index}") for index, material in enumerate(source.document.get("materials", []))]
    mesh_nodes = [index for index, node in enumerate(source.document.get("nodes", [])) if "mesh" in node]
    assigned_nodes: set[int] = set()
    parts: list[dict[str, Any]] = []

    for part_index, (part_groups, payload) in enumerate(final_parts, start=1):
        part_path = output / f"part_{part_index:03d}.glb"
        part_path.write_bytes(payload)
        validation = read_glb(part_path)
        direct_nodes = sorted(node for group in part_groups for node in group.nodes)
        assigned_nodes.update(direct_nodes)
        selected_meshes = [source.document["nodes"][node]["mesh"] for node in direct_nodes]
        vertex_count = 0
        triangle_count = 0
        for mesh_index in selected_meshes:
            for primitive in source.document["meshes"][mesh_index].get("primitives", []):
                position_accessor = primitive.get("attributes", {}).get("POSITION")
                if position_accessor is not None:
                    vertex_count += int(source.document["accessors"][position_accessor]["count"])
                if "indices" in primitive:
                    triangle_count += int(source.document["accessors"][primitive["indices"]]["count"]) // 3
        material_indices = sorted({index for group in part_groups for index in group.key})
        parts.append(
            {
                "path": part_path.name,
                "sha256": sha256(part_path),
                "bytes": len(payload),
                "objects": len(direct_nodes),
                "vertices": vertex_count,
                "triangles": triangle_count,
                "materials": [material_names[index] for index in material_indices],
                "source_nodes": [source.document["nodes"][index].get("name", f"node_{index}") for index in direct_nodes],
                "validated_meshes": len(validation.document.get("meshes", [])),
            }
        )

    if assigned_nodes != set(mesh_nodes):
        raise RuntimeError("Not every source mesh node was assigned exactly once")

    asset_extras = source.document.get("asset", {}).get("extras", {})
    manifest = {
        "format_version": 1,
        "source_file": source_path.name,
        "source_sha256": sha256(source_path),
        "source_bytes": source_path.stat().st_size,
        "source": asset_extras.get("source"),
        "author": asset_extras.get("author"),
        "license": asset_extras.get("license"),
        "split_strategy": "material-set first-fit-decreasing with compacted accessor ranges",
        "target_part_bytes": target_part_bytes,
        "max_part_bytes": MAX_PART_BYTES,
        "source_objects": len(mesh_nodes),
        "source_material_groups": len(groups),
        "parts": parts,
    }
    (output / "split_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--target-part-bytes", type=int, default=DEFAULT_TARGET_PART_BYTES)
    args = parser.parse_args()
    print(json.dumps(split_model(args.source, args.output, args.target_part_bytes), indent=2))


if __name__ == "__main__":
    main()
