extends ProfiledEngineAudioSynthesizer
class_name CrossPlaneV8EngineAudioSynthesizer

const FORD_FE_FIRING_ORDER: Array[int] = [1, 5, 4, 2, 6, 3, 7, 8]
const FORD_FE_BANK_SEQUENCE: Array[int] = [0, 1, 0, 0, 1, 0, 1, 1]
const EVENT_GAINS: Array[float] = [1.000, 0.982, 1.014, 0.993, 1.007, 0.978, 1.012, 0.988]

@export_group("Cross-plane V8")
@export_range(0.0, 1.0, 0.01) var crossplane_roughness: float = 0.72
@export_range(0.0, 1.0, 0.01) var low_order_rumble: float = 0.82
@export_range(0.0, 1.0, 0.01) var bank_stereo_width: float = 0.72
@export_range(0.0, 1.0, 0.01) var exhaust_crossover: float = 0.26
@export_range(0.0, 1.0, 0.01) var cam_loaf: float = 0.30

var _event_phase: float = 0.0
var _event_index: int = 0
var _previous_bank: int = 1
var _bank_a_thump: float = 0.0
var _bank_b_thump: float = 0.0
var _doublet_envelope: float = 0.0

var _header_a_low: float = 0.0
var _header_a_band: float = 0.0
var _header_b_low: float = 0.0
var _header_b_band: float = 0.0
var _rumble_low: float = 0.0
var _rumble_band: float = 0.0
var _common_body_low: float = 0.0
var _common_body_band: float = 0.0
var _common_mid_low: float = 0.0
var _common_mid_band: float = 0.0
var _carb_low: float = 0.0
var _carb_band: float = 0.0
var _metal_low: float = 0.0
var _metal_band: float = 0.0

var _dc_left_input: float = 0.0
var _dc_left_output: float = 0.0
var _dc_right_input: float = 0.0
var _dc_right_output: float = 0.0
var _last_stereo_frame: Vector2 = Vector2.ZERO


func _ready() -> void:
	cylinders = 8
	super._ready()


func _fill_audio_buffer() -> void:
	if _playback == null:
		return
	var frames_available: int = _playback.get_frames_available()
	for frame_index: int in frames_available:
		_playback.push_frame(_generate_stereo_frame())


func _generate_sample() -> float:
	var frame: Vector2 = _generate_stereo_frame()
	return (frame.x + frame.y) * 0.5


func generate_test_stereo_frames(
	frame_count: int,
	rpm: float,
	load: float,
	throttle: float
) -> PackedVector2Array:
	_reset_synthesis_state()
	_rng.seed = 0x428FE
	var point: Dictionary = sanitize_operating_point(rpm, load, throttle, 650.0, 6200.0)
	_smoothed_rpm = float(point.rpm)
	_smoothed_load = float(point.load)
	_smoothed_throttle = float(point.throttle)
	_previous_target_throttle = _smoothed_throttle
	var frames := PackedVector2Array()
	frames.resize(maxi(frame_count, 0))
	for index: int in frames.size():
		frames[index] = _generate_stereo_frame()
	return frames


static func get_firing_order() -> PackedInt32Array:
	return PackedInt32Array(FORD_FE_FIRING_ORDER)


static func get_bank_sequence() -> PackedInt32Array:
	return PackedInt32Array(FORD_FE_BANK_SEQUENCE)


static func get_bank_event_intervals_degrees(bank: int) -> PackedFloat32Array:
	var positions: Array[float] = []
	for event_index: int in FORD_FE_BANK_SEQUENCE.size():
		if FORD_FE_BANK_SEQUENCE[event_index] == bank:
			positions.append(float(event_index) * 90.0)
	var intervals := PackedFloat32Array()
	if positions.is_empty():
		return intervals
	for index: int in positions.size():
		var current: float = positions[index]
		var following: float = positions[(index + 1) % positions.size()]
		if following <= current:
			following += 720.0
		intervals.append(following - current)
	return intervals


