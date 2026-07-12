extends SceneTree

const VISUAL_SCENE: PackedScene = preload("res://scenes/cars/370z_z34_visuals.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var visual: CarVisualController = VISUAL_SCENE.instantiate() as CarVisualController
	_expect(visual != null, "detailed car visual fixture instantiates")
	if visual == null:
		_finish()
		return

	_expect(visual.get_registered_wheel_count() == 0, "wheel setup is deferred while the visual is outside the scene tree")
	_expect(not visual._wheel_visuals_configured, "an early diagnostic query does not permanently mark wheel setup complete")

	root.add_child(visual)
	await process_frame
	_expect(visual._wheel_visuals_configured, "wheel setup retries successfully after scene-tree entry")
	_expect(visual.get_detailed_wheel_binding_count() == 4, "retry creates all four detailed wheel bindings")
	_expect(visual.get_low_detail_wheel_binding_count() == 4, "retry collects all four low-detail wheel pivots")

	visual.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_VISUAL_RETRY_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CAR_VISUAL_RETRY_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_VISUAL_RETRY_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CAR_VISUAL_RETRY_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_VISUAL_RETRY_TEST] - %s" % failure_message)
	quit(1)
