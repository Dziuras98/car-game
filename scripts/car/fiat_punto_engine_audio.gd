extends ProfiledEngineAudioSynthesizer
class_name FiatPuntoEngineAudioSynthesizer

@export_category("Fiat four-cylinder combustion")
@export_range(0.0, 1.0, 0.01) var combustion_sharpness: float = 0.35
@export_range(0.55, 1.45, 0.01) var exhaust_pitch_scale: float = 1.0
@export_range(0.55, 1.45, 0.01) var intake_pitch_scale: float = 1.0

@export_category("Indirect-injection diesel character")
@export_range(0.0, 1.0, 0.01) var diesel_combustion: float = 0.0
@export_range(0.0, 1.0, 0.01) var diesel_injection_rattle: float = 0.0
@export_range(0.0, 1.0, 0.01) var diesel_mechanical_clatter: float = 0.0

@export_category("Turbocharger")
@export_range(0.0, 1.0, 0.01) var turbo_whistle: float = 0.0
@export_range(0.0, 1.0, 0.01) var turbo_flutter: float = 0.0
@export_range(0.0, 1.0, 0.01) var turbo_blowoff: float = 0.0
@export_range(500.0, 6000.0, 50.0) var turbo_spool_start_rpm: float = 1800.0
@export_range(750.0, 7500.0, 50.0) var turbo_full_spool_rpm: float = 3500.0
@export_range(0.5, 2.0, 0.01) var turbo_pitch_scale: float = 1.0

var _punto_phase_firing: float = 0.0
var _punto_phase_crank: float = 0.0
var _punto_phase_valvetrain: float = 0.0
var _punto_phase_injection: float = 0.0
var _punto_phase_turbo: float = 0.0
var _punto_previous_pulse: float = 0.0
var _punto_slow_noise: float = 0.0
var _punto_mid_noise: float = 0.0
var _punto_fast_noise: float = 0.0
var _punto_previous_noise: float = 0.0
var _punto_exhaust_low: float = 0.0
var _punto_exhaust_band: float = 0.0
var _punto_intake_low: float = 0.0
var _punto_intake_band: float = 0.0
var _punto_mechanical_low: float = 0.0
var _punto_mechanical_band: float = 0.0
var _punto_turbo_low: float = 0.0
var _punto_turbo_band: float = 0.0
var _punto_turbo_spool: float = 0.0
var _punto_turbo_release: float = 0.0
var _punto_previous_throttle: float = 0.0
var _punto_dc_input: float = 0.0
var _punto_dc_output: float = 0.0


func _ready() -> void:
	cylinders = 4
	force_full_runtime_generation = true
	super._ready()


