extends RefCounted
class_name CarInstanceFactory

var _available_cars: Array[PackedScene] = []
var _available_variants: Array[CarVariantDefinition] = []
var _rng: RandomNumberGenerator


func configure(
	available_car_scenes: Array[PackedScene],
	available_car_variants: Array[CarVariantDefinition],
	rng: RandomNumberGenerator
) -> void:
	_available_cars = available_car_scenes.duplicate()
	_available_variants = available_car_variants.duplicate()
	_rng = rng


func has_available_cars() -> bool:
	return get_available_count() > 0


func get_available_count() -> int:
	if not _available_variants.is_empty():
		return _available_variants.size()
	return _available_cars.size()


func instantiate_indexed_car(car_index: int) -> PlayerCarController:
	if car_index < 0 or car_index >= get_available_count():
		push_error("Car index %d is outside the configured factory range." % car_index)
		return null

	if not _available_variants.is_empty():
		return _instantiate_variant(_available_variants[car_index])

	return _instantiate_car(_available_cars[car_index], true)


func instantiate_opponent_car() -> PlayerCarController:
	if not _available_variants.is_empty():
		return _instantiate_variant(_get_opponent_variant())

	return _instantiate_automatic_fallback_car()


func _get_opponent_variant() -> CarVariantDefinition:
	var automatic_variants: Array[CarVariantDefinition] = []
	for variant: CarVariantDefinition in _available_variants:
		if variant == null:
			continue
		var specs: CarSpecs = variant.get_specs()
		if specs != null and specs.is_valid() and specs.automatic_transmission_enabled:
			automatic_variants.append(variant)

	var source: Array[CarVariantDefinition] = automatic_variants
	if source.is_empty():
		source = _available_variants
	if source.is_empty():
		return null

	var selected_index: int = 0
	if _rng != null:
		selected_index = _rng.randi_range(0, source.size() - 1)
	return source[selected_index]


func _instantiate_automatic_fallback_car() -> PlayerCarController:
	if _available_cars.is_empty():
		return null

	var start_index: int = 0
	if _rng != null:
		start_index = _rng.randi_range(0, _available_cars.size() - 1)
	for offset: int in range(_available_cars.size()):
		var car_index: int = (start_index + offset) % _available_cars.size()
		var candidate: PlayerCarController = _instantiate_car(_available_cars[car_index], true)
		if candidate == null:
			continue
		if candidate.car_specs.automatic_transmission_enabled:
			return candidate
		candidate.queue_free()

	push_warning("No fallback car scene provides automatic CarSpecs; using a random configured scene.")
	return _instantiate_car(_available_cars[start_index], true)


func _instantiate_variant(variant: CarVariantDefinition) -> PlayerCarController:
	if variant == null:
		return null

	var specs: CarSpecs = variant.get_specs()
	if not _validate_specs(specs, "Car variant %s" % str(variant.variant_id)):
		return null

	# Catalog data is authoritative. A reusable visual/controller scene may be
	# intentionally unconfigured; assign the variant specs before tree entry.
	var car_controller: PlayerCarController = _instantiate_car(variant.get_car_scene(), false)
	if car_controller == null:
		return null

	car_controller.car_specs = specs
	return car_controller


func _instantiate_car(car_scene: PackedScene, require_scene_specs: bool) -> PlayerCarController:
	if car_scene == null:
		return null

	var car_instance: Node = car_scene.instantiate()
	var car_controller: PlayerCarController = car_instance as PlayerCarController

	if car_controller == null:
		push_error("Car scene must have PlayerCarController on its root node.")
		car_instance.queue_free()
		return null

	if require_scene_specs and not _validate_specs(car_controller.car_specs, "Fallback car scene"):
		car_instance.queue_free()
		return null

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
