extends CarModelDefinition
class_name BmwF32ModelDefinition

const PLAYER_SCENE: PackedScene = preload("res://scenes/cars/bmw_f32.tscn")
const AI_SCENE: PackedScene = preload("res://scenes/cars/bmw_f32_ai.tscn")
const MATRIX_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_variant_matrix.data"
const ENGINES_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_engines.data"
const DYNAMICS_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_verified_dynamics.data"

var _audio_profiles: Dictionary = {}
var _torque_curves: Dictionary = {}


func _init() -> void:
	manufacturer = "BMW"
	model_id = &"bmw_4_series_f32"
	display_name = "4 Series Coupé"
	generation = "F32 pre-LCI"
	production_year_start = 2013
	production_year_end = 2017
	default_variant_id = &"bmw_4_series_f32_428i_n20b20_rwd_8at"
	_build_variants()


func get_audio_profile(engine_key: StringName) -> TrafficRiderInlineEngineAudioProfile:
	return _audio_profiles.get(str(engine_key)) as TrafficRiderInlineEngineAudioProfile


func get_torque_curve(engine_key: StringName) -> EngineTorqueCurve:
	return _torque_curves.get(str(engine_key)) as EngineTorqueCurve


func _build_variants() -> void:
	variants.clear()
	_audio_profiles.clear()
	_torque_curves.clear()
	var engines: Dictionary = _index_by(_read_csv(ENGINES_PATH), "engine_key")
	var exact_dynamics: Dictionary = _index_by(_read_csv(DYNAMICS_PATH), "candidate_id")
	for engine_key: String in engines:
		var engine: Dictionary = engines[engine_key]
		_audio_profiles[engine_key] = BmwF32AudioProfileFactory.create(engine)
		_torque_curves[engine_key] = BmwF32EngineCurveFactory.create(engine)

	var sort_order: int = 0
	for row: Dictionary in _read_csv(MATRIX_PATH):
		var engine_key: String = str(row.get("engine_key", ""))
		if not engines.has(engine_key):
			push_error("BMW F32 matrix references missing engine %s" % engine_key)
			continue
		var engine: Dictionary = engines[engine_key]
		var candidate_id: String = str(row.get("candidate_id", ""))
		var dynamics: Dictionary = exact_dynamics.get(candidate_id, {})
		var is_exact_dynamics: bool = not dynamics.is_empty()
		if dynamics.is_empty():
			dynamics = _simulate_dynamics(row, engine)
		var specs: TrafficRiderCarSpecs = _build_specs(row, engine, dynamics, is_exact_dynamics)
		var variant := CarVariantDefinition.new()
		variant.variant_id = StringName("bmw_4_series_f32_%s" % candidate_id)
		variant.display_name = _build_display_name(row)
		variant.sort_order = sort_order
		variant.car_scene = PLAYER_SCENE
		variant.ai_car_scene = AI_SCENE
		variant.specs = specs
		variant.ai_eligible = true
		variant.engine_label = str(engine.get("engine_code", engine_key))
		variant.drivetrain_label = str(row.get("drivetrain", "RWD"))
		variants.append(variant)
		sort_order += 1


