extends SceneTree

const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const BMW_DYNAMICS_PATHS: Array[String] = [
	"res://resources/cars/bmw/e46_sedan/data/bmw_e46_sedan_drivetrain_dynamics_petrol.data",
	"res://resources/cars/bmw/e46_sedan/data/bmw_e46_sedan_drivetrain_dynamics_diesel.data",
]
const EXPECTED_LEGACY_CALIBRATIONS: Dictionary = {
	&"nissan_370z_7at": Vector4(1.02, 0.11, 0.82, 10.0),
	&"nissan_370z_6mt": Vector4(1.02, 0.11, 0.82, 10.0),
	&"nissan_370z_nismo_6mt_eu": Vector4(1.08, 0.10, 0.84, 10.5),
	&"nissan_370z_nismo_7at_global": Vector4(1.08, 0.10, 0.84, 10.5),
	&"ford_mustang_shelby_gt500_1967_4mt": Vector4(0.88, 0.125, 0.95, 9.2),
	&"ford_mustang_shelby_gt500_1967_3at": Vector4(0.88, 0.13, 0.95, 9.2),
	&"fiat_punto_176_1995_55_5mt": Vector4(0.80, 0.14, 0.82, 9.5),
	&"fiat_punto_176_1995_55_6mt": Vector4(0.80, 0.14, 0.72, 9.5),
	&"fiat_punto_176_1995_60_a7_5mt": Vector4(0.82, 0.14, 0.83, 9.7),
	&"fiat_punto_176_1995_60_a7_ecvt": Vector4(0.82, 0.14, 0.73, 9.7),
	&"fiat_punto_176_1995_75_5mt": Vector4(0.84, 0.135, 0.84, 9.9),
	&"fiat_punto_176_1995_90_5mt": Vector4(0.86, 0.13, 0.85, 10.1),
	&"fiat_punto_176_1995_gt_5mt": Vector4(0.90, 0.12, 0.86, 10.5),
	&"fiat_punto_176_1995_d_5mt": Vector4(0.80, 0.14, 0.72, 9.5),
	&"fiat_punto_176_1995_td70_5mt": Vector4(0.82, 0.14, 0.73, 9.7),
}
const EXPECTED_POLONEZ_CALIBRATIONS: Dictionary = {
	&"fso_polonez_caro_mr93_14_gli_16v_5mt": Vector4(0.76, 0.15, 0.78, 8.8),
	&"fso_polonez_caro_mr93_15_gle_5mt": Vector4(0.72, 0.15, 0.78, 8.2),
	&"fso_polonez_caro_mr93_15_gli_5mt": Vector4(0.72, 0.15, 0.78, 8.4),
	&"fso_polonez_caro_mr93_16_gle_5mt": Vector4(0.73, 0.15, 0.78, 8.2),
	&"fso_polonez_caro_mr93_16_gli_5mt": Vector4(0.73, 0.15, 0.78, 8.5),
	&"fso_polonez_caro_mr93_20_gle_ford_5mt": Vector4(0.76, 0.15, 0.78, 8.8),
	&"fso_polonez_caro_mr93_19_gld_5mt": Vector4(0.72, 0.15, 0.78, 8.5),
}

var _checks: int = 0
var _failures: Array[String] = []

func _initialize() -> void:
	_run()
	_finish()

func _run() -> void:
	_expect(CATALOG != null, "production car catalog loads")
	if CATALOG == null:
		return
	var expected_calibrations: Dictionary = _build_expected_calibrations()
	var variants: Array[CarVariantDefinition] = CATALOG.get_all_variants()
	_expect(
		variants.size() == expected_calibrations.size(),
		"every production variant is covered by an explicit longitudinal tire calibration"
	)
	var seen_ids: Dictionary = {}
	for variant: CarVariantDefinition in variants:
		if variant == null:
			_expect(false, "catalog does not contain null variants")
			continue
		var variant_id: StringName = variant.variant_id
		seen_ids[variant_id] = true
		_expect(expected_calibrations.has(variant_id), "%s has a registered tire calibration" % str(variant_id))
		if not expected_calibrations.has(variant_id) or variant.specs == null:
			continue
		var expected: Vector4 = expected_calibrations[variant_id]
		var specs: CarSpecs = variant.specs
		_expect(is_equal_approx(specs.longitudinal_grip_coefficient, expected.x), "%s uses its calibrated longitudinal grip coefficient" % str(variant_id))
		_expect(is_equal_approx(specs.longitudinal_peak_slip_ratio, expected.y), "%s uses its calibrated peak slip ratio" % str(variant_id))
		_expect(is_equal_approx(specs.longitudinal_slide_grip_multiplier, expected.z), "%s uses its calibrated sliding-grip multiplier" % str(variant_id))
		_expect(is_equal_approx(specs.brake_deceleration, expected.w), "%s uses brake demand matched to the tire curve" % str(variant_id))
		var peak_braking_capacity: float = TireModel.STANDARD_GRAVITY * specs.longitudinal_grip_coefficient
		var brake_demand_ratio: float = specs.brake_deceleration / maxf(peak_braking_capacity, 0.001)
		_expect(
			brake_demand_ratio >= 0.95 and brake_demand_ratio <= 1.45,
			"%s full brake demand remains near the tire peak instead of requesting several g" % str(variant_id)
		)
	_expect(seen_ids.size() == expected_calibrations.size(), "no calibrated production variant is missing from the catalog")

func _build_expected_calibrations() -> Dictionary:
	var result: Dictionary = EXPECTED_LEGACY_CALIBRATIONS.duplicate(true)
	for variant_id: StringName in EXPECTED_POLONEZ_CALIBRATIONS:
		result[variant_id] = EXPECTED_POLONEZ_CALIBRATIONS[variant_id]
	for path: String in BMW_DYNAMICS_PATHS:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		_expect(file != null, "BMW tire calibration source loads: %s" % path)
		if file == null:
			continue
		var headers: PackedStringArray = file.get_csv_line()
		var candidate_index: int = headers.find("candidate_id")
		var brake_index: int = headers.find("brake_deceleration_target_mps2")
		_expect(candidate_index >= 0 and brake_index >= 0, "BMW tire calibration source exposes required columns: %s" % path)
		if candidate_index < 0 or brake_index < 0:
			continue
		while not file.eof_reached():
			var values: PackedStringArray = file.get_csv_line()
			if values.is_empty() or values[0].strip_edges().is_empty():
				continue
			if candidate_index >= values.size() or brake_index >= values.size():
				continue
			var candidate_id: String = values[candidate_index].strip_edges()
			var brake_text: String = values[brake_index].strip_edges()
			if candidate_id.is_empty() or not brake_text.is_valid_float():
				continue
			var brake_deceleration: float = brake_text.to_float()
			var grip_coefficient: float = clampf(brake_deceleration / 9.81, 0.88, 1.12)
			result[StringName("bmw_e46_sedan_%s" % candidate_id)] = Vector4(
				grip_coefficient,
				0.12,
				0.78,
				brake_deceleration
			)
	return result

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CATALOG_LONGITUDINAL_TIRE_CALIBRATION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CATALOG_LONGITUDINAL_TIRE_CALIBRATION_TEST][FAIL] %s" % message)

func _finish() -> void:
	if _failures.is_empty():
		print("[CATALOG_LONGITUDINAL_TIRE_CALIBRATION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CATALOG_LONGITUDINAL_TIRE_CALIBRATION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CATALOG_LONGITUDINAL_TIRE_CALIBRATION_TEST] - %s" % failure_message)
	quit(1)
