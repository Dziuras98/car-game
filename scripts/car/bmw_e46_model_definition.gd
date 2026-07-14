extends CarModelDefinition
class_name BmwE46ModelDefinition

const PLAYER_SCENE: PackedScene = preload("res://scenes/cars/bmw_e46_sedan.tscn")
const AI_SCENE: PackedScene = preload("res://scenes/cars/bmw_e46_sedan_ai.tscn")
const ENGINE_CATALOG_PATH := "res://resources/cars/bmw/e46_sedan/data/bmw_e46_sedan_engines.data"
const ENGINE_RUNTIME_PATH := "res://resources/cars/bmw/e46_sedan/data/bmw_e46_sedan_engine_runtime_targets.data"
const DYNAMICS_PATHS: Array[String] = [
	"res://resources/cars/bmw/e46_sedan/data/bmw_e46_sedan_drivetrain_dynamics_petrol.data",
	"res://resources/cars/bmw/e46_sedan/data/bmw_e46_sedan_drivetrain_dynamics_diesel.data",
]
const CURVE_PATHS: Array[String] = [
	"res://resources/cars/bmw/e46_sedan/data/bmw_e46_sedan_torque_curves_petrol_4cyl.data",
	"res://resources/cars/bmw/e46_sedan/data/bmw_e46_sedan_torque_curves_petrol_6cyl_eu.data",
	"res://resources/cars/bmw/e46_sedan/data/bmw_e46_sedan_torque_curves_petrol_6cyl_regional.data",
	"res://resources/cars/bmw/e46_sedan/data/bmw_e46_sedan_torque_curves_diesel.data",
]

var _audio_profiles: Dictionary = {}

func _init() -> void:
	manufacturer = "BMW"
	model_id = &"bmw_e46_sedan"
	display_name = "3 Series Sedan"
	generation = "E46/4 non-M"
	production_year_start = 1998
	production_year_end = 2005
	default_variant_id = &"bmw_e46_sedan_330i_6mt"
	_build_variants()

func get_audio_profile(engine_key: StringName) -> BmwE46EngineAudioProfile:
	return _audio_profiles.get(str(engine_key)) as BmwE46EngineAudioProfile

func _build_variants() -> void:
	variants.clear()
	var engines: Dictionary = _load_engines()
	var runtime_targets: Dictionary = _index_by(_read_csv(ENGINE_RUNTIME_PATH), "engine_key")
	for key: String in runtime_targets:
		var runtime_row: Dictionary = runtime_targets[key]
		if engines.has(key):
			var engine_row: Dictionary = engines[key]
			for field: Variant in engine_row.keys():
				runtime_row[field] = engine_row[field]
		_audio_profiles[key] = BmwE46AudioProfileFactory.create(runtime_row)
	var curves: Dictionary = _load_curves(runtime_targets)
	var sort_order: int = 0
	for path: String in DYNAMICS_PATHS:
		for row: Dictionary in _read_csv(path):
			var engine_key: String = str(row.get("engine_key", ""))
			if not runtime_targets.has(engine_key) or not curves.has(engine_key):
				push_error("BMW E46 dataset is missing engine data for %s" % engine_key)
				continue
			var specs: CarSpecs = _build_specs(row, runtime_targets[engine_key], curves[engine_key], _audio_profiles[engine_key])
			var variant := CarVariantDefinition.new()
			var candidate_id: String = str(row.get("candidate_id", "variant"))
			variant.variant_id = StringName("bmw_e46_sedan_%s" % candidate_id)
			variant.display_name = _build_variant_display_name(row)
			variant.sort_order = sort_order
			variant.car_scene = PLAYER_SCENE
			variant.ai_car_scene = AI_SCENE
			variant.specs = specs
			variant.ai_eligible = true
			variant.engine_label = str(runtime_targets[engine_key].get("engine_code", engine_key))
			variant.drivetrain_label = str(row.get("drivetrain", "RWD"))
			variants.append(variant)
			sort_order += 1

func _load_engines() -> Dictionary:
	return _index_by(_read_csv(ENGINE_CATALOG_PATH), "engine_key")

func _load_curves(runtime_targets: Dictionary) -> Dictionary:
	var raw_points: Dictionary = {}
	for path: String in CURVE_PATHS:
		for row: Dictionary in _read_csv(path):
			var key: String = str(row.get("engine_key", ""))
			if not raw_points.has(key): raw_points[key] = []
			raw_points[key].append(row)
	var result: Dictionary = {}
	for key: String in raw_points:
		if not runtime_targets.has(key): continue
		var peak_torque: float = _float(runtime_targets[key], "peak_torque_nm", 1.0)
		var points: Array = raw_points[key]
		points.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return _float(left, "rpm", 0.0) < _float(right, "rpm", 0.0))
		var curve := EngineTorqueCurve.new()
		var rpm_points := PackedFloat32Array()
		var multipliers := PackedFloat32Array()
		for point: Dictionary in points:
			rpm_points.append(_float(point, "rpm", 0.0))
			multipliers.append(maxf(_float(point, "torque_nm", 0.0) / maxf(peak_torque, 1.0), 0.0))
		curve.rpm_points = rpm_points
		curve.torque_multipliers = multipliers
		curve.resource_name = "BMW E46 %s torque curve" % key
		result[key] = curve
	return result

