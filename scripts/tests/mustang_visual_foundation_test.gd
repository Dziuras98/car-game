extends SceneTree

const SOURCE_MODEL_PATH: String = "res://1967_ford_mustang_shelby_cobra_gt500.glb"
const VISUAL_SCENE_PATH: String = "res://scenes/cars/mustang_shelby_gt500_1967_visuals.tscn"
const LOW_DETAIL_SCENE_PATH: String = "res://scenes/cars/mustang_shelby_gt500_1967_low_detail_visuals.tscn"
const PREVIEW_SCENE_PATH: String = "res://scenes/dev/mustang_shelby_gt500_1967_visual_preview.tscn"
const REQUIRED_LOW_DETAIL_WHEELS: Array[StringName] = [
	&"WheelFrontLeft",
	&"WheelFrontRight",
	&"WheelRearLeft",
	&"WheelRearRight",
]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_source_and_visual_wrapper()
	_test_low_detail_contract()
	await _test_preview_scene()
	_finish()


func _test_source_and_visual_wrapper() -> void:
	var source_model: PackedScene = load(SOURCE_MODEL_PATH) as PackedScene
	_expect(source_model != null, "the uploaded Mustang GLB imports as a PackedScene")

	var packed_visuals: PackedScene = load(VISUAL_SCENE_PATH) as PackedScene
	_expect(packed_visuals != null, "the Mustang visual wrapper scene loads")
	if packed_visuals == null:
		return

	var visuals: Node3D = packed_visuals.instantiate() as Node3D
	_expect(visuals != null, "the Mustang visual wrapper instantiates as Node3D")
	if visuals == null:
		return

	root.add_child(visuals)
	await process_frame
	_expect(visuals.get_node_or_null("ModelAlignment") is Node3D, "the wrapper exposes an isolated alignment root")
	_expect(visuals.get_node_or_null("ModelAlignment/DetailedModel") is Node3D, "the wrapper contains the imported detailed model")
	var low_detail: Node3D = visuals.get_node_or_null("LowDetail") as Node3D
	_expect(low_detail != null, "the wrapper contains a low-detail fallback")
	_expect(low_detail == null or not low_detail.visible, "the detailed wrapper keeps the fallback hidden by default")
	visuals.queue_free()
	await process_frame


func _test_low_detail_contract() -> void:
	var packed_low_detail: PackedScene = load(LOW_DETAIL_SCENE_PATH) as PackedScene
	_expect(packed_low_detail != null, "the Mustang low-detail scene loads")
	if packed_low_detail == null:
		return

	var low_detail: Node3D = packed_low_detail.instantiate() as Node3D
	_expect(low_detail != null, "the Mustang low-detail scene instantiates as Node3D")
	if low_detail == null:
		return

	for wheel_name: StringName in REQUIRED_LOW_DETAIL_WHEELS:
		var wheel: Node3D = low_detail.get_node_or_null(NodePath(String(wheel_name))) as Node3D
		_expect(wheel != null, "the low-detail scene exposes %s" % wheel_name)
		_expect(wheel == null or wheel.get_node_or_null("Mesh") is MeshInstance3D, "%s contains renderable wheel geometry" % wheel_name)
	low_detail.free()


func _test_preview_scene() -> void:
	var packed_preview: PackedScene = load(PREVIEW_SCENE_PATH) as PackedScene
	_expect(packed_preview != null, "the Mustang visual preview scene loads")
	if packed_preview == null:
		return

	var preview: Node3D = packed_preview.instantiate() as Node3D
	_expect(preview != null, "the Mustang visual preview scene instantiates")
	if preview == null:
		return

	root.add_child(preview)
	await process_frame
	await process_frame
	_expect(preview.get_node_or_null("VehicleVisual") is Node3D, "the preview contains the Mustang visual wrapper")
	_expect(preview.get_node_or_null("Camera3D") is Camera3D, "the preview contains a framing camera")
	_expect(preview.get_node_or_null("Ground") is MeshInstance3D, "the preview contains a ground reference")
	preview.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[MUSTANG_VISUAL_FOUNDATION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[MUSTANG_VISUAL_FOUNDATION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[MUSTANG_VISUAL_FOUNDATION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[MUSTANG_VISUAL_FOUNDATION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[MUSTANG_VISUAL_FOUNDATION_TEST] - %s" % failure_message)
	quit(1)
