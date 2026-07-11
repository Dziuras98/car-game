extends "res://scripts/car/procedural_audio_player_3d.gd"
class_name EngineAudioSynthesizer

const CYLINDER_GAINS := [1.000, 0.982, 1.012, 0.991, 1.006, 0.976]
const BANK_BALANCE := [1.000, 0.972, 1.000, 0.972, 1.000, 0.972]

@export_category("Core")
@export_range(4, 12, 1) var cylinders: int = 6
@export_range(16000, 48000, 1000) var mix_rate: int = 32000
@export var idle_volume_db: float = -23.0
@export var load_volume_db: float = -7.0
@export_range(1.0, 40.0, 0.5) var rpm_smoothing: float = 14.0
@export_range(1.0, 40.0, 0.5) var throttle_smoothing: float = 18.0

@export_category("Stock VQ37VHR character")
@export_range(0.0, 1.0, 0.01) var exhaust_roughness: float = 0.13
@export_range(0.0, 1.0, 0.01) var intake_presence: float = 0.22
@export_range(0.0, 1.0, 0.01) var exhaust_resonance: float = 0.38
@export_range(0.0, 1.0, 0.01) var mechanical_noise: float = 0.07
@export_range(0.0, 1.0, 0.01) var overrun_crackle: float = 0.11
@export_range(0.0, 1.0, 0.01) var high_rpm_rasp: float = 0.24
@export_range(0.0, 1.0, 0.01) var bank_asymmetry: float = 0.035
@export_range(0.0, 1.0, 0.01) var idle_irregularity: float = 0.018
@export_range(0.0, 1.0, 0.01) var induction_transient: float = 0.24

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
var _phase_idle_modulation: float = 0.0
var _firing_index: int = 0
var _previous_combustion: float = 0.0

var _noise_slow: float = 0.0
var _noise_medium: float = 0.0
var _previous_white_noise: float = 0.0
var _idle_noise: float = 0.0

var _exhaust_body_low: float = 0.0
var _exhaust_body_band: float = 0.0
var _exhaust_mid_low: float = 0.0
var _exhaust_mid_band: float = 0.0
var _intake_low: float = 0.0
var _intake_band: float = 0.0
var _rasp_low: float = 0.0
var _rasp_band: float = 0.0

var _crackle_timer: float = 0.0
var _crackle_envelope: float = 0.0
var _limiter_phase: float = 0.0
var _limiter_active: bool = false

var _dc_previous_input: float = 0.0
var _dc_previous_output: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _debug_state: Dictionary = {}


func _ready() -> void:
	_car = get_parent() as PlayerCarController
	_rng.seed = int(get_instance_id()) ^ 0x37037
	procedural_voice_group = &"engine"
	max_procedural_voices = mini(max_procedural_voices, 6)

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = maxi(mix_rate, 16000)
	generator.buffer_length = 0.09
	stream = generator
	unit_size = 6.0
	max_distance = 70.0
	procedural_generation_distance = max_distance + 5.0
	volume_db = idle_volume_db
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func _process(delta: float) -> void:
	if not debug_override_enabled and _car == null:
		return
	if not should_generate_procedural_audio(delta):
		return

	var target_rpm: float = debug_rpm if debug_override_enabled else _car.get_engine_rpm()
	var target_load: float = debug_load if debug_override_enabled else _car.get_engine_load()
	var target_throttle: float = debug_throttle if debug_override_enabled else _car.get_throttle_input()
	var point: Dictionary = sanitize_operating_point(
		target_rpm,
		target_load,
		target_throttle,
		_get_idle_rpm(),
		_get_rev_limit_rpm()
	)

	_smoothed_rpm = lerpf(_smoothed_rpm, float(point.rpm), 1.0 - exp(-rpm_smoothing * delta))
	_smoothed_load = lerpf(_smoothed_load, float(point.load), 1.0 - exp(-throttle_smoothing * delta))
	_smoothed_throttle = lerpf(_smoothed_throttle, float(point.throttle), 1.0 - exp(-throttle_smoothing * delta))
	_update_transient_envelopes(float(point.throttle), delta)

	var loudness: float = clampf(_smoothed_load + _smoothed_throttle * 0.18 + _overrun_amount * 0.10, 0.0, 1.0)
	volume_db = lerpf(idle_volume_db, load_volume_db, loudness)
	_fill_audio_buffer()
	_update_debug_state()


func _exit_tree() -> void:
	release_procedural_voice()
	stop()
	_playback = null
	stream = null