func _build_specs(row: Dictionary, engine: Dictionary, curve: EngineTorqueCurve, audio_profile: BmwE46EngineAudioProfile) -> CarSpecs:
	var specs := CarSpecs.new()
	var transmission: String = str(row.get("transmission_type", "manual"))
	var fuel: String = str(engine.get("fuel", "petrol"))
	var drivetrain: String = str(row.get("drivetrain", "RWD"))
	var lateral_g: float = _float(row, "lateral_accel_g_target", 0.80)
	var brake_decel: float = _float(row, "brake_deceleration_target_mps2", 9.8)
	var tire_width: float = _parse_tire_width(str(row.get("tire_size", "205/55 R16")))
	var redline: float = _float(engine, "redline_rpm", 6500.0)
	var peak_torque_rpm: float = _float(engine, "torque_peak_start_rpm", 3500.0)
	var gear_ratios: Array[float] = []
	for index: int in range(1, 7):
		var ratio_text: String = str(row.get("ratio_%d" % index, "")).strip_edges()
		if ratio_text.is_valid_float(): gear_ratios.append(ratio_text.to_float())

	specs.display_name = _build_variant_display_name(row)
	specs.brake_deceleration = brake_decel
	specs.reverse_acceleration = 6.5
	specs.coast_deceleration = 3.6 if fuel == "petrol" else 4.1
	specs.handbrake_deceleration = 17.0
	specs.max_forward_speed = _float(row, "vmax_kph", 200.0) / 3.6
	specs.max_reverse_speed = 10.5
	specs.steering_speed = 2.75 if drivetrain == "RWD" else 2.45
	specs.wheel_base = _float(row, "wheelbase_m", 2.725)
	specs.front_axle_track_width = _float(row, "front_track_m", 1.481)
	specs.rear_axle_track_width = _float(row, "rear_track_m", 1.493)
	specs.max_steering_angle_degrees = _float(row, "max_road_wheel_angle_deg", 33.0)

	specs.idle_rpm = _float(engine, "idle_rpm", 750.0)
	specs.peak_torque_rpm = peak_torque_rpm
	specs.power_peak_rpm = _float(engine, "power_peak_rpm", 6000.0)
	specs.redline_rpm = redline
	specs.rev_limiter_rpm = _float(engine, "rev_limiter_rpm", redline + 200.0)
	specs.torque_curve = curve
	specs.low_rpm_torque_multiplier = _float(engine, "torque_multiplier_1500", curve.sample(1500.0))
	specs.mid_rpm_torque_multiplier = _float(engine, "torque_multiplier_3000", curve.sample(3000.0))
	specs.redline_torque_multiplier = _float(engine, "torque_multiplier_redline", curve.sample(redline))
	specs.engine_force = 24.0
	specs.engine_brake_force = _float(engine, "engine_brake_force_gameplay_seed", 3.0)
	specs.rpm_response = _float(engine, "rpm_response_gameplay_seed", 7.0)
	specs.engine_audio_profile = audio_profile

	specs.transmission_type = CarSpecs.TransmissionType.MANUAL if transmission == "manual" else CarSpecs.TransmissionType.AUTOMATIC
	specs.smg_enabled = transmission == "automated_manual"
	specs.gear_ratios = gear_ratios
	specs.reverse_gear_ratio = _float(row, "reverse_ratio", 3.5)
	specs.final_drive_ratio = _float(row, "final_drive_ratio", 3.2)
	specs.peak_engine_torque = _float(engine, "peak_torque_nm", 200.0)
	specs.wheel_radius = _float(row, "wheel_radius_m", 0.316)
	specs.drivetrain_efficiency = 0.86 if transmission != "automatic" else 0.82
	if drivetrain == "AWD": specs.drivetrain_efficiency -= 0.03
	specs.shift_delay = 0.30 if gear_ratios.size() <= 5 else 0.26
	specs.max_drive_acceleration = 18.0 if fuel == "petrol" else 16.5

	var automatic_upshift: float = minf(redline * (0.94 if fuel == "petrol" else 0.90), redline)
	var automatic_downshift: float = maxf(specs.idle_rpm, peak_torque_rpm * (0.55 if fuel == "petrol" else 0.70))
	specs.automatic_upshift_rpm = automatic_upshift
	specs.automatic_downshift_rpm = minf(automatic_downshift, automatic_upshift - 200.0)
	specs.automatic_kickdown_throttle = 0.76
	specs.automatic_kickdown_rpm = minf(redline * 0.80, redline)
	specs.automatic_shift_delay = 0.30
	specs.torque_converter_stall_rpm = clampf(peak_torque_rpm * 0.65, specs.idle_rpm, redline * 0.65)
	specs.torque_converter_coupling_rpm = clampf(peak_torque_rpm, specs.torque_converter_stall_rpm, redline)
	specs.torque_converter_stall_torque_multiplier = 1.75 if fuel == "petrol" else 1.90
	if specs.smg_enabled:
		specs.smg_auto_mode = true
		specs.smg_shift_delay = 0.24 if gear_ratios.size() <= 5 else 0.18
		specs.smg_launch_full_speed = 4.5
		specs.smg_upshift_rpm = minf(redline * 0.96, redline)
		specs.smg_downshift_rpm = maxf(specs.idle_rpm + 300.0, peak_torque_rpm * 0.55)
		specs.smg_clutch_reengage_point = 0.46

	specs.vehicle_mass = _float(row, "mass_din_kg", 1400.0)
	specs.drag_coefficient = _float(row, "drag_coefficient", 0.30)
	specs.frontal_area = _float(row, "frontal_area_m2", 2.06)
	specs.air_density = 1.225
	specs.rolling_resistance_coefficient = 0.0145 if tire_width <= 0.205 else 0.015

	var lateral_grip: float = lateral_g * 12.0
	specs.front_lateral_grip = lateral_grip
	specs.rear_lateral_grip = lateral_grip * (1.0 if drivetrain == "AWD" else 0.985)
	specs.front_tire_width_m = tire_width
	specs.rear_tire_width_m = tire_width
	specs.longitudinal_grip_coefficient = clampf(brake_decel / 9.81, 0.88, 1.12)
	specs.longitudinal_peak_slip_ratio = 0.12
	specs.longitudinal_slide_grip_multiplier = 0.78
	specs.handbrake_lateral_grip_multiplier = 0.26
	specs.steering_slip_gain = 0.85
	specs.slip_speed_threshold = 2.2
	specs.slip_steering_lock_threshold = 0.55
	specs.slip_steering_same_direction_multiplier = 0.13
	specs.skid_mark_min_slip = 0.44
	specs.skid_mark_interval = 0.055
	specs.skid_mark_lifetime = 10.0
	specs.skid_mark_width = tire_width
	specs.skid_mark_length = 0.86

	specs.gravity = 30.0
	specs.floor_stick_force = 0.52
	specs.suspension_probe_height = 0.39
	specs.suspension_rest_length = 0.25
	specs.suspension_travel = 0.16
	specs.suspension_stiffness = 33.0 if drivetrain == "RWD" else 34.0
	specs.suspension_damping = 5.4 if drivetrain == "RWD" else 5.7
	specs.ground_probe_collision_mask = 1
	specs.minimum_ground_normal_dot = 0.35
	return specs

