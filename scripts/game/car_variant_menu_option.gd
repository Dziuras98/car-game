extends RefCounted
class_name CarVariantMenuOption

var variant_id: StringName
var label: String


func _init(id: StringName = &"", display_label: String = "") -> void:
	variant_id = id
	label = display_label


func is_valid() -> bool:
	return variant_id != &"" and not label.strip_edges().is_empty()