func get_debug_state() -> Dictionary:
	return _debug_state.duplicate(true)


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
	var pressure_spike: float = exp(-normalized * 17.0)
	var exhaust_tail: float = exp(-normalized * 4.3)
	var rarefaction: float = sin(phase) * exp(-normalized * 2.8)
	return pressure_spike * 1.32 - exhaust_tail * 0.34 + rarefaction * 0.16


func _fill_audio_buffer() -> void:
	if _playback == null:
		return
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
	var high_rpm_blend: float = _smoothstep((rpm_ratio - 0.43) / 0.48)
	var very_high_rpm_blend: float = _smoothstep((rpm_ratio - 0.68) / 0.28)

	_phase_idle_modulation = fposmod(_phase_idle_modulation + TAU * 7.2 * delta, TAU)
	_idle_noise = lerpf(_idle_noise, _rng.randf_range(-1.0, 1.0), 0.0028)
	var idle_speed_modulation: float = (
		sin(_phase_idle_modulation) * 0.45 + _idle_noise * 0.55
	) * idle_irregularity * idle_blend
	var firing_frequency: float = maxf(firing_frequency_hz(rpm, cylinders) * (1.0 + idle_speed_modulation), 1.0)
	var crank_frequency: float = maxf(rpm / 60.0, 1.0)
	var previous_firing_phase: float = _phase_firing
	_phase_firing = fposmod(_phase_firing + TAU * firing_frequency * delta, TAU)
	_phase_crank = fposmod(_phase_crank + TAU * crank_frequency * delta, TAU)
	_phase_valvetrain = fposmod(_phase_valvetrain + TAU * crank_frequency * 6.0 * delta, TAU)
	if _phase_firing < previous_firing_phase:
		_firing_index = (_firing_index + 1) % 6

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

	var cylinder_gain: float = float(CYLINDER_GAINS[_firing_index])
	var bank_mix: float = clampf(bank_asymmetry / 0.035, 0.0, 2.0) if bank_asymmetry > 0.0 else 0.0
	var bank_gain: float = lerpf(1.0, float(BANK_BALANCE[_firing_index]), bank_mix)
	var pulse: float = combustion_pulse(_phase_firing) * cylinder_gain * bank_gain * ignition_gate
	var pulse_derivative: float = pulse - _previous_combustion
	_previous_combustion = pulse

	var white_noise: float = _rng.randf_range(-1.0, 1.0)
	_noise_slow = lerpf(_noise_slow, white_noise, 0.035)
	_noise_medium = lerpf(_noise_medium, white_noise, 0.16)
	var highpassed_noise: float = white_noise - _noise_medium
	var differentiated_noise: float = white_noise - _previous_white_noise
	_previous_white_noise = white_noise

	var firing_harmonics: float = (
		sin(_phase_firing) * 0.17
		+ sin(_phase_firing * 2.0) * 0.11
		+ sin(_phase_firing * 3.0) * 0.055
		+ sin(_phase_firing * 4.0) * 0.035 * high_rpm_blend
	)
	var crank_body: float = sin(_phase_crank) * 0.06 + sin(_phase_crank * 2.0) * 0.045

	var exhaust_input: float = pulse * (0.78 + load * 0.40) + firing_harmonics * 0.32
	var exhaust_body_frequency: float = 165.0 + rpm_ratio * 65.0
	var exhaust_body: float = _process_exhaust_body(exhaust_input, exhaust_body_frequency, 0.58, sample_rate)
	var exhaust_mid_frequency: float = 520.0 + rpm_ratio * 420.0
	var exhaust_mid: float = _process_exhaust_mid(exhaust_input + pulse_derivative * 0.45, exhaust_mid_frequency, 0.62, sample_rate)

	var intake_input: float = (
		pulse * 0.42
		+ firing_harmonics * 0.33
		+ _noise_slow * (0.12 + throttle * 0.20)
	)
	var intake_frequency: float = 760.0 + rpm_ratio * 1180.0 + throttle * 170.0
	var intake_tone: float = _process_intake(intake_input, intake_frequency, 0.58, sample_rate)

	var rasp_input: float = pulse_derivative * 0.74 + highpassed_noise * 0.22 + differentiated_noise * 0.06
	var rasp_frequency: float = 2450.0 + rpm_ratio * 1900.0
	var rasp: float = _process_rasp(rasp_input, rasp_frequency, 0.72, sample_rate)

	var valve_lobe: float = pow(maxf(sin(_phase_valvetrain), 0.0), 13.0)
	var valvetrain: float = (valve_lobe - 0.08) * (0.35 + rpm_ratio * 0.85) + highpassed_noise * 0.10
	var crackle: float = _next_overrun_crackle(delta, white_noise)

	var load_gain: float = lerpf(0.32 + idle_blend * 0.11, 1.02, load)
	var rpm_gain: float = lerpf(0.44, 1.0, _smoothstep(rpm_ratio))
	var exhaust_mix: float = (
		exhaust_body * (0.55 + exhaust_resonance * 0.95)
		+ exhaust_mid * (0.20 + exhaust_roughness * 0.72)
		+ pulse * 0.18
		+ crank_body * 0.18
	)
	var intake_mix: float = intake_tone * intake_presence * (
		0.20 + throttle * 1.55 + _throttle_transient * induction_transient * 1.8
	)
	var rasp_mix: float = rasp * high_rpm_rasp * very_high_rpm_blend * (0.28 + load * 1.05)
	var mechanical_mix: float = valvetrain * mechanical_noise * (0.22 + high_rpm_blend * 0.95)
	var overrun_mix: float = crackle * overrun_crackle
	var sample: float = (
		exhaust_mix
		+ intake_mix
		+ rasp_mix
		+ mechanical_mix
		+ overrun_mix
	) * load_gain * rpm_gain * 0.29

	var dc_blocked: float = sample - _dc_previous_input + 0.996 * _dc_previous_output
	_dc_previous_input = sample
	_dc_previous_output = dc_blocked
	var saturated: float = dc_blocked / (1.0 + absf(dc_blocked) * 0.48)
	return clampf(saturated, -0.96, 0.96)