func _update_transient_envelopes(target_throttle: float, delta: float) -> void:
	super._update_transient_envelopes(target_throttle, delta)
	var throttle_drop: float = maxf(_punto_previous_throttle - target_throttle, 0.0)
	if throttle_drop > 0.08 and _punto_turbo_spool > 0.18:
		_punto_turbo_release = maxf(
			_punto_turbo_release,
			clampf(throttle_drop * 2.8 * _punto_turbo_spool, 0.0, 1.0)
		)
	_punto_turbo_release *= exp(-7.5 * maxf(delta, 0.0))
	_punto_previous_throttle = target_throttle


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
	var high_blend: float = _smoothstep((rpm_ratio - 0.45) / 0.45)

	var white_noise: float = _rng.randf_range(-1.0, 1.0)
	_punto_slow_noise = lerpf(_punto_slow_noise, white_noise, 0.018)
	_punto_mid_noise = lerpf(_punto_mid_noise, white_noise, 0.12)
	_punto_fast_noise = lerpf(_punto_fast_noise, white_noise, 0.42)
	var high_noise: float = white_noise - _punto_mid_noise
	var differentiated_noise: float = white_noise - _punto_previous_noise
	_punto_previous_noise = white_noise

	var idle_wander: float = (
		sin(_punto_phase_crank * 0.37) * 0.55 + _punto_slow_noise * 0.45
	) * idle_irregularity * idle_blend
	var firing_hz: float = maxf(EngineAudioSynthesizer.firing_frequency_hz(rpm, 4) * (1.0 + idle_wander), 1.0)
	var crank_hz: float = maxf(rpm / 60.0, 1.0)
	_punto_phase_firing = fposmod(_punto_phase_firing + TAU * firing_hz * delta, TAU)
	_punto_phase_crank = fposmod(_punto_phase_crank + TAU * crank_hz * delta, TAU)
	_punto_phase_valvetrain = fposmod(_punto_phase_valvetrain + TAU * crank_hz * 4.0 * delta, TAU)
	_punto_phase_injection = fposmod(_punto_phase_injection + TAU * firing_hz * 2.0 * delta, TAU)

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
		var startup_progress: float = 1.0 - clampf(_startup_remaining / maxf(starter_duration, 0.01), 0.0, 1.0)
		startup_gate = _smoothstep((startup_progress - 0.20) / 0.52)
		_starter_phase = fposmod(_starter_phase + TAU * (82.0 + startup_progress * 88.0) * delta, TAU)
		starter_motor = (
			sin(_starter_phase) * 0.68
			+ sin(_starter_phase * 2.0) * 0.24
			+ _punto_mid_noise * 0.13
		) * sin(startup_progress * PI) * starter_motor_level
		_startup_remaining = maxf(_startup_remaining - delta, 0.0)

	var shutdown_gate: float = 1.0
	if _shutdown_remaining > 0.0:
		var shutdown_progress: float = 1.0 - clampf(_shutdown_remaining / maxf(shutdown_duration, 0.01), 0.0, 1.0)
		shutdown_gate = 1.0 - _smoothstep(shutdown_progress)
		_shutdown_remaining = maxf(_shutdown_remaining - delta, 0.0)
		if _shutdown_remaining <= 0.0:
			_engine_running = false
	var running_gate: float = 1.0 if _engine_running or _shutdown_remaining > 0.0 else 0.0

	var normalized_phase: float = fposmod(_punto_phase_firing, TAU) / TAU
	var spark_spike: float = exp(-normalized_phase * lerpf(15.0, 31.0, combustion_sharpness))
	var spark_tail: float = exp(-normalized_phase * 4.0)
	var spark_pulse: float = spark_spike * 1.42 - spark_tail * 0.34 + sin(_punto_phase_firing) * exp(-normalized_phase * 2.6) * 0.16
	var diesel_spike: float = exp(-normalized_phase * 43.0) * 1.72
	var diesel_knock: float = sin(_punto_phase_firing * 6.0 + 0.25) * exp(-normalized_phase * 18.0) * 0.26
	var diesel_tail: float = exp(-normalized_phase * 5.8) * 0.29
	var diesel_pulse: float = diesel_spike + diesel_knock - diesel_tail
	var pulse: float = lerpf(spark_pulse, diesel_pulse, diesel_combustion)
	pulse *= ignition_gate * startup_gate * shutdown_gate * running_gate
	var pulse_derivative: float = pulse - _punto_previous_pulse
	_punto_previous_pulse = pulse

	var exhaust_frequency: float = (112.0 + rpm_ratio * 165.0) * exhaust_pitch_scale
	var exhaust_input: float = pulse * (0.85 + load * 0.65) + pulse_derivative * (0.17 + exhaust_roughness * 0.38)
	var exhaust_body: float = _process_punto_resonator(
		exhaust_input,
		exhaust_frequency,
		0.54 + exhaust_roughness * 0.18,
		sample_rate,
		0
	)
	var exhaust_harmonics: float = (
		sin(_punto_phase_firing) * 0.18
		+ sin(_punto_phase_firing * 2.0 + 0.10) * 0.10
		+ sin(_punto_phase_firing * 3.0 - 0.12) * 0.05
	) * (0.25 + load * 0.75)

	var intake_frequency: float = (540.0 + rpm_ratio * 1220.0 + throttle * 180.0) * intake_pitch_scale
	var intake_input: float = pulse_derivative * 0.36 + high_noise * (0.08 + throttle * 0.20)
	var intake_tone: float = _process_punto_resonator(intake_input, intake_frequency, 0.62, sample_rate, 1)
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
	_punto_phase_turbo = fposmod(_punto_phase_turbo + TAU * turbo_hz * delta, TAU)
	var turbo_raw: float = (
		sin(_punto_phase_turbo) * 0.70
		+ sin(_punto_phase_turbo * 2.01 + 0.18) * 0.18
		+ high_noise * 0.12
	)
	var turbo_tone: float = _process_punto_resonator(turbo_raw, minf(turbo_hz, sample_rate * 0.38), 0.66, sample_rate, 3)
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
	var low_rpm_weight: float = lerpf(1.10, 0.78, high_blend)
	var load_gain: float = lerpf(0.38 + idle_blend * 0.15, 1.10, load)
	var sample: float = (
		exhaust_body * (0.68 + exhaust_resonance * 1.08) * low_rpm_weight
		+ exhaust_harmonics * (0.18 + exhaust_roughness * 0.42)
		+ intake_tone * intake_presence * (0.22 + throttle * 1.38 + _throttle_transient * induction_transient)
		+ intake_air
		+ mechanical_tone * (mechanical_noise + diesel_mechanical_clatter * 0.72)
		+ diesel_rattle * 0.30
		+ pulse_derivative * high_rpm_rasp * high_blend * 0.24
		+ turbo_mix
		+ crackle
	) * load_gain * 0.33 + starter_motor * 0.42

	var dc_blocked: float = sample - _punto_dc_input + 0.995 * _punto_dc_output
	_punto_dc_input = sample
	_punto_dc_output = dc_blocked
	return tanh(dc_blocked * db_to_linear(synthesis_gain_db) * 1.12) * 0.96


