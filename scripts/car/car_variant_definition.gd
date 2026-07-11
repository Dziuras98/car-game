extends Resource
class_name CarVariantDefinition

@export_group("Identity")
@export var variant_id: StringName = &""
@export var display_name: String = ""
@export var sort_order: int = 0

@export_group("Runtime")
@export var car_scene: PackedScene
@export var specs: CarSpecs
@export var ai_eligible: bool = false

@export_group("Metadata")
@export var engine_label: String = ""
@export var drivetrain_label: String = ""

# Compatibility accessors retained for callers that used the former duplicated
# metadata fields. Values are always derived from CarSpecs so they cannot drift.
var transmission_label: String:
	get:
		return get_transmission_label()

var mass_kg: float:
	get:
		return get_mass_kg()


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
	if specs == null:
		errors.append("specs must not be null")
	else:
		for specs_error: String in specs.validate():
			errors.append("specs: %s" % specs_error)
	if engine_label.strip_edges().is_empty():
		errors.append("engine_label must not be empty")
	if drivetrain_label.strip_edges().is_empty():
		errors.append("drivetrain_label must not be empty")
	if ai_eligible and specs != null and not specs.is_automatic_transmission():
		errors.append("ai_eligible variants must use an automatic transmission")
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


func is_ai_eligible_for_race() -> bool:
	return (
		ai_eligible
		and car_scene != null
		and specs != null
		and specs.is_valid()
		and specs.is_automatic_transmission()
	)


func get_transmission_label() -> String:
	if specs == null:
		return ""
	var forward_gear_count: int = specs.gear_ratios.size()
	if specs.is_manual_transmission():
		return "%d-speed manual" % forward_gear_count
	if specs.is_automatic_transmission():
		return "%d-speed automatic" % forward_gear_count
	return "Direct drive"


func get_mass_kg() -> float:
	return specs.vehicle_mass if specs != null else 0.0
