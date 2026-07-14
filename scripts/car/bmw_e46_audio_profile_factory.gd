extends RefCounted
class_name BmwE46AudioProfileFactory

static func create(engine: Dictionary) -> BmwE46EngineAudioProfile:
	var profile := BmwE46EngineAudioProfile.new()
	var key: String = str(engine.get("engine_key", "unknown"))
	var code: String = str(engine.get("engine_code", key))
	var fuel: String = str(engine.get("fuel", "petrol"))
	var displacement: float = _to_float(engine.get("displacement_cc", "2000"), 2000.0)
	var power_kw: float = _to_float(engine.get("peak_power_kw", engine.get("power_kw", "100")), 100.0)
	var cylinders: int = int(_to_float(engine.get("cylinders", "6"), 6.0))
	var redline: float = _to_float(engine.get("redline_rpm", "6500"), 6500.0)
	profile.resource_name = "BMW E46 %s audio" % code
	profile.family_id = StringName(key)
	profile.cylinders = cylinders
	profile.engine_layout = "inline"
	profile.firing_order = _firing_order(cylinders, fuel)
	profile.aspiration = "turbocharged" if fuel == "diesel" else "naturally_aspirated"
	profile.idle_volume_db = -12.0
	profile.load_volume_db = -1.0
	profile.output_volume_boost_db = 10.5
	profile.synthesis_gain_db = 0.5
	profile.starter_duration = 0.82 if fuel == "petrol" else 1.05
	profile.starter_motor_level = 0.25 if fuel == "petrol" else 0.34
	profile.shutdown_duration = 1.0 if fuel == "petrol" else 1.25
	profile.limiter_period = 0.055 if fuel == "petrol" else 0.075
	profile.limiter_cut_ratio = 0.42 if fuel == "petrol" else 0.52
	profile.limiter_residual_combustion = 0.17 if fuel == "petrol" else 0.10
	profile.rpm_smoothing = 13.5 if fuel == "petrol" else 10.0
	profile.throttle_smoothing = 17.0 if fuel == "petrol" else 12.5
	if fuel == "diesel":
		_configure_diesel(profile, key, cylinders, displacement, power_kw)
	elif cylinders == 4:
		_configure_petrol_four(profile, key, displacement, power_kw, redline)
	else:
		_configure_petrol_six(profile, key, displacement, power_kw, redline)
	return profile

static func _configure_petrol_four(profile: BmwE46EngineAudioProfile, key: String, displacement: float, power_kw: float, redline: float) -> void:
	var modern: bool = key.begins_with("n4")
	var power_factor: float = clampf((power_kw - 75.0) / 40.0, 0.0, 1.0)
	profile.high_rpm_rasp = 0.12 + power_factor * 0.10
	profile.intake_presence = (0.20 if modern else 0.14) + power_factor * 0.08
	profile.intake_plenum_detail = 0.13 if modern else 0.07
	profile.airflow_noise = 0.08 + power_factor * 0.05
	profile.induction_transient = 0.28 + power_factor * 0.10
	profile.mechanical_noise = 0.10 if modern else 0.13
	profile.rotating_assembly_detail = 0.08 if modern else 0.10
	profile.exhaust_resonance = 0.44 + clampf((displacement - 1600.0) / 500.0, 0.0, 1.0) * 0.08
	profile.exhaust_roughness = 0.18 if modern else 0.23
	profile.exhaust_bank_separation = 0.02
	profile.exhaust_reflection = 0.10
	profile.overrun_crackle = 0.045 if modern else 0.03
	profile.bank_asymmetry = 0.01
	profile.idle_irregularity = 0.045 if modern else 0.065
	profile.combustion_sharpness = 0.38 if modern else 0.31
	profile.exhaust_pitch_scale = 1.04 if displacement < 1800.0 else 1.0
	profile.intake_pitch_scale = 1.05 if redline >= 6500.0 else 1.0

