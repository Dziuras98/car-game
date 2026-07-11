extends SceneTree

const MODEL_PATH: String = "res://resources/cars/nissan/370z_nismo/model.tres"
const MANUAL_SPECS_PATH: String = "res://resources/cars/nissan/370z_nismo/specs/370z_nismo_6mt_specs.tres"
const AUTOMATIC_SPECS_PATH: String = "res://resources/cars/nissan/370z_nismo/specs/370z_nismo_7at_specs.tres"
const STANDARD_SPECS_PATH: String = "res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres"
const SCENE_PATH: String = "res://scenes/cars/370z_nismo.tscn"
const CATALOG_PATH: String = "res://resources/cars/catalog.tres"
const BODY_KIT_PATH: String = "res://assets/cars/nissan/370z_nismo/370z_nismo_2016_bodykit.obj"
const TRIM_PATH: String = "res://assets/cars/nissan/370z_nismo/370z_nismo_2016_trim.obj"
const RED_ACCENTS_PATH: String = "res://assets/cars/nissan/370z_nismo/370z_nismo_2016_red_accents.obj"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_catalog_content()
	_test_powertrain_specs()
	_test_engine_curve()
	_test_visual_scene()
	_finish()


func _test_catalog_content() -> void:
	var model := load(MODEL_PATH) as CarModelDefinition
	_expect(model != null, "the NISMO model resource loads")
	if model != null:
		_expect(model.model_id == &"nissan_370z_nismo", "the NISMO model has a stable unique ID")
		_expect(model.default_variant_id == &"nissan_370z_nismo_6mt_eu", "the European manual is the default NISMO variant")
		_expect(model.variants.size() == 2, "the NISMO model exposes manual and automatic variants")
		_expect(model.validate().is_empty(), "the NISMO model definition validates")

	var catalog := load(CATALOG_PATH) as CarCatalog
	_expect(catalog != null, "the car catalog loads with NISMO content")
	if catalog != null:
		_expect(catalog.validate().is_empty(), "the complete car catalog validates")
		_expect(catalog.get_model_by_id(&"nissan_370z_nismo") != null, "the catalog resolves the NISMO model")
		var manual_variant := catalog.get_variant_by_id(&"nissan_370z_nismo_6mt_eu")
		var automatic_variant := catalog.get_variant_by_id(&"nissan_370z_nismo_7at_global")
		_expect(manual_variant != null, "the catalog resolves the European NISMO manual")
		_expect(automatic_variant != null, "the catalog resolves the global NISMO automatic")
		if manual_variant != null:
			_expect(not manual_variant.ai_eligible, "the manual variant is not marked AI-compatible")
		if automatic_variant != null:
			_expect(automatic_variant.ai_eligible, "the automatic variant is marked AI-compatible")


func _test_powertrain_specs() -> void:
	var manual_specs := load(MANUAL_SPECS_PATH) as CarSpecs
	var automatic_specs := load(AUTOMATIC_SPECS_PATH) as CarSpecs
	_expect(manual_specs != null, "the NISMO manual specs load")
	_expect(automatic_specs != null, "the NISMO automatic specs load")
	if manual_specs != null:
		_expect(manual_specs.validate().is_empty(), "the NISMO manual specs validate")
		_expect(manual_specs.is_manual_transmission(), "the European NISMO uses a manual transmission")
		_expect(manual_specs.gear_ratios.size() == 6, "the NISMO manual has six forward gears")
		_expect(is_equal_approx(manual_specs.final_drive_ratio, 3.916), "the NISMO V2 manual uses the 3.916 final drive")
		_expect(is_equal_approx(manual_specs.peak_engine_torque, 371.0), "the NISMO manual uses the 371 Nm torque target")
		_expect(is_equal_approx(manual_specs.redline_rpm, 7400.0), "the NISMO power peak is represented at 7400 RPM")
		_expect(is_equal_approx(manual_specs.rev_limiter_rpm, 7500.0), "the NISMO limiter is represented at 7500 RPM")
	if automatic_specs != null:
		_expect(automatic_specs.validate().is_empty(), "the NISMO automatic specs validate")
		_expect(automatic_specs.is_automatic_transmission(), "the global NISMO uses an automatic transmission")
		_expect(automatic_specs.gear_ratios.size() == 7, "the NISMO automatic has seven forward gears")
		_expect(is_equal_approx(automatic_specs.final_drive_ratio, 3.357), "the NISMO automatic uses the 3.357 final drive")
		_expect(automatic_specs.automatic_shift_delay < 0.20, "the NISMO automatic has the quicker shift interruption")


