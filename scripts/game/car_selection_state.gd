extends RefCounted
class_name CarSelectionState

var _available_car_variants: Array[CarVariantDefinition] = []
var _available_car_scenes: Array[PackedScene] = []


func configure(car_catalog: CarCatalog, fallback_car_scenes: Array[PackedScene]) -> void:
	_available_car_variants.clear()
	_available_car_scenes.clear()

	if car_catalog != null:
		_available_car_variants = car_catalog.get_all_variants()
		_available_car_scenes = car_catalog.get_variant_scene_list()

	if _available_car_scenes.is_empty():
		_available_car_scenes = fallback_car_scenes.duplicate()


func get_available_car_variants() -> Array[CarVariantDefinition]:
	return _available_car_variants


func get_available_car_scenes() -> Array[PackedScene]:
	return _available_car_scenes


func has_available_options() -> bool:
	return not _available_car_variants.is_empty() or not _available_car_scenes.is_empty()


func get_available_car_count() -> int:
	if not _available_car_variants.is_empty():
		return _available_car_variants.size()
	return _available_car_scenes.size()


func get_valid_car_index(car_index: int) -> int:
	var available_count: int = get_available_car_count()
	if available_count <= 0:
		return 0
	return clampi(car_index, 0, available_count - 1)


func get_car_index_for_variant_id(car_variant_id: StringName) -> int:
	if not _available_car_variants.is_empty():
		for variant_index: int in range(_available_car_variants.size()):
			var variant: CarVariantDefinition = _available_car_variants[variant_index]
			if variant != null and variant.variant_id == car_variant_id:
				return variant_index
		push_warning("Car variant id '%s' was not found; falling back to car index 0." % str(car_variant_id))
		return 0

	return get_valid_car_index(int(str(car_variant_id)))


func get_variant_id_for_index(car_index: int) -> StringName:
	if car_index < 0 or car_index >= _available_car_variants.size():
		return &""
	return _available_car_variants[car_index].variant_id


func get_variant_id_for_spawner_index(car_index: int, fallback_variant_id: StringName) -> StringName:
	var variant_id: StringName = get_variant_id_for_index(car_index)
	if variant_id.is_empty():
		return fallback_variant_id
	return variant_id
