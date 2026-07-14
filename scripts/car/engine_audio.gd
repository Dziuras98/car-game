extends "res://scripts/car/procedural_audio_player_3d.gd"
class_name EngineAudioSynthesizer

const VQ_CYLINDER_COUNT: int = 6
const REFERENCE_SAMPLE_RATE: float = 32000.0
const CYLINDER_GAINS := [1.000, 0.982, 1.012, 0.991, 1.006, 0.976]
const BANK_BALANCE := [1.000, 0.972, 1.000, 0.972, 1.000, 0.972]

@export_category("Core")
@export_range(4, 12, 1) var cylinders: int = 6
@export_range(16000, 48000, 1000) var mix_rate: int = 32000
@export var idle_volume_db: float = -18.0
@export var load_volume_db: float = -2.0
@export_range(0.0, 8.0, 0.5) var output_volume_boost_db: float = 4.0
@export_range(-6.0, 12.0, 0.5) var synthesis_gain_db: float = 3.5
@export_range(1.0, 40.0, 0.5) var rpm_smoothing: float = 14.0
@export_range(1.0, 40.0, 0.5) var throttle_smoothing: float = 18.0
@export_range(0.08, 0.30, 0.01) var generator_buffer_length: float = 0.15

@export_category("Stock VQ37VHR character")
@export_range(0.0, 1.0, 0.01) var exhaust_roughness: float = 0.17
@export_range(0.0, 1.0, 0.01) var intake_presence: float = 0.28
@export_range(0.0, 1.0, 0.01) var exhaust_resonance: float = 0.46
@export_range(0.0, 1.0, 0.01) var mechanical_noise: float = 0.10
@export_range(0.0, 1.0, 0.01) var overrun_crackle: float = 0.13
@export_range(0.0, 1.0, 0.01) var high_rpm_rasp: float = 0.31
@export_range(0.0, 1.0, 0.01) var bank_asymmetry: float = 0.045
@export_range(0.0, 1.0, 0.01) var idle_irregularity: float = 0.020
@export_range(0.0, 1.0, 0.01) var induction_transient: float = 0.31
@export_range(0.0, 1.0, 0.01) var exhaust_bank_separation: float = 0.24
@export_range(0.0, 1.0, 0.01) var exhaust_reflection: float = 0.22
@export_range(0.0, 1.0, 0.01) var intake_plenum_detail: float = 0.27
@export_range(0.0, 1.0, 0.01) var airflow_noise: float = 0.16
@export_range(0.0, 1.0, 0.01) var rotating_assembly_detail: float = 0.09

@export_category("Start and stop")
@export var play_startup_on_ready: bool = false
@export_range(0.2, 2.0, 0.05) var starter_duration: float = 0.80
@export_range(0.0, 1.0, 0.01) var starter_motor_level: float = 0.24
@export_range(0.3, 3.0, 0.05) var shutdown_duration: float = 1.10

@export_category("Limiter")
@export_range(0.02, 0.20, 0.005) var limiter_period: float = 0.060
@export_range(0.1, 0.9, 0.01) var limiter_cut_ratio: float = 0.46
@export_range(0.0, 0.5, 0.01) var limiter_residual_combustion: float = 0.08

@export_category("Debug")
@export var debug_override_enabled: bool = false
@export_range(400.0, 8500.0, 10.0) var debug_rpm: float = 700.0
@export_range(0.0, 1.0, 0.01) var debug_load: float = 0.0
@export_range(0.0, 1.0, 0.01) var debug_throttle: float = 0.0

var _car: PlayerCarController
var _playback: AudioStreamGeneratorPlayback
var _smoothed_rpm: float = 700.0
var _smoothed_load: float = 0.0
var _smoothed_throttle: float = 0.0
var _previous_target_throttle: float = 0.0
var _overrun_amount: float = 0.0
var _throttle_transient: float = 0.0

var _phase_firing: float = 0.0
var _phase_crank: float = 0.0
var _phase_valvetrain: float = 0.0
var _phase_cam_chain: float = 0.0
var _phase_idle_modulation: float = 0.0
var _firing_index: int = 0
var _previous_combustion: float = 0.0
var _previous_pulse_derivative: float = 0.0

var _noise_slow: float = 0.0
var _noise_medium: float = 0.0
var _noise_fast: float = 0.0
var _previous_white_noise: float = 0.0
var _idle_noise: float = 0.0