func _test_engine_curve() -> void:
	var nismo_specs := load(MANUAL_SPECS_PATH) as CarSpecs
	var standard_specs := load(STANDARD_SPECS_PATH) as CarSpecs
	if nismo_specs == null or standard_specs == null:
		_expect(false, "both standard and NISMO specs are available for curve comparison")
		return

	var nismo_engine := _build_engine_model(nismo_specs)
	nismo_engine.set_rpm(5200.0)
	_expect(is_equal_approx(nismo_engine.get_torque_multiplier(), 1.0), "the NISMO curve reaches 371 Nm at 5200 RPM")
	nismo_engine.set_rpm(7400.0)
	var nismo_redline_torque: float = nismo_specs.peak_engine_torque * nismo_engine.get_torque_multiplier()
	var nismo_power_kw: float = _power_kw(nismo_redline_torque, 7400.0)
	_expect(absf(nismo_power_kw - 253.0) < 0.6, "the NISMO curve produces approximately 253 kW at 7400 RPM")

	var standard_engine := _build_engine_model(standard_specs)
	standard_engine.set_rpm(standard_specs.redline_rpm)
	var standard_redline_torque: float = standard_specs.peak_engine_torque * standard_engine.get_torque_multiplier()
	var standard_power_kw: float = _power_kw(standard_redline_torque, standard_specs.redline_rpm)
	_expect(nismo_power_kw > standard_power_kw + 8.0, "the NISMO curve preserves a meaningful high-RPM power increase over the standard 370Z")
	_expect(nismo_specs.redline_rpm > standard_specs.redline_rpm, "the NISMO useful power band extends above the standard 370Z redline")


func _test_visual_scene() -> void:
	var body_kit := load(BODY_KIT_PATH) as Mesh
	var trim := load(TRIM_PATH) as Mesh
	var red_accents := load(RED_ACCENTS_PATH) as Mesh
	_expect(body_kit != null, "the NISMO body-kit mesh imports")
	_expect(trim != null, "the NISMO aero-trim mesh imports")
	_expect(red_accents != null, "the NISMO accent mesh imports")
	if body_kit != null:
		var body_bounds: AABB = body_kit.get_aabb()
		_expect(body_bounds.size.z >= 4.40, "the NISMO body kit reaches the approximately 4.41 m exterior length")
		_expect(body_bounds.size.x >= 1.86, "the NISMO body kit reaches the approximately 1.87 m body width")
		_expect(body_bounds.position.y <= 0.1451, "the NISMO splitter and skirts intersect the lower body")
		_expect(body_bounds.end.y >= 1.0449, "the NISMO rear wing reaches its intended height")

	var packed_scene := load(SCENE_PATH) as PackedScene
	_expect(packed_scene != null, "the NISMO base scene loads")
	if packed_scene == null:
		return
	var car := packed_scene.instantiate()
	_expect(car is PlayerCarController, "the NISMO scene retains the PlayerCarController root contract")
	_expect(car.get_node_or_null("VisualRoot/NismoBodyKit") is MeshInstance3D, "the NISMO body-kit node is present")
	_expect(car.get_node_or_null("VisualRoot/NismoTrim") is MeshInstance3D, "the NISMO trim node is present")
	_expect(car.get_node_or_null("VisualRoot/NismoRedAccents") is MeshInstance3D, "the NISMO red-accent node is present")
	_expect(car.get_node_or_null("EngineAudio") is EngineAudioSynthesizer, "the NISMO scene retains procedural engine audio")
	var collision := car.get_node_or_null("CollisionShape3D") as CollisionShape3D
	_expect(collision != null and collision.shape is BoxShape3D, "the NISMO scene has a valid body collision shape")
	if collision != null and collision.shape is BoxShape3D:
		var box := collision.shape as BoxShape3D
		_expect(is_equal_approx(box.size.z, 4.41), "the NISMO collision follows the extended body-kit length")
		_expect(is_equal_approx(box.size.x, 1.87), "the NISMO collision follows the wider body-kit width")
	car.free()


func _build_engine_model(specs: CarSpecs) -> EngineModel:
	var engine := EngineModel.new()
	engine.configure(
		specs.idle_rpm,
		specs.peak_torque_rpm,
		specs.redline_rpm,
		specs.rev_limiter_rpm,
		specs.low_rpm_torque_multiplier,
		specs.mid_rpm_torque_multiplier,
		specs.redline_torque_multiplier,
		specs.rpm_response
	)
	return engine


func _power_kw(torque_nm: float, rpm: float) -> float:
	return torque_nm * rpm / 9549.2966


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[370Z_NISMO_CONTENT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[370Z_NISMO_CONTENT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[370Z_NISMO_CONTENT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[370Z_NISMO_CONTENT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[370Z_NISMO_CONTENT_TEST] - %s" % failure_message)
	quit(1)
