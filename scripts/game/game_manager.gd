extends Node3D

signal session_phase_changed(phase: GameSessionState.Phase)

const DEFAULT_CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const DEFAULT_TRACK_CATALOG: TrackCatalog = preload("res://resources/tracks/catalog.tres")
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
@export var opponent_random_seed: int = -1
@export var race_lap_count: int = 3
@export var use_track_recommended_laps: bool = true

var _current_car: PlayerCarController
var _session_state: GameSessionState = GameSessionState.new()
var _session_start_transaction: GameSessionStartTransaction
var _car_selection_state: CarSelectionState
var _track_spawn_controller: TrackSpawnController
var _active_track_definition: TrackDefinition
var _track: GeneratedTrack
var _active_lap_count: int = 1
var _car_spawner: CarSpawner
var _race_session: RaceSessionController
var _race_hud: RaceHud
var _pause_menu: PauseMenu

@onready var _car_spawn: Node3D = get_node_or_null(car_spawn_path) as Node3D
@onready var _camera: FollowCamera = get_node_or_null(camera_path) as FollowCamera
@onready var _speedometer: Speedometer = get_node_or_null(speedometer_path) as Speedometer
@onready var _minimap: Minimap = get_node_or_null(minimap_path) as Minimap
@onready var _menu: MainMenu = get_node_or_null(menu_path) as MainMenu
@onready var _track_container: Node3D = get_node_or_null(track_container_path) as Node3D


static func is_supported_mode_id(mode_id: StringName) -> bool:
	return GameModes.is_supported(mode_id)


func _ready() -> void:
	if not _validate_scene_contract() or not _validate_content_catalogs():
		set_process(false)
		set_physics_process(false)
		return

	_session_state.phase_changed.connect(_on_session_phase_changed)
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
	if not _configure_runtime_for_session_track() or not _configure_session_start_transaction():
		set_process(false)
		set_physics_process(false)
		return

	_set_driving_ui_visible(false)
	_menu.selection_completed.connect(_on_menu_selection_completed)


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _process(_delta: float) -> void:
	if not get_tree().paused and Input.is_action_just_pressed(GameInputActions.SWITCH_CAR):
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


func get_session_phase() -> GameSessionState.Phase:
	return _session_state.get_phase()


func get_selected_mode_id() -> StringName:
	return _session_state.get_mode_id()


func get_selected_track_id() -> StringName:
	return _session_state.get_track_id()


func get_selected_car_variant_id() -> StringName:
	return _session_state.get_car_variant_id()


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
	if car_catalog == null:
		push_error("GameManager requires a non-null CarCatalog.")
		return false
	var car_errors: PackedStringArray = car_catalog.validate()
	if not car_errors.is_empty():
		push_error("GameManager received an invalid CarCatalog: %s" % "; ".join(car_errors))
		return false
	if opponent_count < 0:
		push_error("GameManager opponent_count must be non-negative.")
		return false
	if opponent_count > 0:
		var has_ai_variant: bool = false
		for variant: CarVariantDefinition in car_catalog.get_all_variants():
			if variant != null and variant.is_ai_eligible_for_race():
				has_ai_variant = true
				break
		if not has_ai_variant:
			push_error("GameManager requires at least one explicit AI-eligible automatic car variant.")
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
	var next_track: GeneratedTrack = _track_spawn_controller.spawn_track(definition)
	if next_track == null:
		return false
	_sync_active_track_state()
	return true


