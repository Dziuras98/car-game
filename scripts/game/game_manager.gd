extends Node3D

const DEFAULT_CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const DEFAULT_TRACK_CATALOG: TrackCatalog = preload("res://resources/tracks/catalog.tres")
const MOBILE_DRIVE_CONTROLS_SCENE: PackedScene = preload("res://scenes/ui/mobile_drive_controls.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")

@export_group("Content")
@export var car_catalog: CarCatalog = DEFAULT_CAR_CATALOG
@export var track_catalog: TrackCatalog = DEFAULT_TRACK_CATALOG

@export_group("Scene Nodes")
@export var car_spawn_path: NodePath
@export var camera_path: NodePath
@export var speedometer_path: NodePath
@export var minimap_path: NodePath
@export var menu_path: NodePath
@export var track_container_path: NodePath

@export_group("Race")
@export var opponent_count: int = 3
@export var opponent_lane_spacing: float = 4.2
@export var opponent_row_spacing: float = 7.0
@export var race_lap_count: int = 3
@export var use_track_recommended_laps: bool = true

@export_group("Input")
@export var force_mobile_controls: bool = false

const MODE_FREE: String = "free_drive"
const MODE_RACE: String = "race"

var _current_car: PlayerCarController
var selected_mode_id: String = ""
var selected_track_id: String = ""
var selected_car_variant_id: StringName = &""
var _car_selection_state: CarSelectionState
var _track_spawn_controller: TrackSpawnController
var _active_track_definition: TrackDefinition
var _track: GeneratedTrack
var _active_lap_count: int = 1
var _car_spawner: CarSpawner
var _race_session: RaceSessionController
var _race_hud: RaceHud
var _mobile_drive_controls: MobileDriveControls
var _pause_menu: PauseMenu

@onready var _car_spawn: Node3D = get_node_or_null(car_spawn_path) as Node3D
@onready var _camera: FollowCamera = get_node_or_null(camera_path) as FollowCamera
@onready var _speedometer: Speedometer = get_node_or_null(speedometer_path) as Speedometer
@onready var _minimap: Minimap = get_node_or_null(minimap_path) as Minimap
@onready var _menu: MainMenu = get_node_or_null(menu_path) as MainMenu
@onready var _track_container: Node3D = get_node_or_null(track_container_path) as Node3D


func _ready() -> void:
	if not _validate_scene_contract() or not _validate_content_catalogs():
		set_process(false)
		set_physics_process(false)
		return

	_car_selection_state = CarSelectionState.new()
	_car_selection_state.configure(car_catalog)
	_track_spawn_controller = TrackSpawnController.new()
	_track_spawn_controller.configure(_track_container)

	if not _activate_track(track_catalog.get_default_track()):
		set_process(false)
		set_physics_process(false)
		return

	_configure_menu_track_options()
	_configure_menu_car_options()
	if not _menu.has_valid_options():
		push_error("GameManager produced no valid menu content options.")
		set_process(false)
		set_physics_process(false)
		return

	_race_hud = RaceHud.new()
	_race_hud.build(self, _active_lap_count, Callable(self, "_return_to_main_menu"))
	_build_pause_menu()
	_build_mobile_drive_controls()
	_configure_runtime_for_active_track()

	_speedometer.visible = false
	_minimap.visible = false
	_menu.selection_completed.connect(_on_menu_selection_completed)


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _process(_delta: float) -> void:
	if not get_tree().paused and Input.is_action_just_pressed("switch-car"):
		_switch_to_next_car()


func _physics_process(_delta: float) -> void:
	if _race_session != null:
		_race_session.update_physics()


func get_current_car() -> PlayerCarController:
	return _current_car


func get_active_track() -> GeneratedTrack:
	return _track


func get_active_lap_count() -> int:
	return _active_lap_count


func get_opponents() -> Array[PlayerCarController]:
	if _race_session == null:
		var empty_opponents: Array[PlayerCarController] = []
		return empty_opponents
	return _race_session.get_opponents()


func get_configured_opponent_count() -> int:
	return opponent_count


func get_selected_mode_id() -> String:
	return selected_mode_id


func get_selected_track_id() -> String:
	return selected_track_id


func get_selected_car_variant_id() -> StringName:
	return selected_car_variant_id


func _validate_scene_contract() -> bool:
	var missing: PackedStringArray = PackedStringArray()
	if _car_spawn == null:
		missing.append("car spawn")
	if _camera == null:
		missing.append("FollowCamera")
	if _speedometer == null:
		missing.append("Speedometer")
	if _minimap == null:
		missing.append("Minimap")
	if _menu == null:
		missing.append("MainMenu")
	if _track_container == null:
		missing.append("track container")
	if missing.is_empty():
		return true
	push_error("GameManager scene contract is incomplete: %s" % ", ".join(missing))
	return false


func _validate_content_catalogs() -> bool:
	if car_catalog == null or car_catalog.get_all_variants().is_empty():
		push_error("GameManager requires a CarCatalog with at least one variant.")
		return false
	if track_catalog == null:
		push_error("GameManager requires a TrackCatalog.")
		return false
	var track_errors: PackedStringArray = track_catalog.validate()
	if not track_errors.is_empty():
		push_error("GameManager received an invalid TrackCatalog: %s" % "; ".join(track_errors))
		return false
	return true


func _configure_menu_car_options() -> void:
	_menu.set_car_models(MenuOptionsBuilder.build_car_models(car_catalog))


func _configure_menu_track_options() -> void:
	_menu.set_track_options(MenuOptionsBuilder.build_track_options(track_catalog))


