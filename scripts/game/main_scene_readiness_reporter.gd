extends Node

const READY_MARKER: String = "[GAME_READY] Main scene initialized"


func _ready() -> void:
	call_deferred("_report_ready")


func _report_ready() -> void:
	if not is_inside_tree():
		return
	var manager: Node = get_parent()
	if manager == null or bool(manager.get("_initialization_failed")):
		return
	if (
		manager.get("_session_start_transaction") == null
		or manager.get("_race_session") == null
		or manager.get("_pause_menu") == null
		or not manager.has_method("get_active_track")
		or manager.call("get_active_track") == null
	):
		return
	print(READY_MARKER)
