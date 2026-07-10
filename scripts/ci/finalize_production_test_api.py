from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPTS_ROOT = ROOT / "scripts"


def replace_exact(path: Path, old: str, new: str) -> bool:
    text = path.read_text(encoding="utf-8")
    updated = text.replace(old, new)
    if updated == text:
        return False
    path.write_text(updated, encoding="utf-8", newline="\n")
    return True


def clean_transmission_compatibility() -> int:
    changed = 0
    specs_path = ROOT / "scripts/car/car_specs.gd"
    if replace_exact(
        specs_path,
        '''# Compatibility accessor for resources created before the force-based model.\n# It is intentionally hidden from the inspector and is never copied to runtime.\nvar acceleration: float:\n\tset(_value):\n\t\tpass\n\tget:\n\t\treturn engine_force\n\n''',
        "",
    ):
        changed += 1
    if replace_exact(
        specs_path,
        '''var manual_transmission_enabled: bool:\n\tset(value):\n\t\tif value:\n\t\t\ttransmission_type = TransmissionType.MANUAL\n\t\telif transmission_type == TransmissionType.MANUAL:\n\t\t\ttransmission_type = TransmissionType.DIRECT_DRIVE\n\tget:\n\t\treturn transmission_type == TransmissionType.MANUAL\n\nvar automatic_transmission_enabled: bool:\n\tset(value):\n\t\tif value:\n\t\t\ttransmission_type = TransmissionType.AUTOMATIC\n\t\telif transmission_type == TransmissionType.AUTOMATIC:\n\t\t\ttransmission_type = TransmissionType.DIRECT_DRIVE\n\tget:\n\t\treturn transmission_type == TransmissionType.AUTOMATIC\n\n''',
        "",
    ):
        changed += 1

    config_path = ROOT / "scripts/car/car_drive_config.gd"
    if replace_exact(
        config_path,
        '''const DUPLICATE_SKIP_PROPERTIES: Array[StringName] = [\n\t&"manual_transmission_enabled",\n\t&"automatic_transmission_enabled",\n]\n\n''',
        "",
    ):
        changed += 1
    if replace_exact(
        config_path,
        '''var manual_transmission_enabled: bool:\n\tset(value):\n\t\tif value:\n\t\t\ttransmission_type = CarSpecs.TransmissionType.MANUAL\n\t\telif transmission_type == CarSpecs.TransmissionType.MANUAL:\n\t\t\ttransmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE\n\tget:\n\t\treturn transmission_type == CarSpecs.TransmissionType.MANUAL\n\nvar automatic_transmission_enabled: bool:\n\tset(value):\n\t\tif value:\n\t\t\ttransmission_type = CarSpecs.TransmissionType.AUTOMATIC\n\t\telif transmission_type == CarSpecs.TransmissionType.AUTOMATIC:\n\t\t\ttransmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE\n\tget:\n\t\treturn transmission_type == CarSpecs.TransmissionType.AUTOMATIC\n\n''',
        "",
    ):
        changed += 1
    if replace_exact(
        config_path,
        ' or property_name in DUPLICATE_SKIP_PROPERTIES',
        '',
    ):
        changed += 1

    builder_path = ROOT / "scripts/car/car_drive_config_builder.gd"
    builder_text = builder_path.read_text(encoding="utf-8")
    builder_updated = builder_text.replace(
        '''const NON_RUNTIME_PROPERTIES: Array[StringName] = [\n\t&"display_name",\n\t&"acceleration",\n\t&"manual_transmission_enabled",\n\t&"automatic_transmission_enabled",\n]''',
        '''const NON_RUNTIME_PROPERTIES: Array[StringName] = [\n\t&"display_name",\n]''',
    )
    if builder_updated != builder_text:
        builder_path.write_text(builder_updated, encoding="utf-8", newline="\n")
        changed += 1

    assignment_patterns = [
        (r"\b([A-Za-z_][A-Za-z0-9_]*)\.manual_transmission_enabled\s*=\s*true", r"\1.transmission_type = CarSpecs.TransmissionType.MANUAL"),
        (r"\b([A-Za-z_][A-Za-z0-9_]*)\.manual_transmission_enabled\s*=\s*false", r"\1.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE"),
        (r"\b([A-Za-z_][A-Za-z0-9_]*)\.automatic_transmission_enabled\s*=\s*true", r"\1.transmission_type = CarSpecs.TransmissionType.AUTOMATIC"),
        (r"\b([A-Za-z_][A-Za-z0-9_]*)\.automatic_transmission_enabled\s*=\s*false", r"\1.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE"),
    ]
    for path in sorted(SCRIPTS_ROOT.rglob("*.gd")):
        text = path.read_text(encoding="utf-8")
        updated = text
        for pattern, replacement in assignment_patterns:
            updated = re.sub(pattern, replacement, updated)
        updated = updated.replace(".manual_transmission_enabled", ".is_manual_transmission()")
        updated = updated.replace(".automatic_transmission_enabled", ".is_automatic_transmission()")
        if updated != text:
            path.write_text(updated, encoding="utf-8", newline="\n")
            changed += 1
    return changed


