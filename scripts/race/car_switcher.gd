extends Node3D

@export var available_cars: Array[PackedScene] = []
@export var car_spawn_path: NodePath
@export var camera_path: NodePath
@export var speedometer_path: NodePath
@export var menu_path: NodePath
@export var track_path: NodePath
@export var opponent_count: int = 3
@export var opponent_lane_spacing: float = 4.2
@export var opponent_row_spacing: float = 7.0

var _current_car_index: int = -1
var _current_car: PlayerCarController
var selected_mode_id: String = ""
var selected_track_id: String = ""
var _opponents: Array[PlayerCarController] = []
var _ai_drivers: Array[Node] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _countdown_layer: CanvasLayer
var _countdown_label: Label
var _player_controls_locked: bool = false

@onready var _car_spawn: Node3D = get_node(car_spawn_path) as Node3D
@onready var _camera: Node = get_node_or_null(camera_path)
@onready var _speedometer: Node = get_node_or_null(speedometer_path)
@onready var _menu: Node = get_node_or_null(menu_path)
@onready var _track: Node3D = get_node_or_null(track_path) as Node3D

const MODE_RACE: String = "race"
const AI_DRIVER_SCRIPT: Script = preload("res://scripts/race/ai_race_driver.gd")


func _ready() -> void:
	if available_cars.is_empty():
		return

	_rng.randomize()
	_build_countdown_ui()

	if _speedometer != null:
		_speedometer.visible = false

	if _menu != null and _menu.has_signal("selection_completed"):
		_menu.connect("selection_completed", Callable(self, "_on_menu_selection_completed"))
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


func _on_menu_selection_completed(mode_id: String, track_id: String, car_index: int) -> void:
	selected_mode_id = mode_id
	selected_track_id = track_id
	_clear_race_opponents()
	_hide_countdown()

	var selected_car_index: int = car_index
	if selected_car_index < 0 or selected_car_index >= available_cars.size():
		selected_car_index = 0

	_spawn_car(selected_car_index, _car_spawn.global_transform)
	if selected_mode_id == MODE_RACE:
		_start_race()


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
	_current_car.set_player_input_enabled(not _player_controls_locked)
	if _speedometer != null:
		_speedometer.visible = true
	_update_car_targets()


func _update_car_targets() -> void:
	if _camera != null and _camera.has_method("set_target_node"):
		_camera.call("set_target_node", _current_car)

	if _speedometer != null and _speedometer.has_method("set_target_node"):
		_speedometer.call("set_target_node", _current_car)


func _start_race() -> void:
	_player_controls_locked = true
	if _current_car != null:
		_current_car.set_player_input_enabled(false)

	_spawn_opponents()
	_set_ai_enabled(false)
	_run_countdown()


func _spawn_opponents() -> void:
	for opponent_index: int in opponent_count:
		if available_cars.is_empty():
			return

		var car_scene: PackedScene = available_cars[_rng.randi_range(0, available_cars.size() - 1)]
		var car_instance: Node = car_scene.instantiate()
		var car_controller: PlayerCarController = car_instance as PlayerCarController
		if car_controller == null:
			car_instance.queue_free()
			continue

		car_controller.name = "Opponent%d" % (opponent_index + 1)
		car_controller.transform = _get_opponent_spawn_transform(opponent_index)
		car_controller.manual_transmission_enabled = false
		car_controller.automatic_transmission_enabled = true
		car_controller.set_player_input_enabled(false)
		car_controller.set_external_input_enabled(true)
		_randomize_car_paint(car_controller)
		add_child(car_controller)
		_opponents.append(car_controller)

		var ai_driver: Node = AI_DRIVER_SCRIPT.new()
		ai_driver.name = "%sDriver" % car_controller.name
		ai_driver.set("car_path", car_controller.get_path())
		if _track != null:
			ai_driver.set("track_path", _track.get_path())
		ai_driver.set("lane_offset", _get_opponent_lane_offset(opponent_index))
		ai_driver.set("target_speed_kmh", _rng.randf_range(96.0, 128.0))
		ai_driver.set("corner_speed_kmh", _rng.randf_range(66.0, 84.0))
		add_child(ai_driver)
		_ai_drivers.append(ai_driver)


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


func _set_ai_enabled(enabled: bool) -> void:
	for ai_driver: Node in _ai_drivers:
		if is_instance_valid(ai_driver) and ai_driver.has_method("set_driver_enabled"):
			ai_driver.call("set_driver_enabled", enabled)


func _run_countdown() -> void:
	_show_countdown("3")
	await get_tree().create_timer(1.0).timeout
	_show_countdown("2")
	await get_tree().create_timer(1.0).timeout
	_show_countdown("1")
	await get_tree().create_timer(1.0).timeout
	_show_countdown("START")
	_player_controls_locked = false
	if _current_car != null:
		_current_car.set_player_input_enabled(true)
	_set_ai_enabled(true)
	await get_tree().create_timer(0.8).timeout
	_hide_countdown()


func _build_countdown_ui() -> void:
	_countdown_layer = CanvasLayer.new()
	_countdown_layer.layer = 20
	_countdown_layer.visible = false
	add_child(_countdown_layer)

	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_countdown_layer.add_child(root)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	_countdown_label = Label.new()
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 92)
	_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.18, 1.0))
	_countdown_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	_countdown_label.add_theme_constant_override("shadow_offset_x", 4)
	_countdown_label.add_theme_constant_override("shadow_offset_y", 4)
	center.add_child(_countdown_label)


func _show_countdown(text: String) -> void:
	if _countdown_layer == null or _countdown_label == null:
		return

	_countdown_label.text = text
	_countdown_layer.visible = true


func _hide_countdown() -> void:
	if _countdown_layer != null:
		_countdown_layer.visible = false


func _clear_race_opponents() -> void:
	for ai_driver: Node in _ai_drivers:
		if is_instance_valid(ai_driver):
			ai_driver.queue_free()
	_ai_drivers.clear()

	for opponent: PlayerCarController in _opponents:
		if is_instance_valid(opponent):
			opponent.queue_free()
	_opponents.clear()
	_player_controls_locked = false


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