func _process_punto_resonator(input_value: float, frequency: float, damping: float, sample_rate: float, channel: int) -> float:
	var coefficient: float = minf(2.0 * sin(PI * clampf(frequency, 20.0, sample_rate * 0.42) / sample_rate), 1.82)
	var low: float
	var band: float
	match channel:
		0:
			low = _punto_exhaust_low
			band = _punto_exhaust_band
		1:
			low = _punto_intake_low
			band = _punto_intake_band
		2:
			low = _punto_mechanical_low
			band = _punto_mechanical_band
		_:
			low = _punto_turbo_low
			band = _punto_turbo_band
	low += coefficient * band
	var high: float = input_value - low - damping * band
	band += coefficient * high
	match channel:
		0:
			_punto_exhaust_low = low
			_punto_exhaust_band = band
		1:
			_punto_intake_low = low
			_punto_intake_band = band
		2:
			_punto_mechanical_low = low
			_punto_mechanical_band = band
		_:
			_punto_turbo_low = low
			_punto_turbo_band = band
	return band


func _update_debug_state() -> void:
	_debug_state = {
		"mode": "Fiat Tipo 176 four-cylinder procedural model",
		"rpm": _smoothed_rpm,
		"load": _smoothed_load,
		"throttle": _smoothed_throttle,
		"firing_frequency_hz": EngineAudioSynthesizer.firing_frequency_hz(_smoothed_rpm, 4),
		"diesel_combustion": diesel_combustion,
		"turbo_spool": _punto_turbo_spool,
		"turbo_release": _punto_turbo_release,
		"limiter_active": _limiter_active,
		"synthesis_gain_db": synthesis_gain_db,
		"output_volume_boost_db": output_volume_boost_db,
	}


func _reset_synthesis_state() -> void:
	super._reset_synthesis_state()
	_punto_phase_firing = 0.0
	_punto_phase_crank = 0.0
	_punto_phase_valvetrain = 0.0
	_punto_phase_injection = 0.0
	_punto_phase_turbo = 0.0
	_punto_previous_pulse = 0.0
	_punto_slow_noise = 0.0
	_punto_mid_noise = 0.0
	_punto_fast_noise = 0.0
	_punto_previous_noise = 0.0
	_punto_exhaust_low = 0.0
	_punto_exhaust_band = 0.0
	_punto_intake_low = 0.0
	_punto_intake_band = 0.0
	_punto_mechanical_low = 0.0
	_punto_mechanical_band = 0.0
	_punto_turbo_low = 0.0
	_punto_turbo_band = 0.0
	_punto_turbo_spool = 0.0
	_punto_turbo_release = 0.0
	_punto_previous_throttle = 0.0
	_punto_dc_input = 0.0
	_punto_dc_output = 0.0