func _build_specs(row: Dictionary, engine: Dictionary, dynamics: Dictionary, exact_dynamics: bool) -> TrafficRiderCarSpecs:
	var specs := TrafficRiderCarSpecs.new()
	var transmission: String = str(row.get("transmission_type", "6mt"))
	var drivetrain: String = str(row.get("drivetrain", "RWD"))
	var fuel: String = str(engine.get("fuel", "petrol"))
	var engine_key: String = str(row.get("engine_key", ""))
	var curve: EngineTorqueCurve = _torque_curves[engine_key]
	var idle_rpm: float = BmwF32EngineCurveFactory.get_idle_rpm(engine)
	var redline_rpm: float = BmwF32EngineCurveFactory.get_redline_rpm(engine)
	var peak_torque_rpm: float = BmwF32EngineCurveFactory.get_peak_torque_rpm(engine)
	var power_peak_rpm: float = BmwF32EngineCurveFactory.get_power_peak_rpm(engine)
	var target_zero_100: float = _number(dynamics, "zero_100_kph_s", 7.0)
	var target_top_speed: float = _number(dynamics, "top_speed_kph", 220.0)
	var tire_width: float = _parse_tire_width(str(dynamics.get("tire_size", "225/50 R17")))

	specs.resource_name = "BMW F32 %s specs" % str(row.get("candidate_id", "variant"))
	specs.display_name = _build_display_name(row)
	specs.data_quality = TrafficRiderCarSpecs.DataQuality.EVIDENCE_CONSTRAINED_SIMULATION
	specs.confidence_score = 0.88 if exact_dynamics else _confidence_for(str(row.get("evidence_status", "")))
	specs.evidence_basis = str(dynamics.get("source_id", "BMW family architecture, approved matrix and physics calibration targets"))
	specs.simulated_fields = PackedStringArray([
		"sampled_torque_curve",
		"engine_inertia",
		"drivetrain_losses",
		"chassis_balance",
		"tire_grip",
		"suspension",
		"powertrain_control_map",
		"engine_audio_profile",
	])
	if not exact_dynamics:
		specs.simulated_fields.append_array(PackedStringArray([
			"gear_ratios",
			"final_drive_ratio",
			"vehicle_mass",
			"aerodynamics",
			"performance_targets",
		]))
	specs.target_zero_100_s = target_zero_100
	specs.target_top_speed_kph = target_top_speed
	specs.traffic_rider_powertrain_definition = BmwF32PowertrainFactory.create(row, engine)
	specs.inline_engine_audio_profile = _audio_profiles[engine_key]

	specs.brake_deceleration = 10.15
	specs.reverse_acceleration = 6.2
	specs.coast_deceleration = 3.9 if fuel == "diesel" else 3.4
	specs.handbrake_deceleration = 17.0
	specs.max_forward_speed = target_top_speed / 3.6
	specs.max_reverse_speed = 11.0
	specs.steering_speed = 2.65 if drivetrain == "RWD" else 2.45
	specs.steering_response_rate = 7.2
	specs.max_yaw_rate_rad_s = 3.25
	specs.yaw_damping_per_second = 0.38
	specs.released_steering_yaw_damping_per_second = 0.95
	specs.low_speed_yaw_damping_per_second = 3.6
	specs.collision_yaw_response = 0.34
	specs.speed_limiter_strength = 8.0
	specs.wheel_base = 2.810
	specs.front_axle_track_width = 1.545 if drivetrain == "RWD" else 1.544
	specs.rear_axle_track_width = 1.594 if drivetrain == "RWD" else 1.590
	specs.max_steering_angle_degrees = 33.0

	specs.idle_rpm = idle_rpm
	specs.peak_torque_rpm = peak_torque_rpm
	specs.power_peak_rpm = power_peak_rpm
	specs.redline_rpm = redline_rpm
	specs.rev_limiter_rpm = redline_rpm + (150.0 if fuel == "diesel" else 200.0)
	specs.torque_curve = curve
	specs.low_rpm_torque_multiplier = curve.sample(1500.0)
	specs.mid_rpm_torque_multiplier = curve.sample(3000.0)
	specs.redline_torque_multiplier = curve.sample(redline_rpm)
	specs.engine_force = 24.0
	specs.engine_brake_force = 4.0 if fuel == "diesel" else 3.1
	specs.rpm_response = _rpm_response(engine)
	specs.engine_inertia_kg_m2 = _engine_inertia(engine)

	specs.transmission_type = CarSpecs.TransmissionType.AUTOMATIC if transmission == "8at" else CarSpecs.TransmissionType.MANUAL
	specs.gear_ratios = _read_ratios(dynamics, 8 if transmission == "8at" else 6)
	specs.reverse_gear_ratio = _number(dynamics, "reverse_ratio", 3.5)
	specs.final_drive_ratio = _number(dynamics, "final_drive_ratio", 3.2)
	specs.peak_engine_torque = _number(engine, "torque_nm", 300.0)
	specs.wheel_radius = _number(dynamics, "wheel_radius_m", 0.3284)
	specs.drivetrain_efficiency = 0.84 if transmission == "8at" else 0.88
	if drivetrain == "xDrive":
		specs.drivetrain_efficiency -= 0.03
	specs.shift_delay = 0.26 if transmission == "8at" else 0.18
	specs.max_drive_acceleration = 24.0
	specs.drive_layout = CarSpecs.DriveLayout.ALL_WHEEL_DRIVE if drivetrain == "xDrive" else CarSpecs.DriveLayout.REAR_WHEEL_DRIVE
	specs.awd_front_torque_fraction = 0.40
	specs.front_differential_lock = 0.0
	specs.rear_differential_lock = 0.08 if str(row.get("special_scope", "")) == "factory_special" else 0.0
	specs.center_differential_lock = 0.0

	specs.automatic_upshift_rpm = redline_rpm * (0.91 if fuel == "diesel" else 0.95)
	specs.automatic_downshift_rpm = maxf(idle_rpm + 250.0, peak_torque_rpm * (0.72 if fuel == "diesel" else 0.62))
	specs.automatic_kickdown_throttle = 0.74
	specs.automatic_kickdown_rpm = redline_rpm * (0.78 if fuel == "diesel" else 0.82)
	specs.automatic_shift_delay = 0.26
	specs.torque_converter_stall_rpm = clampf(peak_torque_rpm + (400.0 if fuel == "petrol" else 150.0), idle_rpm + 300.0, redline_rpm * 0.62)
	specs.torque_converter_coupling_rpm = clampf(peak_torque_rpm + 1100.0, specs.torque_converter_stall_rpm + 200.0, redline_rpm * 0.82)
	specs.torque_converter_stall_torque_multiplier = 1.82 if fuel == "petrol" else 1.94

	specs.vehicle_mass = _number(dynamics, "mass_din_kg", 1500.0)
	specs.drag_coefficient = _number(dynamics, "drag_coefficient", 0.29)
	specs.frontal_area = _number(dynamics, "frontal_area_m2", 2.16)
	specs.air_density = 1.225
	specs.rolling_resistance_coefficient = 0.0145
	specs.front_static_load_fraction = 0.515 if drivetrain == "xDrive" else 0.505
	specs.center_of_mass_height_m = 0.51
	specs.suspension_load_blend = 0.68
	specs.aerodynamic_lateral_area_multiplier = 1.12
	specs.body_pitch_response = 7.5
	specs.body_roll_response = 7.8
	specs.max_body_pitch_degrees = 3.6
	specs.max_body_roll_degrees = 5.2

	specs.front_lateral_grip = 10.55
	specs.rear_lateral_grip = 10.50 if drivetrain == "RWD" else 10.58
	specs.front_tire_width_m = tire_width
	specs.rear_tire_width_m = tire_width
	specs.longitudinal_grip_coefficient = 1.06
	specs.longitudinal_peak_slip_ratio = 0.115
	specs.longitudinal_slide_grip_multiplier = 0.80
	specs.lateral_slide_grip_multiplier = 0.88
	specs.traction_control_strength = 0.74
	specs.abs_strength = 0.92
	specs.handbrake_lateral_grip_multiplier = 0.26
	specs.steering_slip_gain = 0.84
	specs.slip_speed_threshold = 2.2
	specs.slip_steering_lock_threshold = 0.56
	specs.slip_steering_same_direction_multiplier = 0.13
	specs.skid_mark_min_slip = 0.44
	specs.skid_mark_interval = 0.055
	specs.skid_mark_lifetime = 10.0
	specs.skid_mark_width = tire_width
	specs.skid_mark_length = 0.88
	specs.front_brake_bias = 0.61
	specs.wheel_angular_damping_nm_per_rad_s = 0.08
	specs.wheel_slip_reference_speed_mps = 1.0

	specs.gravity = 30.0
	specs.floor_stick_force = 0.5
	specs.suspension_probe_height = 0.40
	specs.suspension_rest_length = 0.24
	specs.suspension_travel = 0.15
	specs.suspension_stiffness = 35.0 if drivetrain == "xDrive" else 34.0
	specs.suspension_damping = 5.9 if drivetrain == "xDrive" else 5.6
	specs.ground_probe_collision_mask = 1
	specs.minimum_ground_normal_dot = 0.35
	return specs


