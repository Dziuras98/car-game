extends RefCounted
class_name CarSpawner

signal driver_fault(message: String)

const MAX_OPPONENT_COUNT: int = 15
const MIN_LATERAL_SPAWN_SEPARATION: float = 2.2
const MIN_LONGITUDINAL_SPAWN_SEPARATION: float = 4.8
const MIN_TRACK_EDGE_CLEARANCE: float = MIN_LATERAL_SPAWN_SEPARATION * 0.5

var opponent_lane_spacing: float = 4.2
var opponent_row_spacing: float = 7.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _session_seed: int = 0
var _factory: CarInstanceFactory
var _player_spawner: PlayerCarSpawnController
var _opponent_layout: OpponentSpawnLayout
var _paint_randomizer: OpponentPaintRandomizer
var _opponent_spawner: OpponentParticipantSpawner
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
	if opponent_count < 0:
		errors.append("opponent_count must be non-negative")
	elif opponent_count > MAX_OPPONENT_COUNT:
		errors.append("opponent_count must not exceed %d" % MAX_OPPONENT_COUNT)
	if not is_finite(lane_spacing) or lane_spacing < 0.0:
		errors.append("lane_spacing must be finite and non-negative")
	if not is_finite(row_spacing) or row_spacing < 0.0:
		errors.append("row_spacing must be finite and non-negative")
	if opponent_count > 1:
		if not is_finite(lane_spacing) or lane_spacing <= 0.0:
			errors.append("lane_spacing must be positive for a multi-opponent grid")
		if not is_finite(row_spacing) or row_spacing <= 0.0:
			errors.append("row_spacing must be positive for a multi-opponent grid")
	if random_seed < -1:
		errors.append("random_seed must be -1 or non-negative")
	return errors


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
		push_error("CarSpawner requires a committed generated track.")
		return false
	if available_car_variants.is_empty():
		push_error("CarSpawner requires at least one configured car variant.")
		return false

	opponent_lane_spacing = lane_spacing
	opponent_row_spacing = row_spacing
	_car_spawn = car_spawn
	_track = track
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
	return (
		_configured
		and is_instance_valid(_car_spawn)
		and is_instance_valid(_track)
		and _track.has_committed_generation()
	)


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


func validate_opponent_spawn_request(opponent_count: int) -> PackedStringArray:
	var errors: PackedStringArray = validate_configuration_values(
		opponent_count,
		opponent_lane_spacing,
		opponent_row_spacing,
		-1
	)
	if (
		not _configured
		or not is_instance_valid(_car_spawn)
		or not is_instance_valid(_track)
		or _opponent_layout == null
	):
		errors.append("CarSpawner must be configured before validating an opponent grid")
		return errors
	if opponent_count > 0 and not has_ai_eligible_cars():
		errors.append("an AI-eligible car variant is required when opponents are enabled")
	if not errors.is_empty() or opponent_count <= 0:
		return errors

	var transforms: Array[Transform3D] = [_car_spawn.global_transform]
	for opponent_index: int in range(opponent_count):
		transforms.append(_opponent_layout.get_spawn_transform(_car_spawn, opponent_index))
	var spawn_inverse: Transform3D = _car_spawn.global_transform.affine_inverse()
	var start_line_half_width: float = 0.0
	var track_layout: TrackLayoutResource = _track.get_track_layout()
	if track_layout != null:
		start_line_half_width = maxf(track_layout.get_track_width_at(0.0) * 0.5, 0.0)

	var local_positions: Array[Vector3] = []
	for transform_index: int in range(transforms.size()):
		var local_position: Vector3 = spawn_inverse * transforms[transform_index].origin
		local_positions.append(local_position)
		if (
			start_line_half_width > 0.0
			and absf(local_position.x) + MIN_TRACK_EDGE_CLEARANCE > start_line_half_width
		):
			errors.append(
				"spawn transform %d exceeds the usable start-line track width"
				% transform_index
			)

	for first_index: int in range(local_positions.size()):
		var first_local: Vector3 = local_positions[first_index]
		for second_index: int in range(first_index + 1, local_positions.size()):
			var second_local: Vector3 = local_positions[second_index]
			if (
				absf(first_local.x - second_local.x) < MIN_LATERAL_SPAWN_SEPARATION
				and absf(first_local.z - second_local.z) < MIN_LONGITUDINAL_SPAWN_SEPARATION
			):
				errors.append(
					"spawn transforms %d and %d overlap the minimum vehicle footprint"
					% [first_index, second_index]
				)
	return errors


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
	var validation_errors: PackedStringArray = validate_opponent_spawn_request(opponent_count)
	if not validation_errors.is_empty():
		push_error("CarSpawner rejected the opponent grid: %s" % "; ".join(validation_errors))
		var rejected_opponents: Array[PlayerCarController] = []
		return rejected_opponents
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
