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
@export var variants: Array[Resource] = []


func get_model_name() -> String:
	if manufacturer != "" and display_name != "":
		return "%s %s" % [manufacturer, display_name]
	if display_name != "":
		return display_name
	return str(model_id)


func get_variants() -> Array[CarVariantDefinition]:
	var result: Array[CarVariantDefinition] = []
	for variant_resource: Resource in variants:
		var variant: CarVariantDefinition = variant_resource as CarVariantDefinition
		if variant != null:
			result.append(variant)
	result.sort_custom(_sort_variants)
	return result


func get_default_variant() -> CarVariantDefinition:
	var available_variants: Array[CarVariantDefinition] = get_variants()
	for variant: CarVariantDefinition in available_variants:
		if variant.is_default:
			return variant
	if not available_variants.is_empty():
		return available_variants[0]
	return null


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