func _simulate_dynamics(row: Dictionary, engine: Dictionary) -> Dictionary:
	var transmission: String = str(row.get("transmission_type", "6mt"))
	var drivetrain: String = str(row.get("drivetrain", "RWD"))
	var fuel: String = str(engine.get("fuel", "petrol"))
	var cylinders: int = int(_number(engine, "cylinders", 4.0))
	var power_kw: float = _engine_power_kw(engine)
	var torque_nm: float = _number(engine, "torque_nm", 300.0)
	var mass: float = _base_mass(engine)
	if transmission == "8at":
		mass += 18.0
	if drivetrain == "xDrive":
		mass += 72.0 if cylinders <= 4 else 68.0
	if str(row.get("special_scope", "")) == "factory_special":
		mass += 8.0

	var result: Dictionary = {
		"candidate_id": str(row.get("candidate_id", "")),
		"engine_key": str(row.get("engine_key", "")),
		"transmission_type": transmission,
		"drivetrain": drivetrain,
		"mass_din_kg": mass,
		"mass_eu_kg": mass + 75.0,
		"tire_size": "225/50 R17",
		"wheel_radius_m": 0.3284,
		"drag_coefficient": (0.28 if fuel == "diesel" else 0.29) + (0.01 if drivetrain == "xDrive" else 0.0),
		"frontal_area_m2": 2.16,
		"source_id": "BMW_F32_EVIDENCE_CONSTRAINED_SIMULATION_20260716",
		"data_class": "evidence_constrained_simulation",
	}
	var ratios: Array[float] = _simulated_ratios(transmission, fuel, cylinders)
	for index: int in range(ratios.size()):
		result["ratio_%d" % (index + 1)] = ratios[index]
	result["reverse_ratio"] = 3.295 if transmission == "8at" else 3.187 if fuel == "petrol" and cylinders <= 4 else 3.727
	result["final_drive_ratio"] = _simulated_final_drive(transmission, fuel, cylinders, torque_nm)
	result["zero_100_kph_s"] = _estimate_zero_100(mass, power_kw, transmission, drivetrain)
	result["top_speed_kph"] = _estimate_top_speed(power_kw, fuel)
	return result


