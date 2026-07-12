extends SceneTree

const SOURCE_ROOT: String = "res://scripts"
const REMOVED_TUNING_PROPERTIES: PackedStringArray = [
	"acceleration",
	"brake_deceleration",
	"reverse_acceleration",
	"coast_deceleration",
	"handbrake_deceleration",
	"max_forward_speed",
	"max_reverse_speed",
	"steering_speed",
	"wheel_base",
	"max_steering_angle_degrees",
	"idle_rpm",
	"peak_torque_rpm",
	"redline_rpm",
	"rev_limiter_rpm",
	"low_rpm_torque_multiplier",
	"mid_rpm_torque_multiplier",
	"redline_torque_multiplier",
	"engine_force",
	"engine_brake_force",
	"rpm_response",
	"manual_transmission_enabled",
	"automatic_transmission_enabled",
	"gear_ratios",
	"reverse_gear_ratio",
	"final_drive_ratio",
	"peak_engine_torque",
	"wheel_radius",
	"drivetrain_efficiency",
	"shift_delay",
	"automatic_upshift_rpm",
	"automatic_downshift_rpm",
	"automatic_kickdown_throttle",
	"automatic_kickdown_rpm",
	"automatic_shift_delay",
	"torque_converter_stall_rpm",
	"torque_converter_coupling_rpm",
	"torque_converter_stall_torque_multiplier",
	"vehicle_mass",
	"drag_coefficient",
	"frontal_area",
	"air_density",
	"rolling_resistance_coefficient",
	"lateral_grip",
	"handbrake_lateral_grip_multiplier",
	"steering_slip_gain",
	"slip_speed_threshold",
	"slip_steering_lock_threshold",
	"slip_steering_same_direction_multiplier",
	"skid_mark_min_slip",
	"skid_mark_interval",
	"skid_mark_lifetime",
	"skid_mark_width",
	"skid_mark_length",
	"gravity",
	"floor_stick_force",
]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_detector_fixtures()

	var script_paths: PackedStringArray = _collect_gdscript_paths(SOURCE_ROOT)
	_expect(not script_paths.is_empty(), "GDScript source files are discoverable")

	var violations: Array[String] = []
	for script_path: String in script_paths:
		var source_file: FileAccess = FileAccess.open(script_path, FileAccess.READ)
		if source_file == null:
			_failures.append("could not read %s" % script_path)
			continue
		var source_text: String = source_file.get_as_text()
		source_file.close()
		violations.append_array(_find_violations(source_text, script_path))

	violations.sort()
	_expect(
		violations.is_empty(),
		"PlayerCarController consumers do not access removed tuning properties directly"
	)
	for violation: String in violations:
		push_error("[REMOVED_CONTROLLER_ACCESS_TEST] %s" % violation)

	_finish()


func _test_detector_fixtures() -> void:
	var violating_source: String = (
		"var _car: PlayerCarController\n"
		+ "func read_speed() -> float:\n"
		+ "\treturn _car.max_forward_speed\n"
	)
	var violating_results: Array[String] = _find_violations(violating_source, "fixture_violation.gd")
	_expect(violating_results.size() == 1, "detector catches a direct removed-property access")

	var inferred_source: String = (
		"var player_car := scene.instantiate() as PlayerCarController\n"
		+ "func read_redline() -> float:\n"
		+ "\treturn player_car.redline_rpm\n"
	)
	var inferred_results: Array[String] = _find_violations(inferred_source, "fixture_inferred.gd")
	_expect(inferred_results.size() == 1, "detector catches an inferred PlayerCarController variable")

	var allowed_source: String = (
		"var _car: PlayerCarController\n"
		+ "func read_speed() -> float:\n"
		+ "\treturn _car.car_specs.max_forward_speed\n"
	)
	var allowed_results: Array[String] = _find_violations(allowed_source, "fixture_allowed.gd")
	_expect(allowed_results.is_empty(), "detector allows access through CarSpecs")


