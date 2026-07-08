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
@export var race_lap_count: int = 3

var _current_car_index: int = -1
var _current_car: PlayerCarController
var selected_mode_id: String = ""
var selected_track_id: String = ""
var _opponents: Array[PlayerCarController] = []
var _ai_drivers: Array[Node] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _countdown_layer: CanvasLayer
var _countdown_label: Label
var _lap_layer: CanvasLayer
var _lap_label: Label
var _position_label: Label
var _results_layer: CanvasLayer
var _results_list: VBoxContainer
var _player_controls_locked: bool = false
var _race_in_progress: bool = false
var _race_completed: bool = false
var _race_points: Array[Vector3] = []
var _participants: Array[PlayerCarController] = []
var _participant_laps: Array[int] = []
var _participant_progress: Array[int] = []
var _participant_finished: Array[bool] = []
var _participant_lap_armed: Array[bool] = []
var _finish_order: Array[PlayerCarController] = []

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
	_build_lap_ui()
	_build_results_ui()

	if _speedometer != null:
		_speedometer.visible = false

	if _menu != null and _menu.has_signal("selection_completed"):
		_menu.connect("selection_completed", Callable(self, "_on_menu_selection_completed"))
		return

	_spawn_car(0, _car_spawn.global_transform)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("switch-car"):
		_switch_to_next_car()


func _physics_process(_delta: float) -> void:
	if _race_in_progress and not _race_completed:
		_update_race_positions()


func _switch_to_next_car() -> void:
	if available_cars.is_empty() or _race_in_progress:
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
	_clear_current_car()
	_clear_race_opponents()
	_hide_countdown()
	_hide_results()
	_clear_race_tracking()

	var selected_car_index: int = car_index
	if selected_car_index < 0 or selected_car_index >= available_cars.size():
		selected_car_index = 0

	_spawn_car(selected_car_index, _car_spawn.global_transform)
	if selected_mode_id == MODE_RACE:
		_start_race()
	else:
		_hide_lap_ui()


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
	_race_completed = false
	_race_in_progress = false
	_player_controls_locked = true
	if _current_car != null:
		_current_car.set_player_input_enabled(false)

	_spawn_opponents()
	_prepare_race_tracking()
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
	if _race_completed:
		return
	_show_countdown("2")
	await get_tree().create_timer(1.0).timeout
	if _race_completed:
		return
	_show_countdown("1")
	await get_tree().create_timer(1.0).timeout
	if _race_completed:
		return
	_show_countdown("START")
	_player_controls_locked = false
	_race_in_progress = true
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


func _build_lap_ui() -> void:
	_lap_layer = CanvasLayer.new()
	_lap_layer.layer = 12
	_lap_layer.visible = false
	add_child(_lap_layer)

	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lap_layer.add_child(root)

	var panel: PanelContainer = PanelContainer.new()
	panel.offset_left = 24.0
	panel.offset_top = 24.0
	panel.offset_right = 246.0
	panel.offset_bottom = 116.0
	root.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)

	_lap_label = Label.new()
	_lap_label.add_theme_font_size_override("font_size", 22)
	_lap_label.text = "Okrazenie 1/%d" % race_lap_count
	content.add_child(_lap_label)

	_position_label = Label.new()
	_position_label.add_theme_font_size_override("font_size", 22)
	_position_label.text = "Pozycja 1/1"
	content.add_child(_position_label)


func _build_results_ui() -> void:
	_results_layer = CanvasLayer.new()
	_results_layer.layer = 30
	_results_layer.visible = false
	add_child(_results_layer)

	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_results_layer.add_child(root)

	var background: ColorRect = ColorRect.new()
	background.color = Color(0.02, 0.025, 0.03, 0.88)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var title: Label = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.text = "Koniec wyscigu"
	content.add_child(title)

	_results_list = VBoxContainer.new()
	_results_list.add_theme_constant_override("separation", 8)
	content.add_child(_results_list)

	var menu_button: Button = Button.new()
	menu_button.text = "Powrot do menu glownego"
	menu_button.custom_minimum_size = Vector2(0, 46)
	menu_button.pressed.connect(_return_to_main_menu)
	content.add_child(menu_button)


