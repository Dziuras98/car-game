extends Node

const READY_MARKER: String = "[NORMAL_STARTUP_SMOKE] Main scene ready"
const STARTUP_SMOKE_MARKER_ENV: String = "CAR_GAME_NORMAL_STARTUP_MARKER_PATH"


func _ready() -> void:
	call_deferred("_report_ready")


func _report_ready() -> void:
	print(READY_MARKER)

	var marker_path: String = OS.get_environment(STARTUP_SMOKE_MARKER_ENV)
	if marker_path.is_empty():
		return

	var marker_file: FileAccess = FileAccess.open(marker_path, FileAccess.WRITE)
	if marker_file == null:
		push_error(
			"[NORMAL_STARTUP_SMOKE] Failed to create marker file '%s' with error %d."
			% [marker_path, FileAccess.get_open_error()]
		)
		get_tree().quit(1)
		return

	marker_file.store_line(READY_MARKER)
	marker_file.flush()
	get_tree().quit(0)