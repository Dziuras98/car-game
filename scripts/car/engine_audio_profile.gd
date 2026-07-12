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
	_append_range(
		errors,
		"output_volume_boost_db",
		output_volume_boost_db,
		MIN_OUTPUT_VOLUME_BOOST_DB,
		MAX_OUTPUT_VOLUME_BOOST_DB
	)
	_append_range(
		errors,
		"synthesis_gain_db",
		synthesis_gain_db,
		MIN_SYNTHESIS_GAIN_DB,
		MAX_SYNTHESIS_GAIN_DB
	)
	for property_name: StringName in CHARACTER_PROPERTY_NAMES:
		_append_range(errors, str(property_name), float(get(property_name)), 0.0, 1.0)
	_append_range(errors, "limiter_period", limiter_period, 0.02, 0.20)
	_append_range(errors, "limiter_cut_ratio", limiter_cut_ratio, 0.1, 0.9)
	_append_range(
		errors,
		"limiter_residual_combustion",
		limiter_residual_combustion,
		0.0,
		0.5
	)
	return errors


func apply_to(engine_audio: Object) -> bool:
	if engine_audio == null:
		return false
	var validation_errors: PackedStringArray = validate()
	if not validation_errors.is_empty():
		push_error("EngineAudioProfile is invalid: %s" % "; ".join(validation_errors))
		return false
	engine_audio.set("idle_volume_db", idle_volume_db)
	engine_audio.set("load_volume_db", load_volume_db)
	engine_audio.set("output_volume_boost_db", output_volume_boost_db)
	engine_audio.set("synthesis_gain_db", synthesis_gain_db)
	engine_audio.set("high_rpm_rasp", high_rpm_rasp)
	engine_audio.set("intake_presence", intake_presence)
	engine_audio.set("intake_plenum_detail", intake_plenum_detail)
	engine_audio.set("airflow_noise", airflow_noise)
	engine_audio.set("induction_transient", induction_transient)
	engine_audio.set("mechanical_noise", mechanical_noise)
	engine_audio.set("rotating_assembly_detail", rotating_assembly_detail)
	engine_audio.set("exhaust_resonance", exhaust_resonance)
	engine_audio.set("exhaust_roughness", exhaust_roughness)
	engine_audio.set("exhaust_bank_separation", exhaust_bank_separation)
	engine_audio.set("exhaust_reflection", exhaust_reflection)
	engine_audio.set("overrun_crackle", overrun_crackle)
	engine_audio.set("limiter_period", limiter_period)
	engine_audio.set("limiter_cut_ratio", limiter_cut_ratio)
	engine_audio.set("limiter_residual_combustion", limiter_residual_combustion)
	return true


func _append_range(
	errors: PackedStringArray,
	property_name: String,
	value: float,
	minimum: float,
	maximum: float
) -> void:
	if not is_finite(value) or value < minimum or value > maximum:
		errors.append(
			"%s must be finite and between %s and %s" % [property_name, minimum, maximum]
		)
