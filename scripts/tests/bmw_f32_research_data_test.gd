extends SceneTree

const VARIANT_MATRIX_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_variant_matrix.data"
const ENGINE_DATA_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_engines.data"
const VERIFIED_DYNAMICS_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_verified_dynamics.data"

const EXPECTED_VARIANT_COUNT := 44
const EXPECTED_ENGINE_COUNT := 17
const EXPECTED_VERIFIED_DYNAMICS_COUNT := 8
const EXPECTED_VERIFIED_IDS: PackedStringArray = PackedStringArray([
	"428i_n20b20_rwd_6mt",
	"428i_n20b20_rwd_8at",
	"428i_n20b20_xdrive_8at",
	"435i_n55b30_rwd_6mt",
	"435i_n55b30_rwd_8at",
	"435i_n55b30_xdrive_8at",
	"420d_n47d20_rwd_6mt",
	"420d_n47d20_rwd_8at",
])

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var variants: Array[Dictionary] = _read_csv(VARIANT_MATRIX_PATH)
	var engines: Array[Dictionary] = _read_csv(ENGINE_DATA_PATH)
	var dynamics: Array[Dictionary] = _read_csv(VERIFIED_DYNAMICS_PATH)

	_expect(variants.size() == EXPECTED_VARIANT_COUNT, "BMW F32 matrix contains exactly 44 approved variants")
	_expect(engines.size() == EXPECTED_ENGINE_COUNT, "BMW F32 engine table contains all 17 distinct calibrations")
	_expect(dynamics.size() == EXPECTED_VERIFIED_DYNAMICS_COUNT, "BMW F32 launch dataset contains eight factory-exact dynamics rows")

	var variants_by_id := _index_unique(variants, "candidate_id", "variant")
	var engines_by_key := _index_unique(engines, "engine_key", "engine")
	var dynamics_by_id := _index_unique(dynamics, "candidate_id", "verified dynamics")

	_expect(variants_by_id.size() == EXPECTED_VARIANT_COUNT, "all BMW F32 candidate IDs are unique")
	_expect(engines_by_key.size() == EXPECTED_ENGINE_COUNT, "all BMW F32 engine keys are unique")
	_expect(dynamics_by_id.size() == EXPECTED_VERIFIED_DYNAMICS_COUNT, "all verified dynamics IDs are unique")

	_test_variant_matrix(variants, variants_by_id, engines_by_key)
	_test_engines(engines)
	_test_verified_dynamics(dynamics, variants_by_id, engines_by_key, dynamics_by_id)
	_finish()


func _test_variant_matrix(
	variants: Array[Dictionary],
	variants_by_id: Dictionary,
	engines_by_key: Dictionary
) -> void:
	var petrol_count := 0
	var diesel_count := 0
	var zhp_count := 0
	for row: Dictionary in variants:
		var candidate_id := str(row.get("candidate_id", ""))
		var engine_key := str(row.get("engine_key", ""))
		var transmission := str(row.get("transmission_type", ""))
		var drivetrain := str(row.get("drivetrain", ""))
		_expect(not candidate_id.is_empty(), "variant candidate_id is present")
		_expect(engines_by_key.has(engine_key), "%s references a retained engine row" % candidate_id)
		_expect(transmission == "6mt" or transmission == "8at", "%s has an approved F32 transmission architecture" % candidate_id)
		_expect(drivetrain == "RWD" or drivetrain == "xDrive", "%s has an approved drivetrain" % candidate_id)
		if str(row.get("special_scope", "")) == "factory_special":
			zhp_count += 1
		var engine: Dictionary = engines_by_key.get(engine_key, {})
		if str(engine.get("fuel", "")) == "diesel":
			diesel_count += 1
		else:
			petrol_count += 1

	_expect(petrol_count == 25, "matrix contains 23 standard petrol plus two ZHP variants")
	_expect(diesel_count == 19, "matrix contains 19 diesel variants")
	_expect(zhp_count == 2, "matrix contains both approved 435i ZHP variants")
	_expect(variants_by_id.has("435d_n57d30_xdrive_8at"), "matrix retains the single 435d xDrive 8AT row")
	_expect(not variants_by_id.has("435d_n57d30_rwd_8at"), "matrix does not invent a 435d RWD row")


