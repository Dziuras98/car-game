extends RefCounted
class_name CarSpawner

const AI_DRIVER_SCRIPT: Script = preload("res://scripts/race/ai_race_driver.gd")

var opponent_lane_spacing: float = 4.2
var opponent_row_spacing: float = 7.0

var _owner: Node3D
var _car_spawn: Node3D
var _track: Node3D
var _available_cars: Array[PackedScene] = []
var _available_variants: Array[CarVariantDefinition] = []
var _current_car_index: int = -1
var _current_car: PlayerCarController
var _opponents: Array[PlayerCarController] = []
var _ai_drivers: Array[Node] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func configure(
	owner_node: Node3D,
	car_spawn: Node3D,
	track: Node3D,
	available_car_scenes: Array[PackedScene],
	available_car_variants: Array[CarVariantDefinition],
	lane_spacing: float,
	row_spacing: float
) -> void:
	_owner = owner_node
	_car_spawn = car_spawn
	_track = track
	_available_cars = available_car_scenes
	_available_variants = available_car_variants
	opponent_lane_spacing = lane_spacing
	opponent_row_spacing = row_spacing
	_rng.randomize()


func has_available_cars() -> bool:
	return _get_available_count() > 0


func get_current_car() -> PlayerCarController:
	return _current_car


func get_opponents() -> Array[PlayerCarController]:
	return _opponents


func spawn_player_car(car_index: int, spawn_transform: Transform3D, player_input_enabled: bool) -> PlayerCarController:
	if _owner == null or not has_available_cars():
		return null

	var selected_car_index: int = clampi(car_index, 0, _get_available_count() - 1)
	var car_controller: PlayerCarController = _instantiate_indexed_car(selected_car_index)
	if car_controller == null:
		return null

	clear_current_car()
	car_controller.transform = spawn_transform
	_owner.add_child(car_controller)
	car_controller.set_player_input_enabled(player_input_enabled)

	_current_car = car_controller
	_current_car_index = selected_car_index
	return _current_car


func switch_to_next_car(spawn_transform: Transform3D, player_input_enabled: bool) -> PlayerCarController:
	if not has_available_cars():
		return null

	var next_index: int = (_current_car_index + 1) % _get_available_count()
	return spawn_player_car(next_index, spawn_transform, player_input_enabled)


func clear_current_car() -> void:
	if is_instance_valid(_current_car):
		var parent: Node = _current_car.get_parent()
		if parent != null:
			parent.remove_child(_current_car)
		_current_car.queue_free()

	_current_car = null
	_current_car_index = -1


func spawn_opponents(opponent_count: int) -> Array[PlayerCarController]:
	clear_opponents()
	if _owner == null or _car_spawn == null or not has_available_cars():
		return _opponents

	for opponent_index: int in opponent_count:
		var car_controller: PlayerCarController = _instantiate_opponent_car()
		if car_controller == null:
			continue

		car_controller.name = "Opponent%d" % (opponent_index + 1)
		car_controller.transform = _get_opponent_spawn_transform(opponent_index)
		car_controller.set_player_input_enabled(false)
		car_controller.set_external_input_enabled(true)
		_randomize_car_paint(car_controller)
		_owner.add_child(car_controller)
		_opponents.append(car_controller)

		var ai_driver: Node = AI_DRIVER_SCRIPT.new()
		ai_driver.name = "%sDriver" % car_controller.name
		ai_driver.set("car_path", car_controller.get_path())
		if _track != null:
			ai_driver.set("track_path", _track.get_path())
		ai_driver.set("lane_offset", _get_opponent_lane_offset(opponent_index))
		ai_driver.set("target_speed_kmh", _rng.randf_range(96.0, 128.0))
		ai_driver.set("corner_speed_kmh", _rng.randf_range(66.0, 84.0))
		_owner.add_child(ai_driver)
		_ai_drivers.append(ai_driver)

	return _opponents


