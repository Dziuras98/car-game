extends SceneTree

const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run()
	_finish()


func _run() -> void:
	_expect(CATALOG.validate().is_empty(), "production catalog passes the authoritative validation contract")

	var duplicate_models: CarCatalog = CarCatalog.new()
	var first_model: CarModelDefinition = _duplicate_model(CATALOG.models[0])
	var second_model: CarModelDefinition = _duplicate_model(CATALOG.models[0])
	duplicate_models.models = [first_model, second_model]
	_expect(_contains_error(duplicate_models.validate(), "model_id must be globally unique"), "duplicate model IDs are rejected")
	_expect(_contains_error(duplicate_models.validate(), "variant_id must be globally unique"), "duplicate variant IDs across models are rejected")

	var invalid_default: CarCatalog = _single_model_catalog()
	invalid_default.models[0].default_variant_id = &"missing"
	_expect(_contains_error(invalid_default.validate(), "default_variant_id"), "missing default variants are rejected")

	var invalid_years: CarCatalog = _single_model_catalog()
	invalid_years.models[0].production_year_start = 2025
	invalid_years.models[0].production_year_end = 2020
	_expect(_contains_error(invalid_years.validate(), "production_year_end"), "incoherent production years are rejected")

	var missing_scene: CarCatalog = _single_model_catalog()
	missing_scene.models[0].variants[0].car_scene = null
	_expect(_contains_error(missing_scene.validate(), "car_scene"), "variants without player scenes are rejected")

	var missing_ai_scene: CarCatalog = _single_model_catalog()
	var automatic_variant: CarVariantDefinition = _find_automatic_variant(missing_ai_scene)
	_expect(automatic_variant != null, "fixture contains an AI-eligible automatic variant")
	if automatic_variant != null:
		automatic_variant.ai_car_scene = null
		_expect(_contains_error(missing_ai_scene.validate(), "ai_car_scene"), "AI-eligible variants without dedicated AI scenes are rejected")

	var manual_ai: CarCatalog = _single_model_catalog()
	var manual_variant: CarVariantDefinition = _find_manual_variant(manual_ai)
	_expect(manual_variant != null, "fixture contains a manual variant")
	if manual_variant != null:
		manual_variant.ai_eligible = true
		manual_variant.ai_car_scene = _get_production_ai_scene()
		_expect(manual_ai.validate().is_empty(), "manual variants with dedicated AI scenes are accepted")
		_expect(manual_variant.is_ai_eligible_for_race(), "manual variants satisfy the runtime AI eligibility contract")

	var direct_drive_ai: CarCatalog = _single_model_catalog()
	var direct_drive_variant: CarVariantDefinition = _find_manual_variant(direct_drive_ai)
	_expect(direct_drive_variant != null, "fixture provides a variant for unsupported transmission validation")
	if direct_drive_variant != null:
		direct_drive_variant.specs = direct_drive_variant.specs.duplicate(true) as CarSpecs
		direct_drive_variant.specs.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
		direct_drive_variant.ai_eligible = true
		direct_drive_variant.ai_car_scene = _get_production_ai_scene()
		_expect(_contains_error(direct_drive_ai.validate(), "geared transmission"), "AI variants without a geared transmission are rejected")

	var duplicate_sort_order: CarCatalog = _single_model_catalog()
	duplicate_sort_order.models[0].variants[1].sort_order = duplicate_sort_order.models[0].variants[0].sort_order
	_expect(_contains_error(duplicate_sort_order.validate(), "sort_order must be unique"), "duplicate variant sort orders are rejected")


func _single_model_catalog() -> CarCatalog:
	var catalog: CarCatalog = CarCatalog.new()
	catalog.models = [_duplicate_model(CATALOG.models[0])]
	return catalog


func _duplicate_model(source: CarModelDefinition) -> CarModelDefinition:
	var model: CarModelDefinition = source.duplicate(false) as CarModelDefinition
	var variants: Array[CarVariantDefinition] = []
	for source_variant: CarVariantDefinition in source.variants:
		variants.append(source_variant.duplicate(true) as CarVariantDefinition)
	model.variants = variants
	return model


func _find_manual_variant(catalog: CarCatalog) -> CarVariantDefinition:
	for variant: CarVariantDefinition in catalog.models[0].variants:
		if variant.specs != null and variant.specs.is_manual_transmission():
			return variant
	return null


func _find_automatic_variant(catalog: CarCatalog) -> CarVariantDefinition:
	for variant: CarVariantDefinition in catalog.models[0].variants:
		if variant.specs != null and variant.specs.is_automatic_transmission():
			return variant
	return null


func _get_production_ai_scene() -> PackedScene:
	for variant: CarVariantDefinition in CATALOG.get_all_variants():
		if variant.ai_car_scene != null:
			return variant.ai_car_scene
	return null


func _contains_error(errors: PackedStringArray, fragment: String) -> bool:
	for error_text: String in errors:
		if fragment in error_text:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_CATALOG_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CAR_CATALOG_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_CATALOG_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CAR_CATALOG_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_CATALOG_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