func _simulated_ratios(transmission: String, fuel: String, cylinders: int) -> Array[float]:
	if transmission == "8at":
		return [4.714, 3.143, 2.106, 1.667, 1.285, 1.000, 0.839, 0.667]
	if fuel == "diesel":
		return [4.110, 2.248, 1.403, 1.000, 0.802, 0.659]
	if cylinders >= 6:
		return [4.110, 2.315, 1.542, 1.179, 1.000, 0.846]
	return [3.498, 2.005, 1.313, 1.000, 0.809, 0.701]


func _simulated_final_drive(transmission: String, fuel: String, cylinders: int, torque_nm: float) -> float:
	if transmission == "8at":
		if fuel == "diesel":
			return 2.813 if torque_nm < 600.0 else 2.563
		return 3.154
	if fuel == "diesel" or cylinders >= 6:
		return 3.231
	return 3.909


func _base_mass(engine: Dictionary) -> float:
	var key: String = str(engine.get("engine_key", ""))
	var fuel: String = str(engine.get("fuel", "petrol"))
	var cylinders: int = int(_number(engine, "cylinders", 4.0))
	var power_kw: float = _engine_power_kw(engine)
	if key.begins_with("b38"):
		return 1380.0
	if cylinders == 6 and fuel == "diesel":
		return 1585.0 + clampf((power_kw - 190.0) * 0.35, 0.0, 18.0)
	if cylinders == 6:
		return 1510.0 + clampf((power_kw - 225.0) * 0.55, 0.0, 20.0)
	if fuel == "diesel":
		return 1440.0 + clampf((power_kw - 105.0) * 0.30, 0.0, 32.0)
	return 1415.0 + clampf((power_kw - 100.0) * 0.32, 0.0, 34.0)


