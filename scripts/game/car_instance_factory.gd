extends RefCounted
class_name CarInstanceFactory

var _available_variants: Array[CarVariantDefinition] = []
var _rng: RandomNumberGenerator


func configure(
	available_car_variants: Array[CarVariantDefinition],
	rng: RandomNumberGenerator
) -> void:
	_available_variants = available_car_variants.duplicate()
	_rng = rng


func has_available_cars() -> bool:
	return not _available_variants.is_empty()


func get_available_count() -> int:
	return _available_variants.size()


func instantiate_indexed_car(car_index: int) -> PlayerCarController:
	if car_index < 0 or car_index >= _available_variants.size():
		push_error("Car index %d is outside the configured catalog range." % car_index)
		return null
	return _instantiate_variant(_available_variants[car_index])


func instantiate_opponent_car() -> PlayerCarController:
	if _available_variants.is_empty():
		return null
	return _instantiate_variant(_get_opponent_variant())


func _get_opponent_variant() -> CarVariantDefinition:
	var automatic_variants: Array[CarVariantDefinition] = []
	for variant: CarVariantDefinition in _available_variants:
		if variant == null:
			continue
		var specs: CarSpecs = variant.get_specs()
		if specs != null and specs.is_valid() and specs.is_automatic_transmission():
			automatic_variants.append(variant)

	var source: Array[CarVariantDefinition] = automatic_variants
	if source.is_empty():
		source = _available_variants

	var selected_index: int = 0
	if _rng != null:
		selected_index = _rng.randi_range(0, source.size() - 1)
	return source[selected_index]


func _instantiate_variant(variant: CarVariantDefinition) -> PlayerCarController:
	if variant == null:
		return null

	var specs: CarSpecs = variant.get_specs()
	if not _validate_specs(specs, "Car variant %s" % str(variant.variant_id)):
		return null

	var car_scene: PackedScene = variant.get_car_scene()
	if car_scene == null:
		push_error("Car variant %s must provide a car scene." % str(variant.variant_id))
		return null

	var car_instance: Node = car_scene.instantiate()
	var car_controller: PlayerCarController = car_instance as PlayerCarController
	if car_controller == null:
		push_error("Car variant %s scene must have PlayerCarController on its root node." % str(variant.variant_id))
		car_instance.queue_free()
		return null

	# Catalog data is authoritative and is applied before the node enters a tree.
	car_controller.car_specs = specs
	return car_controller


func _validate_specs(specs: CarSpecs, context: String) -> bool:
	if specs == null:
		push_error("%s must provide a non-null CarSpecs resource." % context)
		return false
	var validation_errors: PackedStringArray = specs.validate()
	if validation_errors.is_empty():
		return true
	push_error("%s has invalid CarSpecs: %s" % [context, "; ".join(validation_errors)])
	return false
