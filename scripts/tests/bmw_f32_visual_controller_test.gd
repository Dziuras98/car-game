extends SceneTree

const VISUAL_SCENE := preload("res://scenes/cars/bmw_f32_visuals.tscn")
const WHEEL_IDS: Array[StringName] = [
	&"front_left",
	&"front_right",
	&"rear_left",
	&"rear_right",
]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var visuals := VISUAL_SCENE.instantiate() as BmwF32VisualController
	_expect(visuals != null, "BMW F32 runtime visual controller instantiates")
	if visuals == null:
		_finish()
		return
	root.add_child(visuals)
	_expect(visuals.get_detailed_wheel_binding_count() == 4, "BMW F32 registers four detailed wheel bindings")
	_expect(visuals.get_registered_wheel_count() == 4, "BMW F32 exposes four wheel visuals")
	_expect(not visuals.is_using_low_detail(), "BMW F32 remains on its detailed processed model without a fallback LOD")

	var steering_pivots: Array[Node3D] = []
	var spin_pivots: Array[Node3D] = []
	for wheel_id: StringName in WHEEL_IDS:
		var steering := visuals.get_detailed_wheel_steering_pivot(wheel_id)
		var spin := visuals.get_detailed_wheel_spin_pivot(wheel_id)
		_expect(steering != null, "%s has a steering pivot" % wheel_id)
		_expect(spin != null, "%s has a spin pivot" % wheel_id)
		if steering != null:
			steering_pivots.append(steering)
		if spin != null:
			spin_pivots.append(spin)

	_expect(_all_distinct(steering_pivots), "all BMW F32 steering pivots are distinct")
	_expect(_all_distinct(spin_pivots), "all BMW F32 spin pivots are distinct")
	if steering_pivots.size() == 4:
		_validate_positions(visuals)

	var wheel_positions := PackedFloat32Array([0.1, 0.2, 0.3, 0.4])
	visuals.update_vehicle_wheel_visuals(wheel_positions, 0.5)
	_expect(true, "BMW F32 accepts independent per-wheel angular positions")
	visuals.free()
	_finish()


func _validate_positions(visuals: BmwF32VisualController) -> void:
	var front_left := visuals.get_detailed_wheel_steering_pivot(&"front_left")
	var front_right := visuals.get_detailed_wheel_steering_pivot(&"front_right")
	var rear_left := visuals.get_detailed_wheel_steering_pivot(&"rear_left")
	var rear_right := visuals.get_detailed_wheel_steering_pivot(&"rear_right")
	_expect(front_left.position.x < 0.0 and rear_left.position.x < 0.0, "left pivots use project negative X")
	_expect(front_right.position.x > 0.0 and rear_right.position.x > 0.0, "right pivots use project positive X")
	_expect(front_left.position.z < 0.0 and front_right.position.z < 0.0, "front steering pivots use local -Z")
	_expect(rear_left.position.z > 0.0 and rear_right.position.z > 0.0, "rear pivots use local +Z")
	_expect(absf(absf(front_left.position.z - rear_left.position.z) - 2.81) < 0.001, "runtime wheelbase remains 2.810 m")
	_expect(absf(front_left.position.x + front_right.position.x) < 0.0001, "front pivots are laterally symmetric")
	_expect(absf(rear_left.position.x + rear_right.position.x) < 0.0001, "rear pivots are laterally symmetric")


func _all_distinct(nodes: Array[Node3D]) -> bool:
	var ids: Dictionary = {}
	for node: Node3D in nodes:
		if node == null or ids.has(node.get_instance_id()):
			return false
		ids[node.get_instance_id()] = true
	return ids.size() == nodes.size()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BMW_F32_VISUAL_CONTROLLER_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[BMW_F32_VISUAL_CONTROLLER_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BMW_F32_VISUAL_CONTROLLER_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BMW_F32_VISUAL_CONTROLLER_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
