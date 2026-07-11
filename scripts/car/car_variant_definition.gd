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
