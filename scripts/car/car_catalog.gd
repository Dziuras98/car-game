extends Resource
class_name CarCatalog

@export_group("Models")
@export var models: Array[Resource] = []


func get_models() -> Array[CarModelDefinition]:
	var result: Array[CarModelDefinition] = []
	for model_resource: Resource in models:
		var model: CarModelDefinition = model_resource as CarModelDefinition
		if model != null:
			result.append(model)
	return result


func get_all_variants() -> Array[CarVariantDefinition]:
	var result: Array[CarVariantDefinition] = []
	for model: CarModelDefinition in get_models():
		for variant: CarVariantDefinition in model.get_variants():
			result.append(variant)
	return result


func get_variant_by_id(variant_id: StringName) -> CarVariantDefinition:
	for variant: CarVariantDefinition in get_all_variants():
		if variant.variant_id == variant_id:
			return variant
	return null


func get_model_by_id(model_id: StringName) -> CarModelDefinition:
	for model: CarModelDefinition in get_models():
		if model.model_id == model_id:
			return model
	return null


func get_variant_scene_list() -> Array[PackedScene]:
	var result: Array[PackedScene] = []
	for variant: CarVariantDefinition in get_all_variants():
		if variant.car_scene != null:
			result.append(variant.car_scene)
	return result


func get_variant_menu_names() -> Array[String]:
	var result: Array[String] = []
	for variant: CarVariantDefinition in get_all_variants():
		result.append(variant.get_menu_name())
	return result
