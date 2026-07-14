extends ProfiledEngineAudioSynthesizer
class_name PolonezEngineAudioSynthesizer

@export_category("Polonez four-cylinder combustion")
@export_range(0.0, 1.0, 0.01) var combustion_sharpness: float = 0.42
@export_range(0.55, 1.45, 0.01) var exhaust_pitch_scale: float = 1.0
@export_range(0.55, 1.45, 0.01) var intake_pitch_scale: float = 1.0

@export_category("Polonez mechanical character")
@export var family_label: String = "Polonez inline-four"
@export_range(0.0, 1.5, 0.01) var pushrod_clatter_gain: float = 0.35
@export_range(0.0, 1.5, 0.01) var timing_drive_whine_gain: float = 0.10
@export_range(0.0, 1.5, 0.01) var intake_bark_gain: float = 0.40
@export_range(0.0, 1.5, 0.01) var exhaust_boom_gain: float = 0.55
@export_range(0.0, 1.5, 0.01) var upper_valvetrain_gain: float = 0.16
@export_range(0.0, 1.5, 0.01) var carburettor_flutter_gain: float = 0.20
@export_range(0.0, 1.5, 0.01) var injection_tick_gain: float = 0.05
@export_range(0.0, 1.5, 0.01) var flywheel_pulse_gain: float = 0.25

@export_category("Indirect-injection diesel character")
@export_range(0.0, 1.0, 0.01) var diesel_combustion: float = 0.0
@export_range(0.0, 1.0, 0.01) var diesel_injection_rattle: float = 0.0
@export_range(0.0, 1.0, 0.01) var diesel_mechanical_clatter: float = 0.0
@export_range(0.0, 1.5, 0.01) var diesel_knock_gain: float = 0.0

var _pnz_phase_firing: float = 0.0
var _pnz_phase_crank: float = 0.0
var _pnz_phase_valvetrain: float = 0.0
var _pnz_phase_timing: float = 0.0
var _pnz_phase_injection: float = 0.0
var _pnz_previous_pulse: float = 0.0
var _pnz_slow_noise: float = 0.0
var _pnz_mid_noise: float = 0.0
var _pnz_previous_noise: float = 0.0
var _pnz_exhaust_low: float = 0.0
var _pnz_exhaust_band: float = 0.0
var _pnz_exhaust_mid_low: float = 0.0
var _pnz_exhaust_mid_band: float = 0.0
var _pnz_intake_low: float = 0.0
var _pnz_intake_band: float = 0.0
var _pnz_mechanical_low: float = 0.0
var _pnz_mechanical_band: float = 0.0
var _pnz_dc_input: float = 0.0
var _pnz_dc_output: float = 0.0


func _ready() -> void:
	cylinders = 4
	super._ready()


