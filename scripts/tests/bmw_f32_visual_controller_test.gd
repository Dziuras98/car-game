extends SceneTree

const VISUAL_SCENE := preload("res://scenes/cars/bmw_f32_visuals.tscn")
const PROCESSED_MODEL_ROOT := ^"SketchfabModel/ProcessedModel/Bmw4SeriesF32Processed"
const WHEEL_IDS: Array[StringName] = [
	&"front_left",
	&"front_right",
	&"rear_left",
	&"rear_right",
]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var visuals := VISUAL_SCENE.instantiate() as BmwF32VisualController
	_expect(visuals != null, "BMW F32 runtime visual controller instantiates")
	if visuals == null:
		_finish()
		return
	root.add_child(visuals)
	await process_frame

	_expect(visuals.get_detailed_wheel_binding_count() == 4, "BMW F32 registers four detailed wheel bindings")
	_expect(visuals.get_low_detail_wheel_binding_count() == 4, "BMW F32 registers four low-detail wheel bindings")
	_expect(visuals.get_registered_wheel_count() == 4, "BMW F32 exposes four wheel visuals")
	_expect(visuals.is_using_low_detail(), "BMW F32 starts in fleet-safe low detail while off screen")
	_validate_spec_contract(visuals)

	var processed_root := visuals.get_node_or_null(PROCESSED_MODEL_ROOT) as Node3D
	_expect(processed_root != null, "BMW F32 resolves the processed model root")
	if processed_root != null:
		_expect(processed_root.get_node_or_null(^"Body") is MeshInstance3D, "BMW F32 keeps the processed body mesh")
	_expect(visuals.get_node_or_null(^"LowDetail/WheelFrontLeft") is Node3D, "BMW F32 exposes the standard low-detail wheel hierarchy")

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
			_validate_bound_wheel(spin, wheel_id)

	_expect(_all_distinct(steering_pivots), "all BMW F32 steering pivots are distinct")
	_expect(_all_distinct(spin_pivots), "all BMW F32 spin pivots are distinct")
	if steering_pivots.size() == 4:
		_validate_positions(visuals)

	var notifier := visuals.get_visibility_notifier()
	_expect(notifier != null, "BMW F32 runtime visual controller exposes a visibility notifier")
	if notifier != null:
		notifier.emit_signal(&"screen_entered")
	_expect(not visuals.is_using_low_detail(), "BMW F32 switches to processed detail on screen")
	var wheel_positions := PackedFloat32Array([0.1, 0.2, 0.3, 0.4])
	visuals.update_vehicle_wheel_visuals(wheel_positions, 0.5)
	_validate_independent_wheel_rotation(visuals, wheel_positions)
	if notifier != null:
		notifier.emit_signal(&"screen_exited")
	_expect(visuals.is_using_low_detail(), "BMW F32 returns to low detail off screen")

	visuals.queue_free()
	await process_frame
	_finish()


func _validate_spec_contract(visuals: BmwF32VisualController) -> void:
	var specs: Array[Dictionary] = visuals._get_explicit_detailed_wheel_specs()
	_expect(specs.size() == 4, "BMW F32 exposes four explicit wheel specs")
	for spec: Dictionary in specs:
		var wheel_id: StringName = spec.get("wheel_id", &"")
		_expect(spec.get("pivot_parent_path", NodePath()) == PROCESSED_MODEL_ROOT, "%s pivots below the processed model root" % wheel_id)
		var spin_paths: Array = spec.get("spin_node_paths", [])
		_expect(spin_paths.size() == 1, "%s has exactly one processed spin mesh path" % wheel_id)
		if bool(spec.get("steers", false)):
			_expect(is_equal_approx(float(spec.get("steering_direction", 0.0)), -1.0), "%s uses the project -Z steering sign" % wheel_id)


func _validate_bound_wheel(spin_pivot: Node3D, wheel_id: StringName) -> void:
	var expected_name := _expected_wheel_node_name(wheel_id)
	_expect(spin_pivot.get_child_count() == 1, "%s spin pivot owns exactly one wheel mesh" % wheel_id)
	var wheel: MeshInstance3D = null
	if spin_pivot.get_child_count() == 1:
		wheel = spin_pivot.get_child(0) as MeshInstance3D
	_expect(wheel != null, "%s spin pivot owns a MeshInstance3D" % wheel_id)
	if wheel == null:
		return
	_expect(String(wheel.name) == expected_name, "%s binds the processed %s node" % [wheel_id, expected_name])
	_expect(wheel.position.length() < 0.0001, "%s processed mesh is hub-centred under its spin pivot" % wheel_id)


func _expected_wheel_node_name(wheel_id: StringName) -> String:
	match wheel_id:
		&"front_left": return "FrontLeftWheel"
		&"front_right": return "FrontRightWheel"
		&"rear_left": return "RearLeftWheel"
		&"rear_right": return "RearRightWheel"
	return ""


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


func _validate_independent_wheel_rotation(
	visuals: BmwF32VisualController,
	wheel_positions: PackedFloat32Array
) -> void:
	for wheel_index: int in range(WHEEL_IDS.size()):
		var spin := visuals.get_detailed_wheel_spin_pivot(WHEEL_IDS[wheel_index])
		_expect(spin != null, "%s spin pivot remains available after update" % WHEEL_IDS[wheel_index])
		if spin != null:
			_expect(
				absf(spin.rotation.x - wheel_positions[wheel_index]) < 0.0001,
				"%s receives its independent physics-v3 angular position" % WHEEL_IDS[wheel_index]
			)


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
