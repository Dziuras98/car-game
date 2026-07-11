extends Resource
class_name CarCatalog

@export_group("Models")
@export var models: Array[CarModelDefinition] = []


func is_valid() -> bool:
	return validate().is_empty()


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if models.is_empty():
		errors.append("models must contain at least one entry")

	var model_ids: Dictionary = {}
	var global_variant_ids: Dictionary = {}
	for model_index: int in range(models.size()):
		var model: CarModelDefinition = models[model_index]
		if model == null:
			errors.append("models[%d] must not be null" % model_index)
			continue

		var model_id_key: String = str(model.model_id)
		if not model_id_key.is_empty():
			if model_ids.has(model_id_key):
				errors.append("model_id must be globally unique: %s" % model_id_key)
			else:
				model_ids[model_id_key] = true

		for variant: CarVariantDefinition in model.variants:
			if variant == null or variant.variant_id == &"":
				continue
			var variant_id_key: String = str(variant.variant_id)
			if global_variant_ids.has(variant_id_key):
				errors.append("variant_id must be globally unique: %s" % variant_id_key)
			else:
				global_variant_ids[variant_id_key] = true

		for model_error: String in model.validate():
			errors.append("models[%d]: %s" % [model_index, model_error])
	return errors


func get_models() -> Array[CarModelDefinition]:
	var result: Array[CarModelDefinition] = []
	for model: CarModelDefinition in models:
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
