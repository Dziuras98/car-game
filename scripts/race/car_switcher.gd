extends Node3D

@export var available_cars: Array[PackedScene] = []
@export var car_spawn_path: NodePath
@export var camera_path: NodePath
@export var speedometer_path: NodePath
@export var minimap_path: NodePath
@export var menu_path: NodePath
@export var track_path: NodePath
@export var opponent_count: int = 3
@export var opponent_lane_spacing: float = 4.2
@export var opponent_row_spacing: float = 7.0
@export var race_lap_count: int = 3

var _current_car: PlayerCarController
var selected_mode_id: String = ""
var selected_track_id: String = ""
var _opponents: Array[PlayerCarController] = []
var _countdown_layer: CanvasLayer
var _countdown_label: Label
var _lap_layer: CanvasLayer
var _lap_label: Label
var _position_label: Label
var _results_layer: CanvasLayer
var _results_list: VBoxContainer
var _lap_tracker: LapTracker
var _car_spawner: CarSpawner
var _race_manager: RaceManager

@onready var _car_spawn: Node3D = get_node(car_spawn_path) as Node3D
@onready var _camera: Node = get_node_or_null(camera_path)
@onready var _speedometer: Node = get_node_or_null(speedometer_path)
@onready var _minimap: Node = get_node_or_null(minimap_path)
@onready var _menu: Node = get_node_or_null(menu_path)
@onready var _track: Node3D = get_node_or_null(track_path) as Node3D

const MODE_RACE: String = "race"


func _ready() -> void:
	_lap_tracker = LapTracker.new()
	_lap_tracker.participant_finished.connect(_on_lap_tracker_participant_finished)

	_car_spawner = CarSpawner.new()
	_car_spawner.configure(
		self,
		_car_spawn,
		_track,
		available_cars,
		opponent_lane_spacing,
		opponent_row_spacing
	)

	_race_manager = RaceManager.new()
	_race_manager.countdown_changed.connect(_show_countdown)
	_race_manager.countdown_hidden.connect(_hide_countdown)
	_race_manager.player_input_enabled_changed.connect(_set_player_input_enabled)
	_race_manager.ai_enabled_changed.connect(_set_ai_enabled)
	_race_manager.opponent_should_stop.connect(_stop_participant_car)
	_race_manager.race_finished.connect(_on_race_finished)

	if available_cars.is_empty():
		return

	_build_countdown_ui()
	_build_lap_ui()
	_build_results_ui()

	if _speedometer != null:
		_speedometer.visible = false
	if _minimap != null:
		_minimap.visible = false
		if _track != null and _minimap.has_method("set_track_node"):
			_minimap.call("set_track_node", _track)

	if _menu != null and _menu.has_signal("selection_completed"):
		_menu.connect("selection_completed", Callable(self, "_on_menu_selection_completed"))
		return

	_spawn_car(0, _car_spawn.global_transform)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("switch-car"):
		_switch_to_next_car()


func _physics_process(_delta: float) -> void:
	if _race_manager != null and _race_manager.should_update_race_positions() and _lap_tracker != null:
		_lap_tracker.update_positions()
		_update_lap_ui()


func _switch_to_next_car() -> void:
	if available_cars.is_empty() or _car_spawner == null:
		return
	if _race_manager != null and _race_manager.is_race_in_progress():
		return

	var spawn_transform: Transform3D = _car_spawn.global_transform
	if is_instance_valid(_current_car):
		spawn_transform = _current_car.global_transform

	_current_car = _car_spawner.switch_to_next_car(spawn_transform, _is_player_input_enabled_for_spawn())
	_show_driving_ui_if_needed()
	_update_car_targets()


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
	if _car_spawner == null:
		return

	_current_car = _car_spawner.spawn_player_car(car_index, spawn_transform, _is_player_input_enabled_for_spawn())
	_show_driving_ui_if_needed()
	_update_car_targets()


func _is_player_input_enabled_for_spawn() -> bool:
	if _race_manager == null:
		return true
	return not _race_manager.are_player_controls_locked()


func _show_driving_ui_if_needed() -> void:
	if _current_car == null:
		return

	if _speedometer != null:
		_speedometer.visible = true
	if _minimap != null:
		_minimap.visible = true


