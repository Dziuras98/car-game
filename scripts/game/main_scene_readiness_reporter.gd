extends Node

const READY_MARKER: String = "[GAME_READY] Main scene initialized"
const READY_FILE_ENVIRONMENT_VARIABLE: String = "CAR_GAME_STARTUP_READY_FILE"


func _ready() -> void:
	if OS.get_environment(READY_FILE_ENVIRONMENT_VARIABLE).is_empty():
		return
	call_deferred("_report_ready")


func _report_ready() -> void:
	if not is_inside_tree():
		return
	var readiness_path: String = OS.get_environment(READY_FILE_ENVIRONMENT_VARIABLE)
	if readiness_path.is_empty():
		return
	var manager: Node = get_parent()
	if manager == null or bool(manager.get("_initialization_failed")):
		return
	if not manager.has_method("is_ready_for_input") or not bool(manager.call("is_ready_for_input")):
		return
	if not _write_readiness_file(readiness_path):
		return
	print(READY_MARKER)


func _write_readiness_file(readiness_path: String) -> bool:
	var readiness_file: FileAccess = FileAccess.open(readiness_path, FileAccess.WRITE)
	if readiness_file == null:
		push_error(
			"Could not write the main-scene readiness file '%s' (error %s)."
			% [readiness_path, error_string(FileAccess.get_open_error())]
		)
		return false
	readiness_file.store_line(READY_MARKER)
	readiness_file.flush()
	return true
