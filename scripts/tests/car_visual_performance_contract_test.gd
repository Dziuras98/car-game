extends SceneTree

const STANDARD_PLAYER_VISUAL_SCENE: PackedScene = preload("res://scenes/cars/370z_z34_visuals.tscn")
const NISMO_PLAYER_VISUAL_SCENE: PackedScene = preload("res://scenes/cars/370z_nismo_visuals.tscn")
const STANDARD_AI_VISUAL_SCENE: PackedScene = preload("res://scenes/cars/370z_ai_visuals.tscn")
const NISMO_AI_VISUAL_SCENE: PackedScene = preload("res://scenes/cars/370z_nismo_ai_visuals.tscn")
const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const FLEET_SIZE: int = 16
const MAX_VISIBLE_LOW_DETAIL_FLEET_MESHES: int = FLEET_SIZE * 6
const MAX_VISIBLE_MIXED_FLEET_MESHES: int = 180

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_visual_scene_visibility_lod(STANDARD_PLAYER_VISUAL_SCENE, "standard player")
	await _test_visual_scene_visibility_lod(NISMO_PLAYER_VISUAL_SCENE, "NISMO player")
	await _test_visual_scene_visibility_lod(STANDARD_AI_VISUAL_SCENE, "standard AI")
	await _test_visual_scene_visibility_lod(NISMO_AI_VISUAL_SCENE, "NISMO AI")
	await _test_visibility_lod_fleet_budget()
	await _test_factory_uses_visibility_lod_ai_scenes()
	_finish()


func _test_visual_scene_visibility_lod(scene: PackedScene, scene_label: String) -> void:
	var visual: CarVisualController = scene.instantiate() as CarVisualController
	_expect(visual != null, "%s visual scene instantiates" % scene_label)
	if visual == null:
		return
	root.add_child(visual)
	await process_frame

	var notifier: VisibleOnScreenNotifier3D = visual.get_visibility_notifier()
	_expect(notifier != null, "%s visual creates a screen visibility notifier" % scene_label)
	_expect(
		notifier != null and notifier.aabb == visual.visibility_aabb,
		"%s notifier covers the configured vehicle bounds" % scene_label
	)
	_expect(visual.is_using_low_detail(), "%s visual starts in low detail while off screen" % scene_label)
	_expect(_contains_node_named(visual, &"SketchfabModel"), "%s visual contains the detailed model" % scene_label)

	if notifier != null:
		notifier.emit_signal(&"screen_entered")
		_expect(not visual.is_using_low_detail(), "%s visual becomes detailed when entering the screen" % scene_label)
		_expect_visual_root_visibility(visual, true, scene_label)

		visual.set_force_low_detail(true)
		notifier.emit_signal(&"screen_entered")
		_expect(visual.is_using_low_detail(), "%s forced low detail overrides screen visibility" % scene_label)

		visual.set_force_low_detail(false)
		notifier.emit_signal(&"screen_entered")
		_expect(not visual.is_using_low_detail(), "%s visibility LOD resumes after force is disabled" % scene_label)

		notifier.emit_signal(&"screen_exited")
		_expect(visual.is_using_low_detail(), "%s visual returns to low detail after leaving the screen" % scene_label)
		_expect_visual_root_visibility(visual, false, scene_label)

	visual.queue_free()
	await process_frame