func _build_variant_display_name(row: Dictionary) -> String:
	var badge: String = str(row.get("badge", "E46"))
	var transmission: String = str(row.get("transmission_type", "manual"))
	var gear_count: int = 0
	for index: int in range(1, 7):
		if str(row.get("ratio_%d" % index, "")).strip_edges().is_valid_float(): gear_count += 1
	var suffix: String
	match transmission:
		"automatic": suffix = "%dAT" % gear_count
		"automated_manual": suffix = "%dSMG" % gear_count
		_: suffix = "%dMT" % gear_count
	return "BMW E46 %s %s %s" % [badge, str(row.get("drivetrain", "RWD")), suffix]

func _read_csv(path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("BMW E46 could not open calibration data: %s" % path)
		return result
	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if values.is_empty() or values[0].strip_edges().is_empty(): continue
		var row: Dictionary = {}
		for index: int in range(mini(headers.size(), values.size())):
			row[headers[index]] = values[index]
		result.append(row)
	return result

func _index_by(rows: Array[Dictionary], field: String) -> Dictionary:
	var result: Dictionary = {}
	for row: Dictionary in rows:
		var key: String = str(row.get(field, ""))
		if not key.is_empty(): result[key] = row
	return result

func _float(row: Dictionary, field: String, fallback: float) -> float:
	var text: String = str(row.get(field, "")).strip_edges()
	return text.to_float() if text.is_valid_float() else fallback

func _parse_tire_width(tire_size: String) -> float:
	var slash_index: int = tire_size.find("/")
	if slash_index <= 0: return 0.205
	var width_text: String = tire_size.substr(0, slash_index).strip_edges()
	return width_text.to_float() / 1000.0 if width_text.is_valid_float() else 0.205