def remove_test_facades() -> int:
    changed = 0
    game_manager = ROOT / "scripts/game/game_manager.gd"
    for block in [
        '''func get_moving_opponent_count() -> int:\n\treturn _race_session.get_moving_opponent_count() if _race_session != null else 0\n\n\n''',
        '''func request_return_to_main_menu() -> void:\n\t_return_to_main_menu()\n\n\n''',
        '''func simulate_current_player_finish() -> void:\n\tif _race_session != null:\n\t\t_race_session.simulate_current_player_finish(_current_car)\n\n\n''',
        '''func is_child_visible(node_name: String) -> bool:\n\tvar target: Node = get_node_or_null(node_name)\n\tif target is CanvasItem:\n\t\treturn (target as CanvasItem).is_visible_in_tree()\n\tvar visible_value: Variant = target.get("visible") if target != null else null\n\treturn visible_value is bool and bool(visible_value)\n\n\n''',
    ]:
        if replace_exact(game_manager, block, ""):
            changed += 1

    race_session = ROOT / "scripts/game/race_session_controller.gd"
    for block in [
        '''func get_moving_opponent_count() -> int:\n\tvar moving_count: int = 0\n\tfor opponent: PlayerCarController in _opponents:\n\t\tif is_instance_valid(opponent) and absf(opponent.get_forward_speed()) > 0.05:\n\t\t\tmoving_count += 1\n\treturn moving_count\n\n\n''',
        '''func simulate_current_player_finish(current_car: PlayerCarController) -> void:\n\tif current_car == null:\n\t\treturn\n\t_current_car = current_car\n\t_on_lap_tracker_participant_finished(current_car)\n\n\n''',
    ]:
        if replace_exact(race_session, block, ""):
            changed += 1

    adapter = ROOT / "scripts/tests/game_test_adapter.gd"
    adapter_text = adapter.read_text(encoding="utf-8")
    adapter_updated = adapter_text.replace(
        '''func is_child_visible(node_name: String) -> bool:\n\tif _main == null:\n\t\treturn false\n\n\treturn bool(_main.call("is_child_visible", node_name))''',
        '''func is_child_visible(node_name: String) -> bool:\n\tif _main == null:\n\t\treturn false\n\tvar target: Node = _main.get_node_or_null(node_name)\n\tif target is CanvasItem:\n\t\treturn (target as CanvasItem).is_visible_in_tree()\n\tvar visible_value: Variant = target.get("visible") if target != null else null\n\treturn visible_value is bool and bool(visible_value)''',
    )
    adapter_updated = adapter_updated.replace(
        '''func get_moving_opponent_count() -> int:\n\tif _main == null:\n\t\treturn 0\n\n\treturn int(_main.call("get_moving_opponent_count"))''',
        '''func get_moving_opponent_count() -> int:\n\tvar moving_count: int = 0\n\tfor opponent_value: Variant in get_opponents():\n\t\tvar opponent: PlayerCarController = opponent_value as PlayerCarController\n\t\tif is_instance_valid(opponent) and absf(opponent.get_forward_speed()) > 0.05:\n\t\t\tmoving_count += 1\n\treturn moving_count''',
    )
    adapter_updated = adapter_updated.replace(
        '''func return_to_main_menu() -> void:\n\tif _main != null and _main.has_method("request_return_to_main_menu"):\n\t\t_main.call("request_return_to_main_menu")''',
        '''func return_to_main_menu() -> void:\n\tif _main != null:\n\t\t_main.call("_return_to_main_menu")''',
    )
    adapter_updated = adapter_updated.replace(
        '''func simulate_player_finish() -> void:\n\tif _main != null and _main.has_method("simulate_current_player_finish"):\n\t\t_main.call("simulate_current_player_finish")''',
        '''func simulate_player_finish() -> void:\n\tif _main == null:\n\t\treturn\n\tvar current_car: PlayerCarController = get_current_car()\n\tvar session: RaceSessionController = _main.get("_race_session") as RaceSessionController\n\tif current_car == null or session == null:\n\t\treturn\n\tvar race_manager: RaceManager = session.get_race_manager()\n\tif race_manager != null:\n\t\trace_manager.finish_race(current_car, session.get_opponents())''',
    )
    if adapter_updated != adapter_text:
        adapter.write_text(adapter_updated, encoding="utf-8", newline="\n")
        changed += 1
    return changed


def main() -> None:
    transmission_changes = clean_transmission_compatibility()
    facade_changes = remove_test_facades()
    print(f"Transmission cleanup files: {transmission_changes}; test facade cleanup files: {facade_changes}")


if __name__ == "__main__":
    main()
