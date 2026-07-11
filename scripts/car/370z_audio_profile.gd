extends Node


func _ready() -> void:
	var engine_audio := get_parent().get_node_or_null("EngineAudio") as EngineAudioSynthesizer
	if engine_audio == null:
		push_error("370Z audio profile requires an EngineAudioSynthesizer child named EngineAudio.")
		return

	# Keep the stock VQ37VHR rasp as texture instead of a dominant narrow tone.
	engine_audio.high_rpm_rasp = 0.12
	engine_audio.intake_presence = 0.20
	engine_audio.intake_plenum_detail = 0.16
	engine_audio.airflow_noise = 0.08
	engine_audio.mechanical_noise = 0.045
	engine_audio.rotating_assembly_detail = 0.04

	# Restore exhaust body and pulse texture so the engine remains full under load.
	engine_audio.exhaust_resonance = 0.52
	engine_audio.exhaust_roughness = 0.16
	engine_audio.exhaust_bank_separation = 0.30
	engine_audio.exhaust_reflection = 0.12
	engine_audio.overrun_crackle = 0.10
