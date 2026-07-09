extends Node3D

const DEFAULT_CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")

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
var _available_car_variants: Array[CarVariantDefinition] = []
var _available_car_scenes: Array[PackedScene] = []
var _opponents: Array[PlayerCarController] = []
var _lap_tracker: LapTracker
var _car_spawner: CarSpawner
var _race_manager: RaceManager
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
	_prepare_car_selection_data()
	_configure_menu_car_options()

	_lap_tracker = LapTracker.new()
	_lap_tracker.participant_finished.connect(_on_lap_tracker_participant_finished)

	_car_spawner = CarSpawner.new()
	_car_spawner.configure(
		self,
		_car_spawn,
		_track,
		_available_car_scenes,
		_available_car_variants,
		opponent_lane_spacing,
		opponent_row_spacing
	)

	_race_hud = RaceHud.new()
	_build_mobile_drive_controls()

	_race_manager = RaceManager.new()
	_race_manager.countdown_changed.connect(_show_countdown)
	_race_manager.countdown_hidden.connect(_hide_countdown)
	_race_manager.player_input_enabled_changed.connect(_set_player_input_enabled)
	_race_manager.ai_enabled_changed.connect(_set_ai_enabled)
	_race_manager.opponent_should_stop.connect(_stop_participant_car)
	_race_manager.race_finished.connect(_on_race_finished)

	if not _has_available_car_options():
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
	if _race_manager != null and _race_manager.should_update_race_positions() and _lap_tracker != null:
		_lap_tracker.update_positions()
		_update_lap_ui()


func _prepare_car_selection_data() -> void:
	_available_car_variants.clear()
	_available_car_scenes.clear()

	if car_catalog != null:
		_available_car_variants = car_catalog.get_all_variants()
		_available_car_scenes = car_catalog.get_variant_scene_list()

	if _available_car_scenes.is_empty():
		_available_car_scenes = available_cars.duplicate()


func _configure_menu_car_options() -> void:
	if _menu == null:
		return

	if _menu.has_method("set_car_models"):
		_menu.call("set_car_models", _get_menu_car_models())
		return

	if _menu.has_method("set_car_names"):
		var car_names: PackedStringArray = PackedStringArray()
		if car_catalog != null and not _available_car_variants.is_empty():
			for variant: CarVariantDefinition in _available_car_variants:
				car_names.append(variant.get_menu_name())
		else:
			for car_index: int in range(_available_car_scenes.size()):
				car_names.append("Samochod %d" % (car_index + 1))

		_menu.call("set_car_names", car_names)


func _get_menu_car_models() -> Array[Dictionary]:
	var menu_models: Array[Dictionary] = []
	if car_catalog != null:
		for model: CarModelDefinition in car_catalog.get_models():
			var variants: Array[Dictionary] = []
			for variant: CarVariantDefinition in model.get_variants():
				variants.append({
					"label": variant.get_menu_name(),
					"variant_id": variant.variant_id,
				})
			if not variants.is_empty():
				menu_models.append({
					"label": model.get_model_name(),
					"model_id": model.model_id,
					"variants": variants,
				})

	if not menu_models.is_empty():
		return menu_models

	var fallback_variants: Array[Dictionary] = []
	for car_index: int in range(_available_car_scenes.size()):
		fallback_variants.append({
			"label": "Samochod %d" % (car_index + 1),
			"variant_id": StringName(str(car_index)),
		})

	if not fallback_variants.is_empty():
		menu_models.append({
			"label": "Samochody",
			"model_id": &"fallback_cars",
			"variants": fallback_variants,
		})

	return menu_models


func _has_available_car_options() -> bool:
	return not _available_car_variants.is_empty() or not _available_car_scenes.is_empty()


