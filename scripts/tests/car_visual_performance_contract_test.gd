extends SceneTree

const VISUAL_SCENE: PackedScene = preload("res://scenes/cars/370z_z34_visuals.tscn")
const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const FLEET_SIZE: int = 16
const MAX_VISIBLE_FLEET_MESHES: int = 180
const MAX_VISIBLE_LOW_DETAIL_AI_MESHES: int = FLEET_SIZE * 6
const AI_DETAIL_SWITCH_DISTANCE: float = 30.0
const AI_DETAIL_SWITCH_HYSTERESIS: float = 6.0
const AI_NEAR_DISTANCE: float = 10.0
const AI_FAR_DISTANCE: float = 80.0

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_visual_lod_switching()
	await _test_factory_uses_distance_lod_ai_scenes()
	_finish()


func _test_visual_lod_switching() -> void:
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

	_expect(low_detail_count == FLEET_SIZE - 1, "all forced visual wrappers use low-detail rendering")
	_expect(visible_mesh_count <= MAX_VISIBLE_FLEET_MESHES, "the 16-car visual fleet stays inside the visible mesh budget")

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


func _test_factory_uses_distance_lod_ai_scenes() -> void:
	var camera: Camera3D = Camera3D.new()
	root.add_child(camera)
	camera.current = true

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260712
	var factory: CarInstanceFactory = CarInstanceFactory.new()
	factory.configure(CATALOG.get_all_variants(), rng)
	_expect(factory.has_ai_eligible_cars(), "catalog exposes dedicated AI scenes")

	var cars: Array[PlayerCarController] = []
	for index: int in range(FLEET_SIZE):
		var car: PlayerCarController = factory.instantiate_opponent_car()
		_expect(car != null, "factory AI car %d instantiates" % index)
		if car == null:
			continue
		car.position = Vector3(
			float(index % 4) * 4.0,
			0.0,
			AI_FAR_DISTANCE + float(index / 4) * 7.0
		)
		root.add_child(car)
		car.set_physics_process(false)
		cars.append(car)

	await process_frame
	await process_frame
	var far_visible_mesh_count: int = 0
	for car: PlayerCarController in cars:
		var visual: CarVisualController = car.get_node_or_null("VisualRoot") as CarVisualController
		_expect(visual != null, "factory AI car exposes the visual controller")
		if visual == null:
			continue
		_expect(not visual.force_low_detail, "factory AI car leaves distance-based LOD enabled")
		_expect(
			absf(visual.detail_switch_distance - AI_DETAIL_SWITCH_DISTANCE) < 0.001,
			"factory AI car uses the close-range detail distance"
		)
		_expect(
			absf(visual.detail_switch_hysteresis - AI_DETAIL_SWITCH_HYSTERESIS) < 0.001,
			"factory AI car uses the close-range LOD hysteresis"
		)
		_expect(_contains_node_named(car, &"SketchfabModel"), "factory AI car contains the detailed model")
		_expect(visual.is_using_low_detail(), "far factory AI car uses low-detail rendering")
		far_visible_mesh_count += _count_effectively_visible_meshes(car, true)

	_expect(cars.size() == FLEET_SIZE, "the complete AI fleet is instantiated")
	_expect(
		far_visible_mesh_count <= MAX_VISIBLE_LOW_DETAIL_AI_MESHES,
		"the far AI fleet stays inside the visible low-detail mesh budget"
	)

	if not cars.is_empty():
		var near_car: PlayerCarController = cars[0]
		near_car.position = Vector3(0.0, 0.0, AI_NEAR_DISTANCE)
		await process_frame
		await process_frame
		var near_visual: CarVisualController = near_car.get_node_or_null("VisualRoot") as CarVisualController
		_expect(near_visual != null and not near_visual.is_using_low_detail(), "near AI car switches to the detailed model")
		if near_visual != null:
			var detailed_root: Node3D = near_visual.get_node_or_null("SketchfabModel") as Node3D
			var low_detail_root: Node3D = near_visual.get_node_or_null("LowDetail") as Node3D
			_expect(detailed_root != null and detailed_root.visible, "near AI detailed model is visible")
			_expect(low_detail_root != null and not low_detail_root.visible, "near AI low-detail model is hidden")

		near_car.position = Vector3(0.0, 0.0, AI_FAR_DISTANCE)
		await process_frame
		await process_frame
		_expect(near_visual != null and near_visual.is_using_low_detail(), "AI car returns to low detail after moving away")

	for car: PlayerCarController in cars:
		car.queue_free()
	camera.queue_free()
	await process_frame


func _count_effectively_visible_meshes(node: Node, ancestors_visible: bool) -> int:
	var current_visible: bool = ancestors_visible
	if node is Node3D:
		current_visible = current_visible and (node as Node3D).visible
	var count: int = 1 if current_visible and node is MeshInstance3D else 0
	for child: Node in node.get_children():
		count += _count_effectively_visible_meshes(child, current_visible)
	return count


func _contains_node_named(node: Node, target_name: StringName) -> bool:
	if node.name == target_name:
		return true
	for child: Node in node.get_children():
		if _contains_node_named(child, target_name):
			return true
	return false


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
