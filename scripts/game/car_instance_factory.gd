extends RefCounted
class_name CarInstanceFactory

const VARIANT_ID_METADATA: StringName = &"car_variant_id"

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


func has_ai_eligible_cars() -> bool:
	return false


func get_available_count() -> int:
	return _available_variants.size()


func get_ai_eligible_count() -> int:
	return 0


func get_random_available_index_excluding(excluded_index: int) -> int:
	var available_count: int = _available_variants.size()
	if available_count <= 0:
		return -1
	if excluded_index < 0 or excluded_index >= available_count:
		return _rng.randi_range(0, available_count - 1) if _rng != null else 0
	if available_count == 1:
		return -1
	var selected_index: int = _rng.randi_range(0, available_count - 2) if _rng != null else 0
	if selected_index >= excluded_index:
		selected_index += 1
	return selected_index


func capture_random_state() -> int:
	return _rng.state if _rng != null else 0


func restore_random_state(state: int) -> void:
	if _rng != null:
		_rng.state = state


func instantiate_indexed_car(car_index: int) -> PlayerCarController:
	if car_index < 0 or car_index >= _available_variants.size():
		push_error("Car index %d is outside the configured catalog range." % car_index)
		return null
	var variant: CarVariantDefinition = _available_variants[car_index]
	if variant == null:
		push_error("Car index %d resolves to a null variant." % car_index)
		return null
	return _instantiate_variant_scene(variant)


func instantiate_opponent_car() -> PlayerCarController:
	push_error("Opponent cars were removed with race mode.")
	return null


func _instantiate_variant_scene(variant: CarVariantDefinition) -> PlayerCarController:
	if variant == null:
		return null
	var specs: CarSpecs = variant.get_specs()
	if not _validate_specs(specs, "Car variant %s" % str(variant.variant_id)):
		return null
	var car_scene: PackedScene = variant.get_car_scene()
	if car_scene == null:
		push_error("Car variant %s must provide a player car scene." % str(variant.variant_id))
		return null
	var car_instance: Node = car_scene.instantiate()
	var car_controller: PlayerCarController = car_instance as PlayerCarController
	if car_controller == null:
		push_error("Car variant %s scene must have PlayerCarController on its root node." % str(variant.variant_id))
		car_instance.queue_free()
		return null
	car_controller.car_specs = specs
	_apply_engine_audio_profile(car_controller, specs)
	car_controller.set_meta(VARIANT_ID_METADATA, variant.variant_id)
	return car_controller


func _apply_engine_audio_profile(
	car_controller: PlayerCarController,
	specs: CarSpecs
) -> void:
	if car_controller == null or specs == null or specs.engine_audio_profile == null:
		return
	var engine_audio: ProfiledEngineAudioSynthesizer = (
		car_controller.get_node_or_null(^"EngineAudio") as ProfiledEngineAudioSynthesizer
	)
	if engine_audio != null:
		engine_audio.profile = specs.engine_audio_profile


func _validate_specs(specs: CarSpecs, context: String) -> bool:
	if specs == null:
		push_error("%s must provide a non-null CarSpecs resource." % context)
		return false
	var validation_errors: PackedStringArray = specs.validate()
	if validation_errors.is_empty():
		return true
	push_error("%s has invalid CarSpecs: %s" % [context, "; ".join(validation_errors)])
	return false
