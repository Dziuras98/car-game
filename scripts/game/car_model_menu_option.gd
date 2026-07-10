extends RefCounted
class_name CarModelMenuOption

var model_id: StringName
var label: String
var variants: Array[CarVariantMenuOption] = []


func _init(
	id: StringName = &"",
	display_label: String = "",
	variant_options: Array[CarVariantMenuOption] = []
) -> void:
	model_id = id
	label = display_label
	variants = variant_options.duplicate()


func is_valid() -> bool:
	if model_id == &"" or label.strip_edges().is_empty() or variants.is_empty():
		return false
	for variant: CarVariantMenuOption in variants:
		if variant == null or not variant.is_valid():
			return false
	return true
