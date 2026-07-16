extends RefCounted
class_name BmwF32AudioProfileFactory


static func create(engine: Dictionary) -> TrafficRiderInlineEngineAudioProfile:
	var profile := TrafficRiderInlineEngineAudioProfile.new()
	var key: String = str(engine.get("engine_key", "unknown"))
	var code: String = str(engine.get("engine_code", key))
	var fuel: String = str(engine.get("fuel", "petrol"))
	var cylinders: int = int(_number(engine, "cylinders", 4.0))
	var displacement: float = _number(engine, "displacement_cc", 2000.0)
	var aspiration: String = str(engine.get("aspiration", "turbo"))

	profile.resource_name = "BMW F32 %s physical audio" % key
	profile.engine_family_id = StringName(key)
	profile.display_name = "%s %s" % [code, _architecture_name(cylinders, fuel, aspiration)]
	profile.cylinder_count = cylinders
	profile.firing_order = _firing_order(cylinders)
	profile.collector_group_by_cylinder = _collector_routing(key, cylinders, aspiration)
	profile.combustion_type = TrafficRiderInlineEngineAudioProfile.CombustionType.DIESEL_COMMON_RAIL if fuel == "diesel" else TrafficRiderInlineEngineAudioProfile.CombustionType.PETROL_DIRECT_INJECTION
	profile.aspiration_type = _aspiration_type(fuel, aspiration)
	profile.idle_rpm = BmwF32EngineCurveFactory.get_idle_rpm(engine)
	profile.redline_rpm = BmwF32EngineCurveFactory.get_redline_rpm(engine)
	profile.limiter_period_s = 0.074 if fuel == "diesel" else 0.052
	profile.limiter_cut_fraction = 0.50 if fuel == "diesel" else 0.42
	profile.limiter_residual_combustion = 0.28 if fuel == "diesel" else 0.17
	profile.synthesis_gain = 0.21 if cylinders == 6 else 0.19
	profile.peak_limit = 0.91

	_configure_common(profile, fuel, cylinders, displacement)
	if key.begins_with("b38"):
		_configure_b38(profile)
	elif key.begins_with("n20"):
		_configure_n20(profile)
	elif key.begins_with("b48"):
		_configure_b48(profile)
	elif key.begins_with("n55"):
		_configure_n55(profile, key.contains("zhp"))
	elif key.begins_with("b58"):
		_configure_b58(profile)
	elif key.begins_with("n47"):
		_configure_n47(profile, aspiration == "twin_turbo")
	elif key.begins_with("b47"):
		_configure_b47(profile, aspiration == "twin_turbo")
	elif key.begins_with("n57"):
		_configure_n57(profile, aspiration == "twin_turbo")
	else:
		_configure_unknown(profile, fuel)
	return profile


static func _configure_common(profile: TrafficRiderInlineEngineAudioProfile, fuel: String, cylinders: int, displacement: float) -> void:
	var size_factor: float = clampf((displacement - 1500.0) / 1500.0, 0.0, 1.0)
	profile.combustion_sharpness = 0.72 if fuel == "diesel" else 0.42
	profile.combustion_level = 0.78 if fuel == "diesel" else 0.68
	profile.intake_level = 0.24 + size_factor * 0.10
	profile.exhaust_level = 0.56 + size_factor * 0.14
	profile.mechanical_level = 0.29 if fuel == "diesel" else 0.12
	profile.injector_level = 0.34 if fuel == "diesel" else 0.16
	profile.diesel_clatter_level = 0.58 if fuel == "diesel" else 0.0
	profile.intake_resonance_hz = 128.0 - size_factor * 28.0
	profile.exhaust_resonance_hz = 92.0 - size_factor * 22.0
	profile.mechanical_order = float(cylinders) * 0.5 + (1.0 if fuel == "diesel" else 0.5)
	profile.collector_separation = 0.18 if cylinders == 6 else 0.11
	profile.idle_irregularity = 0.075 if fuel == "diesel" and cylinders == 4 else 0.035 if fuel == "diesel" else 0.026 if cylinders == 3 else 0.012
	profile.turbo_spool_rate_per_s = 2.8 if fuel == "diesel" else 3.6
	profile.turbo_release_rate_per_s = 1.8 if fuel == "diesel" else 2.4
	profile.turbo_whine_base_hz = 620.0 if fuel == "diesel" else 760.0
	profile.turbo_whine_range_hz = 3650.0 if fuel == "diesel" else 5200.0
	profile.turbo_whine_level = 0.20 if fuel == "diesel" else 0.17
	profile.turbine_level = 0.22 if fuel == "diesel" else 0.15
	profile.wastegate_level = 0.045 if fuel == "diesel" else 0.11
	profile.release_level = 0.0 if fuel == "diesel" else 0.10


