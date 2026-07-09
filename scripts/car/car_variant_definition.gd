extends Resource
class_name CarVariantDefinition

@export_group("Identity")
@export var variant_id: StringName = &""
@export var display_name: String = ""
@export var sort_order: int = 0
@export var is_default: bool = false

@export_group("Runtime")
@export var car_scene: PackedScene
@export var specs: CarSpecs

@export_group("Metadata")
@export var engine_label: String = ""
@export var transmission_label: String = ""
@export var drivetrain_label: String = ""
@export var mass_kg: float = 0.0


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