var _bank_a_low: float = 0.0
var _bank_a_band: float = 0.0
var _bank_b_low: float = 0.0
var _bank_b_band: float = 0.0
var _exhaust_body_low: float = 0.0
var _exhaust_body_band: float = 0.0
var _exhaust_mid_low: float = 0.0
var _exhaust_mid_band: float = 0.0
var _exhaust_reflection_low: float = 0.0
var _exhaust_reflection_band: float = 0.0
var _intake_low: float = 0.0
var _intake_band: float = 0.0
var _intake_plenum_low: float = 0.0
var _intake_plenum_band: float = 0.0
var _rasp_low: float = 0.0
var _rasp_band: float = 0.0
var _mechanical_low: float = 0.0
var _mechanical_band: float = 0.0

var _crackle_timer: float = 0.0
var _crackle_envelope: float = 0.0
var _limiter_phase: float = 0.0
var _limiter_active: bool = false
var _startup_remaining: float = 0.0
var _shutdown_remaining: float = 0.0
var _shutdown_start_rpm: float = 0.0
var _starter_phase: float = 0.0
var _engine_running: bool = true
var _engine_state_gain: float = 1.0
var _startup_progress: float = 1.0
var _buffer_underrun_count: int = 0

var _dc_previous_input: float = 0.0
var _dc_previous_output: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _debug_state: Dictionary = {}


func _ready() -> void:
	_car = get_parent() as PlayerCarController
	_rng.seed = int(get_instance_id()) ^ 0x37037
	procedural_voice_group = &"engine"
	max_procedural_voices = mini(max_procedural_voices, 6)
	procedural_voice_cost = 3

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = maxi(mix_rate, 16000)
	generator.buffer_length = clampf(generator_buffer_length, 0.08, 0.30)
	stream = generator
	unit_size = 6.0
	max_distance = 70.0
	procedural_generation_distance = max_distance + 5.0
	volume_db = idle_volume_db + output_volume_boost_db
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback
	if play_startup_on_ready:
		trigger_engine_start()


func _process(delta: float) -> void:
	if not debug_override_enabled and _car == null:
		return
	var safe_delta: float = maxf(delta, 0.0)
	_advance_engine_state(safe_delta)

	var target_rpm: float = debug_rpm if debug_override_enabled else _car.get_engine_rpm()
	var target_load: float = debug_load if debug_override_enabled else _car.get_engine_load()
	var target_throttle: float = debug_throttle if debug_override_enabled else _car.get_throttle_input()
	if _shutdown_remaining > 0.0:
		var shutdown_ratio: float = clampf(_shutdown_remaining / maxf(shutdown_duration, 0.01), 0.0, 1.0)
		target_rpm = _shutdown_start_rpm * shutdown_ratio
		target_load = 0.0
		target_throttle = 0.0
	elif not _engine_running:
		target_rpm = 0.0
		target_load = 0.0
		target_throttle = 0.0
	var point: Dictionary = sanitize_operating_point(
		target_rpm,
		target_load,
		target_throttle,
		_get_idle_rpm(),
		_get_rev_limit_rpm()
	)

	_smoothed_rpm = lerpf(_smoothed_rpm, float(point.rpm), 1.0 - exp(-rpm_smoothing * safe_delta))
	_smoothed_load = lerpf(_smoothed_load, float(point.load), 1.0 - exp(-throttle_smoothing * safe_delta))
	_smoothed_throttle = lerpf(_smoothed_throttle, float(point.throttle), 1.0 - exp(-throttle_smoothing * safe_delta))
	_update_transient_envelopes(float(point.throttle), safe_delta)

	var loudness: float = clampf(
		_smoothed_load * 0.90
		+ _smoothed_throttle * 0.26
		+ _overrun_amount * 0.12
		+ _throttle_transient * 0.08,
		0.0,
		1.0
	)
	volume_db = lerpf(idle_volume_db, load_volume_db, loudness) + output_volume_boost_db
	if should_generate_procedural_audio(safe_delta):
		_fill_audio_buffer()
	_update_debug_state()


func _exit_tree() -> void:
	release_procedural_voice()
	stop()
	_playback = null
	stream = null


func get_debug_state() -> Dictionary:
	return _debug_state.duplicate(true)