func _generate_sample() -> float:
	var sample_rate: float = float(maxi(mix_rate, 16000))
	var delta: float = 1.0 / sample_rate
	var idle_rpm: float = _get_idle_rpm()
	var limit_rpm: float = _get_rev_limit_rpm()
	var rpm: float = clampf(_smoothed_rpm, 0.0, limit_rpm * 1.08)
	var load: float = clampf(_smoothed_load, 0.0, 1.0)
	var throttle: float = clampf(_smoothed_throttle, 0.0, 1.0)
	var rpm_ratio: float = clampf(rpm / maxf(limit_rpm, 1.0), 0.0, 1.08)
	var idle_blend: float = 1.0 - _smoothstep((rpm - idle_rpm) / 720.0)
	var mid_blend: float = _smoothstep((rpm_ratio - 0.18) / 0.48)
	var high_blend: float = _smoothstep((rpm_ratio - 0.50) / 0.42)

	var white_noise: float = _rng.randf_range(-1.0, 1.0)
	_pnz_slow_noise = lerpf(_pnz_slow_noise, white_noise, EngineAudioSynthesizer.sample_rate_invariant_alpha(0.014, sample_rate))
	_pnz_mid_noise = lerpf(_pnz_mid_noise, white_noise, EngineAudioSynthesizer.sample_rate_invariant_alpha(0.105, sample_rate))
	var high_noise: float = white_noise - _pnz_mid_noise
	var differentiated_noise: float = white_noise - _pnz_previous_noise
	_pnz_previous_noise = white_noise

	var idle_wander: float = (
		sin(_pnz_phase_crank * 0.31) * 0.54
		+ _pnz_slow_noise * 0.46
	) * idle_irregularity * idle_blend
	var firing_hz: float = maxf(
		EngineAudioSynthesizer.firing_frequency_hz(rpm, 4) * (1.0 + idle_wander),
		0.0
	)
	var crank_hz: float = maxf(rpm / 60.0, 0.0)
	_pnz_phase_firing = fposmod(_pnz_phase_firing + TAU * firing_hz * delta, TAU)
	_pnz_phase_crank = fposmod(_pnz_phase_crank + TAU * crank_hz * delta, TAU)
	_pnz_phase_valvetrain = fposmod(_pnz_phase_valvetrain + TAU * crank_hz * 4.0 * delta, TAU)
	_pnz_phase_timing = fposmod(_pnz_phase_timing + TAU * crank_hz * 0.5 * delta, TAU)
	_pnz_phase_injection = fposmod(_pnz_phase_injection + TAU * firing_hz * 2.0 * delta, TAU)

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
		_starter_phase = fposmod(
			_starter_phase + TAU * (78.0 + startup_progress * 86.0) * delta,
			TAU
		)
		starter_motor = (
			sin(_starter_phase) * 0.70
			+ sin(_starter_phase * 2.0) * 0.22
			+ _pnz_mid_noise * 0.11
		) * sin(startup_progress * PI) * starter_motor_level

	var normalized_phase: float = fposmod(_pnz_phase_firing, TAU) / TAU
	var spark_spike: float = exp(-normalized_phase * lerpf(13.0, 31.0, combustion_sharpness))
	var spark_tail: float = exp(-normalized_phase * 4.2)
	var spark_ring: float = sin(_pnz_phase_firing * 4.0 + 0.21) * exp(-normalized_phase * 10.0)
	var spark_pulse: float = (
		spark_spike * 1.46
		- spark_tail * 0.36
		+ spark_ring * 0.08
		+ sin(_pnz_phase_firing) * exp(-normalized_phase * 2.7) * 0.15
	)
	var diesel_spike: float = exp(-normalized_phase * 46.0) * 1.82
	var diesel_ring: float = sin(_pnz_phase_firing * 7.0 + 0.18) * exp(-normalized_phase * 20.0) * 0.32
	var diesel_tail: float = exp(-normalized_phase * 6.0) * 0.30
	var diesel_pulse: float = diesel_spike + diesel_ring - diesel_tail
	var pulse: float = lerpf(spark_pulse, diesel_pulse, diesel_combustion)
	pulse *= ignition_gate * startup_gate
	var pulse_derivative: float = pulse - _pnz_previous_pulse
	_pnz_previous_pulse = pulse

	var firing_harmonics: float = (
		sin(_pnz_phase_firing) * 0.18
		+ sin(_pnz_phase_firing * 2.0 + 0.10) * 0.105
		+ sin(_pnz_phase_firing * 3.0 - 0.16) * 0.060
		+ sin(_pnz_phase_firing * 5.0 + 0.22) * 0.030 * high_blend
	)
	var flywheel_pulse: float = (
		sin(_pnz_phase_crank) * 0.09
		+ sin(_pnz_phase_crank * 2.0 + 0.18) * 0.055
	) * flywheel_pulse_gain

	var exhaust_frequency: float = (
		92.0 + rpm_ratio * 132.0 + load * 18.0
	) * exhaust_pitch_scale
	var exhaust_input: float = (
		pulse * (0.88 + load * 0.76)
		+ pulse_derivative * (0.14 + exhaust_roughness * 0.46)
		+ firing_harmonics * 0.30
		+ flywheel_pulse
	)
	var exhaust_body: float = _process_polonez_resonator(
		exhaust_input,
		exhaust_frequency,
		0.52 + exhaust_roughness * 0.16,
		sample_rate,
		0
	)
	var exhaust_mid: float = _process_polonez_resonator(
		pulse_derivative * 0.58 + firing_harmonics * 0.34 + high_noise * 0.08,
		(410.0 + rpm_ratio * 760.0) * exhaust_pitch_scale,
		0.66,
		sample_rate,
		1
	)

	var carb_flutter: float = (
		sin(_pnz_phase_crank * 0.5 + _pnz_slow_noise * 0.8) * 0.52
		+ _pnz_mid_noise * 0.28
	) * carburettor_flutter_gain * throttle * (0.25 + load * 0.75)
	var intake_frequency: float = (
		480.0 + rpm_ratio * 1500.0 + throttle * 260.0
	) * intake_pitch_scale
	var intake_input: float = (
		pulse_derivative * 0.34
		+ firing_harmonics * 0.30
		+ high_noise * (0.06 + throttle * 0.22)
		+ carb_flutter * 0.18
	)
	var intake_tone: float = _process_polonez_resonator(
		intake_input,
		intake_frequency,
		0.61,
		sample_rate,
		2
	)
	var intake_air: float = (
		high_noise * 0.65
		+ differentiated_noise * 0.17
		+ _pnz_slow_noise * 0.18
	) * airflow_noise * throttle * (0.25 + load * 0.75)

	var valve_impulse: float = pow(maxf(sin(_pnz_phase_valvetrain), 0.0), 14.0) - 0.055
	var injection_impulse: float = pow(maxf(sin(_pnz_phase_injection), 0.0), 26.0) - 0.032
	var timing_whine: float = (
		sin(_pnz_phase_timing * 18.0 + 0.12) * 0.52
		+ sin(_pnz_phase_timing * 26.0 - 0.19) * 0.24
		+ high_noise * 0.10
	) * timing_drive_whine_gain * (0.18 + rpm_ratio * 0.82)
	var pushrod_clatter: float = (
		valve_impulse * (0.45 + rpm_ratio * 0.92)
		+ high_noise * 0.08
	) * pushrod_clatter_gain
	var injection_tick: float = (
		injection_impulse * (0.42 + load * 0.60)
		+ high_noise * 0.08
	) * injection_tick_gain
	var diesel_rattle: float = (
		injection_impulse * (0.65 + load * 0.82)
		+ pulse_derivative * 0.20
		+ high_noise * 0.14
	) * diesel_injection_rattle * diesel_knock_gain
	var upper_valvetrain: float = (
		valve_impulse * (0.20 + high_blend * 1.20)
		+ pulse_derivative * high_blend * 0.10
	) * upper_valvetrain_gain
	var mechanical_input: float = (
		pushrod_clatter
		+ timing_whine
		+ injection_tick
		+ diesel_rattle
		+ upper_valvetrain
	)
	var mechanical_tone: float = _process_polonez_resonator(
		mechanical_input,
		(1180.0 + rpm_ratio * 2850.0) * lerpf(1.0, 0.76, diesel_combustion),
		0.72,
		sample_rate,
		3
	)

	var crackle: float = _next_overrun_crackle(delta, white_noise) * overrun_crackle
	var load_gain: float = lerpf(0.39 + idle_blend * 0.16, 1.10, load)
	var rpm_gain: float = lerpf(0.58, 1.02, mid_blend)
	var engine_sample: float = (
		exhaust_body * (0.58 + exhaust_resonance * 0.98 + exhaust_boom_gain * 0.46)
		+ exhaust_mid * (0.14 + exhaust_roughness * 0.62)
		+ intake_tone * intake_presence * intake_bark_gain * (
			0.28 + throttle * 1.50 + _throttle_transient * induction_transient * 1.4
		)
		+ intake_air
		+ carb_flutter * 0.12
		+ mechanical_tone * (mechanical_noise + diesel_mechanical_clatter * 0.70 + 0.15)
		+ pulse_derivative * high_rpm_rasp * high_blend * 0.20
		+ crackle
	) * load_gain * rpm_gain * 0.34
	var sample: float = engine_sample * _engine_state_gain + starter_motor * 0.42

	var dc_decay: float = EngineAudioSynthesizer.sample_rate_invariant_decay(0.995, sample_rate)
	var dc_blocked: float = sample - _pnz_dc_input + dc_decay * _pnz_dc_output
	_pnz_dc_input = sample
	_pnz_dc_output = dc_blocked
	return tanh(dc_blocked * db_to_linear(synthesis_gain_db) * 1.10) * 0.96


