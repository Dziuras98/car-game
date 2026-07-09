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
	_available_cars = available_car_scenes
	_available_variants = available_car_variants
	_rng = rng


func has_available_cars() -> bool:
	return get_available_count() > 0


func get_available_count() -> int:
	if not _available_variants.is_empty():
		return _available_variants.size()
	return _available_cars.size()


func instantiate_indexed_car(car_index: int) -> PlayerCarController:
	if not _available_variants.is_empty():
		return _instantiate_variant(_available_variants[car_index])

	return _instantiate_car(_available_cars[car_index])


func instantiate_opponent_car() -> PlayerCarController:
	if not _available_variants.is_empty():
		return _instantiate_variant(_get_opponent_variant())

	if _available_cars.is_empty():
		return null

	var car_controller: PlayerCarController = _instantiate_car(_available_cars[_rng.randi_range(0, _available_cars.size() - 1)])
	if car_controller != null:
		car_controller.manual_transmission_enabled = false
		car_controller.automatic_transmission_enabled = true
	return car_controller


func _get_opponent_variant() -> CarVariantDefinition:
	var automatic_variants: Array[CarVariantDefinition] = []
	for variant: CarVariantDefinition in _available_variants:
		if variant == null:
			continue
		var specs: CarSpecs = variant.get_specs()
		if specs == null or specs.automatic_transmission_enabled:
			automatic_variants.append(variant)

	if not automatic_variants.is_empty():
		return automatic_variants[_rng.randi_range(0, automatic_variants.size() - 1)]

	return _available_variants[_rng.randi_range(0, _available_variants.size() - 1)]


func _instantiate_variant(variant: CarVariantDefinition) -> PlayerCarController:
	if variant == null:
		return null

	var car_controller: PlayerCarController = _instantiate_car(variant.get_car_scene())
	if car_controller == null:
		return null

	if variant.get_specs() != null:
		car_controller.car_specs = variant.get_specs()
	return car_controller


func _instantiate_car(car_scene: PackedScene) -> PlayerCarController:
	if car_scene == null:
		return null

	var car_instance: Node = car_scene.instantiate()
	var car_controller: PlayerCarController = car_instance as PlayerCarController

	if car_controller == null:
		push_error("Car scene must have PlayerCarController on its root node.")
		car_instance.queue_free()
		return null

	return car_controller
