extends Resource
class_name CarVariantDefinition

const PLAYER_CAR_CONTROLLER_SCRIPT: Script = preload("res://scripts/car/car_controller.gd")

@export_group("Identity")
@export var variant_id: StringName = &""
@export var display_name: String = ""
@export var sort_order: int = 0

@export_group("Runtime")
@export var car_scene: PackedScene
@export var ai_car_scene: PackedScene
@export var specs: CarSpecs
@export var ai_eligible: bool = false

@export_group("Metadata")
@export var engine_label: String = ""
@export var drivetrain_label: String = ""


func is_valid() -> bool:
	return validate().is_empty()


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if variant_id == &"":
		errors.append("variant_id must not be empty")
	if get_menu_name().strip_edges().is_empty():
		errors.append("variant menu name must not be empty")
	if sort_order < 0:
		errors.append("sort_order must be non-negative")
	if car_scene == null:
		errors.append("car_scene must not be null")
	elif not _scene_has_player_car_root(car_scene):
		errors.append("car_scene must instantiate PlayerCarController on its root node")
	if ai_eligible and ai_car_scene == null:
		errors.append("ai_car_scene must not be null for ai_eligible variants")
	elif ai_car_scene != null and not _scene_has_player_car_root(ai_car_scene):
		errors.append("ai_car_scene must instantiate PlayerCarController on its root node")
	if specs == null:
		errors.append("specs must not be null")
	else:
		for specs_error: String in specs.validate():
			errors.append("specs: %s" % specs_error)
	if engine_label.strip_edges().is_empty():
		errors.append("engine_label must not be empty")
	if drivetrain_label.strip_edges().is_empty():
		errors.append("drivetrain_label must not be empty")
	if ai_eligible and specs != null and not specs.uses_geared_transmission():
		errors.append("ai_eligible variants must use a geared transmission")
	return errors


func get_menu_name() -> String:
	if display_name != "":
		return display_name
	if specs != null and specs.display_name != "":
		return specs.display_name
	return str(variant_id)


func get_specs() -> CarSpecs:
	return specs


func get_car_scene() -> PackedScene:
	return car_scene


func get_ai_car_scene() -> PackedScene:
	return ai_car_scene


func is_ai_eligible_for_race() -> bool:
	return (
		ai_eligible
		and car_scene != null
		and ai_car_scene != null
		and _scene_has_player_car_root(car_scene)
		and _scene_has_player_car_root(ai_car_scene)
		and specs != null
		and specs.is_valid()
		and specs.uses_geared_transmission()
	)


func get_transmission_label() -> String:
	if specs == null:
		return ""
	var forward_gear_count: int = specs.gear_ratios.size()
	if specs.is_manual_transmission():
		return "%d-speed manual" % forward_gear_count
	if specs.is_automatic_transmission():
		return "%d-speed automatic" % forward_gear_count
	if specs.is_cvt_transmission():
		return "CVT"
	return "Direct drive"


func _scene_has_player_car_root(scene: PackedScene) -> bool:
	if scene == null or not scene.can_instantiate():
		return false
	var root_script: Script = _get_scene_root_script(scene.get_state(), {})
	return _script_inherits(root_script, PLAYER_CAR_CONTROLLER_SCRIPT)


func _get_scene_root_script(scene_state: SceneState, visited_states: Dictionary) -> Script:
	if scene_state == null:
		return null
	var state_id: int = scene_state.get_instance_id()
	if visited_states.has(state_id):
		return null
	visited_states[state_id] = true

	if scene_state.get_node_count() > 0:
		for property_index: int in range(scene_state.get_node_property_count(0)):
			if scene_state.get_node_property_name(0, property_index) == &"script":
				return scene_state.get_node_property_value(0, property_index) as Script
		var root_instance: PackedScene = scene_state.get_node_instance(0)
		if root_instance != null:
			var instance_script: Script = _get_scene_root_script(root_instance.get_state(), visited_states)
			if instance_script != null:
				return instance_script

	return _get_scene_root_script(scene_state.get_base_scene_state(), visited_states)


func _script_inherits(script: Script, expected_base: Script) -> bool:
	var current_script: Script = script
	while current_script != null:
		if current_script == expected_base:
			return true
		current_script = current_script.get_base_script()
	return false