func _activate_track(definition: TrackDefinition) -> bool:
	if definition == null or not definition.is_valid():
		push_error("Cannot activate an invalid track definition.")
		return false
	if (
		_active_track_definition != null
		and _active_track_definition.track_id == definition.track_id
		and is_instance_valid(_track)
	):
		_active_lap_count = _resolve_lap_count(definition)
		return true

	_track = _track_spawn_controller.spawn_track(definition)
	if _track == null:
		return false
	_active_track_definition = definition
	_active_lap_count = _resolve_lap_count(definition)
	return true


func _resolve_lap_count(definition: TrackDefinition) -> int:
	return maxi(definition.recommended_laps, 1) if use_track_recommended_laps else maxi(race_lap_count, 1)


func _configure_runtime_for_active_track() -> void:
	_car_spawner = CarSpawner.new()
	_car_spawner.configure(
		self,
		_car_spawn,
		_track,
		_car_selection_state.get_available_car_variants(),
		opponent_lane_spacing,
		opponent_row_spacing
	)

	_race_session = RaceSessionController.new()
	_race_session.configure(
		_car_spawner,
		_race_hud,
		_track,
		_minimap,
		_active_lap_count,
		opponent_count
	)
	_minimap.set_track_node(_track)


func _switch_to_next_car() -> void:
	if selected_mode_id != MODE_FREE or _car_spawner == null:
		return
	var spawn_global_transform: Transform3D = (
		_current_car.global_transform if is_instance_valid(_current_car) else _car_spawn.global_transform
	)
	_current_car = _car_spawner.switch_to_next_car(
		spawn_global_transform,
		_is_player_input_enabled_for_spawn()
	)
	selected_car_variant_id = _car_selection_state.get_variant_id_for_index(
		_car_spawner.get_current_car_index()
	)
	_show_driving_ui_if_needed()
	_update_car_targets()


func _on_menu_selection_completed(
	mode_id: String,
	track_id: String,
	car_variant_id: StringName
) -> void:
	var selected_car_index: int = _car_selection_state.get_car_index_for_variant_id(car_variant_id)
	var selected_track: TrackDefinition = track_catalog.get_track_by_id(StringName(track_id))
	if selected_car_index < 0 or selected_track == null:
		push_error("Menu emitted an unavailable car or track selection.")
		return

	_clear_current_car()
	if _race_session != null:
		_race_session.reset_to_menu_state()
	if not _activate_track(selected_track):
		return
	_configure_runtime_for_active_track()

	selected_mode_id = mode_id
	selected_track_id = str(selected_track.track_id)
	selected_car_variant_id = _car_selection_state.get_variant_id_for_index(selected_car_index)
	_spawn_car(selected_car_index, _car_spawn.global_transform)
	if selected_mode_id == MODE_RACE:
		_start_race()
	else:
		_race_session.hide_lap_ui()


func _spawn_car(car_index: int, spawn_global_transform: Transform3D) -> void:
	if _car_spawner == null:
		return
	_current_car = _car_spawner.spawn_player_car(
		car_index,
		spawn_global_transform,
		_is_player_input_enabled_for_spawn()
	)
	_show_driving_ui_if_needed()
	_update_car_targets()


func _is_player_input_enabled_for_spawn() -> bool:
	return _race_session == null or not _race_session.are_player_controls_locked()


func _show_driving_ui_if_needed() -> void:
	if _current_car == null:
		return
	_speedometer.visible = true
	_minimap.visible = true
	if _pause_menu != null:
		_pause_menu.set_pause_enabled(true)


func _update_car_targets() -> void:
	_camera.set_target_node(_current_car)
	_speedometer.set_target_node(_current_car)
	_minimap.set_target_node(_current_car)
	_minimap.set_track_node(_track)
	var opponents: Array[PlayerCarController] = []
	if _race_session != null:
		opponents = _race_session.get_opponents()
	_minimap.set_opponents(opponents)
	if _mobile_drive_controls != null:
		_mobile_drive_controls.set_target_node(_current_car)


func _start_race() -> void:
	if _race_session != null:
		_race_session.start_race(_current_car, get_tree())


func _clear_current_car() -> void:
	if _pause_menu != null:
		_pause_menu.set_pause_enabled(false)
	if _mobile_drive_controls != null:
		_mobile_drive_controls.set_target_node(null)
	if _car_spawner != null:
		_car_spawner.clear_current_car()
	_current_car = null
	_camera.set_target_node(null)
	_speedometer.set_target_node(null)
	_minimap.set_target_node(null)
	_minimap.set_opponents([])


func _return_to_main_menu() -> void:
	if _pause_menu != null:
		_pause_menu.resume_game()
	if _race_session != null:
		_race_session.reset_to_menu_state()
	_clear_current_car()
	selected_mode_id = ""
	selected_track_id = ""
	selected_car_variant_id = &""
	_speedometer.visible = false
	_minimap.visible = false
	_menu.reset_menu()


func _build_pause_menu() -> void:
	_pause_menu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	if _pause_menu == null:
		push_error("Pause menu scene must instantiate PauseMenu.")
		return
	add_child(_pause_menu)
	_pause_menu.set_pause_enabled(false)
	_pause_menu.main_menu_requested.connect(_return_to_main_menu)


func _build_mobile_drive_controls() -> void:
	if _mobile_drive_controls != null:
		return
	if not force_mobile_controls and not OS.has_feature("android"):
		return
	_mobile_drive_controls = MOBILE_DRIVE_CONTROLS_SCENE.instantiate() as MobileDriveControls
	if _mobile_drive_controls == null:
		push_error("Mobile drive controls scene must instantiate MobileDriveControls.")
		return
	_mobile_drive_controls.force_visible = force_mobile_controls
	_mobile_drive_controls.rear_view_changed.connect(_camera.set_rear_view_active)
	add_child(_mobile_drive_controls)