func _process_polonez_resonator(
	input_value: float,
	frequency: float,
	damping: float,
	sample_rate: float,
	channel: int
) -> float:
	var coefficient: float = minf(
		2.0 * sin(PI * clampf(frequency, 20.0, sample_rate * 0.42) / sample_rate),
		1.82
	)
	var low: float
	var band: float
	match channel:
		0:
			low = _pnz_exhaust_low
			band = _pnz_exhaust_band
		1:
			low = _pnz_exhaust_mid_low
			band = _pnz_exhaust_mid_band
		2:
			low = _pnz_intake_low
			band = _pnz_intake_band
		_:
			low = _pnz_mechanical_low
			band = _pnz_mechanical_band
	low += coefficient * band
	var high: float = input_value - low - damping * band
	band += coefficient * high
	match channel:
		0:
			_pnz_exhaust_low = low
			_pnz_exhaust_band = band
		1:
			_pnz_exhaust_mid_low = low
			_pnz_exhaust_mid_band = band
		2:
			_pnz_intake_low = low
			_pnz_intake_band = band
		_:
			_pnz_mechanical_low = low
			_pnz_mechanical_band = band
	return band


func _clear_audio_tail_state() -> void:
	super._clear_audio_tail_state()
	_pnz_previous_pulse = 0.0
	_pnz_exhaust_low = 0.0
	_pnz_exhaust_band = 0.0
	_pnz_exhaust_mid_low = 0.0
	_pnz_exhaust_mid_band = 0.0
	_pnz_intake_low = 0.0
	_pnz_intake_band = 0.0
	_pnz_mechanical_low = 0.0
	_pnz_mechanical_band = 0.0
	_pnz_dc_input = 0.0
	_pnz_dc_output = 0.0


