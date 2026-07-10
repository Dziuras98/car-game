extends Node

const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_catalog()
	_finish()


func _validate_catalog() -> void:
	_expect(CATALOG != null, "catalog resource loads")
	if CATALOG == null:
		return

	var models: Array[CarModelDefinition] = CATALOG.get_models()
	_expect(not models.is_empty(), "catalog exposes at least one car model")
	_expect(CATALOG.models.size() == models.size(), "catalog model entries are valid CarModelDefinition resources")

	var model_ids: Dictionary = {}
	var variant_ids: Dictionary = {}
	var all_variants: Array[CarVariantDefinition] = []

	for model: CarModelDefinition in models:
		_validate_model(model, model_ids, variant_ids, all_variants)

	var catalog_variants: Array[CarVariantDefinition] = CATALOG.get_all_variants()
	_expect(catalog_variants.size() == all_variants.size(), "catalog get_all_variants returns every validated model variant")
	_expect(CATALOG.get_variant_scene_list().size() == all_variants.size(), "catalog scene list contains one scene per variant")
	_expect(CATALOG.get_variant_menu_names().size() == all_variants.size(), "catalog menu-name list contains one name per variant")

	for variant: CarVariantDefinition in all_variants:
		_expect(CATALOG.get_variant_by_id(variant.variant_id) == variant, "catalog resolves variant id %s" % str(variant.variant_id))

	for model: CarModelDefinition in models:
		_expect(CATALOG.get_model_by_id(model.model_id) == model, "catalog resolves model id %s" % str(model.model_id))


func _validate_model(
	model: CarModelDefinition,
	model_ids: Dictionary,
	variant_ids: Dictionary,
	all_variants: Array[CarVariantDefinition]
) -> void:
	_expect(model != null, "model entry is not null")
	if model == null:
		return

	var model_id_key: String = str(model.model_id)
	_expect(model_id_key != "", "model has a non-empty model_id")
	_expect(not model_ids.has(model_id_key), "model id is unique: %s" % model_id_key)
	model_ids[model_id_key] = true

	_expect(model.get_model_name() != "", "model has a non-empty menu/display name")
	_expect(model.production_year_start <= model.production_year_end or model.production_year_end == 0, "model production-year range is coherent for %s" % model_id_key)

	var variants: Array[CarVariantDefinition] = model.get_variants()
	_expect(not variants.is_empty(), "model %s exposes at least one variant" % model_id_key)
	_expect(model.variants.size() == variants.size(), "model %s variant entries are valid CarVariantDefinition resources" % model_id_key)
	_expect(model.get_variant_count() == variants.size(), "model %s reports the same variant count as get_variants" % model_id_key)

	var default_count: int = 0
	var sort_orders: Dictionary = {}
	for i: int in range(variants.size()):
		var variant: CarVariantDefinition = variants[i]
		if variant != null and variant.is_default:
			default_count += 1
		_validate_variant(model_id_key, variant, i, variant_ids, sort_orders)
		if variant != null:
			all_variants.append(variant)

	_expect(default_count == 1, "model %s has exactly one default variant" % model_id_key)
	_expect(model.get_default_variant() != null, "model %s resolves a default variant" % model_id_key)

	for i: int in range(variants.size()):
		_expect(model.get_variant(i) == variants[i], "model %s resolves variant index %d" % [model_id_key, i])
	_expect(model.get_variant(-1) == null, "model %s rejects negative variant index" % model_id_key)
	_expect(model.get_variant(variants.size()) == null, "model %s rejects out-of-range variant index" % model_id_key)


func _validate_variant(
	model_id_key: String,
	variant: CarVariantDefinition,
	index: int,
	variant_ids: Dictionary,
	sort_orders: Dictionary
) -> void:
	_expect(variant != null, "model %s variant index %d is not null" % [model_id_key, index])
	if variant == null:
		return

	var variant_id_key: String = str(variant.variant_id)
	_expect(variant_id_key != "", "variant in model %s has a non-empty variant_id" % model_id_key)
	_expect(not variant_ids.has(variant_id_key), "variant id is globally unique: %s" % variant_id_key)
	variant_ids[variant_id_key] = true

	_expect(not sort_orders.has(variant.sort_order), "variant sort_order is unique inside model %s: %d" % [model_id_key, variant.sort_order])
	sort_orders[variant.sort_order] = true

	_expect(variant.get_menu_name() != "", "variant %s has a non-empty menu name" % variant_id_key)
	_expect(variant.get_car_scene() != null, "variant %s has a car scene" % variant_id_key)
	_expect(variant.get_specs() != null, "variant %s has CarSpecs" % variant_id_key)
	_expect(variant.engine_label != "", "variant %s has engine label" % variant_id_key)
	_expect(variant.transmission_label != "", "variant %s has transmission label" % variant_id_key)
	_expect(variant.drivetrain_label != "", "variant %s has drivetrain label" % variant_id_key)
	_expect(variant.mass_kg > 0.0, "variant %s has positive metadata mass" % variant_id_key)

	_validate_variant_scene(variant_id_key, variant)
	_validate_specs(variant_id_key, variant.get_specs())