func _generate_stereo_frame() -> Vector2:
	var sample_rate: float = float(maxi(mix_rate, 16000))
	var delta: float = 1.0 / sample_rate
	var idle_rpm: float = _get_idle_rpm()
	var rev_limit_rpm: float = _get_rev_limit_rpm()
	var rpm: float = clampf(_smoothed_rpm, 0.0, rev_limit_rpm * 1.08)
	var load: float = clampf(_smoothed_load, 0.0, 1.0)
	var throttle: float = clampf(_smoothed_throttle, 0.0, 1.0)
	var rpm_ratio: float = clampf(rpm / maxf(rev_limit_rpm, 1.0), 0.0, 1.08)
	var idle_blend: float = 1.0 - _smoothstep((rpm - idle_rpm) / 900.0)
	var mid_blend: float = _smoothstep((rpm_ratio - 0.18) / 0.48)
	var high_blend: float = _smoothstep((rpm_ratio - 0.58) / 0.38)

	_phase_idle_modulation = fposmod(_phase_idle_modulation + TAU * 6.1 * delta, TAU)
	_idle_noise = lerpf(_idle_noise, _rng.randf_range(-1.0, 1.0), 0.0022)
	var idle_speed_variation: float = (
		sin(_phase_idle_modulation) * 0.42
		+ _idle_noise * 0.58
	) * idle_irregularity * (1.0 + cam_loaf * 1.8) * idle_blend

	var firing_frequency: float = maxf(firing_frequency_hz(rpm, 8) * (1.0 + idle_speed_variation), 1.0)
	var crank_frequency: float = maxf(rpm / 60.0, 1.0)
	var previous_event_phase: float = _event_phase
	_event_phase = fposmod(_event_phase + firing_frequency * delta, 1.0)
	var event_started: bool = _event_phase < previous_event_phase
	if event_started:
		_event_index = (_event_index + 1) % FORD_FE_BANK_SEQUENCE.size()
		var event_bank: int = FORD_FE_BANK_SEQUENCE[_event_index]
		var impulse: float = EVENT_GAINS[_event_index] * (0.72 + load * 0.48)
		if event_bank == 0:
			_bank_a_thump += impulse
		else:
			_bank_b_thump += impulse
		if event_bank == _previous_bank:
			_doublet_envelope = maxf(_doublet_envelope, impulse)
		_previous_bank = event_bank

	_phase_crank = fposmod(_phase_crank + TAU * crank_frequency * delta, TAU)
	_phase_valvetrain = fposmod(_phase_valvetrain + TAU * crank_frequency * 4.0 * delta, TAU)
	_phase_cam_chain = fposmod(_phase_cam_chain + TAU * crank_frequency * 0.5 * delta, TAU)

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

	var startup_gate: float = 1.0
	var starter_motor: float = 0.0
	if _startup_remaining > 0.0:
		var startup_progress: float = 1.0 - clampf(
			_startup_remaining / maxf(starter_duration, 0.01),
			0.0,
			1.0
		)
		startup_gate = _smoothstep((startup_progress - 0.20) / 0.50)
		var starter_frequency: float = 82.0 + startup_progress * 78.0
		_starter_phase = fposmod(_starter_phase + TAU * starter_frequency * delta, TAU)
		starter_motor = (
			sin(_starter_phase) * 0.72
			+ sin(_starter_phase * 2.0) * 0.20
			+ _noise_medium * 0.12
		) * sin(startup_progress * PI) * starter_motor_level
		_startup_remaining = maxf(_startup_remaining - delta, 0.0)

	var shutdown_gate: float = 1.0
	if _shutdown_remaining > 0.0:
		var shutdown_progress: float = 1.0 - clampf(
			_shutdown_remaining / maxf(shutdown_duration, 0.01),
			0.0,
			1.0
		)
		shutdown_gate = 1.0 - _smoothstep(shutdown_progress)
		_shutdown_remaining = maxf(_shutdown_remaining - delta, 0.0)
		if _shutdown_remaining <= 0.0:
			_engine_running = false
	var running_gate: float = 1.0 if _engine_running or _shutdown_remaining > 0.0 else 0.0

	var event_bank: int = FORD_FE_BANK_SEQUENCE[_event_index]
	var cylinder_gain: float = EVENT_GAINS[_event_index]
	var pulse: float = combustion_pulse(_event_phase * TAU)
	pulse *= cylinder_gain * ignition_gate * startup_gate * shutdown_gate * running_gate
	var pulse_derivative: float = pulse - _previous_combustion
	var pulse_acceleration: float = pulse_derivative - _previous_pulse_derivative
	_previous_combustion = pulse
	_previous_pulse_derivative = pulse_derivative

	var white_noise: float = _rng.randf_range(-1.0, 1.0)
	_noise_slow = lerpf(_noise_slow, white_noise, 0.022)
	_noise_medium = lerpf(_noise_medium, white_noise, 0.12)
	_noise_fast = lerpf(_noise_fast, white_noise, 0.34)
	var highpassed_noise: float = white_noise - _noise_medium
	var differentiated_noise: float = white_noise - _previous_white_noise
	_previous_white_noise = white_noise

	_bank_a_thump *= exp(-delta * (25.0 + rpm_ratio * 24.0))
	_bank_b_thump *= exp(-delta * (25.0 + rpm_ratio * 24.0))
	_doublet_envelope *= exp(-delta * (31.0 + rpm_ratio * 30.0))
	var bank_a_gate: float = 1.0 if event_bank == 0 else 0.0
	var bank_b_gate: float = 1.0 - bank_a_gate
	var common_harmonics: float = (
		sin(_event_phase * TAU) * 0.16
		+ sin(_event_phase * TAU * 2.0) * 0.095
		+ sin(_event_phase * TAU * 3.0 + 0.18) * 0.052
	)
	var bank_a_input: float = pulse * bank_a_gate + _bank_a_thump * 0.17 + common_harmonics * 0.025
	var bank_b_input: float = pulse * bank_b_gate + _bank_b_thump * 0.17 + common_harmonics * 0.025

	var header_frequency: float = 78.0 + rpm_ratio * 112.0
	var header_a: float = _process_header_a(bank_a_input, header_frequency, 0.52, sample_rate)
	var header_b: float = _process_header_b(bank_b_input, header_frequency * 1.035, 0.54, sample_rate)
	var bank_sum: float = header_a + header_b
	var bank_difference: float = header_a - header_b

	var irregular_bank_energy: float = (
		(_bank_a_thump - _bank_b_thump) * 0.30
		+ bank_difference * 0.74
		+ _doublet_envelope * sin(_phase_crank * 2.0 + 0.35) * 0.22
	)
	var rumble_frequency: float = clampf(crank_frequency * 2.0, 34.0, 190.0)
	var rumble: float = _process_rumble(
		irregular_bank_energy + bank_sum * 0.21,
		rumble_frequency,
		0.46,
		sample_rate
	)

	var common_input: float = (
		bank_sum * (0.84 + load * 0.36)
		+ pulse * 0.28
		+ pulse_derivative * 0.22
		+ rumble * low_order_rumble * 0.42
	)
	var common_body: float = _process_common_body(
		common_input,
		112.0 + rpm_ratio * 102.0,
		0.50,
		sample_rate
	)
	var common_mid: float = _process_common_mid(
		common_input + pulse_derivative * 0.42 + pulse_acceleration * 0.08,
		365.0 + rpm_ratio * 610.0,
		0.62,
		sample_rate
	)

	var carb_input: float = (
		pulse * 0.23
		+ common_harmonics * 0.18
		+ _noise_slow * (0.10 + throttle * 0.30)
		+ highpassed_noise * throttle * 0.10
	)
	var carb_tone: float = _process_carb(
		carb_input,
		430.0 + rpm_ratio * 980.0 + throttle * 160.0,
		0.59,
		sample_rate
	)
	var induction_air: float = (
		highpassed_noise * 0.58
		+ differentiated_noise * 0.12
		+ _noise_slow * 0.30
	) * airflow_noise * throttle * (0.24 + load * 0.76) * (0.35 + mid_blend * 0.65)

	var metal_input: float = pulse_derivative * 0.34 + pulse_acceleration * 0.06 + highpassed_noise * 0.12
	var metal: float = _process_metal(
		metal_input,
		1180.0 + rpm_ratio * 1850.0,
		0.71,
		sample_rate
	)
	var valve_lobe: float = pow(maxf(sin(_phase_valvetrain), 0.0), 12.0) - 0.075
	var mechanical: float = valve_lobe * 0.22 + metal * (0.30 + high_blend * 0.40)
	var crackle: float = _next_overrun_crackle(delta, white_noise)

	var load_gain: float = lerpf(0.44 + idle_blend * 0.17, 1.10, load)
	var rpm_gain: float = 0.88 + mid_blend * 0.15 - high_blend * 0.05
	var common_exhaust: float = (
		common_body * (0.72 + exhaust_resonance * 1.12)
		+ common_mid * (0.15 + exhaust_roughness * 0.56)
		+ rumble * low_order_rumble * (0.48 + idle_blend * 0.32)
		+ common_harmonics * 0.055
	)
	var intake_mix: float = (
		carb_tone * (0.22 + throttle * 1.36 + _throttle_transient * induction_transient * 1.6)
		+ induction_air
	) * intake_presence
	var mechanical_mix: float = mechanical * mechanical_noise * (0.22 + high_blend * 0.86)
	var overrun_mix: float = crackle * overrun_crackle

	var crossover: float = clampf(exhaust_crossover, 0.0, 1.0)
	var width: float = clampf(bank_stereo_width, 0.0, 1.0)
	var bank_level: float = 0.42 + exhaust_bank_separation * 0.68
	var left_bank: float = (header_a + header_b * crossover) * bank_level
	var right_bank: float = (header_b + header_a * crossover) * bank_level
	var bank_mono: float = (left_bank + right_bank) * 0.5
	left_bank = lerpf(bank_mono, left_bank, width)
	right_bank = lerpf(bank_mono, right_bank, width)

	var common_mix: float = common_exhaust + intake_mix + mechanical_mix + overrun_mix
	var scale: float = load_gain * rpm_gain * 0.29
	var left_sample: float = (common_mix + left_bank * (0.50 + crossplane_roughness * 0.34)) * scale
	var right_sample: float = (common_mix + right_bank * (0.50 + crossplane_roughness * 0.34)) * scale
	left_sample += starter_motor * 0.36
	right_sample += starter_motor * 0.36

	var left_dc: float = left_sample - _dc_left_input + 0.996 * _dc_left_output
	_dc_left_input = left_sample
	_dc_left_output = left_dc
	var right_dc: float = right_sample - _dc_right_input + 0.996 * _dc_right_output
	_dc_right_input = right_sample
	_dc_right_output = right_dc
	var gain: float = db_to_linear(synthesis_gain_db)
	_last_stereo_frame = Vector2(
		tanh(left_dc * gain * 1.04) * 0.96,
		tanh(right_dc * gain * 1.04) * 0.96
	)
	return _last_stereo_frame