func _test_visibility_lod_fleet_budget() -> void:
	var visuals: Array[CarVisualController] = []
	for index: int in range(FLEET_SIZE):
		var visual: CarVisualController = STANDARD_PLAYER_VISUAL_SCENE.instantiate() as CarVisualController
		_expect(visual != null, "fleet visual %d instantiates" % index)
		if visual == null:
			continue
		visual.position = Vector3(float(index % 4) * 4.0, 0.0, float(index / 4) * 7.0)
		root.add_child(visual)
		visuals.append(visual)

	await process_frame
	var low_detail_count: int = 0
	var low_detail_visible_mesh_count: int = 0
	for visual: CarVisualController in visuals:
		var notifier: VisibleOnScreenNotifier3D = visual.get_visibility_notifier()
		if notifier != null:
			notifier.emit_signal(&"screen_exited")
		if visual.is_using_low_detail():
			low_detail_count += 1
		low_detail_visible_mesh_count += _count_effectively_visible_meshes(visual, true)

	_expect(low_detail_count == FLEET_SIZE, "the complete off-screen fleet uses low-detail rendering")
	_expect(
		low_detail_visible_mesh_count <= MAX_VISIBLE_LOW_DETAIL_FLEET_MESHES,
		"the off-screen fleet stays inside the visible low-detail mesh budget"
	)

	if not visuals.is_empty():
		var visible_visual: CarVisualController = visuals[0]
		var visible_notifier: VisibleOnScreenNotifier3D = visible_visual.get_visibility_notifier()
		if visible_notifier != null:
			visible_notifier.emit_signal(&"screen_entered")
		_expect(not visible_visual.is_using_low_detail(), "an on-screen fleet car uses the detailed model")
		var mixed_visible_mesh_count: int = 0
		for visual: CarVisualController in visuals:
			mixed_visible_mesh_count += _count_effectively_visible_meshes(visual, true)
		_expect(
			mixed_visible_mesh_count <= MAX_VISIBLE_MIXED_FLEET_MESHES,
			"one visible detailed car and fifteen off-screen cars stay inside the mixed mesh budget"
		)

	if visuals.size() > 1:
		var low_detail_visual: CarVisualController = visuals[1]
		var front_wheel := low_detail_visual.get_node_or_null("LowDetail/WheelFrontLeft") as Node3D
		_expect(front_wheel != null, "low-detail visual exposes an animatable front wheel pivot")
		if front_wheel != null:
			var initial_rotation: Vector3 = front_wheel.rotation
			low_detail_visual.update_vehicle_visuals(0.1, 20.0, 0.5, 0.34)
			_expect(front_wheel.rotation.distance_to(initial_rotation) > 0.01, "visible low-detail wheel pivot remains animated")

	for visual: CarVisualController in visuals:
		visual.queue_free()
	await process_frame


func _test_factory_uses_visibility_lod_ai_scenes() -> void:
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
		car.position = Vector3(float(index % 4) * 4.0, 0.0, float(index / 4) * 7.0)
		root.add_child(car)
		car.set_physics_process(false)
		cars.append(car)

	await process_frame
	var off_screen_visible_mesh_count: int = 0
	for car: PlayerCarController in cars:
		var visual: CarVisualController = car.get_node_or_null("VisualRoot") as CarVisualController
		_expect(visual != null, "factory AI car exposes the visual controller")
		if visual == null:
			continue
		var notifier: VisibleOnScreenNotifier3D = visual.get_visibility_notifier()
		_expect(notifier != null, "factory AI car exposes the visibility notifier")
		_expect(not visual.force_low_detail, "factory AI car leaves visibility-based LOD enabled")
		_expect(_contains_node_named(car, &"SketchfabModel"), "factory AI car contains the detailed model")
		if notifier != null:
			notifier.emit_signal(&"screen_exited")
		_expect(visual.is_using_low_detail(), "off-screen factory AI car uses low-detail rendering")
		off_screen_visible_mesh_count += _count_effectively_visible_meshes(car, true)

	_expect(cars.size() == FLEET_SIZE, "the complete AI fleet is instantiated")
	_expect(
		off_screen_visible_mesh_count <= MAX_VISIBLE_LOW_DETAIL_FLEET_MESHES,
		"the off-screen AI fleet stays inside the visible low-detail mesh budget"
	)

	if not cars.is_empty():
		var visible_car: PlayerCarController = cars[0]
		var visible_visual: CarVisualController = visible_car.get_node_or_null("VisualRoot") as CarVisualController
		var visible_notifier: VisibleOnScreenNotifier3D = (
			visible_visual.get_visibility_notifier() if visible_visual != null else null
		)
		if visible_notifier != null:
			visible_notifier.emit_signal(&"screen_entered")
		_expect(visible_visual != null and not visible_visual.is_using_low_detail(), "visible AI car switches to the detailed model")
		if visible_visual != null:
			_expect_visual_root_visibility(visible_visual, true, "visible AI car")
		if visible_notifier != null:
			visible_notifier.emit_signal(&"screen_exited")
		_expect(visible_visual != null and visible_visual.is_using_low_detail(), "AI car returns to low detail after leaving the screen")

	for car: PlayerCarController in cars:
		car.queue_free()
	await process_frame


func _expect_visual_root_visibility(visual: CarVisualController, detailed_visible: bool, context: String) -> void:
	var detailed_root: Node3D = visual.get_node_or_null("SketchfabModel") as Node3D
	var low_detail_root: Node3D = visual.get_node_or_null("LowDetail") as Node3D
	_expect(
		detailed_root != null and detailed_root.visible == detailed_visible,
		"%s detailed root visibility matches the screen state" % context
	)
	_expect(
		low_detail_root != null and low_detail_root.visible != detailed_visible,
		"%s low-detail root visibility opposes the screen state" % context
	)


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
