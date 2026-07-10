extends Node

const READY_MARKER: String = "[NORMAL_STARTUP_SMOKE] Main scene ready"


func _ready() -> void:
	call_deferred("_report_ready")


func _report_ready() -> void:
	print(READY_MARKER)