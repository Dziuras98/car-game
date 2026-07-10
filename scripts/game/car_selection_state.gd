extends RefCounted
class_name CarSelectionState

var _available_car_variants: Array[CarVariantDefinition] = []


func configure(car_catalog: CarCatalog) -> void:
	_available_car_variants.clear()
	if car_catalog == null:
		return
	_available_car_variants = car_catalog.get_all_variants()


func get_available_car_variants() -> Array[CarVariantDefinition]:
	return _available_car_variants.duplicate()


func has_available_options() -> bool:
	return not _available_car_variants.is_empty()


func get_available_car_count() -> int:
	return _available_car_variants.size()


func get_valid_car_index(car_index: int) -> int:
	if _available_car_variants.is_empty():
		return -1
	return clampi(car_index, 0, _available_car_variants.size() - 1)


func get_car_index_for_variant_id(car_variant_id: StringName) -> int:
	for variant_index: int in range(_available_car_variants.size()):
		var variant: CarVariantDefinition = _available_car_variants[variant_index]
		if variant != null and variant.variant_id == car_variant_id:
			return variant_index
	return -1


func get_variant_id_for_index(car_index: int) -> StringName:
	if car_index < 0 or car_index >= _available_car_variants.size():
		return &""
	return _available_car_variants[car_index].variant_id
