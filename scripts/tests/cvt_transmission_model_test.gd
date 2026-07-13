extends SceneTree

const CVT_SPECS: CarSpecs = preload("res://resources/cars/fiat/punto_176_1995/specs/punto_60_cvt_specs.tres")
const CVT_VARIANT: CarVariantDefinition = preload("res://resources/cars/fiat/punto_176_1995/variants/punto_60_cvt.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_specs_contract()
	_test_unbounded_overdrive_ratio()
	_test_runtime_and_ai_contract()
	_finish()


func _test_specs_contract() -> void:
	_expect(CVT_SPECS != null and CVT_SPECS.validate().is_empty(), "Selecta CVT specs validate")
	if CVT_SPECS == null:
		return
	_expect(CVT_SPECS.is_cvt_transmission(), "Selecta uses the dedicated CVT enum")
	_expect(not CVT_SPECS.is_manual_transmission(), "CVT is not exposed as manual")
	_expect(not CVT_SPECS.is_automatic_transmission(), "CVT is not exposed as a stepped automatic")
	_expect(CVT_SPECS.uses_geared_transmission(), "CVT participates in powered drivetrain contracts")
	_expect(not CVT_SPECS.uses_discrete_gears(), "CVT does not expose discrete forward gears")
	_expect(CVT_SPECS.gear_ratios.is_empty(), "Selecta does not store a fake gear list")


func _test_unbounded_overdrive_ratio() -> void:
	var model := CvtTransmissionModel.new()
	model.configure(
		CVT_SPECS.idle_rpm,
		CVT_SPECS.cvt_max_ratio,
		CVT_SPECS.reverse_gear_ratio,
		CVT_SPECS.final_drive_ratio,
		CVT_SPECS.wheel_radius,
		CVT_SPECS.peak_engine_torque,
		CVT_SPECS.drivetrain_efficiency,
		CVT_SPECS.vehicle_mass,
		CVT_SPECS.cvt_target_rpm_min,
		CVT_SPECS.cvt_target_rpm_max,
		CVT_SPECS.cvt_ratio_response,
		CVT_SPECS.cvt_clutch_engagement_rpm,
		CVT_SPECS.cvt_clutch_full_rpm
	)
	_expect(is_equal_approx(model.get_current_ratio(), CVT_SPECS.cvt_max_ratio), "CVT resets at its shortest ratio")
	for step: int in range(600):
		model.update_ratio(30.0, 1.0, 1.0 / 120.0)
	var motorway_ratio: float = model.get_current_ratio()
	_expect(motorway_ratio < CVT_SPECS.cvt_max_ratio, "CVT reduces ratio continuously as road speed rises")
	for step: int in range(600):
		model.update_ratio(120.0, 1.0, 1.0 / 120.0)
	var extreme_speed_ratio: float = model.get_current_ratio()
	_expect(extreme_speed_ratio < motorway_ratio, "CVT has no configured longest-ratio floor")
	_expect(extreme_speed_ratio > 0.0, "CVT retains only a numerical non-zero safety ratio")
	model.reset()
	for step: int in range(600):
		model.update_ratio(30.0, 0.15, 1.0 / 120.0)
	_expect(model.get_target_rpm() < CVT_SPECS.cvt_target_rpm_max, "partial load commands lower engine RPM")


func _test_runtime_and_ai_contract() -> void:
	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(CVT_SPECS)
	_expect(config != null and config.is_cvt_transmission(), "CVT maps into runtime configuration")
	_expect(config != null and config.gear_ratios.is_empty(), "runtime CVT keeps an empty discrete gear list")
	_expect(CVT_VARIANT != null and CVT_VARIANT.is_ai_eligible_for_race(), "Selecta CVT is eligible for AI racing")
	if CVT_VARIANT != null:
		_expect(CVT_VARIANT.get_transmission_label() == "CVT", "catalog exposes a dedicated CVT label")
		var instance := CVT_VARIANT.car_scene.instantiate() as PlayerCarController
		_expect(instance != null, "CVT scene instantiates as PlayerCarController")
		if instance != null:
			_expect(instance.car_specs == CVT_SPECS, "CVT scene carries authoritative specs")
			instance.free()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CVT_TRANSMISSION_MODEL_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CVT_TRANSMISSION_MODEL_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CVT_TRANSMISSION_MODEL_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CVT_TRANSMISSION_MODEL_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CVT_TRANSMISSION_MODEL_TEST] - %s" % failure_message)
	quit(1)
