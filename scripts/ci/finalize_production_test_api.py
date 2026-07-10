from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPTS_ROOT = ROOT / "scripts"


def replace_all_gd_identifiers() -> int:
    changed = 0
    for path in sorted(SCRIPTS_ROOT.rglob("*.gd")):
        text = path.read_text(encoding="utf-8")
        updated = text.replace("_for_test", "")
        if updated != text:
            path.write_text(updated, encoding="utf-8", newline="\n")
            changed += 1
    return changed


def type_ai_track_contract() -> bool:
    path = ROOT / "scripts/race/ai_race_driver.gd"
    text = path.read_text(encoding="utf-8")
    updated = text
    updated = updated.replace("var _track: Node3D", "var _track: GeneratedTrack")
    updated = updated.replace(
        "_track = get_node_or_null(track_path) as Node3D",
        "_track = get_node_or_null(track_path) as GeneratedTrack",
    )
    updated = updated.replace(
        '''\tif not is_instance_valid(_track) or not _track.has_method("get_racing_line_points"):\n\t\treturn\n\tvar local_points: Array = _track.call("get_racing_line_points")\n\tfor point: Variant in local_points:\n\t\tif point is Vector3:\n\t\t\t_points.append(_track.to_global(point))''',
        '''\tif not is_instance_valid(_track):\n\t\treturn\n\tfor point: Vector3 in _track.get_racing_line_points():\n\t\t_points.append(_track.to_global(point))''',
    )
    updated = updated.replace(
        '''\tif not is_instance_valid(_track) or not _track.has_signal("geometry_rebuilt"):\n\t\treturn''',
        '''\tif not is_instance_valid(_track):\n\t\treturn''',
    )
    if updated == text:
        return False
    path.write_text(updated, encoding="utf-8", newline="\n")
    return True


def main() -> None:
    changed_files = replace_all_gd_identifiers()
    ai_changed = type_ai_track_contract()
    print(f"Updated GDScript files: {changed_files}; AI contract changed: {ai_changed}")


if __name__ == "__main__":
    main()
