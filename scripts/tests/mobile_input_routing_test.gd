extends Node

const MOBILE_CONTROLS_SCENE: PackedScene = preload("res://scenes/ui/mobile_drive_controls.tscn")
const MANUAL_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []
var _rear_view_events: Array[bool] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var car: PlayerCarController = PlayerCarController.new()
	car.name = "TouchCar"
	car.car_specs = MANUAL_SPECS
	add_child(car)
	await get_tree().process_frame
	car.set_physics_process(false)

	var controls: MobileDriveControls = MOBILE_CONTROLS_SCENE.instantiate() as MobileDriveControls
	controls.force_visible = true
	controls.show_on_android = false
	controls.rear_view_changed.connect(_on_rear_view_changed)
	add_child(controls)
	controls.set_target_node(car)
	await get_tree().process_frame

	var accelerate: Button = controls.get_node("Root/Accelerate") as Button
	var gear_up: Button = controls.get_node("Root/GearUp") as Button
	var reset: Button = controls.get_node("Root/Reset") as Button
	var camera_back: Button = controls.get_node("Root/CameraBack") as Button

	accelerate.button_down.emit()
	car.call("_physics_process", 0.016)
	_expect(car.get_throttle_input() > 0.99, "touch throttle reaches the active car without global input injection")

	Input.action_press("accelerate")
	accelerate.button_up.emit()
	car.call("_physics_process", 0.016)
	_expect(car.get_throttle_input() > 0.99, "releasing touch throttle does not release a keyboard-held action")
	Input.action_release("accelerate")
	car.call("_physics_process", 0.016)
	_expect(car.get_throttle_input() < 0.01, "throttle clears after both independent sources are released")

	var initial_gear: int = car.get_current_gear_for_test()
	gear_up.button_down.emit()
	car.call("_physics_process", 0.016)
	_expect(car.get_current_gear_for_test() == initial_gear + 1, "touch gear request is consumed once by the manual transmission")
	car.call("_physics_process", 0.016)
	_expect(car.get_current_gear_for_test() == initial_gear + 1, "touch gear request does not repeat on later physics frames")

	car.global_position = Vector3(12.0, 3.0, -7.0)
	reset.button_down.emit()
	car.call("_physics_process", 0.016)
	_expect(car.global_position.distance_to(Vector3.ZERO) < 0.01, "touch reset uses the same reset controller as keyboard input")

	camera_back.button_down.emit()
	camera_back.button_up.emit()
	_expect(_rear_view_events == [true, false], "camera-back hold emits explicit press and release states")

	accelerate.button_down.emit()
	controls.set_target_node(null)
	car.call("_physics_process", 0.016)
	_expect(car.get_throttle_input() < 0.01, "detaching mobile controls clears held input on the old car")

	var source_text: String = FileAccess.get_file_as_string("res://scripts/ui/mobile_drive_controls.gd")
	_expect("Input.action_press" not in source_text, "mobile overlay cannot inject global pressed actions")
	_expect("Input.action_release" not in source_text, "mobile overlay cannot release actions owned by another device")

	controls.queue_free()
	car.queue_free()
	await get_tree().process_frame
	_finish()


func _on_rear_view_changed(active: bool) -> void:
	_rear_view_events.append(active)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[MOBILE_INPUT_ROUTING_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[MOBILE_INPUT_ROUTING_TEST][FAIL] %s" % message)


func _finish() -> void:
	Input.action_release("accelerate")
	if _failures.is_empty():
		print("[MOBILE_INPUT_ROUTING_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[MOBILE_INPUT_ROUTING_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[MOBILE_INPUT_ROUTING_TEST] - %s" % failure_message)
	get_tree().quit(1)
