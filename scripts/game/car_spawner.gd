extends RefCounted
class_name CarSpawner

signal driver_fault(message: String)

var opponent_lane_spacing: float = 4.2
var opponent_row_spacing: float = 7.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _session_seed: int = 0
var _factory: CarInstanceFactory
var _player_spawner: PlayerCarSpawnController
var _opponent_layout: OpponentSpawnLayout
var _paint_randomizer: OpponentPaintRandomizer
var _opponent_spawner: OpponentParticipantSpawner
var _configured: bool = false


func configure(
	owner_node: Node3D,
	car_spawn: Node3D,
	track: GeneratedTrack,
	available_car_variants: Array[CarVariantDefinition],
	lane_spacing: float,
	row_spacing: float,
	random_seed: int = -1
) -> bool:
	_configured = false
	if not is_instance_valid(owner_node):
		push_error("CarSpawner requires a valid owner node.")
		return false
	if not is_instance_valid(car_spawn):
		push_error("CarSpawner requires a valid player spawn marker.")
		return false
	if not is_instance_valid(track) or not track.has_committed_generation():
		push_error("CarSpawner requires a committed generated track.")
		return false
	if available_car_variants.is_empty():
		push_error("CarSpawner requires at least one configured car variant.")
		return false
	if not is_finite(lane_spacing) or lane_spacing < 0.0:
		push_error("CarSpawner lane spacing must be finite and non-negative.")
		return false
	if not is_finite(row_spacing) or row_spacing < 0.0:
		push_error("CarSpawner row spacing must be finite and non-negative.")
		return false

	opponent_lane_spacing = lane_spacing
	opponent_row_spacing = row_spacing
	if random_seed >= 0:
		_rng.seed = random_seed
	else:
		_rng.randomize()
	_session_seed = _rng.seed

	_factory = CarInstanceFactory.new()
	_factory.configure(available_car_variants, _rng)
	if not _factory.has_available_cars():
		push_error("CarSpawner produced no available player car variants.")
		return false

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
		_session_seed
	)
	_opponent_spawner.driver_fault.connect(_on_driver_fault)
	_configured = true
	return true


func is_configured() -> bool:
	return _configured


func has_available_cars() -> bool:
	return _configured and _factory != null and _factory.has_available_cars()


func has_ai_eligible_cars() -> bool:
	return _configured and _factory != null and _factory.has_ai_eligible_cars()


func get_session_seed() -> int:
	return _session_seed


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


func get_ai_drivers() -> Array[AiRaceDriver]:
	if _opponent_spawner == null:
		var empty_drivers: Array[AiRaceDriver] = []
		return empty_drivers
	return _opponent_spawner.get_ai_drivers()


func spawn_player_car(car_index: int, spawn_global_transform: Transform3D, player_input_enabled: bool) -> PlayerCarController:
	if not _configured or _player_spawner == null:
		return null
	return _player_spawner.spawn_player_car(car_index, spawn_global_transform, player_input_enabled)


func switch_to_next_car(spawn_global_transform: Transform3D, player_input_enabled: bool) -> PlayerCarController:
	if not _configured or _player_spawner == null:
		return null
	return _player_spawner.switch_to_next_car(spawn_global_transform, player_input_enabled)


func clear_current_car() -> void:
	if _player_spawner == null:
		return
	_player_spawner.clear_current_car()


func spawn_opponents(opponent_count: int) -> Array[PlayerCarController]:
	if not _configured or _opponent_spawner == null:
		var empty_opponents: Array[PlayerCarController] = []
		return empty_opponents
	if opponent_count > 0 and not has_ai_eligible_cars():
		push_error("CarSpawner cannot create opponents without an explicit AI-eligible variant.")
		var no_opponents: Array[PlayerCarController] = []
		return no_opponents
	return _opponent_spawner.spawn_opponents(opponent_count)


func clear_opponents() -> void:
	if _opponent_spawner == null:
		return
	_opponent_spawner.clear_opponents()


func set_ai_enabled(enabled: bool) -> void:
	if _opponent_spawner == null:
		return
	_opponent_spawner.set_ai_enabled(enabled)


func _on_driver_fault(message: String) -> void:
	driver_fault.emit(message)
