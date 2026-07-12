extends Resource
class_name EngineAudioProfile


@export_group("Levels")
@export var idle_volume_db: float = -10.0
@export var load_volume_db: float = 0.0
@export var output_volume_boost_db: float = 11.5
@export var synthesis_gain_db: float = 1.0

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


func apply_to(engine_audio: Object) -> void:
	if engine_audio == null:
		return
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