func _show_countdown(text: String) -> void:
	if _countdown_layer == null or _countdown_label == null:
		return

	_countdown_label.text = text
	_countdown_layer.visible = true


func _hide_countdown() -> void:
	if _countdown_layer != null:
		_countdown_layer.visible = false


func _show_lap_ui() -> void:
	if _lap_layer != null:
		_lap_layer.visible = true
	_update_lap_ui()


func _hide_lap_ui() -> void:
	if _lap_layer != null:
		_lap_layer.visible = false


func _update_lap_ui() -> void:
	if (_lap_label == null and _position_label == null) or _current_car == null:
		return

	var player_index: int = _participants.find(_current_car)
	var completed_laps: int = 0
	if player_index >= 0:
		completed_laps = _participant_laps[player_index]
	var current_lap: int = clampi(completed_laps + 1, 1, maxi(race_lap_count, 1))
	if _lap_label != null:
		_lap_label.text = "Okrazenie %d/%d" % [current_lap, maxi(race_lap_count, 1)]
	if _position_label != null:
		_position_label.text = "Pozycja %d/%d" % [_get_player_race_position(), maxi(_participants.size(), 1)]


func _hide_results() -> void:
	if _results_layer != null:
		_results_layer.visible = false


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
	_race_in_progress = false


func _clear_current_car() -> void:
	if is_instance_valid(_current_car):
		remove_child(_current_car)
		_current_car.queue_free()
	_current_car = null
	_current_car_index = -1


func _prepare_race_tracking() -> void:
	_clear_race_tracking()
	_refresh_race_points()
	if _current_car != null:
		_register_participant(_current_car)
	for opponent: PlayerCarController in _opponents:
		_register_participant(opponent)
	_show_lap_ui()


func _clear_race_tracking() -> void:
	_race_points.clear()
	_participants.clear()
	_participant_laps.clear()
	_participant_progress.clear()
	_participant_finished.clear()
	_participant_lap_armed.clear()
	_finish_order.clear()


func _refresh_race_points() -> void:
	_race_points.clear()
	if _track == null or not _track.has_method("get_racing_line_points"):
		return

	var local_points: Array = _track.call("get_racing_line_points")
	for point: Variant in local_points:
		if point is Vector3:
			_race_points.append(_track.to_global(point))


func _register_participant(car: PlayerCarController) -> void:
	if car == null:
		return

	_participants.append(car)
	_participant_laps.append(0)
	_participant_progress.append(_get_nearest_race_point_index(car.global_position))
	_participant_finished.append(false)
	_participant_lap_armed.append(false)


func _update_race_positions() -> void:
	if _race_points.is_empty():
		_refresh_race_points()
		if _race_points.is_empty():
			return

	for participant_index: int in _participants.size():
		var car: PlayerCarController = _participants[participant_index]
		if not is_instance_valid(car) or _participant_finished[participant_index]:
			continue

		var previous_index: int = _participant_progress[participant_index]
		var current_index: int = _get_nearest_race_point_index(car.global_position)
		_participant_progress[participant_index] = current_index

		if _is_lap_arming_progress(current_index):
			_participant_lap_armed[participant_index] = true

		if _participant_lap_armed[participant_index] and _crossed_finish_line(previous_index, current_index):
			_participant_lap_armed[participant_index] = false
			_participant_laps[participant_index] += 1
			if _participant_laps[participant_index] >= maxi(race_lap_count, 1):
				_mark_participant_finished(participant_index)

	_update_lap_ui()


func _get_nearest_race_point_index(position: Vector3) -> int:
	var nearest_index: int = 0
	var nearest_distance: float = INF

	for point_index: int in _race_points.size():
		var distance: float = position.distance_squared_to(_race_points[point_index])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = point_index

	return nearest_index