static func _configure_b38(profile: TrafficRiderInlineEngineAudioProfile) -> void:
	profile.combustion_sharpness = 0.48
	profile.combustion_level = 0.70
	profile.intake_level = 0.34
	profile.exhaust_level = 0.58
	profile.mechanical_level = 0.16
	profile.injector_level = 0.19
	profile.intake_resonance_hz = 146.0
	profile.exhaust_resonance_hz = 108.0
	profile.mechanical_order = 2.0
	profile.collector_separation = 0.04
	profile.idle_irregularity = 0.032
	profile.turbo_spool_rate_per_s = 4.1
	profile.turbo_release_rate_per_s = 2.8
	profile.turbo_whine_base_hz = 920.0
	profile.turbo_whine_range_hz = 5700.0
	profile.turbo_whine_level = 0.19
	profile.turbine_level = 0.13
	profile.wastegate_level = 0.12
	profile.release_level = 0.09


static func _configure_n20(profile: TrafficRiderInlineEngineAudioProfile) -> void:
	profile.combustion_sharpness = 0.46
	profile.intake_level = 0.31
	profile.exhaust_level = 0.64
	profile.mechanical_level = 0.17
	profile.injector_level = 0.20
	profile.intake_resonance_hz = 132.0
	profile.exhaust_resonance_hz = 91.0
	profile.collector_separation = 0.30
	profile.turbo_spool_rate_per_s = 3.4
	profile.turbo_whine_level = 0.18
	profile.turbine_level = 0.17
	profile.wastegate_level = 0.15
	profile.release_level = 0.13


static func _configure_b48(profile: TrafficRiderInlineEngineAudioProfile) -> void:
	profile.combustion_sharpness = 0.39
	profile.intake_level = 0.29
	profile.exhaust_level = 0.58
	profile.mechanical_level = 0.11
	profile.injector_level = 0.23
	profile.intake_resonance_hz = 138.0
	profile.exhaust_resonance_hz = 96.0
	profile.collector_separation = 0.27
	profile.turbo_spool_rate_per_s = 3.9
	profile.turbo_whine_base_hz = 840.0
	profile.turbo_whine_level = 0.16
	profile.turbine_level = 0.14
	profile.wastegate_level = 0.10
	profile.release_level = 0.09


static func _configure_n55(profile: TrafficRiderInlineEngineAudioProfile, zhp: bool) -> void:
	profile.combustion_sharpness = 0.29
	profile.combustion_level = 0.66
	profile.intake_level = 0.41 + (0.05 if zhp else 0.0)
	profile.exhaust_level = 0.75 + (0.07 if zhp else 0.0)
	profile.mechanical_level = 0.075
	profile.injector_level = 0.13
	profile.intake_resonance_hz = 103.0
	profile.exhaust_resonance_hz = 69.0
	profile.mechanical_order = 3.5
	profile.collector_separation = 0.36
	profile.idle_irregularity = 0.008
	profile.turbo_spool_rate_per_s = 3.15
	profile.turbo_whine_base_hz = 720.0
	profile.turbo_whine_range_hz = 4700.0
	profile.turbo_whine_level = 0.16
	profile.turbine_level = 0.18
	profile.wastegate_level = 0.12
	profile.release_level = 0.12


static func _configure_b58(profile: TrafficRiderInlineEngineAudioProfile) -> void:
	profile.combustion_sharpness = 0.25
	profile.combustion_level = 0.64
	profile.intake_level = 0.44
	profile.exhaust_level = 0.71
	profile.mechanical_level = 0.055
	profile.injector_level = 0.14
	profile.intake_resonance_hz = 98.0
	profile.exhaust_resonance_hz = 66.0
	profile.mechanical_order = 3.5
	profile.collector_separation = 0.34
	profile.idle_irregularity = 0.006
	profile.turbo_spool_rate_per_s = 3.75
	profile.turbo_whine_base_hz = 780.0
	profile.turbo_whine_range_hz = 5100.0
	profile.turbo_whine_level = 0.15
	profile.turbine_level = 0.16
	profile.wastegate_level = 0.085
	profile.release_level = 0.08