func _estimate_zero_100(mass_kg: float, power_kw: float, transmission: String, drivetrain: String) -> float:
	var estimate: float = 2.25 + 0.48 * mass_kg / maxf(power_kw, 1.0)
	if transmission == "8at":
		estimate -= 0.15
	if drivetrain == "xDrive":
		estimate -= 0.18 + clampf((power_kw - 170.0) / 300.0, 0.0, 0.18)
	return snappedf(clampf(estimate, 4.4, 10.5), 0.1)


func _estimate_top_speed(power_kw: float, fuel: String) -> float:
	if power_kw >= 180.0:
		return 250.0
	if power_kw >= 150.0:
		return 245.0 if fuel == "diesel" else 250.0
	if power_kw >= 130.0:
		return 235.0
	if power_kw >= 110.0:
		return 220.0
	return 210.0


func _engine_power_kw(engine: Dictionary) -> float:
	var power_kw: float = _number(engine, "power_kw", 0.0)
	if power_kw <= 0.0:
		power_kw = _number(engine, "power_hp", 100.0) * 0.745699872
	return power_kw


func _engine_inertia(engine: Dictionary) -> float:
	var cylinders: float = _number(engine, "cylinders", 4.0)
	var diesel_bonus: float = 0.09 if str(engine.get("fuel", "petrol")) == "diesel" else 0.0
	return 0.10 + cylinders * 0.025 + diesel_bonus


func _rpm_response(engine: Dictionary) -> float:
	var cylinders: int = int(_number(engine, "cylinders", 4.0))
	var fuel: String = str(engine.get("fuel", "petrol"))
	if fuel == "diesel":
		return 5.7 if cylinders == 6 else 6.1
	return 7.0 if cylinders == 6 else 7.8 if cylinders == 4 else 8.2


func _build_display_name(row: Dictionary) -> String:
	return "BMW F32 %s %s %s" % [str(row.get("badge", "4 Series")), str(row.get("drivetrain", "RWD")), str(row.get("transmission_type", "6mt")).to_upper()]


func _read_ratios(row: Dictionary, count: int) -> Array[float]:
	var ratios: Array[float] = []
	for index: int in range(1, count + 1):
		var value: String = str(row.get("ratio_%d" % index, "")).strip_edges()
		if value.is_valid_float():
			ratios.append(value.to_float())
	return ratios


func _read_csv(path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("BMW F32 could not open calibration data: %s" % path)
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


func _index_by(rows: Array[Dictionary], field: String) -> Dictionary:
	var result: Dictionary = {}
	for row: Dictionary in rows:
		var key: String = str(row.get(field, ""))
		if not key.is_empty():
			result[key] = row
	return result


func _confidence_for(status: String) -> float:
	if status.contains("verified"):
		return 0.78
	if status.contains("strongly_supported"):
		return 0.70
	return 0.58


func _parse_tire_width(tire_size: String) -> float:
	var slash_index: int = tire_size.find("/")
	if slash_index <= 0:
		return 0.225
	var width_text: String = tire_size.substr(0, slash_index).strip_edges()
	return width_text.to_float() / 1000.0 if width_text.is_valid_float() else 0.225


func _number(row: Dictionary, field: String, fallback: float) -> float:
	var text: String = str(row.get(field, "")).strip_edges()
	return text.to_float() if text.is_valid_float() else fallback
