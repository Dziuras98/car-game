extends RefCounted
class_name CarInstanceFactory

const VARIANT_ID_METADATA: StringName = &"car_variant_id"

var _available_variants: Array[CarVariantDefinition] = []
var _ai_eligible_variants: Array[CarVariantDefinition] = []
var _rng: RandomNumberGenerator


func configure(available_car_variants: Array[CarVariantDefinition], rng: RandomNumberGenerator) -> void:
	_available_variants = available_car_variants.duplicate()
	_ai_eligible_variants.clear()
	for variant: CarVariantDefinition in _available_variants:
		if variant != null and variant.is_ai_eligible_for_race():
			_ai_eligible_variants.append(variant)
	_rng = rng


func has_available_cars() -> bool:
	return not _available_variants.is_empty()


func has_ai_eligible_cars() -> bool:
	return not _ai_eligible_variants.is_empty()


func get_available_count() -> int:
	return _available_variants.size()


func get_ai_eligible_count() -> int:
	return _ai_eligible_variants.size()


func capture_random_state() -> int:
	return _rng.state if _rng != null else 0


func restore_random_state(state: int) -> void:
	if _rng != null:
		_rng.state = state


func instantiate_indexed_car(car_index: int) -> PlayerCarController:
	if car_index < 0 or car_index >= _available_variants.size():
		push_error("Car index %d is outside the configured catalog range." % car_index)
		return null
	return _instantiate_variant(_available_variants[car_index])


func instantiate_opponent_car() -> PlayerCarController:
	if _ai_eligible_variants.is_empty():
		push_error("CarInstanceFactory requires at least one explicit AI-eligible variant.")
		return null
	return _instantiate_variant(_get_opponent_variant())


func _get_opponent_variant() -> CarVariantDefinition:
	var selected_index: int = 0
	if _rng != null:
		selected_index = _rng.randi_range(0, _ai_eligible_variants.size() - 1)
	return _ai_eligible_variants[selected_index]


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
	car_controller.car_specs = specs
	car_controller.set_meta(VARIANT_ID_METADATA, variant.variant_id)
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
