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
	var first_model: CarModelDefinition = CATALOG.models[0].duplicate(true) as CarModelDefinition
	var second_model: CarModelDefinition = CATALOG.models[0].duplicate(true) as CarModelDefinition
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
	var automatic_variant: CarVariantDefinition = null
	for variant: CarVariantDefinition in missing_ai_scene.models[0].variants:
		if variant.ai_eligible:
			automatic_variant = variant
			break
	_expect(automatic_variant != null, "fixture contains an AI-eligible variant")
	if automatic_variant != null:
		automatic_variant.ai_car_scene = null
		_expect(_contains_error(missing_ai_scene.validate(), "ai_car_scene"), "AI-eligible variants without dedicated AI scenes are rejected")

	var manual_ai: CarCatalog = _single_model_catalog()
	var manual_variant: CarVariantDefinition = null
	for variant: CarVariantDefinition in manual_ai.models[0].variants:
		if variant.specs != null and variant.specs.is_manual_transmission():
			manual_variant = variant
			break
	_expect(manual_variant != null, "fixture contains a manual variant")
	if manual_variant != null:
		manual_variant.ai_eligible = true
		manual_variant.ai_car_scene = automatic_variant.ai_car_scene if automatic_variant != null else null
		_expect(_contains_error(manual_ai.validate(), "ai_eligible"), "manual AI variants are rejected")

	var duplicate_sort_order: CarCatalog = _single_model_catalog()
	duplicate_sort_order.models[0].variants[1].sort_order = duplicate_sort_order.models[0].variants[0].sort_order
	_expect(_contains_error(duplicate_sort_order.validate(), "sort_order must be unique"), "duplicate variant sort orders are rejected")


func _single_model_catalog() -> CarCatalog:
	var catalog: CarCatalog = CarCatalog.new()
	catalog.models = [CATALOG.models[0].duplicate(true) as CarModelDefinition]
	return catalog


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
