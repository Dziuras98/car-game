extends Node

const READY_MARKER: String = "[GAME_READY] Main scene initialized"
const READY_FILE_ENVIRONMENT_VARIABLE: String = "CAR_GAME_STARTUP_READY_FILE"


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
	_write_readiness_file()
	print(READY_MARKER)


func _write_readiness_file() -> void:
	var readiness_path := OS.get_environment(READY_FILE_ENVIRONMENT_VARIABLE)
	if readiness_path.is_empty():
		return
	var readiness_file := FileAccess.open(readiness_path, FileAccess.WRITE)
	if readiness_file == null:
		push_error(
			"Could not write the main-scene readiness file '%s' (error %s)."
			% [readiness_path, error_string(FileAccess.get_open_error())]
		)
		return
	readiness_file.store_line(READY_MARKER)
	readiness_file.flush()