static func _configure_n47(profile: TrafficRiderInlineEngineAudioProfile, twin: bool) -> void:
	profile.combustion_sharpness = 0.80
	profile.combustion_level = 0.83
	profile.intake_level = 0.22
	profile.exhaust_level = 0.56
	profile.mechanical_level = 0.34
	profile.injector_level = 0.42
	profile.diesel_clatter_level = 0.70
	profile.intake_resonance_hz = 116.0
	profile.exhaust_resonance_hz = 82.0
	profile.collector_separation = 0.05
	profile.turbo_whine_level = 0.23
	profile.turbine_level = 0.28
	profile.wastegate_level = 0.035
	_configure_second_stage(profile, twin, 0.46, 0.33)


static func _configure_b47(profile: TrafficRiderInlineEngineAudioProfile, twin: bool) -> void:
	profile.combustion_sharpness = 0.70
	profile.combustion_level = 0.76
	profile.intake_level = 0.24
	profile.exhaust_level = 0.53
	profile.mechanical_level = 0.27
	profile.injector_level = 0.38
	profile.diesel_clatter_level = 0.58
	profile.intake_resonance_hz = 121.0
	profile.exhaust_resonance_hz = 86.0
	profile.collector_separation = 0.05
	profile.turbo_spool_rate_per_s = 3.1
	profile.turbo_whine_level = 0.21
	profile.turbine_level = 0.25
	_configure_second_stage(profile, twin, 0.44, 0.29)


static func _configure_n57(profile: TrafficRiderInlineEngineAudioProfile, twin: bool) -> void:
	profile.combustion_sharpness = 0.58
	profile.combustion_level = 0.74
	profile.intake_level = 0.30
	profile.exhaust_level = 0.69
	profile.mechanical_level = 0.20
	profile.injector_level = 0.29
	profile.diesel_clatter_level = 0.42
	profile.intake_resonance_hz = 94.0
	profile.exhaust_resonance_hz = 62.0
	profile.mechanical_order = 4.0
	profile.collector_separation = 0.12
	profile.idle_irregularity = 0.022
	profile.turbo_whine_base_hz = 560.0
	profile.turbo_whine_level = 0.20
	profile.turbine_level = 0.31
	_configure_second_stage(profile, twin, 0.42, 0.35)


static func _configure_second_stage(profile: TrafficRiderInlineEngineAudioProfile, enabled: bool, threshold: float, level: float) -> void:
	if not enabled:
		return
	profile.aspiration_type = TrafficRiderInlineEngineAudioProfile.AspirationType.SEQUENTIAL_TWIN_TURBO
	profile.second_stage_threshold = threshold
	profile.second_stage_level = level


static func _configure_unknown(profile: TrafficRiderInlineEngineAudioProfile, fuel: String) -> void:
	profile.combustion_sharpness = 0.72 if fuel == "diesel" else 0.40


static func _firing_order(cylinders: int) -> PackedInt32Array:
	match cylinders:
		3: return PackedInt32Array([1, 2, 3])
		6: return PackedInt32Array([1, 5, 3, 6, 2, 4])
		_: return PackedInt32Array([1, 3, 4, 2])


static func _collector_routing(key: String, cylinders: int, aspiration: String) -> PackedInt32Array:
	if cylinders == 6 and not key.begins_with("n57"):
		return PackedInt32Array([0, 0, 0, 1, 1, 1])
	if cylinders == 4 and not aspiration.contains("twin") and not key.begins_with("n47") and not key.begins_with("b47"):
		return PackedInt32Array([0, 1, 1, 0])
	if cylinders == 3:
		return PackedInt32Array([0, 0, 0])
	if cylinders == 6:
		return PackedInt32Array([0, 0, 0, 0, 0, 0])
	return PackedInt32Array([0, 0, 0, 0])


static func _aspiration_type(fuel: String, aspiration: String) -> int:
	if aspiration == "twin_turbo":
		return TrafficRiderInlineEngineAudioProfile.AspirationType.SEQUENTIAL_TWIN_TURBO
	if fuel == "diesel":
		return TrafficRiderInlineEngineAudioProfile.AspirationType.VARIABLE_GEOMETRY_TURBO
	return TrafficRiderInlineEngineAudioProfile.AspirationType.SINGLE_TURBO


static func _architecture_name(cylinders: int, fuel: String, aspiration: String) -> String:
	return "turbo inline-%d %s%s" % [cylinders, fuel, " sequential" if aspiration == "twin_turbo" else ""]


static func _number(row: Dictionary, field: String, fallback: float) -> float:
	var text: String = str(row.get(field, "")).strip_edges()
	return text.to_float() if text.is_valid_float() else fallback