func trigger_engine_start() -> void:
	_engine_running = true
	_engine_state_gain = 1.0
	_shutdown_remaining = 0.0
	_startup_remaining = maxf(starter_duration, 0.0)
	_startup_progress = 0.0 if _startup_remaining > 0.0 else 1.0
	_smoothed_rpm = minf(_smoothed_rpm, 230.0)
	_smoothed_load = 0.0
	_smoothed_throttle = 0.0


func trigger_engine_shutdown() -> void:
	_startup_remaining = 0.0
	_startup_progress = 1.0
	_shutdown_remaining = maxf(shutdown_duration, 0.0)
	_shutdown_start_rpm = maxf(_smoothed_rpm, _get_idle_rpm())
	if _shutdown_remaining <= 0.0:
		_engine_running = false
		_engine_state_gain = 0.0
		_clear_audio_tail_state()


func generate_test_frames(frame_count: int, rpm: float, load: float, throttle: float) -> PackedFloat32Array:
	_reset_synthesis_state()
	_rng.seed = 0x37037
	var point: Dictionary = sanitize_operating_point(rpm, load, throttle, 650.0, 7600.0)
	_smoothed_rpm = float(point.rpm)
	_smoothed_load = float(point.load)
	_smoothed_throttle = float(point.throttle)
	_previous_target_throttle = _smoothed_throttle
	var frames := PackedFloat32Array()
	frames.resize(maxi(frame_count, 0))
	for index: int in frames.size():
		frames[index] = _generate_sample()
	return frames


func generate_stateful_frames(frame_count: int) -> PackedFloat32Array:
	var frames := PackedFloat32Array()
	frames.resize(maxi(frame_count, 0))
	for index: int in frames.size():
		frames[index] = _generate_sample()
	return frames


func advance_engine_state(delta: float) -> void:
	_advance_engine_state(maxf(delta, 0.0))


func get_buffer_underrun_count() -> int:
	return _buffer_underrun_count


static func sample_rate_invariant_alpha(alpha_at_32k: float, sample_rate: float) -> float:
	var safe_alpha: float = clampf(alpha_at_32k, 0.0, 1.0)
	var safe_rate: float = maxf(sample_rate, 1.0)
	return 1.0 - pow(1.0 - safe_alpha, REFERENCE_SAMPLE_RATE / safe_rate)


static func sample_rate_invariant_decay(decay_at_32k: float, sample_rate: float) -> float:
	var safe_decay: float = clampf(decay_at_32k, 0.0, 1.0)
	return pow(safe_decay, REFERENCE_SAMPLE_RATE / maxf(sample_rate, 1.0))


static func bandlimited_frequency(frequency: float, sample_rate: float, nyquist_ratio: float = 0.42) -> float:
	return clampf(frequency, 0.0, maxf(sample_rate, 1.0) * clampf(nyquist_ratio, 0.05, 0.49))


static func sanitize_operating_point(
	rpm: float,
	load: float,
	throttle: float,
	idle_rpm: float,
	rev_limit_rpm: float
) -> Dictionary:
	var safe_idle: float = idle_rpm if is_finite(idle_rpm) and idle_rpm > 0.0 else 650.0
	var safe_limit: float = rev_limit_rpm if is_finite(rev_limit_rpm) and rev_limit_rpm > safe_idle else safe_idle + 1000.0
	var safe_rpm: float = rpm if is_finite(rpm) else safe_idle
	var safe_load: float = load if is_finite(load) else 0.0
	var safe_throttle: float = throttle if is_finite(throttle) else 0.0
	return {
		"rpm": clampf(safe_rpm, 0.0, safe_limit * 1.08),
		"load": clampf(safe_load, 0.0, 1.0),
		"throttle": clampf(safe_throttle, 0.0, 1.0),
		"idle_rpm": safe_idle,
		"rev_limit_rpm": safe_limit,
	}


static func firing_frequency_hz(rpm: float, cylinder_count: int) -> float:
	var safe_rpm: float = rpm if is_finite(rpm) else 0.0
	return maxf(safe_rpm, 0.0) / 60.0 * float(maxi(cylinder_count, 1)) * 0.5


static func limiter_gate(
	rpm: float,
	throttle: float,
	rev_limit_rpm: float,
	cycle_phase: float,
	cut_ratio: float,
	residual: float
) -> float:
	if not is_finite(rpm) or not is_finite(throttle) or not is_finite(rev_limit_rpm):
		return 1.0
	if rev_limit_rpm <= 0.0 or rpm < rev_limit_rpm * 0.985 or throttle <= 0.65:
		return 1.0
	var normalized_phase: float = fposmod(cycle_phase, 1.0)
	return clampf(residual, 0.0, 1.0) if normalized_phase < clampf(cut_ratio, 0.0, 1.0) else 1.0