static func _configure_petrol_six(profile: BmwE46EngineAudioProfile, key: String, displacement: float, power_kw: float, redline: float) -> void:
	var m54: bool = key.begins_with("m54") or key.begins_with("m56")
	var sport: bool = key.contains("zhp") or power_kw >= 165.0
	var size_factor: float = clampf((displacement - 2000.0) / 1000.0, 0.0, 1.0)
	profile.high_rpm_rasp = 0.08 + (0.07 if sport else 0.03)
	profile.intake_presence = 0.19 + size_factor * 0.08 + (0.04 if sport else 0.0)
	profile.intake_plenum_detail = 0.15 + (0.04 if m54 else 0.0)
	profile.airflow_noise = 0.06 + size_factor * 0.05
	profile.induction_transient = 0.30 + (0.07 if sport else 0.02)
	profile.mechanical_noise = 0.045 if m54 else 0.06
	profile.rotating_assembly_detail = 0.045
	profile.exhaust_resonance = 0.57 + size_factor * 0.12 + (0.05 if sport else 0.0)
	profile.exhaust_roughness = 0.09 + (0.04 if sport else 0.0)
	profile.exhaust_bank_separation = 0.01
	profile.exhaust_reflection = 0.12 + size_factor * 0.04
	profile.overrun_crackle = 0.06 + (0.05 if sport else 0.0)
	profile.bank_asymmetry = 0.005
	profile.idle_irregularity = 0.012 if m54 else 0.018
	profile.combustion_sharpness = 0.26 + (0.06 if sport else 0.0)
	profile.exhaust_pitch_scale = lerpf(1.04, 0.93, size_factor)
	profile.intake_pitch_scale = 1.0 + (0.03 if redline >= 6800.0 else 0.0)
	if key.contains("sulev"):
		profile.exhaust_resonance *= 0.82
		profile.load_volume_db -= 1.5
		profile.output_volume_boost_db -= 0.5

static func _configure_diesel(profile: BmwE46EngineAudioProfile, key: String, cylinders: int, displacement: float, power_kw: float) -> void:
	var six: bool = cylinders == 6
	var tu: bool = key.contains("tu")
	var power_factor: float = clampf((power_kw - 80.0) / 80.0, 0.0, 1.0)
	profile.idle_volume_db = -9.5
	profile.load_volume_db = -0.5
	profile.output_volume_boost_db = 9.5
	profile.synthesis_gain_db = 0.0
	profile.high_rpm_rasp = 0.015
	profile.intake_presence = 0.08 + power_factor * 0.05
	profile.intake_plenum_detail = 0.035
	profile.airflow_noise = 0.16 + power_factor * 0.08
	profile.induction_transient = 0.12
	profile.mechanical_noise = 0.18 if six else 0.24
	profile.rotating_assembly_detail = 0.14 if six else 0.18
	profile.exhaust_resonance = 0.48 + clampf((displacement - 1900.0) / 1100.0, 0.0, 1.0) * 0.16
	profile.exhaust_roughness = 0.17 if six else 0.26
	profile.exhaust_bank_separation = 0.01
	profile.exhaust_reflection = 0.08
	profile.overrun_crackle = 0.005
	profile.bank_asymmetry = 0.008
	profile.idle_irregularity = 0.055 if six else 0.085
	profile.combustion_sharpness = 0.66 if tu else 0.72
	profile.diesel_combustion = 0.72 if six else 0.82
	profile.diesel_injection_rattle = 0.50 if tu else 0.64
	profile.diesel_mechanical_clatter = 0.46 if six else 0.62
	profile.turbo_whistle = 0.34 + power_factor * 0.16
	profile.turbo_flutter = 0.025
	profile.turbo_blowoff = 0.0
	profile.turbo_spool_start_rpm = 1250.0 if six else 1450.0
	profile.turbo_full_spool_rpm = 1900.0 if six else 2200.0
	profile.turbo_pitch_scale = 0.90 if six else 1.08
	profile.exhaust_pitch_scale = 0.83 if six else 0.94
	profile.intake_pitch_scale = 0.90 if six else 1.0

static func _firing_order(cylinders: int, fuel: String) -> String:
	if cylinders == 6: return "1-5-3-6-2-4"
	if fuel == "diesel": return "1-3-4-2"
	return "1-3-4-2"

static func _to_float(value: Variant, fallback: float) -> float:
	var text: String = str(value).strip_edges()
	return text.to_float() if text.is_valid_float() else fallback
