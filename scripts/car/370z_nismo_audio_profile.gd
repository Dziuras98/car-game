extends Node


func _ready() -> void:
	var engine_audio := get_parent().get_node_or_null("EngineAudio") as EngineAudioSynthesizer
	if engine_audio == null:
		push_error("370Z NISMO audio profile requires an EngineAudioSynthesizer child named EngineAudio.")
		return

	# Keep the same combined gain as the standard 370Z profile. The NISMO
	# difference comes from the spectrum and exhaust envelope rather than from
	# hiding a level increase inside the nonlinear synthesis stage.
	engine_audio.synthesis_gain_db = 0.5
	engine_audio.output_volume_boost_db = 12.0
	engine_audio.idle_volume_db = -9.0
	engine_audio.load_volume_db = 0.0

	# The freer NISMO intake and ECU calibration make the high-rpm induction
	# layer more present while remaining below the harshness of the old generic
	# VQ preset.
	engine_audio.high_rpm_rasp = 0.11
	engine_audio.intake_presence = 0.24
	engine_audio.intake_plenum_detail = 0.14
	engine_audio.airflow_noise = 0.07
	engine_audio.induction_transient = 0.36
	engine_audio.mechanical_noise = 0.04
	engine_audio.rotating_assembly_detail = 0.035

	# Model the lower-backpressure NISMO dual exhaust as a fuller and more
	# separated twin-bank note with a slightly stronger overrun signature.
	engine_audio.exhaust_resonance = 0.66
	engine_audio.exhaust_roughness = 0.15
	engine_audio.exhaust_bank_separation = 0.38
	engine_audio.exhaust_reflection = 0.10
	engine_audio.overrun_crackle = 0.13

	# The engine reaches its useful power peak later than the standard 370Z.
	# Retain combustion through the short limiter window to avoid a hard digital
	# edge at 7,400-7,600 RPM.
	engine_audio.limiter_period = 0.055
	engine_audio.limiter_cut_ratio = 0.36
	engine_audio.limiter_residual_combustion = 0.24
