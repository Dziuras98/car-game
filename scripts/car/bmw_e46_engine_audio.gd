extends FiatPuntoEngineAudioSynthesizer
class_name BmwE46EngineAudioSynthesizer

var _requested_full_runtime_generation: bool = true
var _bmw_phase_secondary: float = 0.0
var _bmw_previous_collector_pulse: float = 0.0


static func inline_six_collector_frequency_hz(rpm: float) -> float:
	return maxf(rpm, 0.0) / 60.0 * 1.5


func _ready() -> void:
	_requested_full_runtime_generation = force_full_runtime_generation
	# The parent supplies the diesel, turbo, start/stop and resonator backend.
	# Its profiled ready path reapplies the exact BMW cylinder count afterwards.
	super._ready()
	force_full_runtime_generation = _requested_full_runtime_generation


func _generate_sample() -> float:
	var sample_rate: float = float(maxi(mix_rate, 16000))
	var delta: float = 1.0 / sample_rate
	var idle_rpm: float = _get_idle_rpm()
	var limit_rpm: float = _get_rev_limit_rpm()
	var rpm: float = clampf(_smoothed_rpm, 0.0, limit_rpm * 1.08)
	var load: float = clampf(_smoothed_load, 0.0, 1.0)
	var throttle: float = clampf(_smoothed_throttle, 0.0, 1.0)
	var rpm_ratio: float = clampf(rpm / maxf(limit_rpm, 1.0), 0.0, 1.08)
	var idle_blend: float = 1.0 - _smoothstep((rpm - idle_rpm) / 750.0)
	var high_blend: float = _smoothstep((rpm_ratio - 0.43) / 0.47)
	var six_cylinder_blend: float = clampf((float(cylinders) - 4.0) / 2.0, 0.0, 1.0)

	var white_noise: float = _rng.randf_range(-1.0, 1.0)
	_punto_slow_noise = lerpf(_punto_slow_noise, white_noise, EngineAudioSynthesizer.sample_rate_invariant_alpha(0.018, sample_rate))
	_punto_mid_noise = lerpf(_punto_mid_noise, white_noise, EngineAudioSynthesizer.sample_rate_invariant_alpha(0.12, sample_rate))
	var high_noise: float = white_noise - _punto_mid_noise
	var differentiated_noise: float = white_noise - _punto_previous_noise
	_punto_previous_noise = white_noise

	var idle_wander: float = (
		sin(_punto_phase_crank * 0.37) * 0.55 + _punto_slow_noise * 0.45
	) * idle_irregularity * idle_blend * lerpf(1.0, 0.58, six_cylinder_blend)
	var firing_hz: float = maxf(
		EngineAudioSynthesizer.firing_frequency_hz(rpm, cylinders) * (1.0 + idle_wander),
		0.0
	)
	var crank_hz: float = maxf(rpm / 60.0, 0.0)
	var collector_hz: float = maxf(
		inline_six_collector_frequency_hz(rpm) * (1.0 + idle_wander * 0.45),
		0.0
	)
	_punto_phase_firing = fposmod(_punto_phase_firing + TAU * firing_hz * delta, TAU)
	_punto_phase_crank = fposmod(_punto_phase_crank + TAU * crank_hz * delta, TAU)
	_punto_phase_valvetrain = fposmod(_punto_phase_valvetrain + TAU * crank_hz * 4.0 * delta, TAU)
	_punto_phase_injection = fposmod(_punto_phase_injection + TAU * firing_hz * 2.0 * delta, TAU)
	_bmw_phase_secondary = fposmod(_bmw_phase_secondary + TAU * collector_hz * delta, TAU)

	var limiter_cycle: float = maxf(limiter_period, 0.02)
	_limiter_active = rpm >= limit_rpm * 0.985 and throttle > 0.65
	_limiter_phase = fposmod(_limiter_phase + delta / limiter_cycle, 1.0) if _limiter_active else 0.0
	var ignition_gate: float = EngineAudioSynthesizer.limiter_gate(
		rpm,
		throttle,
		limit_rpm,
		_limiter_phase,
		limiter_cut_ratio,
		limiter_residual_combustion
	)

	var startup_gate: float = 1.0
	var starter_motor: float = 0.0
	if _startup_remaining > 0.0:
		var startup_progress: float = _startup_progress
		startup_gate = _smoothstep((startup_progress - 0.20) / 0.52)
		_starter_phase = fposmod(_starter_phase + TAU * (82.0 + startup_progress * 88.0) * delta, TAU)
		starter_motor = (
			sin(_starter_phase) * 0.68
			+ sin(_starter_phase * 2.0) * 0.24
			+ _punto_mid_noise * 0.13
		) * sin(startup_progress * PI) * starter_motor_level

	var normalized_phase: float = fposmod(_punto_phase_firing, TAU) / TAU
	var spark_spike: float = exp(-normalized_phase * lerpf(15.0, 31.0, combustion_sharpness))
	var spark_tail: float = exp(-normalized_phase * 4.0)
	var spark_pulse: float = (
		spark_spike * 1.42
		- spark_tail * 0.34
		+ sin(_punto_phase_firing) * exp(-normalized_phase * 2.6) * 0.16
	)
	var diesel_spike: float = exp(-normalized_phase * 43.0) * 1.72
	var diesel_knock: float = sin(_punto_phase_firing * 6.0 + 0.25) * exp(-normalized_phase * 18.0) * 0.26
	var diesel_tail: float = exp(-normalized_phase * 5.8) * 0.29
	var diesel_pulse: float = diesel_spike + diesel_knock - diesel_tail
	var pulse: float = lerpf(spark_pulse, diesel_pulse, diesel_combustion) * ignition_gate * startup_gate
	var pulse_derivative: float = pulse - _punto_previous_pulse
	_punto_previous_pulse = pulse

	# An inline six uses two interleaved three-cylinder collector groups. Their
	# 1.5-order cadence and its strong second harmonic are what separate the
	# smooth BMW six-cylinder note from the two-firing-events-per-revolution R4.
	var collector_phase: float = fposmod(_bmw_phase_secondary, TAU) / TAU
	var collector_spark_spike: float = exp(-collector_phase * lerpf(8.0, 16.0, combustion_sharpness))
	var collector_spark_tail: float = exp(-collector_phase * 2.6)
	var collector_spark_pulse: float = (
		collector_spark_spike * 0.92
		- collector_spark_tail * 0.20
		+ sin(_bmw_phase_secondary) * exp(-collector_phase * 1.8) * 0.20
	)
	var collector_diesel_spike: float = exp(-collector_phase * 25.0) * 1.12
	var collector_diesel_knock: float = sin(_bmw_phase_secondary * 4.0 + 0.20) * exp(-collector_phase * 11.0) * 0.15
	var collector_diesel_tail: float = exp(-collector_phase * 3.6) * 0.22
	var collector_diesel_pulse: float = collector_diesel_spike + collector_diesel_knock - collector_diesel_tail
	var collector_pulse: float = lerpf(
		collector_spark_pulse,
		collector_diesel_pulse,
		diesel_combustion
	) * ignition_gate * startup_gate * six_cylinder_blend
	var collector_derivative: float = collector_pulse - _bmw_previous_collector_pulse
	_bmw_previous_collector_pulse = collector_pulse

	var displacement_pitch: float = exhaust_pitch_scale
	var exhaust_frequency: float = (
		lerpf(108.0, 88.0, six_cylinder_blend)
		+ rpm_ratio * lerpf(168.0, 145.0, six_cylinder_blend)
	) * displacement_pitch
	var exhaust_input: float = (
		pulse * (0.85 + load * 0.65)
		+ pulse_derivative * lerpf(0.17 + exhaust_roughness * 0.38, 0.12 + exhaust_roughness * 0.24, six_cylinder_blend)
		+ collector_pulse * (0.18 + load * 0.34)
		+ collector_derivative * 0.10
	)
	var exhaust_body: float = _process_punto_resonator(
		exhaust_input,
		exhaust_frequency,
		0.54 + exhaust_roughness * 0.18,
		sample_rate,
		0
	)
	var four_cylinder_order: float = (
		sin(_punto_phase_firing) * 0.18
		+ sin(_punto_phase_firing * 2.0 + 0.10) * 0.10
		+ sin(_punto_phase_firing * 3.0 - 0.12) * 0.05
	) * (0.25 + load * 0.75)
	var inline_six_order: float = (
		sin(_bmw_phase_secondary) * 0.30
		+ sin(_bmw_phase_secondary * 2.0 + 0.08) * 0.24
		+ sin(_bmw_phase_secondary * 3.0 - 0.14) * 0.09
		+ sin(_bmw_phase_secondary * 4.0 + 0.03) * 0.045
	) * (0.22 + load * 0.78)
	var engine_order: float = lerpf(four_cylinder_order, inline_six_order, six_cylinder_blend)

	var intake_frequency: float = (
		500.0 + rpm_ratio * lerpf(1260.0, 1380.0, six_cylinder_blend) + throttle * 190.0
	) * intake_pitch_scale
	var intake_impulse: float = lerpf(
		pulse_derivative * 0.36,
		pulse_derivative * 0.24 + collector_derivative * 0.18,
		six_cylinder_blend
	)
	var intake_input: float = intake_impulse + high_noise * (0.08 + throttle * 0.20)
	var intake_tone: float = _process_punto_resonator(intake_input, intake_frequency, 0.62, sample_rate, 1)
	var four_plenum_harmonic: float = (
		sin(_punto_phase_firing * 0.5 + 0.17) * 0.55
		+ sin(_punto_phase_firing * 1.5 - 0.11) * 0.24
	)
	var six_plenum_harmonic: float = (
		sin(_bmw_phase_secondary + 0.14) * 0.42
		+ sin(_bmw_phase_secondary * 2.0 - 0.11) * 0.38
		+ sin(_bmw_phase_secondary * 4.0 + 0.05) * 0.12
	)
	var plenum_harmonic: float = lerpf(
		four_plenum_harmonic,
		six_plenum_harmonic,
		six_cylinder_blend
	) * intake_plenum_detail * throttle * (0.20 + high_blend * 0.80)
	var intake_air: float = (
		high_noise * 0.70 + differentiated_noise * 0.18 + _punto_slow_noise * 0.12
	) * airflow_noise * throttle * (0.20 + load * 0.80)

	var valve_impulse: float = pow(maxf(sin(_punto_phase_valvetrain), 0.0), 13.0) - 0.07
	var injection_impulse: float = pow(maxf(sin(_punto_phase_injection), 0.0), 24.0) - 0.035
	var diesel_rattle: float = (
		injection_impulse * (0.52 + load * 0.70)
		+ high_noise * 0.17
		+ sin(_punto_phase_injection * 0.5) * 0.08
	) * diesel_injection_rattle
	var mechanical_input: float = (
		valve_impulse * (0.42 + rpm_ratio * 0.75)
		+ high_noise * 0.10
		+ diesel_rattle
		+ pulse_derivative * diesel_mechanical_clatter * 0.18
	)
	var mechanical_tone: float = _process_punto_resonator(
		mechanical_input,
		(1250.0 + rpm_ratio * 2350.0) * lerpf(1.0, 0.78, diesel_combustion),
		0.72,
		sample_rate,
		2
	)

	var spool_span: float = maxf(turbo_full_spool_rpm - turbo_spool_start_rpm, 1.0)
	var spool_rpm: float = _smoothstep((rpm - turbo_spool_start_rpm) / spool_span)
	var spool_target: float = spool_rpm * (0.18 + load * 0.82) * (0.30 + throttle * 0.70)
	_punto_turbo_spool = lerpf(_punto_turbo_spool, spool_target, 1.0 - exp(-5.5 * delta))
	var turbo_hz: float = (620.0 + rpm_ratio * 5200.0 + _punto_turbo_spool * 2300.0) * turbo_pitch_scale
	turbo_hz = EngineAudioSynthesizer.bandlimited_frequency(turbo_hz, sample_rate)
	_punto_phase_turbo = fposmod(_punto_phase_turbo + TAU * turbo_hz * delta, TAU)
	var turbo_raw: float = (
		sin(_punto_phase_turbo) * 0.70
		+ sin(_punto_phase_turbo * 2.01 + 0.18) * 0.18
		+ high_noise * 0.12
	)
	var turbo_tone: float = _process_punto_resonator(
		turbo_raw,
		minf(turbo_hz, sample_rate * 0.38),
		0.66,
		sample_rate,
		3
	)
	var flutter_gate: float = _punto_turbo_release * turbo_flutter
	var flutter: float = (
		sin(_punto_phase_turbo * 0.19) * sin(_punto_phase_turbo * 0.037) * 0.55
		+ high_noise * 0.24
	) * flutter_gate
	var blowoff: float = (
		high_noise * 0.72 + _punto_mid_noise * 0.20 + differentiated_noise * 0.08
	) * _punto_turbo_release * turbo_blowoff
	var turbo_mix: float = turbo_tone * turbo_whistle * _punto_turbo_spool + flutter + blowoff

	var crackle: float = _next_overrun_crackle(delta, white_noise) * overrun_crackle
	var low_rpm_weight: float = lerpf(1.10, 0.80, high_blend)
	var load_gain: float = lerpf(0.38 + idle_blend * 0.15, 1.10, load)
	var engine_order_gain: float = lerpf(
		0.18 + exhaust_roughness * 0.42,
		0.42 + exhaust_resonance * 0.14,
		six_cylinder_blend
	)
	var rasp_impulse: float = lerpf(
		pulse_derivative,
		pulse_derivative * 0.45 + collector_derivative * 0.55,
		six_cylinder_blend
	)
	var engine_sample: float = (
		exhaust_body * (0.68 + exhaust_resonance * 1.08) * low_rpm_weight
		+ engine_order * engine_order_gain
		+ intake_tone * intake_presence * (0.22 + throttle * 1.38 + _throttle_transient * induction_transient)
		+ plenum_harmonic
		+ intake_air
		+ mechanical_tone * (mechanical_noise + diesel_mechanical_clatter * 0.72)
		+ diesel_rattle * 0.30
		+ rasp_impulse * high_rpm_rasp * high_blend * 0.24
		+ turbo_mix
		+ crackle
	) * load_gain * lerpf(0.33, 0.29, six_cylinder_blend)
	var sample: float = engine_sample * _engine_state_gain + starter_motor * 0.42

	var dc_decay: float = EngineAudioSynthesizer.sample_rate_invariant_decay(0.995, sample_rate)
	var dc_blocked: float = sample - _punto_dc_input + dc_decay * _punto_dc_output
	_punto_dc_input = sample
	_punto_dc_output = dc_blocked
	return tanh(dc_blocked * db_to_linear(synthesis_gain_db) * 1.12) * 0.96


func _clear_audio_tail_state() -> void:
	super._clear_audio_tail_state()
	_bmw_previous_collector_pulse = 0.0


func _update_debug_state() -> void:
	_debug_state = {
		"mode": "BMW E46 inline engine procedural model",
		"rpm": _smoothed_rpm,
		"load": _smoothed_load,
		"throttle": _smoothed_throttle,
		"cylinders": cylinders,
		"firing_frequency_hz": EngineAudioSynthesizer.firing_frequency_hz(_smoothed_rpm, cylinders),
		"inline_six_collector_frequency_hz": inline_six_collector_frequency_hz(_smoothed_rpm),
		"diesel_combustion": diesel_combustion,
		"turbo_spool": _punto_turbo_spool,
		"turbo_release": _punto_turbo_release,
		"limiter_active": _limiter_active,
		"synthesis_gain_db": synthesis_gain_db,
		"output_volume_boost_db": output_volume_boost_db,
	}


func _reset_synthesis_state() -> void:
	super._reset_synthesis_state()
	_bmw_phase_secondary = 0.0
	_bmw_previous_collector_pulse = 0.0