func _process_header_a(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_header_a_low += coefficient * _header_a_band
	var high: float = input_value - _header_a_low - damping * _header_a_band
	_header_a_band += coefficient * high
	return _header_a_band


func _process_header_b(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_header_b_low += coefficient * _header_b_band
	var high: float = input_value - _header_b_low - damping * _header_b_band
	_header_b_band += coefficient * high
	return _header_b_band


func _process_rumble(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_rumble_low += coefficient * _rumble_band
	var high: float = input_value - _rumble_low - damping * _rumble_band
	_rumble_band += coefficient * high
	return _rumble_band


func _process_common_body(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_common_body_low += coefficient * _common_body_band
	var high: float = input_value - _common_body_low - damping * _common_body_band
	_common_body_band += coefficient * high
	return _common_body_band


func _process_common_mid(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_common_mid_low += coefficient * _common_mid_band
	var high: float = input_value - _common_mid_low - damping * _common_mid_band
	_common_mid_band += coefficient * high
	return _common_mid_band


func _process_carb(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_carb_low += coefficient * _carb_band
	var high: float = input_value - _carb_low - damping * _carb_band
	_carb_band += coefficient * high
	return _carb_band


func _process_metal(input_value: float, frequency: float, damping: float, sample_rate: float) -> float:
	var coefficient: float = _svf_coefficient(frequency, sample_rate)
	_metal_low += coefficient * _metal_band
	var high: float = input_value - _metal_low - damping * _metal_band
	_metal_band += coefficient * high
	return _metal_band


func _update_debug_state() -> void:
	super._update_debug_state()
	_debug_state["mode"] = "Ford FE cross-plane V8 bank-resolved procedural model"
	_debug_state["firing_order"] = FORD_FE_FIRING_ORDER.duplicate()
	_debug_state["bank_sequence"] = FORD_FE_BANK_SEQUENCE.duplicate()
	_debug_state["event_index"] = _event_index
	_debug_state["event_bank"] = FORD_FE_BANK_SEQUENCE[_event_index]
	_debug_state["stereo_frame"] = _last_stereo_frame


func _reset_synthesis_state() -> void:
	super._reset_synthesis_state()
	_event_phase = 0.0
	_event_index = 0
	_previous_bank = 1
	_bank_a_thump = 0.0
	_bank_b_thump = 0.0
	_doublet_envelope = 0.0
	_header_a_low = 0.0
	_header_a_band = 0.0
	_header_b_low = 0.0
	_header_b_band = 0.0
	_rumble_low = 0.0
	_rumble_band = 0.0
	_common_body_low = 0.0
	_common_body_band = 0.0
	_common_mid_low = 0.0
	_common_mid_band = 0.0
	_carb_low = 0.0
	_carb_band = 0.0
	_metal_low = 0.0
	_metal_band = 0.0
	_dc_left_input = 0.0
	_dc_left_output = 0.0
	_dc_right_input = 0.0
	_dc_right_output = 0.0
	_last_stereo_frame = Vector2.ZERO
