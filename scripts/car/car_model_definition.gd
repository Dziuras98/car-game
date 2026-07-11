extends Resource
class_name CarModelDefinition

@export_group("Identity")
@export var manufacturer: String = ""
@export var model_id: StringName = &""
@export var display_name: String = ""
@export var generation: String = ""
@export var production_year_start: int = 0
@export var production_year_end: int = 0

@export_group("Variants")
@export var variants: Array[CarVariantDefinition] = []
@export var default_variant_id: StringName = &""


func is_valid() -> bool:
	return validate().is_empty()


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if manufacturer.strip_edges().is_empty():
		errors.append("manufacturer must not be empty")
	if model_id == &"":
		errors.append("model_id must not be empty")
	if display_name.strip_edges().is_empty():
		errors.append("display_name must not be empty")
	if production_year_start < 0:
		errors.append("production_year_start must be non-negative")
	if production_year_end < 0:
		errors.append("production_year_end must be non-negative")
	if production_year_end > 0 and production_year_start > production_year_end:
		errors.append("production_year_end must be at or after production_year_start")
	if variants.is_empty():
		errors.append("variants must contain at least one entry")

	var variant_ids: Dictionary = {}
	var sort_orders: Dictionary = {}
	for variant_index: int in range(variants.size()):
		var variant: CarVariantDefinition = variants[variant_index]
		if variant == null:
			errors.append("variants[%d] must not be null" % variant_index)
			continue
		var variant_id_key: String = str(variant.variant_id)
		if not variant_id_key.is_empty():
			if variant_ids.has(variant_id_key):
				errors.append("variant_id must be unique inside model: %s" % variant_id_key)
			else:
				variant_ids[variant_id_key] = true
		if sort_orders.has(variant.sort_order):
			errors.append("sort_order must be unique inside model: %d" % variant.sort_order)
		else:
			sort_orders[variant.sort_order] = true
		for variant_error: String in variant.validate():
			errors.append("variants[%d]: %s" % [variant_index, variant_error])

	if default_variant_id == &"":
		errors.append("default_variant_id must not be empty")
	elif get_variant_by_id(default_variant_id) == null:
		errors.append("default_variant_id must reference a variant in this model")
	return errors


func get_model_name() -> String:
	if manufacturer != "" and display_name != "":
		return "%s %s" % [manufacturer, display_name]
	if display_name != "":
		return display_name
	return str(model_id)


func get_variants() -> Array[CarVariantDefinition]:
	var result: Array[CarVariantDefinition] = []
	for variant: CarVariantDefinition in variants:
		if variant != null:
			result.append(variant)
	result.sort_custom(_sort_variants)
	return result


func get_variant_by_id(variant_id: StringName) -> CarVariantDefinition:
	for variant: CarVariantDefinition in get_variants():
		if variant.variant_id == variant_id:
			return variant
	return null


func get_default_variant() -> CarVariantDefinition:
	if default_variant_id == &"":
		return null
	return get_variant_by_id(default_variant_id)


func get_variant_count() -> int:
	return get_variants().size()


func get_variant(index: int) -> CarVariantDefinition:
	var available_variants: Array[CarVariantDefinition] = get_variants()
	if index < 0 or index >= available_variants.size():
		return null
	return available_variants[index]


static func _sort_variants(left: CarVariantDefinition, right: CarVariantDefinition) -> bool:
	if left == null:
		return false
	if right == null:
		return true
	return left.sort_order < right.sort_order