static func combustion_pulse(phase: float) -> float:
	var normalized: float = fposmod(phase, TAU) / TAU
	var pressure_spike: float = exp(-normalized * 19.0)
	var exhaust_tail: float = exp(-normalized * 4.1)
	var rarefaction: float = sin(phase) * exp(-normalized * 2.7)
	var chamber_ring: float = sin(phase * 5.0 + 0.32) * exp(-normalized * 9.0)
	return pressure_spike * 1.38 - exhaust_tail * 0.35 + rarefaction * 0.17 + chamber_ring * 0.055


func _advance_engine_state(delta: float) -> void:
	var safe_delta: float = maxf(delta, 0.0)
	if _startup_remaining > 0.0:
		_startup_remaining = maxf(_startup_remaining - safe_delta, 0.0)
		_startup_progress = 1.0 - clampf(
			_startup_remaining / maxf(starter_duration, 0.01),
			0.0,
			1.0
		)
	else:
		_startup_progress = 1.0

	if _shutdown_remaining > 0.0:
		_shutdown_remaining = maxf(_shutdown_remaining - safe_delta, 0.0)
		var shutdown_progress: float = 1.0 - clampf(
			_shutdown_remaining / maxf(shutdown_duration, 0.01),
			0.0,
			1.0
		)
		_engine_state_gain = 1.0 - _smoothstep(shutdown_progress)
		if _shutdown_remaining <= 0.0:
			_engine_running = false
			_engine_state_gain = 0.0
			_clear_audio_tail_state()
	elif _engine_running:
		_engine_state_gain = 1.0
	else:
		_engine_state_gain = 0.0


func _fill_audio_buffer() -> void:
	if _playback == null:
		return
	_buffer_underrun_count = _playback.get_skips()
	var frames_available: int = _playback.get_frames_available()
	for frame_index: int in frames_available:
		var sample: float = _generate_sample()
		_playback.push_frame(Vector2(sample, sample))


