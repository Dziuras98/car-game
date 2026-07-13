extends Resource
class_name EngineAudioProfile

const MIN_PLAYER_VOLUME_DB: float = -80.0
const MAX_PLAYER_VOLUME_DB: float = 12.0
const MIN_OUTPUT_VOLUME_BOOST_DB: float = 0.0
const MAX_OUTPUT_VOLUME_BOOST_DB: float = 16.0
const MIN_SYNTHESIS_GAIN_DB: float = -6.0
const MAX_SYNTHESIS_GAIN_DB: float = 12.0
const CHARACTER_PROPERTY_NAMES: Array[StringName] = [
	&"high_rpm_rasp",
	&"intake_presence",
	&"intake_plenum_detail",
	&"airflow_noise",
	&"induction_transient",
	&"mechanical_noise",
	&"rotating_assembly_detail",
	&"exhaust_resonance",
	&"exhaust_roughness",
	&"exhaust_bank_separation",
	&"exhaust_reflection",
	&"overrun_crackle",
	&"bank_asymmetry",
	&"idle_irregularity",
	&"combustion_sharpness",
	&"diesel_combustion",
	&"diesel_injection_rattle",
	&"diesel_mechanical_clatter",
	&"turbo_whistle",
	&"turbo_flutter",
	&"turbo_blowoff",
]


@export_group("Levels")
@export_range(-80.0, 12.0, 0.5) var idle_volume_db: float = -10.0
@export_range(-80.0, 12.0, 0.5) var load_volume_db: float = 0.0
@export_range(0.0, 16.0, 0.5) var output_volume_boost_db: float = 11.5
@export_range(-6.0, 12.0, 0.5) var synthesis_gain_db: float = 1.0

@export_group("Character")
@export_range(0.0, 1.0, 0.01) var high_rpm_rasp: float = 0.07
@export_range(0.0, 1.0, 0.01) var intake_presence: float = 0.18
@export_range(0.0, 1.0, 0.01) var intake_plenum_detail: float = 0.10
@export_range(0.0, 1.0, 0.01) var airflow_noise: float = 0.05
@export_range(0.0, 1.0, 0.01) var induction_transient: float = 0.31
@export_range(0.0, 1.0, 0.01) var mechanical_noise: float = 0.035
@export_range(0.0, 1.0, 0.01) var rotating_assembly_detail: float = 0.03
@export_range(0.0, 1.0, 0.01) var exhaust_resonance: float = 0.54
@export_range(0.0, 1.0, 0.01) var exhaust_roughness: float = 0.12
@export_range(0.0, 1.0, 0.01) var exhaust_bank_separation: float = 0.30
@export_range(0.0, 1.0, 0.01) var exhaust_reflection: float = 0.08
@export_range(0.0, 1.0, 0.01) var overrun_crackle: float = 0.10
@export_range(0.0, 1.0, 0.01) var bank_asymmetry: float = 0.02
@export_range(0.0, 1.0, 0.01) var idle_irregularity: float = 0.025
@export_range(0.0, 1.0, 0.01) var combustion_sharpness: float = 0.25
@export_range(0.55, 1.45, 0.01) var exhaust_pitch_scale: float = 1.0
@export_range(0.55, 1.45, 0.01) var intake_pitch_scale: float = 1.0

@export_group("Diesel")
@export_range(0.0, 1.0, 0.01) var diesel_combustion: float = 0.0
@export_range(0.0, 1.0, 0.01) var diesel_injection_rattle: float = 0.0
@export_range(0.0, 1.0, 0.01) var diesel_mechanical_clatter: float = 0.0

@export_group("Turbocharger")
@export_range(0.0, 1.0, 0.01) var turbo_whistle: float = 0.0
@export_range(0.0, 1.0, 0.01) var turbo_flutter: float = 0.0
@export_range(0.0, 1.0, 0.01) var turbo_blowoff: float = 0.0
@export_range(500.0, 6000.0, 50.0) var turbo_spool_start_rpm: float = 1800.0
@export_range(750.0, 7500.0, 50.0) var turbo_full_spool_rpm: float = 3500.0
@export_range(0.5, 2.0, 0.01) var turbo_pitch_scale: float = 1.0

