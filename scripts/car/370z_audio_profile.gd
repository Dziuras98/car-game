extends Node


func _ready() -> void:
	var engine_audio := get_parent().get_node_or_null("EngineAudio") as EngineAudioSynthesizer
	if engine_audio == null:
		push_error("370Z audio profile requires an EngineAudioSynthesizer child named EngineAudio.")
		return

	# Keep the same combined gain while moving 2.5 dB from the internal tanh
	# stage to the linear player stage. This reduces saturation-generated
	# harmonics without reducing perceived output level.
	engine_audio.synthesis_gain_db = 1.0
	engine_audio.output_volume_boost_db = 11.5

	# Preserve the exact 10 dB span between closed throttle and full load.
	engine_audio.idle_volume_db = -10.0
	engine_audio.load_volume_db = 0.0

	# Retain the stock VQ37VHR body while reducing narrow and derivative-heavy
	# layers that made the waveform sound triangular or clipped at high RPM.
	engine_audio.high_rpm_rasp = 0.07
	engine_audio.intake_presence = 0.18
	engine_audio.intake_plenum_detail = 0.10
	engine_audio.airflow_noise = 0.05
	engine_audio.mechanical_noise = 0.035
	engine_audio.rotating_assembly_detail = 0.03

	# Keep the exhaust body dominant and reduce the upper-mid reflection edge.
	engine_audio.exhaust_resonance = 0.54
	engine_audio.exhaust_roughness = 0.12
	engine_audio.exhaust_bank_separation = 0.30
	engine_audio.exhaust_reflection = 0.08
	engine_audio.overrun_crackle = 0.10

	# Make ignition cuts less discontinuous. The limiter remains audible, but
	# its residual combustion prevents the hard square-like edge between cuts.
	engine_audio.limiter_cut_ratio = 0.40
	engine_audio.limiter_residual_combustion = 0.20
