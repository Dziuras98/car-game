extends SceneTree

const VISUAL_SCENE: PackedScene = preload("res://scenes/cars/370z_z34_visuals.tscn")
const FLEET_SIZE: int = 16
const MAX_VISIBLE_FLEET_MESHES: int = 180

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var visuals: Array[CarVisualController] = []
	for index: int in range(FLEET_SIZE):
		var visual: CarVisualController = VISUAL_SCENE.instantiate() as CarVisualController
		_expect(visual != null, "fleet visual %d instantiates" % index)
		if visual == null:
			continue
		visual.position = Vector3(float(index % 4) * 4.0, 0.0, float(index / 4) * 7.0)
		visual.force_low_detail = index > 0
		root.add_child(visual)
		visuals.append(visual)

	await process_frame
	var low_detail_count: int = 0
	var visible_mesh_count: int = 0
	for index: int in range(visuals.size()):
		var visual: CarVisualController = visuals[index]
		if index > 0 and visual.is_using_low_detail():
			low_detail_count += 1
		visible_mesh_count += _count_effectively_visible_meshes(visual, true)

	_expect(low_detail_count == FLEET_SIZE - 1, "all AI fleet members use forced low-detail visuals")
	_expect(visible_mesh_count <= MAX_VISIBLE_FLEET_MESHES, "the 16-car fleet stays inside the visible mesh budget")

	if visuals.size() > 1:
		var ai_visual: CarVisualController = visuals[1]
		var front_wheel := ai_visual.get_node_or_null("LowDetail/WheelFrontLeft") as Node3D
		_expect(front_wheel != null, "low-detail visual exposes an animatable front wheel pivot")
		if front_wheel != null:
			var initial_rotation: Vector3 = front_wheel.rotation
			ai_visual.update_vehicle_visuals(0.1, 20.0, 0.5, 0.34)
			_expect(front_wheel.rotation.distance_to(initial_rotation) > 0.01, "wheel spin and steering update the low-detail pivot")

	for visual: CarVisualController in visuals:
		visual.queue_free()
	await process_frame
	_finish()


func _count_effectively_visible_meshes(node: Node, ancestors_visible: bool) -> int:
	var current_visible: bool = ancestors_visible
	if node is Node3D:
		current_visible = current_visible and (node as Node3D).visible
	var count: int = 1 if current_visible and node is MeshInstance3D else 0
	for child: Node in node.get_children():
		count += _count_effectively_visible_meshes(child, current_visible)
	return count


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_VISUAL_PERFORMANCE_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CAR_VISUAL_PERFORMANCE_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_VISUAL_PERFORMANCE_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CAR_VISUAL_PERFORMANCE_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_VISUAL_PERFORMANCE_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