func _generate_sample() -> float:
	var sample_rate: float = float(maxi(mix_rate, 16000))
	var delta: float = 1.0 / sample_rate
	var idle_rpm: float = _get_idle_rpm()
	var rev_limit_rpm: float = _get_rev_limit_rpm()
	var rpm: float = clampf(_smoothed_rpm, 0.0, rev_limit_rpm * 1.08)
	var load: float = clampf(_smoothed_load, 0.0, 1.0)
	var throttle: float = clampf(_smoothed_throttle, 0.0, 1.0)
	var rpm_ratio: float = clampf(rpm / maxf(rev_limit_rpm, 1.0), 0.0, 1.08)
	var idle_blend: float = 1.0 - _smoothstep((rpm - idle_rpm) / 850.0)
	var mid_rpm_blend: float = _smoothstep((rpm_ratio - 0.20) / 0.42)
	var high_rpm_blend: float = _smoothstep((rpm_ratio - 0.43) / 0.48)
	var very_high_rpm_blend: float = _smoothstep((rpm_ratio - 0.68) / 0.28)

	_phase_idle_modulation = fposmod(_phase_idle_modulation + TAU * 7.2 * delta, TAU)
	_idle_noise = lerpf(_idle_noise, _rng.randf_range(-1.0, 1.0), sample_rate_invariant_alpha(0.0028, sample_rate))
	var idle_speed_modulation: float = (
		sin(_phase_idle_modulation) * 0.45 + _idle_noise * 0.55
	) * idle_irregularity * idle_blend
	var firing_frequency: float = maxf(firing_frequency_hz(rpm, VQ_CYLINDER_COUNT) * (1.0 + idle_speed_modulation), 0.0)
	var crank_frequency: float = maxf(rpm / 60.0, 0.0)
	var previous_firing_phase: float = _phase_firing
	_phase_firing = fposmod(_phase_firing + TAU * firing_frequency * delta, TAU)
	_phase_crank = fposmod(_phase_crank + TAU * crank_frequency * delta, TAU)
	_phase_valvetrain = fposmod(_phase_valvetrain + TAU * crank_frequency * 6.0 * delta, TAU)
	_phase_cam_chain = fposmod(_phase_cam_chain + TAU * crank_frequency * 0.5 * delta, TAU)
	if _phase_firing < previous_firing_phase:
		_firing_index = (_firing_index + 1) % VQ_CYLINDER_COUNT

	var limiter_cycle: float = maxf(limiter_period, 0.02)
	_limiter_active = rpm >= rev_limit_rpm * 0.985 and throttle > 0.65
	_limiter_phase = fposmod(_limiter_phase + delta / limiter_cycle, 1.0) if _limiter_active else 0.0
	var ignition_gate: float = limiter_gate(
		rpm,
		throttle,
		rev_limit_rpm,
		_limiter_phase,
		limiter_cut_ratio,
		limiter_residual_combustion
	)

	var startup_progress: float = _startup_progress
	var startup_combustion_gate: float = 1.0
	var starter_motor: float = 0.0
	if _startup_remaining > 0.0:
		startup_combustion_gate = _smoothstep((startup_progress - 0.24) / 0.46)
		var starter_frequency: float = 115.0 + startup_progress * 95.0
		_starter_phase = fposmod(_starter_phase + TAU * starter_frequency * delta, TAU)
		var starter_envelope: float = sin(clampf(startup_progress, 0.0, 1.0) * PI)
		starter_motor = (
			sin(_starter_phase) * 0.70
			+ sin(_starter_phase * 2.0) * 0.21
			+ sin(_starter_phase * 3.0) * 0.07
			+ _noise_medium * 0.09
		) * starter_envelope * starter_motor_level

	var combustion_state_gate: float = 1.0
	var cylinder_gain: float = float(CYLINDER_GAINS[_firing_index])
	var bank_mix: float = clampf(bank_asymmetry / 0.035, 0.0, 2.0) if bank_asymmetry > 0.0 else 0.0
	var bank_gain: float = lerpf(1.0, float(BANK_BALANCE[_firing_index]), bank_mix)
	var pulse: float = combustion_pulse(_phase_firing) * cylinder_gain * bank_gain * ignition_gate * startup_combustion_gate * combustion_state_gate
	var pulse_derivative: float = pulse - _previous_combustion
	var pulse_acceleration: float = pulse_derivative - _previous_pulse_derivative
	_previous_combustion = pulse
	_previous_pulse_derivative = pulse_derivative

	var white_noise: float = _rng.randf_range(-1.0, 1.0)
	_noise_slow = lerpf(_noise_slow, white_noise, sample_rate_invariant_alpha(0.030, sample_rate))
	_noise_medium = lerpf(_noise_medium, white_noise, sample_rate_invariant_alpha(0.14, sample_rate))
	_noise_fast = lerpf(_noise_fast, white_noise, sample_rate_invariant_alpha(0.38, sample_rate))
	var highpassed_noise: float = white_noise - _noise_medium
	var upper_noise: float = white_noise - _noise_fast
	var differentiated_noise: float = white_noise - _previous_white_noise
	_previous_white_noise = white_noise

	var firing_harmonics: float = (
		sin(_phase_firing) * 0.18
		+ sin(_phase_firing * 2.0) * 0.12
		+ sin(_phase_firing * 3.0) * 0.070
		+ sin(_phase_firing * 4.0) * 0.046 * mid_rpm_blend
		+ sin(_phase_firing * 5.0 + 0.18) * 0.031 * high_rpm_blend
		+ sin(_phase_firing * 7.0 - 0.23) * 0.020 * very_high_rpm_blend
	) * startup_combustion_gate * shutdown_gate * combustion_state_gate
	var crank_body: float = (
		sin(_phase_crank) * 0.070
		+ sin(_phase_crank * 2.0) * 0.052
		+ sin(_phase_crank * 3.0 + 0.24) * 0.025 * mid_rpm_blend
	)

	var bank_a_gate: float = 1.0 if (_firing_index % 2) == 0 else 0.0
	var bank_b_gate: float = 1.0 - bank_a_gate
	var bank_a_input: float = pulse * bank_a_gate + firing_harmonics * 0.11
	var bank_b_input: float = pulse * bank_b_gate + firing_harmonics * 0.11
	var bank_a_frequency: float = 188.0 + rpm_ratio * 77.0
	var bank_b_frequency: float = 197.0 + rpm_ratio * 70.0
	var bank_a_body: float = _process_bank_a(bank_a_input, bank_a_frequency, 0.61, sample_rate)
	var bank_b_body: float = _process_bank_b(bank_b_input, bank_b_frequency, 0.63, sample_rate)
	var bank_sum: float = bank_a_body + bank_b_body
	var bank_difference: float = bank_a_body - bank_b_body

	var exhaust_input: float = pulse * (0.82 + load * 0.46) + firing_harmonics * 0.36 + bank_sum * 0.22
	var exhaust_body_frequency: float = 158.0 + rpm_ratio * 82.0
	var exhaust_body: float = _process_exhaust_body(exhaust_input, exhaust_body_frequency, 0.57, sample_rate)
	var exhaust_mid_frequency: float = 500.0 + rpm_ratio * 510.0
	var exhaust_mid: float = _process_exhaust_mid(
		exhaust_input + pulse_derivative * 0.50 + bank_difference * exhaust_bank_separation,
		exhaust_mid_frequency,
		0.61,
		sample_rate
	)
	var reflection_frequency: float = 1040.0 + rpm_ratio * 620.0
	var exhaust_echo: float = _process_exhaust_reflection(
		pulse_derivative * 0.50 + pulse_acceleration * 0.12 + exhaust_mid * 0.20,
		reflection_frequency,
		0.69,
		sample_rate
	)

	var intake_input: float = (
		pulse * 0.40
		+ firing_harmonics * 0.36
		+ _noise_slow * (0.10 + throttle * 0.24)
	)
	var intake_frequency: float = 720.0 + rpm_ratio * 1280.0 + throttle * 210.0
	var intake_tone: float = _process_intake(intake_input, intake_frequency, 0.57, sample_rate)
	var plenum_frequency: float = 1420.0 + rpm_ratio * 1700.0 + throttle * 260.0
	var intake_plenum: float = _process_intake_plenum(
		pulse_derivative * 0.34 + firing_harmonics * 0.28 + highpassed_noise * 0.11,
		plenum_frequency,
		0.66,
		sample_rate
	)
	var intake_air: float = (
		highpassed_noise * 0.60
		+ differentiated_noise * 0.17
		+ _noise_slow * 0.23
	) * airflow_noise * throttle * (0.28 + load * 0.72) * (0.30 + high_rpm_blend * 0.70)

	var rasp_input: float = pulse_derivative * 0.76 + pulse_acceleration * 0.12 + highpassed_noise * 0.20 + differentiated_noise * 0.07
	var rasp_frequency: float = 2380.0 + rpm_ratio * 2200.0
	var rasp: float = _process_rasp(rasp_input, rasp_frequency, 0.71, sample_rate)

	var valve_lobe: float = pow(maxf(sin(_phase_valvetrain), 0.0), 15.0)
	var chain_whine: float = (
		sin(_phase_cam_chain * 12.0 + 0.16) * 0.40
		+ sin(_phase_cam_chain * 18.0 - 0.21) * 0.23
		+ upper_noise * 0.16
	)
	var mechanical_frequency: float = 1750.0 + rpm_ratio * 2300.0
	var mechanical_resonance: float = _process_mechanical(
		(valve_lobe - 0.065) * 0.84 + chain_whine * rotating_assembly_detail,
		mechanical_frequency,
		0.74,
		sample_rate
	)
	var valvetrain: float = (
		(valve_lobe - 0.065) * (0.34 + rpm_ratio * 0.94)
		+ highpassed_noise * 0.08
		+ mechanical_resonance * 0.48
	)
	var crackle: float = _next_overrun_crackle(delta, white_noise)

	var load_gain: float = lerpf(0.36 + idle_blend * 0.13, 1.08, load)
	var rpm_gain: float = lerpf(0.49, 1.04, _smoothstep(rpm_ratio))
	var exhaust_mix: float = (
		exhaust_body * (0.58 + exhaust_resonance * 1.02)
		+ exhaust_mid * (0.23 + exhaust_roughness * 0.78)
		+ exhaust_echo * exhaust_reflection * (0.22 + load * 0.78)
		+ bank_sum * exhaust_bank_separation * 0.54
		+ bank_difference * exhaust_bank_separation * 0.18
		+ pulse * 0.19
		+ crank_body * 0.20
	)
	var intake_mix: float = (
		intake_tone * (0.25 + throttle * 1.55 + _throttle_transient * induction_transient * 1.9)
		+ intake_plenum * intake_plenum_detail * (0.18 + throttle * 1.28)
		+ intake_air
	) * intake_presence
	var rasp_mix: float = rasp * high_rpm_rasp * very_high_rpm_blend * (0.34 + load * 1.12)
	var mechanical_mix: float = valvetrain * mechanical_noise * (0.24 + high_rpm_blend * 1.02)
	var overrun_mix: float = crackle * overrun_crackle
	var engine_sample: float = (
		exhaust_mix
		+ intake_mix
		+ rasp_mix
		+ mechanical_mix
		+ overrun_mix
	) * load_gain * rpm_gain * 0.31
	var sample: float = engine_sample * _engine_state_gain + starter_motor * 0.38

	var dc_decay: float = sample_rate_invariant_decay(0.996, sample_rate)
	var dc_blocked: float = sample - _dc_previous_input + dc_decay * _dc_previous_output
	_dc_previous_input = sample
	_dc_previous_output = dc_blocked
	var driven: float = dc_blocked * db_to_linear(synthesis_gain_db)
	return tanh(driven * 1.08) * 0.97


