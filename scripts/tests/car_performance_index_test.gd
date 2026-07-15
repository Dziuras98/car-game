extends SceneTree

const CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const REFERENCE_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var localization_errors: PackedStringArray = LocalizationCatalogLoader.ensure_loaded()
	_expect(localization_errors.is_empty(), "localization catalogs load for DPI menu labels")
	_expect(CAR_CATALOG != null and CAR_CATALOG.is_valid(), "authoritative car catalog is valid")

	var variants: Array[CarVariantDefinition] = CAR_CATALOG.get_all_variants()
	_expect(not variants.is_empty(), "car catalog exposes variants for DPI evaluation")
	for variant: CarVariantDefinition in variants:
		var direct_index: int = CarPerformanceIndexCalculator.calculate(variant.get_specs())
		_expect(direct_index > 0, "%s receives a positive DPI" % variant.variant_id)
		_expect(
			variant.get_performance_index() == direct_index,
			"%s exposes the deterministic calculator result" % variant.variant_id
		)

	var reference_index: int = CarPerformanceIndexCalculator.calculate(REFERENCE_SPECS)
	_expect(
		reference_index >= 990 and reference_index <= 1010,
		"frozen 370Z 7AT reference remains normalized near DPI 1000"
	)
	_expect(
		CarPerformanceIndexCalculator.calculate(REFERENCE_SPECS) == reference_index,
		"repeated evaluation of identical specs is deterministic"
	)

	var improved_specs: CarSpecs = REFERENCE_SPECS.duplicate(true) as CarSpecs
	improved_specs.peak_engine_torque *= 1.25
	improved_specs.max_forward_speed *= 1.05
	improved_specs.front_lateral_grip *= 1.08
	improved_specs.rear_lateral_grip *= 1.08
	improved_specs.brake_deceleration *= 1.08
	_expect(improved_specs.validate().is_empty(), "synthetic improved reference remains valid")
	_expect(
		CarPerformanceIndexCalculator.calculate(improved_specs) > reference_index,
		"more power, grip, braking and top speed produce a higher DPI"
	)

	var altered_vertical_gravity: CarSpecs = REFERENCE_SPECS.duplicate(true) as CarSpecs
	altered_vertical_gravity.gravity *= 1.5
	_expect(
		altered_vertical_gravity.validate().is_empty(),
		"synthetic vertical-gravity variant remains valid"
	)
	_expect(
		CarPerformanceIndexCalculator.calculate(altered_vertical_gravity) == reference_index,
		"vertical grounding gravity does not alter tire grip or rolling resistance in DPI"
	)

	var layout_base: CarSpecs = REFERENCE_SPECS.duplicate(true) as CarSpecs
	layout_base.peak_engine_torque *= 2.5
	layout_base.front_static_load_fraction = 0.55
	layout_base.longitudinal_grip_coefficient = 0.90
	layout_base.front_wheel_inertia_kg_m2 = 1.0
	layout_base.rear_wheel_inertia_kg_m2 = 1.0
	var fwd_specs: CarSpecs = layout_base.duplicate(true) as CarSpecs
	fwd_specs.drive_layout = CarSpecs.DriveLayout.FRONT_WHEEL_DRIVE
	var rwd_specs: CarSpecs = layout_base.duplicate(true) as CarSpecs
	rwd_specs.drive_layout = CarSpecs.DriveLayout.REAR_WHEEL_DRIVE
	var awd_specs: CarSpecs = layout_base.duplicate(true) as CarSpecs
	awd_specs.drive_layout = CarSpecs.DriveLayout.ALL_WHEEL_DRIVE
	awd_specs.awd_front_torque_fraction = 0.50
	_expect(
		fwd_specs.validate().is_empty()
		and rwd_specs.validate().is_empty()
		and awd_specs.validate().is_empty(),
		"synthetic drivetrain-layout variants remain valid"
	)
	var fwd_index: int = CarPerformanceIndexCalculator.calculate(fwd_specs)
	var rwd_index: int = CarPerformanceIndexCalculator.calculate(rwd_specs)
	var awd_index: int = CarPerformanceIndexCalculator.calculate(awd_specs)
	_expect(
		awd_index > rwd_index and rwd_index > fwd_index,
		"per-axle load transfer and driven-wheel grip affect DPI"
	)

	var light_wheels: CarSpecs = REFERENCE_SPECS.duplicate(true) as CarSpecs
	light_wheels.front_wheel_inertia_kg_m2 = 0.60
	light_wheels.rear_wheel_inertia_kg_m2 = 0.60
	var heavy_wheels: CarSpecs = light_wheels.duplicate(true) as CarSpecs
	heavy_wheels.front_wheel_inertia_kg_m2 = 4.0
	heavy_wheels.rear_wheel_inertia_kg_m2 = 4.0
	_expect(
		CarPerformanceIndexCalculator.calculate(light_wheels)
		> CarPerformanceIndexCalculator.calculate(heavy_wheels),
		"higher wheel inertia lowers DPI acceleration performance"
	)

	var standard_width: CarSpecs = REFERENCE_SPECS.duplicate(true) as CarSpecs
	standard_width.front_wheel_inertia_kg_m2 = 1.0
	standard_width.rear_wheel_inertia_kg_m2 = 1.0
	var wider_tires: CarSpecs = standard_width.duplicate(true) as CarSpecs
	wider_tires.front_tire_width_m *= 1.15
	wider_tires.rear_tire_width_m *= 1.15
	_expect(
		CarPerformanceIndexCalculator.calculate(wider_tires)
		> CarPerformanceIndexCalculator.calculate(standard_width),
		"runtime tire-width scaling contributes to DPI cornering performance"
	)

	var menu_models: Array[CarModelMenuOption] = MenuOptionsBuilder.build_car_models(CAR_CATALOG)
	var menu_variant_count: int = 0
	for model: CarModelMenuOption in menu_models:
		for option: CarVariantMenuOption in model.variants:
			menu_variant_count += 1
			_expect(option.performance_index > 0, "%s menu option exposes structured DPI" % option.variant_id)
			_expect(
				not option.label.contains(" — DPI "),
				"%s keeps DPI separate from the variant label" % option.variant_id
			)
	_expect(
		menu_variant_count == variants.size(),
		"every authoritative catalog variant is represented by a DPI menu option"
	)

	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_PERFORMANCE_INDEX_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CAR_PERFORMANCE_INDEX_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_PERFORMANCE_INDEX_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CAR_PERFORMANCE_INDEX_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_PERFORMANCE_INDEX_TEST] - %s" % failure_message)
	quit(1)