func clear_opponents() -> void:
	for ai_driver: Node in _ai_drivers:
		if is_instance_valid(ai_driver):
			ai_driver.queue_free()
	_ai_drivers.clear()

	for opponent: PlayerCarController in _opponents:
		if is_instance_valid(opponent):
			opponent.queue_free()
	_opponents.clear()


func set_ai_enabled(enabled: bool) -> void:
	for ai_driver: Node in _ai_drivers:
		if is_instance_valid(ai_driver) and ai_driver.has_method("set_driver_enabled"):
			ai_driver.call("set_driver_enabled", enabled)


func _get_available_count() -> int:
	if not _available_variants.is_empty():
		return _available_variants.size()
	return _available_cars.size()


func _instantiate_indexed_car(car_index: int) -> PlayerCarController:
	if not _available_variants.is_empty():
		return _instantiate_variant(_available_variants[car_index])

	return _instantiate_car(_available_cars[car_index])


func _instantiate_opponent_car() -> PlayerCarController:
	if not _available_variants.is_empty():
		return _instantiate_variant(_get_opponent_variant())

	if _available_cars.is_empty():
		return null

	var car_controller: PlayerCarController = _instantiate_car(_available_cars[_rng.randi_range(0, _available_cars.size() - 1)])
	if car_controller != null:
		car_controller.manual_transmission_enabled = false
		car_controller.automatic_transmission_enabled = true
	return car_controller


func _get_opponent_variant() -> CarVariantDefinition:
	var automatic_variants: Array[CarVariantDefinition] = []
	for variant: CarVariantDefinition in _available_variants:
		if variant == null:
			continue
		var specs: CarSpecs = variant.get_specs()
		if specs == null or specs.automatic_transmission_enabled:
			automatic_variants.append(variant)

	if not automatic_variants.is_empty():
		return automatic_variants[_rng.randi_range(0, automatic_variants.size() - 1)]

	return _available_variants[_rng.randi_range(0, _available_variants.size() - 1)]


func _instantiate_variant(variant: CarVariantDefinition) -> PlayerCarController:
	if variant == null:
		return null

	var car_controller: PlayerCarController = _instantiate_car(variant.get_car_scene())
	if car_controller == null:
		return null

	if variant.get_specs() != null:
		car_controller.car_specs = variant.get_specs()
	return car_controller


func _instantiate_car(car_scene: PackedScene) -> PlayerCarController:
	if car_scene == null:
		return null

	var car_instance: Node = car_scene.instantiate()
	var car_controller: PlayerCarController = car_instance as PlayerCarController

	if car_controller == null:
		push_error("Car scene must have PlayerCarController on its root node.")
		car_instance.queue_free()
		return null

	return car_controller


func _get_opponent_spawn_transform(opponent_index: int) -> Transform3D:
	var spawn_transform: Transform3D = _car_spawn.global_transform
	var row: int = floori(float(opponent_index) / 2.0) + 1
	var side_multiplier: float = -1.0 if opponent_index % 2 == 0 else 1.0
	var lane_offset: float = side_multiplier * opponent_lane_spacing * (0.5 + float(opponent_index % 2))
	spawn_transform.origin += spawn_transform.basis.x.normalized() * lane_offset
	spawn_transform.origin += spawn_transform.basis.z.normalized() * opponent_row_spacing * float(row)
	return spawn_transform


func _get_opponent_lane_offset(opponent_index: int) -> float:
	var side_multiplier: float = -1.0 if opponent_index % 2 == 0 else 1.0
	return side_multiplier * opponent_lane_spacing * 0.45


func _randomize_car_paint(root: Node) -> void:
	var paint_color: Color = Color.from_hsv(_rng.randf(), 0.72, 0.82, 1.0)
	_apply_paint_to_children(root, paint_color)


func _apply_paint_to_children(node: Node, paint_color: Color) -> void:
	var mesh_instance: MeshInstance3D = node as MeshInstance3D
	if mesh_instance != null and node.name.to_lower().contains("paint"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = paint_color
		material.roughness = 0.42
		mesh_instance.material_override = material

	for child: Node in node.get_children():
		_apply_paint_to_children(child, paint_color)
