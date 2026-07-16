extends Node3D

const DEFAULT_CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")

@export_group("Content")
@export var car_catalog: CarCatalog = DEFAULT_CAR_CATALOG

@export_group("Scene Nodes")
@export var car_spawn_path: NodePath
@export var camera_path: NodePath
@export var speedometer_path: NodePath
@export var menu_path: NodePath
@export var grid_path: NodePath

var _current_car: PlayerCarController
var _active_variant_id: StringName = &""
var _car_spawner: CarSpawner
var _pause_menu: PauseMenu
var _fatal_error_layer: CanvasLayer
var _initialization_failed: bool = false

@onready var _car_spawn: Node3D = get_node_or_null(car_spawn_path) as Node3D
@onready var _camera: FollowCamera = get_node_or_null(camera_path) as FollowCamera
@onready var _speedometer: Speedometer = get_node_or_null(speedometer_path) as Speedometer
@onready var _menu: MainMenu = get_node_or_null(menu_path) as MainMenu
@onready var _grid: InfiniteGridTrack = get_node_or_null(grid_path) as InfiniteGridTrack


func _ready() -> void:
	if not _validate_scene_contract():
		_fail_initialization("Free-drive scene contract validation failed.")
		return
	if car_catalog == null:
		_fail_initialization("A car catalog is required.")
		return
	var catalog_errors: PackedStringArray = car_catalog.validate()
	if not catalog_errors.is_empty():
		_fail_initialization("Car catalog validation failed: %s" % "; ".join(catalog_errors))
		return
	if not _grid.has_committed_generation():
		_fail_initialization("The infinite grid could not be initialized.")
		return

	var variants: Array[CarVariantDefinition] = car_catalog.get_all_variants()
	_car_spawner = CarSpawner.new()
	if not _car_spawner.configure(self, _car_spawn, _grid, variants, 0.0, 0.0, -1):
		_fail_initialization("The player car spawner could not be configured.")
		return

	_menu.set_car_models(MenuOptionsBuilder.build_car_models(car_catalog))
	if not _menu.has_valid_options():
		_fail_initialization("No valid car variants are available.")
		return
	if not _build_pause_menu():
		_fail_initialization("Pause menu construction failed.")
		return

	_set_driving_ui_visible(false)
	_menu.car_selected.connect(_on_car_selected)


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _process(_delta: float) -> void:
	if _initialization_failed or not is_instance_valid(_current_car):
		return
	if not get_tree().paused and Input.is_action_just_pressed(GameInputActions.SWITCH_CAR):
		_switch_to_next_car()


func get_current_car() -> PlayerCarController:
	return _current_car


func get_active_track() -> GeneratedTrack:
	return _grid


func get_selected_car_variant_id() -> StringName:
	return _active_variant_id


func is_ready_for_input() -> bool:
	return (
		not _initialization_failed
		and _car_spawner != null
		and _pause_menu != null
		and _menu != null
		and is_instance_valid(_grid)
		and _grid.has_committed_generation()
	)


func _validate_scene_contract() -> bool:
	var missing: PackedStringArray = PackedStringArray()
	if _car_spawn == null:
		missing.append("car spawn")
	if _camera == null:
		missing.append("FollowCamera")
	if _speedometer == null:
		missing.append("Speedometer")
	if _menu == null:
		missing.append("MainMenu")
	if _grid == null:
		missing.append("InfiniteGridTrack")
	if missing.is_empty():
		return true
	push_error("Free-drive scene contract is incomplete: %s" % ", ".join(missing))
	return false


func _on_car_selected(car_variant_id: StringName) -> void:
	var car_index: int = _find_variant_index(car_variant_id)
	if car_index < 0:
		push_error("Selected car variant is not present in the catalog: %s" % str(car_variant_id))
		_menu.complete_loading(false)
		return
	var next_car: PlayerCarController = _car_spawner.spawn_player_car(
		car_index,
		_car_spawn.global_transform,
		true
	)
	if next_car == null:
		push_error("The selected car could not be spawned.")
		_menu.complete_loading(false)
		return
	_current_car = next_car
	_active_variant_id = car_variant_id
	_update_car_targets()
	_set_driving_ui_visible(true)
	_menu.complete_loading(true)


func _find_variant_index(variant_id: StringName) -> int:
	var variants: Array[CarVariantDefinition] = car_catalog.get_all_variants()
	for variant_index: int in range(variants.size()):
		var variant: CarVariantDefinition = variants[variant_index]
		if variant != null and variant.variant_id == variant_id:
			return variant_index
	return -1


func _switch_to_next_car() -> void:
	if _car_spawner == null or not is_instance_valid(_current_car):
		return
	var next_car: PlayerCarController = _car_spawner.switch_to_next_car(
		_current_car.global_transform,
		true
	)
	if next_car == null:
		return
	_current_car = next_car
	var next_index: int = _car_spawner.get_current_car_index()
	var variants: Array[CarVariantDefinition] = car_catalog.get_all_variants()
	if next_index >= 0 and next_index < variants.size() and variants[next_index] != null:
		_active_variant_id = variants[next_index].variant_id
	_update_car_targets()


func _update_car_targets() -> void:
	if _camera != null:
		_camera.set_target_node(_current_car)
	if _speedometer != null:
		_speedometer.set_target_node(_current_car)


func _clear_current_car() -> void:
	if _car_spawner != null:
		_car_spawner.clear_current_car()
	_current_car = null
	_active_variant_id = &""
	if _camera != null:
		_camera.set_target_node(null)
	if _speedometer != null:
		_speedometer.set_target_node(null)


func _set_driving_ui_visible(visible: bool) -> void:
	if _speedometer != null:
		_speedometer.visible = visible
	if _pause_menu != null:
		_pause_menu.set_pause_enabled(visible)


func _return_to_main_menu() -> void:
	if _pause_menu != null:
		_pause_menu.resume_game()
	_clear_current_car()
	_set_driving_ui_visible(false)
	if _menu != null:
		_menu.reset_menu()


func _build_pause_menu() -> bool:
	_pause_menu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	if _pause_menu == null:
		push_error("Pause menu scene must instantiate PauseMenu.")
		return false
	add_child(_pause_menu)
	_pause_menu.set_pause_enabled(false)
	_pause_menu.main_menu_requested.connect(_return_to_main_menu)
	return true


func _fail_initialization(message: String) -> void:
	if _initialization_failed:
		return
	_initialization_failed = true
	push_error(message)
	set_process(false)
	if _car_spawner != null:
		_car_spawner.clear_current_car()
	_set_driving_ui_visible(false)
	if _menu != null:
		_menu.hide()
	_show_fatal_error(message)
	if OS.has_feature("export_smoke_test") and get_tree() != null:
		get_tree().call_deferred("quit", 1)


func _show_fatal_error(message: String) -> void:
	if _fatal_error_layer != null:
		return
	_fatal_error_layer = CanvasLayer.new()
	_fatal_error_layer.name = "FatalInitializationError"
	_fatal_error_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_fatal_error_layer)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fatal_error_layer.add_child(panel)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)

	var label := Label.new()
	label.custom_minimum_size = Vector2(640.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "%s\n\n%s" % [tr("Nie można uruchomić gry"), message]
	center.add_child(label)