@export_group("Start and stop")
@export_range(0.2, 2.0, 0.05) var starter_duration: float = 0.80
@export_range(0.0, 1.0, 0.01) var starter_motor_level: float = 0.24
@export_range(0.3, 3.0, 0.05) var shutdown_duration: float = 1.10

@export_group("Limiter")
@export_range(0.02, 0.20, 0.005) var limiter_period: float = 0.060
@export_range(0.1, 0.9, 0.01) var limiter_cut_ratio: float = 0.40
@export_range(0.0, 0.5, 0.01) var limiter_residual_combustion: float = 0.20


func is_valid() -> bool:
	return validate().is_empty()


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	_append_range(errors, "idle_volume_db", idle_volume_db, MIN_PLAYER_VOLUME_DB, MAX_PLAYER_VOLUME_DB)
	_append_range(errors, "load_volume_db", load_volume_db, MIN_PLAYER_VOLUME_DB, MAX_PLAYER_VOLUME_DB)
	_append_range(errors, "output_volume_boost_db", output_volume_boost_db, MIN_OUTPUT_VOLUME_BOOST_DB, MAX_OUTPUT_VOLUME_BOOST_DB)
	_append_range(errors, "synthesis_gain_db", synthesis_gain_db, MIN_SYNTHESIS_GAIN_DB, MAX_SYNTHESIS_GAIN_DB)
	for property_name: StringName in CHARACTER_PROPERTY_NAMES:
		_append_range(errors, str(property_name), float(get(property_name)), 0.0, 1.0)
	_append_range(errors, "exhaust_pitch_scale", exhaust_pitch_scale, 0.55, 1.45)
	_append_range(errors, "intake_pitch_scale", intake_pitch_scale, 0.55, 1.45)
	_append_range(errors, "turbo_spool_start_rpm", turbo_spool_start_rpm, 500.0, 6000.0)
	_append_range(errors, "turbo_full_spool_rpm", turbo_full_spool_rpm, 750.0, 7500.0)
	if turbo_full_spool_rpm <= turbo_spool_start_rpm:
		errors.append("turbo_full_spool_rpm must be above turbo_spool_start_rpm")
	_append_range(errors, "turbo_pitch_scale", turbo_pitch_scale, 0.5, 2.0)
	_append_range(errors, "starter_duration", starter_duration, 0.2, 2.0)
	_append_range(errors, "starter_motor_level", starter_motor_level, 0.0, 1.0)
	_append_range(errors, "shutdown_duration", shutdown_duration, 0.3, 3.0)
	_append_range(errors, "limiter_period", limiter_period, 0.02, 0.20)
	_append_range(errors, "limiter_cut_ratio", limiter_cut_ratio, 0.1, 0.9)
	_append_range(errors, "limiter_residual_combustion", limiter_residual_combustion, 0.0, 0.5)
	return errors


func apply_to(engine_audio: Object) -> bool:
	if engine_audio == null:
		return false
	var validation_errors: PackedStringArray = validate()
	if not validation_errors.is_empty():
		push_error("EngineAudioProfile is invalid: %s" % "; ".join(validation_errors))
		return false
	for property: Dictionary in get_property_list():
		var property_name: StringName = property.get("name", &"")
		var usage: int = int(property.get("usage", 0))
		if property_name == &"" or usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		if property_name in [&"script", &"resource_local_to_scene", &"resource_name", &"resource_path"]:
			continue
		engine_audio.set(property_name, get(property_name))
	return true


func _append_range(errors: PackedStringArray, property_name: String, value: float, minimum: float, maximum: float) -> void:
	if not is_finite(value) or value < minimum or value > maximum:
		errors.append("%s must be finite and between %s and %s" % [property_name, minimum, maximum])