func _update_transient_envelopes(target_throttle: float, delta: float) -> void:
	var throttle_rise: float = maxf(target_throttle - _previous_target_throttle, 0.0)
	var throttle_drop: float = maxf(_previous_target_throttle - target_throttle, 0.0)
	_throttle_transient = maxf(_throttle_transient * exp(-7.5 * delta), clampf(throttle_rise * 5.0, 0.0, 1.0))
	var rpm_factor: float = clampf((_smoothed_rpm - 2800.0) / 3300.0, 0.0, 1.0)
	var overrun_target: float = rpm_factor if throttle_drop > 0.025 and target_throttle < 0.08 and _smoothed_load < 0.16 else 0.0
	_overrun_amount = lerpf(_overrun_amount, overrun_target, 1.0 - exp(-9.0 * delta))
	_previous_target_throttle = target_throttle


func _next_overrun_crackle(delta: float, white_noise: float) -> float:
	_crackle_timer -= delta
	if _overrun_amount > 0.08 and _crackle_timer <= 0.0:
		_crackle_envelope = _rng.randf_range(0.18, 0.52) * _overrun_amount
		_crackle_timer = _rng.randf_range(0.055, 0.19)
	_crackle_envelope *= exp(-58.0 * delta)
	return (white_noise * 0.72 + _noise_medium * 0.28) * _crackle_envelope


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


func _process_intake(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_intake_low += coefficient * _intake_band
	var high: float = input_value - _intake_low - damping * _intake_band
	_intake_band += coefficient * high
	return _intake_band


func _process_rasp(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_rasp_low += coefficient * _rasp_band
	var high: float = input_value - _rasp_low - damping * _rasp_band
	_rasp_band += coefficient * high
	return _rasp_band


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
		"mode": "self-contained VQ37VHR procedural model",
		"rpm": _smoothed_rpm,
		"load": _smoothed_load,
		"throttle": _smoothed_throttle,
		"firing_frequency_hz": firing_frequency_hz(_smoothed_rpm, cylinders),
		"limiter_active": _limiter_active,
		"overrun": _overrun_amount,
		"induction_transient": _throttle_transient,
		"rpm_ratio": _smoothed_rpm / maxf(rev_limit_rpm, 1.0),
	}


func _reset_synthesis_state() -> void:
	_phase_firing = 0.0
	_phase_crank = 0.0
	_phase_valvetrain = 0.0
	_phase_idle_modulation = 0.0
	_firing_index = 0
	_previous_combustion = 0.0
	_noise_slow = 0.0
	_noise_medium = 0.0
	_previous_white_noise = 0.0
	_idle_noise = 0.0
	_exhaust_body_low = 0.0
	_exhaust_body_band = 0.0
	_exhaust_mid_low = 0.0
	_exhaust_mid_band = 0.0
	_intake_low = 0.0
	_intake_band = 0.0
	_rasp_low = 0.0
	_rasp_band = 0.0
	_crackle_timer = 0.0
	_crackle_envelope = 0.0
	_limiter_phase = 0.0
	_limiter_active = false
	_dc_previous_input = 0.0
	_dc_previous_output = 0.0


func _smoothstep(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return clamped_value * clamped_value * (3.0 - 2.0 * clamped_value)
