extends SceneTree

const MODEL_PATH := "res://resources/cars/bmw/4_series_f32/model.tres"
const CATALOG_PATH := "res://resources/cars/catalog.tres"
const MATRIX_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_variant_matrix.data"
const ENGINES_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_engines.data"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var model: BmwF32ModelDefinition = load(MODEL_PATH) as BmwF32ModelDefinition
	_expect(model != null, "BMW F32 model resource loads")
	if model == null:
		_finish()
		return
	_expect(model.get_variant_count() == 44, "BMW F32 exposes all 44 approved variants")
	_expect(model.validate().is_empty(), "BMW F32 model and every variant validate")
	var automatic_count: int = 0
	var manual_count: int = 0
	var awd_count: int = 0
	var exact_dynamics_count: int = 0
	for variant: CarVariantDefinition in model.get_variants():
		var specs: TrafficRiderCarSpecs = variant.specs as TrafficRiderCarSpecs
		_expect(specs != null, "%s uses TrafficRiderCarSpecs" % str(variant.variant_id))
		if specs == null:
			continue
		_expect(specs.validate().is_empty(), "%s simulated specs validate" % str(variant.variant_id))
		_expect(specs.inline_engine_audio_profile != null, "%s has a physical inline audio profile" % str(variant.variant_id))
		_expect(specs.traffic_rider_powertrain_definition != null, "%s has an explicit powertrain definition" % str(variant.variant_id))
		_expect(specs.torque_curve != null and specs.torque_curve.rpm_points.size() >= 6, "%s has a sampled torque curve" % str(variant.variant_id))
		_expect(specs.confidence_score >= 0.50 and specs.confidence_score <= 0.90, "%s records bounded simulation confidence" % str(variant.variant_id))
		_expect(not specs.simulated_fields.is_empty(), "%s exposes simulated fields" % str(variant.variant_id))
		if specs.transmission_type == CarSpecs.TransmissionType.AUTOMATIC:
			automatic_count += 1
			_expect(specs.gear_ratios.size() == 8, "%s has eight automatic ratios" % str(variant.variant_id))
			_expect(specs.traffic_rider_powertrain_definition.planetary_automatic_enabled, "%s activates phased planetary automatic" % str(variant.variant_id))
		else:
			manual_count += 1
			_expect(specs.gear_ratios.size() == 6, "%s has six manual ratios" % str(variant.variant_id))
			_expect(not specs.traffic_rider_powertrain_definition.planetary_automatic_enabled, "%s does not fake an automatic model" % str(variant.variant_id))
		if specs.drive_layout == CarSpecs.DriveLayout.ALL_WHEEL_DRIVE:
			awd_count += 1
			_expect(specs.traffic_rider_powertrain_definition.on_demand_awd_enabled, "%s activates dynamic xDrive coupling" % str(variant.variant_id))
		else:
			_expect(not specs.traffic_rider_powertrain_definition.on_demand_awd_enabled, "%s does not fake xDrive" % str(variant.variant_id))
		if not specs.simulated_fields.has("vehicle_mass"):
			exact_dynamics_count += 1
	_expect(automatic_count == 25, "BMW F32 matrix retains 25 automatic variants")
	_expect(manual_count == 19, "BMW F32 matrix retains 19 manual variants")
	_expect(awd_count == 15, "BMW F32 matrix retains 15 xDrive variants")
	_expect(exact_dynamics_count == 8, "eight variants retain exact factory dynamics")
	_test_engine_architectures(model)
	_test_power_consistency(model)
	var catalog: CarCatalog = load(CATALOG_PATH) as CarCatalog
	_expect(catalog != null and catalog.get_model_by_id(&"bmw_4_series_f32") != null, "main catalog exposes BMW F32")
	_finish()