func _crossed_finish_line(previous_index: int, current_index: int) -> bool:
	if _race_points.size() < 4:
		return false

	var finish_exit_index: int = floori(float(_race_points.size()) * 0.75)
	var finish_entry_index: int = ceili(float(_race_points.size()) * 0.25)
	return previous_index >= finish_exit_index and current_index <= finish_entry_index


func _is_lap_arming_progress(current_index: int) -> bool:
	if _race_points.size() < 4:
		return false

	var arming_start_index: int = floori(float(_race_points.size()) * 0.35)
	var arming_end_index: int = ceili(float(_race_points.size()) * 0.85)
	return current_index >= arming_start_index and current_index <= arming_end_index


func _mark_participant_finished(participant_index: int) -> void:
	_participant_finished[participant_index] = true
	var car: PlayerCarController = _participants[participant_index]
	_finish_order.append(car)

	if car == _current_car:
		_finish_race()
	elif is_instance_valid(car):
		car.set_external_drive_inputs(0.0, 0.85, 0.0)


func _finish_race() -> void:
	_race_completed = true
	_race_in_progress = false
	_player_controls_locked = true
	if _current_car != null:
		_current_car.set_player_input_enabled(false)
	_set_ai_enabled(false)
	for opponent: PlayerCarController in _opponents:
		if is_instance_valid(opponent):
			opponent.set_external_drive_inputs(0.0, 0.85, 0.0)
	_hide_countdown()
	_hide_lap_ui()
	_show_results()


func _show_results() -> void:
	if _results_layer == null or _results_list == null:
		return

	for child: Node in _results_list.get_children():
		_results_list.remove_child(child)
		child.queue_free()

	var ordered_participants: Array[PlayerCarController] = _get_result_order()
	for result_index: int in ordered_participants.size():
		var car: PlayerCarController = ordered_participants[result_index]
		var row: Label = Label.new()
		row.add_theme_font_size_override("font_size", 21)
		row.text = "%d. %s" % [result_index + 1, _get_participant_label(car)]
		_results_list.add_child(row)

	_results_layer.visible = true


func _get_result_order() -> Array[PlayerCarController]:
	var ordered: Array[PlayerCarController] = []
	for finished_car: PlayerCarController in _finish_order:
		if is_instance_valid(finished_car) and not ordered.has(finished_car):
			ordered.append(finished_car)

	var remaining: Array[PlayerCarController] = []
	for car: PlayerCarController in _participants:
		if is_instance_valid(car) and not ordered.has(car):
			remaining.append(car)

	remaining.sort_custom(Callable(self, "_sort_participants_by_progress"))
	ordered.append_array(remaining)
	return ordered


func _get_player_race_position() -> int:
	if _current_car == null:
		return 1

	var ordered_participants: Array[PlayerCarController] = _get_result_order()
	var player_position: int = ordered_participants.find(_current_car)
	if player_position < 0:
		return 1
	return player_position + 1


func _sort_participants_by_progress(a: PlayerCarController, b: PlayerCarController) -> bool:
	return _get_race_distance_score(a) > _get_race_distance_score(b)


func _get_race_distance_score(car: PlayerCarController) -> int:
	var participant_index: int = _participants.find(car)
	if participant_index < 0:
		return -1
	return _participant_laps[participant_index] * maxi(_race_points.size(), 1) + _participant_progress[participant_index]


func _get_participant_label(car: PlayerCarController) -> String:
	if car == _current_car:
		return "Ty"
	if car != null and car.name != "":
		return car.name
	return "Kierowca"


func _return_to_main_menu() -> void:
	_hide_results()
	_hide_lap_ui()
	_hide_countdown()
	_clear_race_opponents()
	_clear_current_car()
	_clear_race_tracking()
	selected_mode_id = ""
	selected_track_id = ""
	if _speedometer != null:
		_speedometer.visible = false
	if _menu != null:
		if _menu.has_method("reset_menu"):
			_menu.call("reset_menu")
		else:
			_menu.show()


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