func _update_car_targets() -> void:
	if _camera != null and _camera.has_method("set_target_node"):
		_camera.call("set_target_node", _current_car)

	if _speedometer != null and _speedometer.has_method("set_target_node"):
		_speedometer.call("set_target_node", _current_car)

	if _minimap != null:
		if _minimap.has_method("set_target_node"):
			_minimap.call("set_target_node", _current_car)
		if _track != null and _minimap.has_method("set_track_node"):
			_minimap.call("set_track_node", _track)
		if _minimap.has_method("set_opponents"):
			_minimap.call("set_opponents", _opponents)


func _start_race() -> void:
	_spawn_opponents()
	_prepare_race_tracking()
	if _race_manager != null:
		_race_manager.start_race(_current_car, get_tree())


func _spawn_opponents() -> void:
	if _car_spawner == null:
		return

	_opponents = _car_spawner.spawn_opponents(opponent_count)
	_update_minimap_opponents()


func _set_ai_enabled(enabled: bool) -> void:
	if _car_spawner != null:
		_car_spawner.set_ai_enabled(enabled)


func _set_player_input_enabled(enabled: bool) -> void:
	if _current_car != null:
		_current_car.set_player_input_enabled(enabled)


func _stop_participant_car(car: PlayerCarController) -> void:
	if is_instance_valid(car):
		car.set_external_drive_inputs(0.0, 0.85, 0.0)


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
	if (_lap_label == null and _position_label == null) or _current_car == null or _lap_tracker == null:
		return

	var current_lap: int = _lap_tracker.get_current_lap(_current_car)
	if _lap_label != null:
		_lap_label.text = "Okrazenie %d/%d" % [current_lap, maxi(race_lap_count, 1)]
	if _position_label != null:
		_position_label.text = "Pozycja %d/%d" % [
			_lap_tracker.get_race_position(_current_car),
			maxi(_lap_tracker.get_participant_count(), 1)
		]


func _hide_results() -> void:
	if _results_layer != null:
		_results_layer.visible = false


func _clear_race_opponents() -> void:
	if _race_manager != null:
		_race_manager.reset_to_idle()
	if _car_spawner != null:
		_car_spawner.clear_opponents()
	_opponents.clear()
	_update_minimap_opponents()


func _clear_current_car() -> void:
	if _car_spawner != null:
		_car_spawner.clear_current_car()
	_current_car = null


func _prepare_race_tracking() -> void:
	if _lap_tracker == null:
		return

	_lap_tracker.prepare(_track, race_lap_count, _current_car, _opponents)
	_show_lap_ui()


func _clear_race_tracking() -> void:
	if _lap_tracker != null:
		_lap_tracker.clear()


func _on_lap_tracker_participant_finished(car: PlayerCarController) -> void:
	if car == _current_car:
		_finish_race()
	elif is_instance_valid(car):
		_stop_participant_car(car)


func _finish_race() -> void:
	if _race_manager != null:
		_race_manager.finish_race(_current_car, _opponents)


func _on_race_finished() -> void:
	_hide_lap_ui()
	_show_results()


func _show_results() -> void:
	if _results_layer == null or _results_list == null or _lap_tracker == null:
		return

	for child: Node in _results_list.get_children():
		_results_list.remove_child(child)
		child.queue_free()

	var ordered_participants: Array[PlayerCarController] = _lap_tracker.get_result_order()
	for result_index: int in ordered_participants.size():
		var car: PlayerCarController = ordered_participants[result_index]
		var row: Label = Label.new()
		row.add_theme_font_size_override("font_size", 21)
		row.text = "%d. %s" % [result_index + 1, _get_participant_label(car)]
		_results_list.add_child(row)

	_results_layer.visible = true


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
	if _minimap != null:
		_minimap.visible = false
		if _minimap.has_method("set_target_node"):
			_minimap.call("set_target_node", null)
		_update_minimap_opponents()
	if _menu != null:
		if _menu.has_method("reset_menu"):
			_menu.call("reset_menu")
		else:
			_menu.show()


func _update_minimap_opponents() -> void:
	if _minimap != null and _minimap.has_method("set_opponents"):
		_minimap.call("set_opponents", _opponents)
