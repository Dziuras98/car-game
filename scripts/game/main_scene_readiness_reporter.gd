extends Node

const READY_MARKER: String = "[GAME_READY] Main scene initialized"


func _ready() -> void:
	call_deferred("_report_ready")


func _report_ready() -> void:
	if not is_inside_tree():
		return
	print(READY_MARKER)
