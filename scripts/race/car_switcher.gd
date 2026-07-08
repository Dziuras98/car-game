extends Node3D

@export var available_cars: Array[PackedScene] = []
@export var car_spawn_path: NodePath
@export var camera_path: NodePath
@export var speedometer_path: NodePath

var _current_car_index: int = -1
var _current_car: PlayerCarController

@onready var _car_spawn: Node3D = get_node(car_spawn_path) as Node3D
@onready var _camera: Node = get_node_or_null(camera_path)
@onready var _speedometer: Node = get_node_or_null(speedometer_path)


func _ready() -> void:
	if available_cars.is_empty():
		return

	_spawn_car(0, _car_spawn.global_transform)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("switch-car"):
		_switch_to_next_car()


func _switch_to_next_car() -> void:
	if available_cars.is_empty():
		return

	var next_index: int = (_current_car_index + 1) % available_cars.size()
	var spawn_transform: Transform3D = _car_spawn.global_transform

	if is_instance_valid(_current_car):
		spawn_transform = _current_car.global_transform
		remove_child(_current_car)
		_current_car.queue_free()
		_current_car = null

	_spawn_car(next_index, spawn_transform)


func _spawn_car(car_index: int, spawn_transform: Transform3D) -> void:
	var car_scene: PackedScene = available_cars[car_index]
	var car_instance: Node = car_scene.instantiate()
	var car_controller: PlayerCarController = car_instance as PlayerCarController

	if car_controller == null:
		push_error("Car scene must have PlayerCarController on its root node.")
		car_instance.queue_free()
		return

	car_controller.transform = spawn_transform
	add_child(car_controller)

	_current_car = car_controller
	_current_car_index = car_index
	_update_car_targets()


func _update_car_targets() -> void:
	if _camera != null and _camera.has_method("set_target_node"):
		_camera.call("set_target_node", _current_car)

	if _speedometer != null and _speedometer.has_method("set_target_node"):
		_speedometer.call("set_target_node", _current_car)
