extends SceneTree

const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	for variant: CarVariantDefinition in CATALOG.get_all_variants():
		_test_variant(variant)
	_test_empty_variant()
	_finish()


func _test_variant(variant: CarVariantDefinition) -> void:
	_expect(variant != null and variant.specs != null, "catalog variant exposes authoritative specs")
	if variant == null or variant.specs == null:
		return
	_expect(variant.specs.vehicle_mass > 0.0, "%s exposes positive mass through authoritative specs" % str(variant.variant_id))
	var transmission_label: String = variant.get_transmission_label()
	if variant.specs.is_cvt_transmission():
		_expect(transmission_label == "CVT", "%s CVT enum produces a CVT label" % str(variant.variant_id))
	else:
		var expected_gear_count: String = str(variant.specs.gear_ratios.size())
		_expect(expected_gear_count in transmission_label, "%s transmission label reflects the configured gear count" % str(variant.variant_id))
	if variant.specs.is_manual_transmission():
		_expect("manual" in transmission_label.to_lower(), "%s manual enum produces a manual label" % str(variant.variant_id))
	elif variant.specs.is_automatic_transmission():
		_expect("automatic" in transmission_label.to_lower(), "%s automatic enum produces an automatic label" % str(variant.variant_id))


func _test_empty_variant() -> void:
	var variant: CarVariantDefinition = CarVariantDefinition.new()
	_expect(variant.get_transmission_label().is_empty(), "variant without specs exposes an empty derived transmission label")
	_expect(variant.get_menu_name().is_empty(), "empty variant menu name remains safe")


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_VARIANT_METADATA_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CAR_VARIANT_METADATA_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_VARIANT_METADATA_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CAR_VARIANT_METADATA_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_VARIANT_METADATA_TEST] - %s" % failure_message)
	quit(1)