func _validate_variant_scene(variant_id_key: String, variant: CarVariantDefinition) -> void:
	var car_scene: PackedScene = variant.get_car_scene()
	if car_scene == null:
		return

	var raw_instance: Node = car_scene.instantiate()
	var raw_controller: PlayerCarController = raw_instance as PlayerCarController
	_expect(raw_controller != null, "variant %s scene root is PlayerCarController" % variant_id_key)
	raw_instance.free()

	var factory: CarInstanceFactory = CarInstanceFactory.new()
	var scenes: Array[PackedScene] = [car_scene]
	var variants: Array[CarVariantDefinition] = [variant]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1
	factory.configure(scenes, variants, rng)
	var configured_controller: PlayerCarController = factory.instantiate_indexed_car(0)
	_expect(configured_controller != null, "variant %s instantiates through the catalog factory" % variant_id_key)
	if configured_controller != null:
		_expect(configured_controller.car_specs == variant.get_specs(), "variant %s receives authoritative catalog CarSpecs before tree entry" % variant_id_key)
		configured_controller.free()


func _validate_specs(variant_id_key: String, specs: CarSpecs) -> void:
	if specs == null:
		return

	_expect(specs.display_name != "", "variant %s specs have display name" % variant_id_key)
	_expect(specs.max_forward_speed > 0.0, "variant %s specs have positive max forward speed" % variant_id_key)
	_expect(specs.max_reverse_speed >= 0.0, "variant %s specs have non-negative max reverse speed" % variant_id_key)
	_expect(specs.brake_deceleration > 0.0, "variant %s specs have positive brake deceleration" % variant_id_key)
	_expect(specs.steering_speed > 0.0, "variant %s specs have positive steering speed" % variant_id_key)
	_expect(specs.wheel_base > 0.0, "variant %s specs have positive wheel base" % variant_id_key)
	_expect(specs.idle_rpm > 0.0, "variant %s specs have positive idle RPM" % variant_id_key)
	_expect(specs.redline_rpm > specs.idle_rpm, "variant %s specs redline is above idle RPM" % variant_id_key)
	_expect(specs.rev_limiter_rpm >= specs.redline_rpm, "variant %s specs rev limiter is at or above redline" % variant_id_key)
	_expect(specs.gear_ratios.size() > 0, "variant %s specs define at least one forward gear ratio" % variant_id_key)
	_expect(not (specs.manual_transmission_enabled and specs.automatic_transmission_enabled), "variant %s specs do not enable manual and automatic transmission at the same time" % variant_id_key)
	_expect(specs.manual_transmission_enabled or specs.automatic_transmission_enabled, "variant %s specs use an explicit transmission mode" % variant_id_key)
	_expect(specs.reverse_gear_ratio > 0.0, "variant %s specs have positive reverse gear ratio" % variant_id_key)
	_expect(specs.final_drive_ratio > 0.0, "variant %s specs have positive final drive ratio" % variant_id_key)
	_expect(specs.peak_engine_torque > 0.0, "variant %s specs have positive peak engine torque" % variant_id_key)
	_expect(specs.wheel_radius > 0.0, "variant %s specs have positive wheel radius" % variant_id_key)
	_expect(specs.vehicle_mass > 0.0, "variant %s specs have positive vehicle mass" % variant_id_key)
	_expect(specs.lateral_grip > 0.0, "variant %s specs have positive lateral grip" % variant_id_key)
	_expect(specs.slip_speed_threshold > 0.0, "variant %s specs have positive slip speed threshold" % variant_id_key)
	_expect(specs.skid_mark_interval > 0.0, "variant %s specs have positive skid mark interval" % variant_id_key)
	_expect(specs.skid_mark_lifetime > 0.0, "variant %s specs have positive skid mark lifetime" % variant_id_key)
	_expect(specs.skid_mark_width > 0.0, "variant %s specs have positive skid mark width" % variant_id_key)
	_expect(specs.skid_mark_length > 0.0, "variant %s specs have positive skid mark length" % variant_id_key)
	_expect(specs.gravity > 0.0, "variant %s specs have positive gravity" % variant_id_key)
	_expect(specs.floor_stick_force >= 0.0, "variant %s specs have non-negative floor stick force" % variant_id_key)

	for i: int in range(specs.gear_ratios.size()):
		_expect(specs.gear_ratios[i] > 0.0, "variant %s specs forward gear ratio %d is positive" % [variant_id_key, i + 1])


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_CATALOG_VALIDATION_TEST][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[CAR_CATALOG_VALIDATION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_CATALOG_VALIDATION_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return

	push_error("[CAR_CATALOG_VALIDATION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_CATALOG_VALIDATION_TEST] - %s" % failure_message)
	get_tree().quit(1)
