extends RefCounted
class_name OpponentParticipantSpawner

const AI_DRIVER_SCRIPT: Script = preload("res://scripts/race/ai_race_driver.gd")

var _owner: Node3D
var _car_spawn: Node3D
var _track: Node3D
var _factory: CarInstanceFactory
var _layout: OpponentSpawnLayout
var _paint_randomizer: OpponentPaintRandomizer
var _rng: RandomNumberGenerator
var _opponents: Array[PlayerCarController] = []
var _ai_drivers: Array[Node] = []


func configure(
	owner_node: Node3D,
	car_spawn: Node3D,
	track: Node3D,
	factory: CarInstanceFactory,
	layout: OpponentSpawnLayout,
	paint_randomizer: OpponentPaintRandomizer,
	rng: RandomNumberGenerator
) -> void:
	_owner = owner_node
	_car_spawn = car_spawn
	_track = track
	_factory = factory
	_layout = layout
	_paint_randomizer = paint_randomizer
	_rng = rng


func get_opponents() -> Array[PlayerCarController]:
	return _opponents


func spawn_opponents(opponent_count: int) -> Array[PlayerCarController]:
	clear_opponents()
	if _owner == null or _car_spawn == null or _factory == null or not _factory.has_available_cars():
		return _opponents

	for opponent_index: int in opponent_count:
		var car_controller: PlayerCarController = _factory.instantiate_opponent_car()
		if car_controller == null:
			continue

		car_controller.name = "Opponent%d" % (opponent_index + 1)
		car_controller.transform = _layout.get_spawn_transform(_car_spawn, opponent_index)
		car_controller.set_player_input_enabled(false)
		car_controller.set_external_input_enabled(true)
		_paint_randomizer.randomize_car_paint(car_controller)
		_owner.add_child(car_controller)
		_opponents.append(car_controller)

		var ai_driver: Node = AI_DRIVER_SCRIPT.new()
		ai_driver.name = "%sDriver" % car_controller.name
		ai_driver.set("car_path", car_controller.get_path())
		if _track != null:
			ai_driver.set("track_path", _track.get_path())
		ai_driver.set("lane_offset", _layout.get_lane_offset(opponent_index))
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
