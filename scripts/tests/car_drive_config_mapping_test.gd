extends SceneTree

const MANUAL_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")
const AUTOMATIC_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run()
	_finish()


func _run() -> void:
	_expect(
		CarDriveConfigBuilder.get_unmapped_specs_properties(MANUAL_SPECS).is_empty(),
		"every runtime CarSpecs property has an explicit CarDriveConfig destination"
	)

	var manual_config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(MANUAL_SPECS)
	var automatic_config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(AUTOMATIC_SPECS)
	_expect(manual_config != null, "manual specs build a runtime configuration")
	_expect(automatic_config != null, "automatic specs build a runtime configuration")
	if manual_config == null or automatic_config == null:
		return

	_expect(manual_config.transmission_type == CarSpecs.TransmissionType.MANUAL, "manual transmission enum is preserved")
	_expect(automatic_config.transmission_type == CarSpecs.TransmissionType.AUTOMATIC, "automatic transmission enum is preserved")
	_expect(manual_config.is_manual_transmission() and not manual_config.is_automatic_transmission(), "manual runtime configuration exposes one exclusive mode")
	_expect(automatic_config.is_automatic_transmission() and not automatic_config.is_manual_transmission(), "automatic runtime configuration exposes one exclusive mode")
	_expect(is_equal_approx(manual_config.vehicle_mass, MANUAL_SPECS.vehicle_mass), "vehicle mass is reflected into runtime configuration")
	_expect(is_equal_approx(automatic_config.automatic_upshift_rpm, AUTOMATIC_SPECS.automatic_upshift_rpm), "automatic shift data is reflected into runtime configuration")
	_expect(manual_config.gear_ratios == MANUAL_SPECS.gear_ratios, "gear ratios retain their configured values")

	var original_first_ratio: float = MANUAL_SPECS.gear_ratios[0]
	manual_config.gear_ratios[0] += 1.0
	_expect(is_equal_approx(MANUAL_SPECS.gear_ratios[0], original_first_ratio), "runtime gear ratio arrays are deep-copied from resources")

	var duplicate: CarDriveConfig = automatic_config.duplicate_config()
	_expect(duplicate != automatic_config, "duplicate_config returns a distinct runtime object")
	_expect(duplicate.transmission_type == automatic_config.transmission_type, "duplicate_config preserves transmission enum")
	var automatic_first_ratio: float = automatic_config.gear_ratios[0]
	duplicate.gear_ratios[0] += 2.0
	_expect(is_equal_approx(automatic_config.gear_ratios[0], automatic_first_ratio), "duplicate_config deep-copies mutable arrays")

	var exclusive_config: CarDriveConfig = CarDriveConfig.new()
	exclusive_config.manual_transmission_enabled = true
	exclusive_config.automatic_transmission_enabled = true
	_expect(exclusive_config.is_automatic_transmission(), "compatibility setters resolve to the last selected transmission mode")
	_expect(not exclusive_config.is_manual_transmission(), "runtime configuration cannot expose two transmission modes")


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_DRIVE_CONFIG_MAPPING_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CAR_DRIVE_CONFIG_MAPPING_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_DRIVE_CONFIG_MAPPING_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CAR_DRIVE_CONFIG_MAPPING_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_DRIVE_CONFIG_MAPPING_TEST] - %s" % failure_message)
	quit(1)