func _update_transient_envelopes(target_throttle: float, delta: float) -> void:
	var throttle_rise: float = maxf(target_throttle - _previous_target_throttle, 0.0)
	var throttle_drop: float = maxf(_previous_target_throttle - target_throttle, 0.0)
	_throttle_transient = maxf(_throttle_transient * exp(-7.5 * delta), clampf(throttle_rise * 5.4, 0.0, 1.0))
	var rpm_factor: float = clampf((_smoothed_rpm - 2700.0) / 3400.0, 0.0, 1.0)
	var overrun_target: float = rpm_factor if throttle_drop > 0.022 and target_throttle < 0.09 and _smoothed_load < 0.18 else 0.0
	_overrun_amount = lerpf(_overrun_amount, overrun_target, 1.0 - exp(-9.0 * delta))
	_previous_target_throttle = target_throttle


func _next_overrun_crackle(delta: float, white_noise: float) -> float:
	_crackle_timer -= delta
	if _overrun_amount > 0.08 and _crackle_timer <= 0.0:
		_crackle_envelope = _rng.randf_range(0.20, 0.56) * _overrun_amount
		_crackle_timer = _rng.randf_range(0.050, 0.18)
	_crackle_envelope *= exp(-55.0 * delta)
	return (white_noise * 0.66 + _noise_medium * 0.25 + _noise_slow * 0.09) * _crackle_envelope


