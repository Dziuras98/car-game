extends RefCounted
class_name CarSpawner

signal driver_fault(message: String)

const MAX_OPPONENT_COUNT: int = 0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _session_seed: int = 0
var _factory: CarInstanceFactory
var _player_spawner: PlayerCarSpawnController
var _car_spawn: Node3D
var _track: GeneratedTrack
var _configured: bool = false


static func validate_configuration_values(
	opponent_count: int,
	lane_spacing: float,
	row_spacing: float,
	random_seed: int
) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if opponent_count != 0:
		errors.append("opponents are not supported in the free-drive build")
	if not is_finite(lane_spacing) or lane_spacing < 0.0:
		errors.append("lane_spacing must be finite and non-negative")
	if not is_finite(row_spacing) or row_spacing < 0.0:
		errors.append("row_spacing must be finite and non-negative")
	if random_seed < -1:
		errors.append("random_seed must be -1 or non-negative")
	return errors


func configure(
	owner_node: Node3D,
	car_spawn: Node3D,
	track: GeneratedTrack,
	available_car_variants: Array[CarVariantDefinition],
	lane_spacing: float = 0.0,
	row_spacing: float = 0.0,
	random_seed: int = -1
) -> bool:
	var configuration_errors: PackedStringArray = validate_configuration_values(
		0,
		lane_spacing,
		row_spacing,
		random_seed
	)
	if not configuration_errors.is_empty():
		push_error("CarSpawner received invalid configuration: %s" % "; ".join(configuration_errors))
		return false
	if not is_instance_valid(owner_node):
		push_error("CarSpawner requires a valid owner node.")
		return false
	if not is_instance_valid(car_spawn):
		push_error("CarSpawner requires a valid player spawn marker.")
		return false
	if not is_instance_valid(track) or not track.has_committed_generation():
		push_error("CarSpawner requires the initialized infinite grid.")
		return false
	if available_car_variants.is_empty():
		push_error("CarSpawner requires at least one configured car variant.")
		return false

	var next_rng := RandomNumberGenerator.new()
	if random_seed >= 0:
		next_rng.seed = random_seed
	else:
		next_rng.randomize()

	var next_factory := CarInstanceFactory.new()
	next_factory.configure(available_car_variants, next_rng)
	if not next_factory.has_available_cars():
		push_error("CarSpawner produced no available player car variants.")
		return false

	var next_player_spawner := PlayerCarSpawnController.new()
	next_player_spawner.configure(owner_node, next_factory)

	clear_current_car()
	_rng = next_rng
	_session_seed = next_rng.seed
	_factory = next_factory
	_player_spawner = next_player_spawner
	_car_spawn = car_spawn
	_track = track
	_configured = true
	return true


func is_configured() -> bool:
	return (
		_configured
		and is_instance_valid(_car_spawn)
		and is_instance_valid(_track)
		and _track.has_committed_generation()
		and _factory != null
		and _factory.has_available_cars()
	)


func has_available_cars() -> bool:
	return is_configured()


func has_ai_eligible_cars() -> bool:
	return false


func get_session_seed() -> int:
	return _session_seed


func get_current_car() -> PlayerCarController:
	return _player_spawner.get_current_car() if _player_spawner != null else null


func get_current_car_index() -> int:
	return _player_spawner.get_current_car_index() if _player_spawner != null else -1


func get_opponents() -> Array[PlayerCarController]:
	var empty: Array[PlayerCarController] = []
	return empty


func get_ai_drivers() -> Array[AiRaceDriver]:
	var empty: Array[AiRaceDriver] = []
	return empty


func validate_opponent_spawn_request(opponent_count: int) -> PackedStringArray:
	return validate_configuration_values(opponent_count, 0.0, 0.0, -1)


func spawn_player_car(
	car_index: int,
	spawn_global_transform: Transform3D,
	player_input_enabled: bool
) -> PlayerCarController:
	if not is_configured() or _player_spawner == null:
		return null
	return _player_spawner.spawn_player_car(car_index, spawn_global_transform, player_input_enabled)


func switch_to_next_car(
	spawn_global_transform: Transform3D,
	player_input_enabled: bool
) -> PlayerCarController:
	if not is_configured() or _player_spawner == null:
		return null
	return _player_spawner.switch_to_next_car(spawn_global_transform, player_input_enabled)


func clear_current_car() -> void:
	if _player_spawner != null:
		_player_spawner.clear_current_car()


func spawn_opponents(opponent_count: int) -> Array[PlayerCarController]:
	if opponent_count > 0:
		push_error("Opponent spawning was removed with race mode.")
	var empty: Array[PlayerCarController] = []
	return empty


func clear_opponents() -> void:
	pass


func set_ai_enabled(_enabled: bool) -> void:
	pass
