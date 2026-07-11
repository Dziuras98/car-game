extends RefCounted
class_name OpponentParticipantSpawner

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


func get_opponents() -> Array[PlayerCarController]:
	return _opponents.duplicate()


func get_ai_drivers() -> Array[AiRaceDriver]:
	return _ai_drivers.duplicate()


func spawn_opponents(opponent_count: int) -> Array[PlayerCarController]:
	clear_opponents()
	if not is_configured():
		push_error("OpponentParticipantSpawner requires an owner, spawn marker, committed track, car factory and layout.")
		return _opponents.duplicate()

	for opponent_index: int in range(maxi(opponent_count, 0)):
		var car_controller: PlayerCarController = _factory.instantiate_opponent_car()
		if car_controller == null:
			continue

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
			continue

		var spawn_global_transform: Transform3D = _layout.get_spawn_transform(_car_spawn, opponent_index)
		car_controller.name = "Opponent%d" % (opponent_index + 1)
		car_controller.set_player_input_enabled(false)
		car_controller.set_external_input_enabled(true)
		if _paint_randomizer != null:
			_paint_randomizer.randomize_car_paint(car_controller)
		_owner.add_child(car_controller)
		car_controller.global_transform = spawn_global_transform
		car_controller.capture_current_transform_as_start()
		_opponents.append(car_controller)

		_owner.add_child(ai_driver)
		_ai_drivers.append(ai_driver)

	return _opponents.duplicate()


func clear_opponents() -> void:
	for ai_driver: AiRaceDriver in _ai_drivers:
		if is_instance_valid(ai_driver):
			ai_driver.set_driver_enabled(false)
			ai_driver.queue_free()
	_ai_drivers.clear()

	for opponent: PlayerCarController in _opponents:
		if is_instance_valid(opponent):
			opponent.queue_free()
	_opponents.clear()


func set_ai_enabled(enabled: bool) -> void:
	for ai_driver: AiRaceDriver in _ai_drivers:
		if is_instance_valid(ai_driver):
			ai_driver.set_driver_enabled(enabled)
