extends RefCounted
class_name PlayerCarSpawnController

var _owner: Node3D
var _factory: CarInstanceFactory
var _current_car_index: int = -1
var _current_car: PlayerCarController


func configure(owner_node: Node3D, factory: CarInstanceFactory) -> void:
	_owner = owner_node
	_factory = factory


func get_current_car() -> PlayerCarController:
	return _current_car


func get_current_car_index() -> int:
	return _current_car_index


func spawn_player_car(car_index: int, spawn_global_transform: Transform3D, player_input_enabled: bool) -> PlayerCarController:
	if _owner == null or _factory == null or not _factory.has_available_cars():
		return null
	if car_index < 0 or car_index >= _factory.get_available_count():
		push_error("Player car index %d is outside the configured catalog range." % car_index)
		return null

	var car_controller: PlayerCarController = _factory.instantiate_indexed_car(car_index)
	if car_controller == null:
		return null

	clear_current_car()
	_owner.add_child(car_controller)
	car_controller.global_transform = spawn_global_transform
	car_controller.capture_current_transform_as_start()
	car_controller.set_player_input_enabled(player_input_enabled)

	_current_car = car_controller
	_current_car_index = car_index
	return _current_car


func switch_to_next_car(spawn_global_transform: Transform3D, player_input_enabled: bool) -> PlayerCarController:
	if _factory == null or not _factory.has_available_cars():
		return null

	var next_index: int = _factory.get_random_available_index_excluding(_current_car_index)
	if next_index < 0:
		return null
	return spawn_player_car(next_index, spawn_global_transform, player_input_enabled)


func clear_current_car() -> void:
	if is_instance_valid(_current_car):
		var parent: Node = _current_car.get_parent()
		if parent != null:
			parent.remove_child(_current_car)
		_current_car.queue_free()

	_current_car = null
	_current_car_index = -1