func _update_debug_state() -> void:
	_debug_state = {
		"mode": "dedicated FSO Polonez four-cylinder procedural model",
		"family": family_label,
		"rpm": _smoothed_rpm,
		"load": _smoothed_load,
		"throttle": _smoothed_throttle,
		"firing_frequency_hz": EngineAudioSynthesizer.firing_frequency_hz(_smoothed_rpm, 4),
		"diesel_combustion": diesel_combustion,
		"pushrod_clatter_gain": pushrod_clatter_gain,
		"timing_drive_whine_gain": timing_drive_whine_gain,
		"intake_bark_gain": intake_bark_gain,
		"limiter_active": _limiter_active,
		"synthesis_gain_db": synthesis_gain_db,
		"output_volume_boost_db": output_volume_boost_db,
	}


func _reset_synthesis_state() -> void:
	super._reset_synthesis_state()
	_pnz_phase_firing = 0.0
	_pnz_phase_crank = 0.0
	_pnz_phase_valvetrain = 0.0
	_pnz_phase_timing = 0.0
	_pnz_phase_injection = 0.0
	_pnz_previous_pulse = 0.0
	_pnz_slow_noise = 0.0
	_pnz_mid_noise = 0.0
	_pnz_previous_noise = 0.0
	_pnz_exhaust_low = 0.0
	_pnz_exhaust_band = 0.0
	_pnz_exhaust_mid_low = 0.0
	_pnz_exhaust_mid_band = 0.0
	_pnz_intake_low = 0.0
	_pnz_intake_band = 0.0
	_pnz_mechanical_low = 0.0
	_pnz_mechanical_band = 0.0
	_pnz_dc_input = 0.0
	_pnz_dc_output = 0.0
