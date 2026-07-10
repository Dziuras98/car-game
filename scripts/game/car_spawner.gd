extends RefCounted
class_name CarSpawner

var opponent_lane_spacing: float = 4.2
var opponent_row_spacing: float = 7.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _factory: CarInstanceFactory
var _player_spawner: PlayerCarSpawnController
var _opponent_layout: OpponentSpawnLayout
var _paint_randomizer: OpponentPaintRandomizer
var _opponent_spawner: OpponentParticipantSpawner


func configure(
	owner_node: Node3D,
	car_spawn: Node3D,
	track: Node3D,
	available_car_variants: Array[CarVariantDefinition],
	lane_spacing: float,
	row_spacing: float
) -> void:
	opponent_lane_spacing = lane_spacing
	opponent_row_spacing = row_spacing
	_rng.randomize()

	_factory = CarInstanceFactory.new()
	_factory.configure(available_car_variants, _rng)

	_player_spawner = PlayerCarSpawnController.new()
	_player_spawner.configure(owner_node, _factory)

	_opponent_layout = OpponentSpawnLayout.new()
	_opponent_layout.configure(lane_spacing, row_spacing)

	_paint_randomizer = OpponentPaintRandomizer.new()
	_paint_randomizer.configure(_rng)

	_opponent_spawner = OpponentParticipantSpawner.new()
	_opponent_spawner.configure(
		owner_node,
		car_spawn,
		track,
		_factory,
		_opponent_layout,
		_paint_randomizer,
		_rng
	)


func has_available_cars() -> bool:
	return _factory != null and _factory.has_available_cars()


func get_current_car() -> PlayerCarController:
	if _player_spawner == null:
		return null
	return _player_spawner.get_current_car()


func get_current_car_index() -> int:
	if _player_spawner == null:
		return -1
	return _player_spawner.get_current_car_index()


func get_opponents() -> Array[PlayerCarController]:
	if _opponent_spawner == null:
		var empty_opponents: Array[PlayerCarController] = []
		return empty_opponents
	return _opponent_spawner.get_opponents()


func spawn_player_car(car_index: int, spawn_global_transform: Transform3D, player_input_enabled: bool) -> PlayerCarController:
	if _player_spawner == null:
		return null
	return _player_spawner.spawn_player_car(car_index, spawn_global_transform, player_input_enabled)


func switch_to_next_car(spawn_global_transform: Transform3D, player_input_enabled: bool) -> PlayerCarController:
	if _player_spawner == null:
		return null
	return _player_spawner.switch_to_next_car(spawn_global_transform, player_input_enabled)


func clear_current_car() -> void:
	if _player_spawner == null:
		return
	_player_spawner.clear_current_car()


func spawn_opponents(opponent_count: int) -> Array[PlayerCarController]:
	if _opponent_spawner == null:
		var empty_opponents: Array[PlayerCarController] = []
		return empty_opponents
	return _opponent_spawner.spawn_opponents(opponent_count)


func clear_opponents() -> void:
	if _opponent_spawner == null:
		return
	_opponent_spawner.clear_opponents()


func set_ai_enabled(enabled: bool) -> void:
	if _opponent_spawner == null:
		return
	_opponent_spawner.set_ai_enabled(enabled)
