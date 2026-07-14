extends RefCounted
class_name CarVariantMenuOption

var variant_id: StringName
var label: String
var performance_index: int
var car_scene: PackedScene
var specs: CarSpecs
var engine_label: String
var drivetrain_label: String
var model_id: StringName
var model_label: String


func _init(
	id: StringName = &"",
	display_label: String = "",
	dpi: int = 0,
	preview_scene: PackedScene = null,
	technical_specs: CarSpecs = null,
	engine_description: String = "",
	drivetrain_description: String = "",
	source_model_id: StringName = &"",
	source_model_label: String = ""
) -> void:
	variant_id = id
	label = display_label
	performance_index = dpi
	car_scene = preview_scene
	specs = technical_specs
	engine_label = engine_description
	drivetrain_label = drivetrain_description
	model_id = source_model_id
	model_label = source_model_label


func is_valid() -> bool:
	return variant_id != &"" and not label.strip_edges().is_empty()


func has_technical_data() -> bool:
	return performance_index > 0 and specs != null and specs.is_valid()


func has_preview() -> bool:
	return car_scene != null and car_scene.can_instantiate()