func _process_bank_a(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_bank_a_low += coefficient * _bank_a_band
	var high: float = input_value - _bank_a_low - damping * _bank_a_band
	_bank_a_band += coefficient * high
	return _bank_a_band


func _process_bank_b(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_bank_b_low += coefficient * _bank_b_band
	var high: float = input_value - _bank_b_low - damping * _bank_b_band
	_bank_b_band += coefficient * high
	return _bank_b_band


func _process_exhaust_body(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_exhaust_body_low += coefficient * _exhaust_body_band
	var high: float = input_value - _exhaust_body_low - damping * _exhaust_body_band
	_exhaust_body_band += coefficient * high
	return _exhaust_body_band


func _process_exhaust_mid(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_exhaust_mid_low += coefficient * _exhaust_mid_band
	var high: float = input_value - _exhaust_mid_low - damping * _exhaust_mid_band
	_exhaust_mid_band += coefficient * high
	return _exhaust_mid_band


func _process_exhaust_reflection(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_exhaust_reflection_low += coefficient * _exhaust_reflection_band
	var high: float = input_value - _exhaust_reflection_low - damping * _exhaust_reflection_band
	_exhaust_reflection_band += coefficient * high
	return _exhaust_reflection_band


func _process_intake(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_intake_low += coefficient * _intake_band
	var high: float = input_value - _intake_low - damping * _intake_band
	_intake_band += coefficient * high
	return _intake_band


func _process_intake_plenum(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_intake_plenum_low += coefficient * _intake_plenum_band
	var high: float = input_value - _intake_plenum_low - damping * _intake_plenum_band
	_intake_plenum_band += coefficient * high
	return _intake_plenum_band


func _process_rasp(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_rasp_low += coefficient * _rasp_band
	var high: float = input_value - _rasp_low - damping * _rasp_band
	_rasp_band += coefficient * high
	return _rasp_band


func _process_mechanical(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_mechanical_low += coefficient * _mechanical_band
	var high: float = input_value - _mechanical_low - damping * _mechanical_band
	_mechanical_band += coefficient * high
	return _mechanical_band


func _svf_coefficient(frequency: float, sample_rate: float) -> float:
	var safe_frequency: float = clampf(frequency, 20.0, sample_rate * 0.42)
	return minf(2.0 * sin(PI * safe_frequency / sample_rate), 1.82)


func _get_idle_rpm() -> float:
	if _car != null and _car.car_specs != null:
		return maxf(_car.car_specs.idle_rpm, 1.0)
	return 650.0


func _get_rev_limit_rpm() -> float:
	if _car != null and _car.car_specs != null:
		return maxf(_car.car_specs.rev_limiter_rpm, _get_idle_rpm() + 1.0)
	return 7600.0


func _update_debug_state() -> void:
	var rev_limit_rpm: float = _get_rev_limit_rpm()
	_debug_state = {
		"mode": "detailed self-contained VQ37VHR procedural model",
		"rpm": _smoothed_rpm,
		"load": _smoothed_load,
		"throttle": _smoothed_throttle,
		"firing_frequency_hz": firing_frequency_hz(_smoothed_rpm, VQ_CYLINDER_COUNT),
		"limiter_active": _limiter_active,
		"overrun": _overrun_amount,
		"induction_transient": _throttle_transient,
		"rpm_ratio": _smoothed_rpm / maxf(rev_limit_rpm, 1.0),
		"startup_active": _startup_remaining > 0.0,
		"shutdown_active": _shutdown_remaining > 0.0,
		"engine_running": _engine_running,
		"engine_state_gain": _engine_state_gain,
		"buffer_underruns": _buffer_underrun_count,
		"synthesis_gain_db": synthesis_gain_db,
		"output_volume_boost_db": output_volume_boost_db,
	}


func _clear_audio_tail_state() -> void:
	_previous_combustion = 0.0
	_previous_pulse_derivative = 0.0
	_bank_a_low = 0.0
	_bank_a_band = 0.0
	_bank_b_low = 0.0
	_bank_b_band = 0.0
	_exhaust_body_low = 0.0
	_exhaust_body_band = 0.0
	_exhaust_mid_low = 0.0
	_exhaust_mid_band = 0.0
	_exhaust_reflection_low = 0.0
	_exhaust_reflection_band = 0.0
	_intake_low = 0.0
	_intake_band = 0.0
	_intake_plenum_low = 0.0
	_intake_plenum_band = 0.0
	_rasp_low = 0.0
	_rasp_band = 0.0
	_mechanical_low = 0.0
	_mechanical_band = 0.0
	_crackle_envelope = 0.0
	_dc_previous_input = 0.0
	_dc_previous_output = 0.0


func _reset_synthesis_state() -> void:
	_phase_firing = 0.0
	_phase_crank = 0.0
	_phase_valvetrain = 0.0
	_phase_cam_chain = 0.0
	_phase_idle_modulation = 0.0
	_firing_index = 0
	_previous_combustion = 0.0
	_previous_pulse_derivative = 0.0
	_noise_slow = 0.0
	_noise_medium = 0.0
	_noise_fast = 0.0
	_previous_white_noise = 0.0
	_idle_noise = 0.0
	_bank_a_low = 0.0
	_bank_a_band = 0.0
	_bank_b_low = 0.0
	_bank_b_band = 0.0
	_exhaust_body_low = 0.0
	_exhaust_body_band = 0.0
	_exhaust_mid_low = 0.0
	_exhaust_mid_band = 0.0
	_exhaust_reflection_low = 0.0
	_exhaust_reflection_band = 0.0
	_intake_low = 0.0
	_intake_band = 0.0
	_intake_plenum_low = 0.0
	_intake_plenum_band = 0.0
	_rasp_low = 0.0
	_rasp_band = 0.0
	_mechanical_low = 0.0
	_mechanical_band = 0.0
	_crackle_timer = 0.0
	_crackle_envelope = 0.0
	_limiter_phase = 0.0
	_limiter_active = false
	_startup_remaining = 0.0
	_shutdown_remaining = 0.0
	_shutdown_start_rpm = 0.0
	_starter_phase = 0.0
	_engine_running = true
	_engine_state_gain = 1.0
	_startup_progress = 1.0
	_buffer_underrun_count = 0
	_dc_previous_input = 0.0
	_dc_previous_output = 0.0


func _smoothstep(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return clamped_value * clamped_value * (3.0 - 2.0 * clamped_value)