func _switch_to_next_car() -> void:
	if not _has_available_car_options() or _car_spawner == null:
		return
	if not _can_switch_cars():
		return

	var spawn_transform: Transform3D = _car_spawn.global_transform
	if is_instance_valid(_current_car):
		spawn_transform = _current_car.global_transform

	_current_car = _car_spawner.switch_to_next_car(spawn_transform, _is_player_input_enabled_for_spawn())
	selected_car_variant_id = _get_variant_id_for_current_spawner_index()
	_show_driving_ui_if_needed()
	_update_car_targets()


func _can_switch_cars() -> bool:
	return selected_mode_id == MODE_FREE


func _on_menu_selection_completed(mode_id: String, track_id: String, car_variant_id: StringName) -> void:
	selected_mode_id = mode_id
	selected_track_id = track_id
	_clear_current_car()
	_clear_race_opponents()
	_hide_countdown()
	_hide_results()
	_clear_race_tracking()

	var selected_car_index: int = _get_car_index_for_variant_id(car_variant_id)
	selected_car_variant_id = _get_variant_id_for_index(selected_car_index)

	_spawn_car(selected_car_index, _car_spawn.global_transform)
	if selected_mode_id == MODE_RACE:
		_start_race()
	else:
		_hide_lap_ui()


func _get_valid_car_index(car_index: int) -> int:
	var available_count: int = _get_available_car_count()
	if available_count <= 0:
		return 0
	return clampi(car_index, 0, available_count - 1)


func _get_car_index_for_variant_id(car_variant_id: StringName) -> int:
	if not _available_car_variants.is_empty():
		for variant_index: int in range(_available_car_variants.size()):
			var variant: CarVariantDefinition = _available_car_variants[variant_index]
			if variant != null and variant.variant_id == car_variant_id:
				return variant_index
		push_warning("Car variant id '%s' was not found; falling back to car index 0." % str(car_variant_id))
		return 0

	return _get_valid_car_index(int(str(car_variant_id)))


func _get_available_car_count() -> int:
	if not _available_car_variants.is_empty():
		return _available_car_variants.size()
	return _available_car_scenes.size()


func _get_variant_id_for_index(car_index: int) -> StringName:
	if car_index < 0 or car_index >= _available_car_variants.size():
		return &""
	return _available_car_variants[car_index].variant_id


func _get_variant_id_for_current_spawner_index() -> StringName:
	if _car_spawner == null:
		return selected_car_variant_id
	var variant_id: StringName = _get_variant_id_for_index(_car_spawner.get_current_car_index())
	if variant_id.is_empty():
		return selected_car_variant_id
	return variant_id


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


func _show_countdown(text: String) -> void:
	if _race_hud != null:
		_race_hud.show_countdown(text)


func _hide_countdown() -> void:
	if _race_hud != null:
		_race_hud.hide_countdown()


func _show_lap_ui() -> void:
	if _race_hud != null:
		_race_hud.show_lap()
	_update_lap_ui()


func _hide_lap_ui() -> void:
	if _race_hud != null:
		_race_hud.hide_lap()


func _update_lap_ui() -> void:
	if _current_car == null or _lap_tracker == null or _race_hud == null:
		return

	_race_hud.update_lap(
		_lap_tracker.get_current_lap(_current_car),
		maxi(race_lap_count, 1),
		_lap_tracker.get_race_position(_current_car),
		maxi(_lap_tracker.get_participant_count(), 1)
	)


func _hide_results() -> void:
	if _race_hud != null:
		_race_hud.hide_results()


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
	if _lap_tracker == null or _race_hud == null:
		return

	var result_labels: Array[String] = []
	var ordered_participants: Array[PlayerCarController] = _lap_tracker.get_result_order()
	for car: PlayerCarController in ordered_participants:
		result_labels.append(_get_participant_label(car))

	_race_hud.show_results(result_labels)


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
	selected_car_variant_id = &""
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


func _build_mobile_drive_controls() -> void:
	if _mobile_drive_controls != null:
		return

	_mobile_drive_controls = MOBILE_DRIVE_CONTROLS_SCENE.instantiate() as CanvasLayer
	if _mobile_drive_controls != null:
		add_child(_mobile_drive_controls)
