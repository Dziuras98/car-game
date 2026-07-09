extends Node3D

const DEFAULT_CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const CarSelectionState = preload("res://scripts/game/car_selection_state.gd")
const MenuOptionsBuilder = preload("res://scripts/game/menu_options_builder.gd")
const RaceSessionController = preload("res://scripts/game/race_session_controller.gd")

@export_group("Cars")
@export var car_catalog: CarCatalog = DEFAULT_CAR_CATALOG
@export var available_cars: Array[PackedScene] = []

@export_group("Scene Nodes")
@export var car_spawn_path: NodePath
@export var camera_path: NodePath
@export var speedometer_path: NodePath
@export var minimap_path: NodePath
@export var menu_path: NodePath
@export var track_path: NodePath

@export_group("Race")
@export var opponent_count: int = 3
@export var opponent_lane_spacing: float = 4.2
@export var opponent_row_spacing: float = 7.0
@export var race_lap_count: int = 3

var _current_car: PlayerCarController
var selected_mode_id: String = ""
var selected_track_id: String = ""
var selected_car_variant_id: StringName = &""
var _car_selection_state: CarSelectionState
var _car_spawner: CarSpawner
var _race_session: RaceSessionController
var _race_hud: RaceHud
var _mobile_drive_controls: CanvasLayer

@onready var _car_spawn: Node3D = get_node(car_spawn_path) as Node3D
@onready var _camera: Node = get_node_or_null(camera_path)
@onready var _speedometer: Node = get_node_or_null(speedometer_path)
@onready var _minimap: Node = get_node_or_null(minimap_path)
@onready var _menu: Node = get_node_or_null(menu_path)
@onready var _track: Node3D = get_node_or_null(track_path) as Node3D

const MODE_FREE: String = "free_drive"
const MODE_RACE: String = "race"
const MOBILE_DRIVE_CONTROLS_SCENE: PackedScene = preload("res://scenes/ui/mobile_drive_controls.tscn")


func _ready() -> void:
	_car_selection_state = CarSelectionState.new()
	_car_selection_state.configure(car_catalog, available_cars)
	_configure_menu_track_options()
	_configure_menu_car_options()

	_car_spawner = CarSpawner.new()
	_car_spawner.configure(
		self,
		_car_spawn,
		_track,
		_car_selection_state.get_available_car_scenes(),
		_car_selection_state.get_available_car_variants(),
		opponent_lane_spacing,
		opponent_row_spacing
	)

	_race_hud = RaceHud.new()
	_build_mobile_drive_controls()

	_race_session = RaceSessionController.new()
	_race_session.configure(_car_spawner, _race_hud, _track, _minimap, race_lap_count, opponent_count)

	if not _car_selection_state.has_available_options():
		return

	_race_hud.build(self, race_lap_count, Callable(self, "_return_to_main_menu"))

	if _speedometer != null:
		_speedometer.visible = false
	if _minimap != null:
		_minimap.visible = false
		if _track != null and _minimap.has_method("set_track_node"):
			_minimap.call("set_track_node", _track)

	if _menu != null and _menu.has_signal("selection_completed"):
		_menu.connect("selection_completed", Callable(self, "_on_menu_selection_completed"))
		return

	selected_mode_id = MODE_FREE
	_spawn_car(0, _car_spawn.global_transform)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("switch-car"):
		_switch_to_next_car()


func _physics_process(_delta: float) -> void:
	if _race_session != null:
		_race_session.update_physics()


func get_current_car() -> PlayerCarController:
	return _current_car


func get_opponents() -> Array[PlayerCarController]:
	if _race_session == null:
		var empty_opponents: Array[PlayerCarController] = []
		return empty_opponents

	return _race_session.get_opponents()


func get_moving_opponent_count_for_test() -> int:
	if _race_session == null:
		return 0

	return _race_session.get_moving_opponent_count_for_test()


func get_configured_opponent_count() -> int:
	return opponent_count


func get_selected_mode_id() -> String:
	return selected_mode_id


func get_selected_track_id() -> String:
	return selected_track_id


func get_selected_car_variant_id() -> StringName:
	return selected_car_variant_id


func request_return_to_main_menu_for_test() -> void:
	_return_to_main_menu()


func simulate_current_player_finish_for_test() -> void:
	if _race_session == null:
		return

	_race_session.simulate_current_player_finish_for_test(_current_car)