func _find_violations(source_text: String, source_path: String) -> Array[String]:
	var sanitized_source: String = _sanitize_source(source_text)
	var controller_variable_names: Dictionary = _find_controller_variable_names(sanitized_source)
	var violations: Array[String] = []

	for variable_name_value: Variant in controller_variable_names.keys():
		var variable_name: String = str(variable_name_value)
		for property_name: String in REMOVED_TUNING_PROPERTIES:
			var access_regex: RegEx = RegEx.new()
			var compile_error: Error = access_regex.compile(
				"\\b%s\\s*\\.\\s*%s\\b" % [variable_name, property_name]
			)
			if compile_error != OK:
				violations.append("%s: failed to compile access detector for %s.%s" % [source_path, variable_name, property_name])
				continue

			for access_match: RegExMatch in access_regex.search_all(sanitized_source):
				var line_number: int = sanitized_source.substr(0, access_match.get_start()).count("\n") + 1
				violations.append(
					"%s:%d directly accesses removed property %s.%s; use car_specs or a public controller method"
					% [source_path, line_number, variable_name, property_name]
				)

	return violations


func _find_controller_variable_names(source_text: String) -> Dictionary:
	var variable_names: Dictionary = {}

	var typed_regex: RegEx = RegEx.new()
	var typed_compile_error: Error = typed_regex.compile(
		"\\b([A-Za-z_][A-Za-z0-9_]*)\\s*:\\s*PlayerCarController\\b"
	)
	if typed_compile_error == OK:
		for typed_match: RegExMatch in typed_regex.search_all(source_text):
			variable_names[typed_match.get_string(1)] = true

	var inferred_regex: RegEx = RegEx.new()
	var inferred_compile_error: Error = inferred_regex.compile(
		"\\bvar\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*(?::=|=)[^\\n]*\\bas\\s+PlayerCarController\\b"
	)
	if inferred_compile_error == OK:
		for inferred_match: RegExMatch in inferred_regex.search_all(source_text):
			variable_names[inferred_match.get_string(1)] = true

	return variable_names


func _sanitize_source(source_text: String) -> String:
	var sanitized: String = ""
	var in_comment: bool = false
	var in_string: bool = false
	var string_delimiter: String = ""
	var escaped: bool = false

	for character_index: int in source_text.length():
		var character: String = source_text.substr(character_index, 1)

		if in_comment:
			if character == "\n":
				in_comment = false
				sanitized += "\n"
			else:
				sanitized += " "
			continue

		if in_string:
			if character == "\n":
				sanitized += "\n"
			else:
				sanitized += " "

			if escaped:
				escaped = false
			elif character == "\\":
				escaped = true
			elif character == string_delimiter:
				in_string = false
				string_delimiter = ""
			continue

		if character == "#":
			in_comment = true
			sanitized += " "
		elif character == "\"" or character == "'":
			in_string = true
			string_delimiter = character
			sanitized += " "
		else:
			sanitized += character

	return sanitized


func _collect_gdscript_paths(directory_path: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		return result

	directory.list_dir_begin()
	var entry_name: String = directory.get_next()
	while entry_name != "":
		if not entry_name.begins_with("."):
			var entry_path: String = directory_path.path_join(entry_name)
			if directory.current_is_dir():
				result.append_array(_collect_gdscript_paths(entry_path))
			elif entry_name.ends_with(".gd"):
				result.append(entry_path)
		entry_name = directory.get_next()
	directory.list_dir_end()

	return result


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[REMOVED_CONTROLLER_ACCESS_TEST][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[REMOVED_CONTROLLER_ACCESS_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[REMOVED_CONTROLLER_ACCESS_TEST] Passed: %d checks" % _checks)
		quit(0)
		return

	push_error(
		"[REMOVED_CONTROLLER_ACCESS_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[REMOVED_CONTROLLER_ACCESS_TEST] - %s" % failure_message)
	quit(1)