func _test_engines(engines: Array[Dictionary]) -> void:
	for row: Dictionary in engines:
		var engine_key := str(row.get("engine_key", ""))
		_expect(_positive_float(row, "displacement_cc"), "%s displacement is retained" % engine_key)
		_expect(_positive_float(row, "cylinders"), "%s cylinder count is retained" % engine_key)
		_expect(_positive_float(row, "torque_nm"), "%s peak torque is retained" % engine_key)
		var has_metric_power := _positive_float(row, "power_kw") and _positive_float(row, "power_ps")
		var has_hp_power := _positive_float(row, "power_hp")
		_expect(has_metric_power or has_hp_power, "%s factory power is retained" % engine_key)
		_expect(str(row.get("layout", "")) == "inline", "%s cylinder layout is retained as inline" % engine_key)


func _test_verified_dynamics(
	dynamics: Array[Dictionary],
	variants_by_id: Dictionary,
	engines_by_key: Dictionary,
	dynamics_by_id: Dictionary
) -> void:
	for expected_id: String in EXPECTED_VERIFIED_IDS:
		_expect(dynamics_by_id.has(expected_id), "factory launch dataset contains %s" % expected_id)

	for row: Dictionary in dynamics:
		var candidate_id := str(row.get("candidate_id", ""))
		var engine_key := str(row.get("engine_key", ""))
		var transmission := str(row.get("transmission_type", ""))
		_expect(variants_by_id.has(candidate_id), "%s belongs to the approved 44-row matrix" % candidate_id)
		_expect(engines_by_key.has(engine_key), "%s references a retained engine calibration" % candidate_id)
		_expect(str(row.get("data_class", "")) == "factory_exact", "%s is explicitly classified as factory exact" % candidate_id)
		_expect(_positive_float(row, "mass_din_kg"), "%s retains DIN mass" % candidate_id)
		_expect(_positive_float(row, "mass_eu_kg"), "%s retains EU mass" % candidate_id)
		_expect(_positive_float(row, "reverse_ratio"), "%s retains reverse ratio" % candidate_id)
		_expect(_positive_float(row, "final_drive_ratio"), "%s retains final drive" % candidate_id)
		_expect(_positive_float(row, "wheel_radius_m"), "%s retains wheel rolling radius" % candidate_id)
		_expect(_positive_float(row, "drag_coefficient"), "%s retains drag coefficient" % candidate_id)
		_expect(_positive_float(row, "frontal_area_m2"), "%s retains frontal area" % candidate_id)
		_expect(_positive_float(row, "zero_100_kph_s"), "%s retains 0-100 km/h target" % candidate_id)
		_expect(_positive_float(row, "top_speed_kph"), "%s retains top speed" % candidate_id)
		_expect(str(row.get("source_id", "")) == "BMW_F32_LAUNCH_201306", "%s retains its source record" % candidate_id)
		_expect(str(row.get("gearbox_exact_code", "")).is_empty(), "%s does not invent an exact gearbox suffix" % candidate_id)
		_expect(
			str(row.get("gearbox_exact_code_status", "")) == "not_retained_in_research_record",
			"%s explicitly records the missing exact gearbox suffix" % candidate_id
		)
		var required_gears := 6 if transmission == "6mt" else 8
		for gear_index: int in range(1, required_gears + 1):
			_expect(_positive_float(row, "ratio_%d" % gear_index), "%s retains ratio %d" % [candidate_id, gear_index])
		if transmission == "6mt":
			_expect(str(row.get("ratio_7", "")).is_empty(), "%s does not invent seventh gear" % candidate_id)
			_expect(str(row.get("ratio_8", "")).is_empty(), "%s does not invent eighth gear" % candidate_id)
		else:
			_expect(
				str(row.get("gearbox_architecture", "")) == "planetary_torque_converter_automatic",
				"%s preserves the torque-converter planetary architecture" % candidate_id
			)


func _read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "%s is readable" % path)
	if file == null:
		return rows
	var header: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if values.size() == 1 and values[0].strip_edges().is_empty():
			continue
		var row: Dictionary = {}
		for index: int in range(header.size()):
			row[header[index]] = values[index] if index < values.size() else ""
		rows.append(row)
	file.close()
	return rows


func _index_unique(rows: Array[Dictionary], field: String, label: String) -> Dictionary:
	var result: Dictionary = {}
	for row: Dictionary in rows:
		var key := str(row.get(field, ""))
		_expect(not key.is_empty(), "%s %s is present" % [label, field])
		if key.is_empty():
			continue
		_expect(not result.has(key), "%s key is unique: %s" % [label, key])
		result[key] = row
	return result


func _positive_float(row: Dictionary, field: String) -> bool:
	var text := str(row.get(field, "")).strip_edges()
	return text.is_valid_float() and text.to_float() > 0.0


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BMW_F32_RESEARCH_DATA_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[BMW_F32_RESEARCH_DATA_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BMW_F32_RESEARCH_DATA_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BMW_F32_RESEARCH_DATA_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