func _stage_track(definition: TrackDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	return _track_spawn_controller.stage_track(definition) != null


func _commit_staged_track() -> bool:
	if _track_spawn_controller.commit_staged_track() == null:
		return false
	_sync_active_track_state()
	_update_car_targets()
	return true


func _finalize_staged_track_commit() -> void:
	_track_spawn_controller.finalize_track_commit()


func _sync_active_track_state() -> void:
	_track = _track_spawn_controller.get_current_track()
	_active_track_definition = _track_spawn_controller.get_current_definition()
	if _active_track_definition != null:
		_active_lap_count = _resolve_lap_count(_active_track_definition)
	if _minimap != null:
		_minimap.set_track_node(_track)


func _get_session_track() -> GeneratedTrack:
	var staged_track: GeneratedTrack = _track_spawn_controller.get_staged_track()
	return staged_track if is_instance_valid(staged_track) else _track


func _get_session_track_definition() -> TrackDefinition:
	var staged_definition: TrackDefinition = _track_spawn_controller.get_staged_definition()
	return staged_definition if staged_definition != null else _active_track_definition


func _get_session_lap_count() -> int:
	var definition: TrackDefinition = _get_session_track_definition()
	return _resolve_lap_count(definition) if definition != null else _active_lap_count


func _resolve_lap_count(definition: TrackDefinition) -> int:
	return maxi(definition.recommended_laps, 1) if use_track_recommended_laps else maxi(race_lap_count, 1)


func _configure_runtime_for_session_track() -> bool:
	var session_track: GeneratedTrack = _get_session_track()
	if not is_instance_valid(session_track):
		return false
	var session_lap_count: int = _get_session_lap_count()
	var next_car_spawner: CarSpawner = CarSpawner.new()
	if not next_car_spawner.configure(
		self,
		_car_spawn,
		session_track,
		_car_selection_state.get_available_car_variants(),
		opponent_lane_spacing,
		opponent_row_spacing,
		opponent_random_seed
	):
		return false

	var next_race_session: RaceSessionController = RaceSessionController.new()
	if not next_race_session.configure(
		next_car_spawner,
		_race_hud,
		session_track,
		_minimap,
		session_lap_count,
		opponent_count
	):
		return false

	_car_spawner = next_car_spawner
	_race_session = next_race_session
	_minimap.set_track_node(session_track)
	return true


func _configure_session_start_transaction() -> bool:
	_session_start_transaction = GameSessionStartTransaction.new()
	return _session_start_transaction.configure(
		_session_state,
		_car_selection_state,
		track_catalog,
		Callable(self, "_reset_session_start_runtime"),
		Callable(self, "_stage_track"),
		Callable(self, "_configure_runtime_for_session_track"),
		Callable(self, "_spawn_car"),
		Callable(self, "_start_race"),
		Callable(self, "_commit_staged_track"),
		Callable(self, "_finalize_staged_track_commit")
	)


func _switch_to_next_car() -> void:
	if not _session_state.is_free_drive() or _car_spawner == null:
		return
	var spawn_global_transform: Transform3D = (
		_current_car.global_transform if is_instance_valid(_current_car) else _car_spawn.global_transform
	)
	var next_car: PlayerCarController = _car_spawner.switch_to_next_car(
		spawn_global_transform,
		_is_player_input_enabled_for_spawn()
	)
	if next_car == null:
		return
	_current_car = next_car
	var next_variant_id: StringName = _car_selection_state.get_variant_id_for_index(
		_car_spawner.get_current_car_index()
	)
	var update_result: GameSessionState.Result = _session_state.update_free_drive_car_variant(next_variant_id)
	if not GameSessionState.is_success(update_result):
		_reset_to_main_menu("Session lifecycle rejected the switched free-drive car.")
		return
	_update_car_targets()


func _on_menu_selection_completed(
	mode_id: StringName,
	track_id: StringName,
	car_variant_id: StringName
) -> void:
	if _session_start_transaction == null:
		_reset_to_main_menu("Session-start transaction is unavailable.")
		return
	var result: GameSessionStartTransaction.Result = _session_start_transaction.execute(
		mode_id,
		track_id,
		car_variant_id,
		_car_spawn.global_transform
	)
	if result != GameSessionStartTransaction.Result.OK:
		_handle_session_start_failure(result)
		return
	if _session_state.is_free_drive():
		_race_session.hide_lap_ui()


func _handle_session_start_failure(result: GameSessionStartTransaction.Result) -> void:
	var message: String = GameSessionStartTransaction.get_failure_message(result)
	if result == GameSessionStartTransaction.Result.NOT_CONFIGURED:
		_reset_to_main_menu(message)
		return
	if not message.is_empty():
		push_error(message)
	if result == GameSessionStartTransaction.Result.SESSION_BEGIN_REJECTED:
		return
	_menu.reset_menu()


func _spawn_car(car_index: int, spawn_global_transform: Transform3D) -> bool:
	if _car_spawner == null:
		return false
	var next_car: PlayerCarController = _car_spawner.spawn_player_car(
		car_index,
		spawn_global_transform,
		_is_player_input_enabled_for_spawn()
	)
	if next_car == null:
		return false
	_current_car = next_car
	_set_driving_ui_visible(true)
	_update_car_targets()
	return true


func _is_player_input_enabled_for_spawn() -> bool:
	return _race_session == null or not _race_session.are_player_controls_locked()


func _set_driving_ui_visible(visible: bool) -> void:
	_speedometer.visible = visible
	_minimap.visible = visible
	if _pause_menu != null:
		_pause_menu.set_pause_enabled(visible)


func _update_car_targets() -> void:
	_camera.set_target_node(_current_car)
	_speedometer.set_target_node(_current_car)
	_minimap.set_target_node(_current_car)
	_minimap.set_track_node(_get_session_track())
	var opponents: Array[PlayerCarController] = []
	if _race_session != null:
		opponents = _race_session.get_opponents()
	_minimap.set_opponents(opponents)


func _start_race() -> bool:
	return _race_session != null and _race_session.start_race(_current_car, get_tree())


func _clear_current_car() -> void:
	if _car_spawner != null:
		_car_spawner.clear_current_car()
	_current_car = null
	_camera.set_target_node(null)
	_speedometer.set_target_node(null)
	_minimap.set_target_node(null)
	_minimap.set_opponents([])


func _clear_runtime_state(resume_game: bool) -> void:
	if resume_game and _pause_menu != null:
		_pause_menu.resume_game()
	if _race_session != null:
		_race_session.reset_to_menu_state()
	_clear_current_car()
	_car_spawner = null
	_race_session = null
	_set_driving_ui_visible(false)


func _reset_session_start_runtime() -> void:
	_clear_runtime_state(false)
	if _track_spawn_controller != null:
		_track_spawn_controller.rollback_track_transaction()
		_sync_active_track_state()


func _clear_active_session(resume_game: bool) -> void:
	_clear_runtime_state(resume_game)
	_session_state.reset()


func _reset_to_main_menu(message: String = "", resume_game: bool = false) -> void:
	if not message.is_empty():
		push_error(message)
	_clear_active_session(resume_game)
	_menu.reset_menu()


func _return_to_main_menu() -> void:
	_reset_to_main_menu("", true)


func _on_session_phase_changed(phase: GameSessionState.Phase) -> void:
	session_phase_changed.emit(phase)


func _build_pause_menu() -> void:
	_pause_menu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	if _pause_menu == null:
		push_error("Pause menu scene must instantiate PauseMenu.")
		return
	add_child(_pause_menu)
	_pause_menu.set_pause_enabled(false)
	_pause_menu.main_menu_requested.connect(_return_to_main_menu)