func is_child_visible_for_test(node_name: String) -> bool:
	var target: Node = get_node_or_null(node_name)
	if target == null:
		return false

	var visible_value: Variant = target.get("visible")
	if visible_value is bool:
		return bool(visible_value)

	if target is CanvasItem:
		return (target as CanvasItem).is_visible_in_tree()

	return false


func _configure_menu_car_options() -> void:
	if _menu == null:
		return

	if _menu.has_method("set_car_models"):
		_menu.call(
			"set_car_models",
			MenuOptionsBuilder.build_car_models(car_catalog, _car_selection_state.get_available_car_scenes())
		)
		return

	if _menu.has_method("set_car_names"):
		var car_names: PackedStringArray = MenuOptionsBuilder.build_fallback_car_names(
			car_catalog,
			_car_selection_state.get_available_car_variants(),
			_car_selection_state.get_available_car_scenes()
		)
		_menu.call("set_car_names", car_names)


func _configure_menu_track_options() -> void:
	if _menu == null or not _menu.has_method("set_track_options"):
		return

	var track_options: Array[Dictionary] = MenuOptionsBuilder.build_track_options()
	_menu.call("set_track_options", track_options)


func _switch_to_next_car() -> void:
	if not _car_selection_state.has_available_options() or _car_spawner == null:
		return
	if not _can_switch_cars():
		return

	var spawn_transform: Transform3D = _car_spawn.global_transform
	if is_instance_valid(_current_car):
		spawn_transform = _current_car.global_transform

	_current_car = _car_spawner.switch_to_next_car(spawn_transform, _is_player_input_enabled_for_spawn())
	selected_car_variant_id = _car_selection_state.get_variant_id_for_spawner_index(
		_car_spawner.get_current_car_index(),
		selected_car_variant_id
	)
	_show_driving_ui_if_needed()
	_update_car_targets()


func _can_switch_cars() -> bool:
	return selected_mode_id == MODE_FREE


func _on_menu_selection_completed(mode_id: String, track_id: String, car_variant_id: StringName) -> void:
	selected_mode_id = mode_id
	selected_track_id = track_id
	_clear_current_car()
	if _race_session != null:
		_race_session.reset_to_menu_state()

	var selected_car_index: int = _car_selection_state.get_car_index_for_variant_id(car_variant_id)
	selected_car_variant_id = _car_selection_state.get_variant_id_for_index(selected_car_index)

	_spawn_car(selected_car_index, _car_spawn.global_transform)
	if selected_mode_id == MODE_RACE:
		_start_race()
	else:
		if _race_session != null:
			_race_session.hide_lap_ui()


func _spawn_car(car_index: int, spawn_transform: Transform3D) -> void:
	if _car_spawner == null:
		return

	_current_car = _car_spawner.spawn_player_car(car_index, spawn_transform, _is_player_input_enabled_for_spawn())
	_show_driving_ui_if_needed()
	_update_car_targets()


func _is_player_input_enabled_for_spawn() -> bool:
	if _race_session == null:
		return true
	return not _race_session.are_player_controls_locked()


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
		if _minimap.has_method("set_opponents") and _race_session != null:
			_minimap.call("set_opponents", _race_session.get_opponents())


func _start_race() -> void:
	if _race_session != null:
		_race_session.start_race(_current_car, get_tree())


func _clear_current_car() -> void:
	if _car_spawner != null:
		_car_spawner.clear_current_car()
	_current_car = null


func _return_to_main_menu() -> void:
	if _race_session != null:
		_race_session.reset_to_menu_state()
	_clear_current_car()
	selected_mode_id = ""
	selected_track_id = ""
	selected_car_variant_id = &""
	if _speedometer != null:
		_speedometer.visible = false
	if _minimap != null:
		_minimap.visible = false
		if _minimap.has_method("set_target_node"):
			_minimap.call("set_target_node", null)
	if _menu != null:
		if _menu.has_method("reset_menu"):
			_menu.call("reset_menu")
		else:
			_menu.show()


func _build_mobile_drive_controls() -> void:
	if _mobile_drive_controls != null:
		return

	_mobile_drive_controls = MOBILE_DRIVE_CONTROLS_SCENE.instantiate() as CanvasLayer
	if _mobile_drive_controls != null:
		add_child(_mobile_drive_controls)