func _test_engine_architectures(model: BmwF32ModelDefinition) -> void:
	var b38: TrafficRiderInlineEngineAudioProfile = model.get_audio_profile(&"b38b15_100")
	var n20: TrafficRiderInlineEngineAudioProfile = model.get_audio_profile(&"n20b20_180")
	var b48: TrafficRiderInlineEngineAudioProfile = model.get_audio_profile(&"b48b20_185")
	var n55: TrafficRiderInlineEngineAudioProfile = model.get_audio_profile(&"n55b30_225")
	var b58: TrafficRiderInlineEngineAudioProfile = model.get_audio_profile(&"b58b30_240")
	var n47: TrafficRiderInlineEngineAudioProfile = model.get_audio_profile(&"n47d20_135")
	var n57_twin: TrafficRiderInlineEngineAudioProfile = model.get_audio_profile(&"n57d30_230")
	_expect(b38 != null and b38.cylinder_count == 3 and b38.firing_order == PackedInt32Array([1, 2, 3]), "B38 rebuilds the real inline-three event order")
	_expect(n20 != null and n20.collector_group_by_cylinder == PackedInt32Array([0, 1, 1, 0]), "N20 rebuilds twin-scroll cylinder grouping")
	_expect(b48 != null and absf(b48.mechanical_level - n20.mechanical_level) > 0.02, "B48 is not an N20 pitch/EQ clone")
	_expect(n55 != null and n55.firing_order == PackedInt32Array([1, 5, 3, 6, 2, 4]), "N55 rebuilds BMW inline-six firing order")
	_expect(b58 != null and absf(b58.intake_level - n55.intake_level) > 0.02, "B58 is not an N55 pitch/EQ clone")
	_expect(n47 != null and n47.combustion_type == TrafficRiderInlineEngineAudioProfile.CombustionType.DIESEL_COMMON_RAIL, "N47 uses common-rail diesel combustion")
	_expect(n57_twin != null and n57_twin.aspiration_type == TrafficRiderInlineEngineAudioProfile.AspirationType.SEQUENTIAL_TWIN_TURBO, "435d N57 rebuilds sequential twin-turbo state")


func _test_power_consistency(model: BmwF32ModelDefinition) -> void:
	var engines: Array[Dictionary] = _read_csv(ENGINES_PATH)
	for engine: Dictionary in engines:
		var key: String = str(engine.get("engine_key", ""))
		var curve: EngineTorqueCurve = model.get_torque_curve(StringName(key))
		_expect(curve != null, "%s curve exists" % key)
		if curve == null:
			continue
		var peak_torque: float = _number(engine, "torque_nm", 1.0)
		var power_kw: float = _number(engine, "power_kw", 0.0)
		if power_kw <= 0.0:
			power_kw = _number(engine, "power_hp", 1.0) * 0.745699872
		var peak_rpm: float = BmwF32EngineCurveFactory.get_power_peak_rpm(engine)
		var reconstructed_power: float = peak_torque * curve.sample(peak_rpm) * peak_rpm / 9549.296596
		_expect(absf(reconstructed_power - power_kw) / maxf(power_kw, 1.0) <= 0.035, "%s curve reproduces catalog power within 3.5%%" % key)
		_expect(curve.sample(BmwF32EngineCurveFactory.get_peak_torque_rpm(engine)) >= 0.99, "%s curve preserves peak-torque anchor" % key)


func _read_csv(path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result
	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if values.is_empty() or values[0].strip_edges().is_empty():
			continue
		var row: Dictionary = {}
		for index: int in range(mini(headers.size(), values.size())):
			row[headers[index]] = values[index]
		result.append(row)
	file.close()
	return result


func _number(row: Dictionary, field: String, fallback: float) -> float:
	var text: String = str(row.get(field, "")).strip_edges()
	return text.to_float() if text.is_valid_float() else fallback


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BMW_F32_SIMULATED_CONTENT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[BMW_F32_SIMULATED_CONTENT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BMW_F32_SIMULATED_CONTENT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BMW_F32_SIMULATED_CONTENT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure: String in _failures:
		push_error("[BMW_F32_SIMULATED_CONTENT_TEST] - %s" % failure)
	quit(1)
