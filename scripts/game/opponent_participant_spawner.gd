extends RefCounted
class_name OpponentParticipantSpawner

signal driver_fault(message: String)

enum Result {
	OK,
	INVALID_COUNT,
	NOT_CONFIGURED,
	NO_ELIGIBLE_VARIANTS,
	PREPARATION_FAILED,
}

var _owner: Node3D
var _car_spawn: Node3D
var _track: GeneratedTrack
var _factory: CarInstanceFactory
var _layout: OpponentSpawnLayout
var _paint_randomizer: OpponentPaintRandomizer
var _session_seed: int = 0
var _profile_factory: OpponentAiProfileFactory = OpponentAiProfileFactory.new()
var _opponents: Array[PlayerCarController] = []
var _ai_drivers: Array[AiRaceDriver] = []
var _last_spawn_result: Result = Result.OK


static func is_success(result: Result) -> bool:
	return result == Result.OK


func configure(
	owner_node: Node3D,
	car_spawn: Node3D,
	track: GeneratedTrack,
	factory: CarInstanceFactory,
	layout: OpponentSpawnLayout,
	paint_randomizer: OpponentPaintRandomizer,
	session_seed: int
) -> void:
	_owner = owner_node
	_car_spawn = car_spawn
	_track = track
	_factory = factory
	_layout = layout
	_paint_randomizer = paint_randomizer
	_session_seed = session_seed


func is_configured() -> bool:
	return (
		is_instance_valid(_owner)
		and is_instance_valid(_car_spawn)
		and is_instance_valid(_track)
		and _track.has_committed_generation()
		and _factory != null
		and _factory.has_available_cars()
		and _layout != null
	)


func get_last_spawn_result() -> Result:
	return _last_spawn_result


func get_opponents() -> Array[PlayerCarController]:
	return _opponents.duplicate()


func get_ai_drivers() -> Array[AiRaceDriver]:
	return _ai_drivers.duplicate()


func spawn_opponents(opponent_count: int) -> Array[PlayerCarController]:
	if opponent_count < 0:
		_last_spawn_result = Result.INVALID_COUNT
		var invalid_count: Array[PlayerCarController] = []
		return invalid_count
	if opponent_count == 0:
		clear_opponents()
		_last_spawn_result = Result.OK
		return _opponents.duplicate()
	if not is_configured():
		_last_spawn_result = Result.NOT_CONFIGURED
		push_error("OpponentParticipantSpawner requires an owner, spawn marker, committed track, car factory and layout.")
		var unavailable: Array[PlayerCarController] = []
		return unavailable
	if not _factory.has_ai_eligible_cars():
		_last_spawn_result = Result.NO_ELIGIBLE_VARIANTS
		push_error("OpponentParticipantSpawner requires an explicit AI-eligible car variant.")
		var no_eligible_variants: Array[PlayerCarController] = []
		return no_eligible_variants

	var random_state_before: int = _factory.capture_random_state()
	var requested_count: int = opponent_count
	var staged_cars: Array[PlayerCarController] = []
	var staged_drivers: Array[AiRaceDriver] = []
	var staged_transforms: Array[Transform3D] = []

	for opponent_index: int in range(requested_count):
		var car_controller: PlayerCarController = _factory.instantiate_opponent_car()
		if car_controller == null:
			_rollback_preparation(staged_cars, staged_drivers, random_state_before)
			_last_spawn_result = Result.PREPARATION_FAILED
			push_error("OpponentParticipantSpawner could not prepare opponent %d of %d." % [opponent_index + 1, requested_count])
			var failed_cars: Array[PlayerCarController] = []
			return failed_cars

		var profile: AiDriverProfile = _profile_factory.create_profile(
			_session_seed,
			opponent_index,
			_layout.get_lane_offset(opponent_index)
		)
		var ai_driver: AiRaceDriver = AiRaceDriver.new()
		ai_driver.name = "Opponent%dDriver" % (opponent_index + 1)
		if not ai_driver.configure(car_controller, _track, profile):
			car_controller.free()
			ai_driver.free()
			_rollback_preparation(staged_cars, staged_drivers, random_state_before)
			_last_spawn_result = Result.PREPARATION_FAILED
			push_error("OpponentParticipantSpawner could not configure opponent %d of %d." % [opponent_index + 1, requested_count])
			var failed_drivers: Array[PlayerCarController] = []
			return failed_drivers

		car_controller.name = "Opponent%d" % (opponent_index + 1)
		car_controller.set_player_input_enabled(false)
		car_controller.set_external_input_enabled(true)
		car_controller.set_force_low_detail_visuals(false)
		if _paint_randomizer != null:
			_paint_randomizer.randomize_car_paint(car_controller)
		staged_cars.append(car_controller)
		staged_drivers.append(ai_driver)
		staged_transforms.append(_layout.get_spawn_transform(_car_spawn, opponent_index))

	if staged_cars.size() != requested_count or staged_drivers.size() != requested_count:
		_rollback_preparation(staged_cars, staged_drivers, random_state_before)
		_last_spawn_result = Result.PREPARATION_FAILED
		push_error("OpponentParticipantSpawner did not prepare the complete requested participant set.")
		var incomplete: Array[PlayerCarController] = []
		return incomplete

	clear_opponents()
	for opponent_index: int in range(requested_count):
		var car_controller: PlayerCarController = staged_cars[opponent_index]
		var ai_driver: AiRaceDriver = staged_drivers[opponent_index]
		_owner.add_child(car_controller)
		car_controller.global_transform = staged_transforms[opponent_index]
		car_controller.capture_current_transform_as_start()
		_opponents.append(car_controller)
		var fault_callback: Callable = Callable(self, "_on_ai_driver_fault")
		if not ai_driver.driver_fault.is_connected(fault_callback):
			ai_driver.driver_fault.connect(fault_callback)
		_owner.add_child(ai_driver)
		_ai_drivers.append(ai_driver)

	_last_spawn_result = Result.OK
	return _opponents.duplicate()


func clear_opponents() -> void:
	for ai_driver: AiRaceDriver in _ai_drivers:
		if is_instance_valid(ai_driver):
			ai_driver.set_driver_enabled(false)
			var driver_parent: Node = ai_driver.get_parent()
			if driver_parent != null:
				driver_parent.remove_child(ai_driver)
			ai_driver.queue_free()
	_ai_drivers.clear()

	for opponent: PlayerCarController in _opponents:
		if is_instance_valid(opponent):
			var opponent_parent: Node = opponent.get_parent()
			if opponent_parent != null:
				opponent_parent.remove_child(opponent)
			opponent.queue_free()
	_opponents.clear()


func set_ai_enabled(enabled: bool) -> void:
	for ai_driver: AiRaceDriver in _ai_drivers:
		if is_instance_valid(ai_driver):
			ai_driver.set_driver_enabled(enabled)


func _rollback_preparation(
	staged_cars: Array[PlayerCarController],
	staged_drivers: Array[AiRaceDriver],
	random_state_before: int
) -> void:
	_discard_staged_participants(staged_cars, staged_drivers)
	if _factory != null:
		_factory.restore_random_state(random_state_before)


func _discard_staged_participants(
	staged_cars: Array[PlayerCarController],
	staged_drivers: Array[AiRaceDriver]
) -> void:
	for ai_driver: AiRaceDriver in staged_drivers:
		if is_instance_valid(ai_driver):
			ai_driver.free()
	for car_controller: PlayerCarController in staged_cars:
		if is_instance_valid(car_controller):
			car_controller.free()


func _on_ai_driver_fault(message: String) -> void:
	driver_fault.emit(message)
