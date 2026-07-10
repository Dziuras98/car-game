extends Node

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var target: Node3D = Node3D.new()
	target.name = "Target"
	add_child(target)

	var camera: FollowCamera = FollowCamera.new()
	camera.position_smoothing = 100.0
	add_child(camera)
	camera.set_target_node(target)
	camera.call("_process", 1.0)
	_expect(camera.global_position.z > target.global_position.z, "normal camera mode follows behind the car")
	_expect(camera.is_processing(), "camera processes frames while it has a target")

	Input.action_press("camera-back")
	camera.call("_process", 1.0)
	Input.action_release("camera-back")
	_expect(camera.global_position.z < target.global_position.z, "camera-back moves the camera in front of the car")

	camera.set_target_node(null)
	_expect(not camera.is_processing(), "camera stops processing after its target is cleared")

	camera.queue_free()
	target.queue_free()
	await get_tree().process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[FOLLOW_CAMERA_RUNTIME_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[FOLLOW_CAMERA_RUNTIME_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FOLLOW_CAMERA_RUNTIME_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[FOLLOW_CAMERA_RUNTIME_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[FOLLOW_CAMERA_RUNTIME_TEST] - %s" % failure_message)
	get_tree().quit(1)
