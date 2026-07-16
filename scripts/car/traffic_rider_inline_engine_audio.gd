extends ProceduralAudioPlayer3D
class_name TrafficRiderInlineEngineAudioSynthesizer

const REFERENCE_SAMPLE_RATE: float = 32000.0
const MIN_MIX_RATE: int = 16000
const MAX_MIX_RATE: int = 48000

@export var profile: TrafficRiderInlineEngineAudioProfile
@export_range(MIN_MIX_RATE, MAX_MIX_RATE, 1000) var mix_rate: int = 32000
@export_range(0.08, 0.30, 0.01) var generator_buffer_length_s: float = 0.15
@export_range(1.0, 40.0, 0.5) var rpm_smoothing_per_s: float = 14.0
@export_range(1.0, 40.0, 0.5) var load_smoothing_per_s: float = 16.0
@export var force_full_runtime_generation: bool = false

@export_group("Debug")
@export var debug_override_enabled: bool = false
@export var debug_rpm: float = 800.0
@export_range(0.0, 1.0, 0.01) var debug_load: float = 0.0
@export_range(0.0, 1.0, 0.01) var debug_throttle: float = 0.0

var _car: PlayerCarController
var _playback: AudioStreamGeneratorPlayback
var _rng := RandomNumberGenerator.new()
var _smoothed_rpm: float = 0.0
var _smoothed_load: float = 0.0
var _smoothed_throttle: float = 0.0
var _target_rpm: float = 0.0
var _target_load: float = 0.0
var _target_throttle: float = 0.0
var _previous_target_throttle: float = 0.0

var _event_phase: float = 0.0
var _event_index: int = 0
var _crank_phase: float = 0.0
var _mechanical_phase: float = 0.0
var _turbo_phase: float = 0.0
var _second_turbo_phase: float = 0.0
var _limiter_phase: float = 0.0
var _limiter_active: bool = false
var _turbo_spool: float = 0.0
var _second_stage_spool: float = 0.0
var _release_envelope: float = 0.0
var _wastegate_envelope: float = 0.0
var _collector_a_impulse: float = 0.0
var _collector_b_impulse: float = 0.0
var _intake_low: float = 0.0
var _exhaust_a_low: float = 0.0
var _exhaust_b_low: float = 0.0
var _mechanical_low: float = 0.0
var _noise_low: float = 0.0
var _previous_noise: float = 0.0
var _engine_running: bool = true
var _engine_state_gain: float = 1.0
var _startup_progress: float = 1.0
var _shutdown_progress: float = 0.0
var _debug_state: Dictionary = {}


func _ready() -> void:
	_car = get_parent() as PlayerCarController
	_rng.seed = int(get_instance_id()) ^ 0x71A11E
	procedural_voice_group = &"engine"
	procedural_voice_cost = 2
	max_procedural_voices = mini(max_procedural_voices, 8)
	if profile == null or not profile.validate().is_empty():
		push_error("TrafficRiderInlineEngineAudioSynthesizer requires a valid architecture profile.")
		set_process(false)
		return
	_smoothed_rpm = profile.idle_rpm
	_target_rpm = profile.idle_rpm
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = clampi(mix_rate, MIN_MIX_RATE, MAX_MIX_RATE)
	generator.buffer_length = clampf(generator_buffer_length_s, 0.08, 0.30)
	stream = generator
	unit_size = 6.0
	max_distance = 70.0
	procedural_generation_distance = max_distance + 5.0
	volume_db = 0.0
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback
	if DisplayServer.get_name() == "headless":
		set_process(false)


func _process(delta: float) -> void:
	if profile == null:
		return
	var safe_delta: float = maxf(delta, 0.0)
	if debug_override_enabled:
		_set_target_operating_point(debug_rpm, debug_load, debug_throttle)
	elif _car != null:
		_set_target_operating_point(
			_car.get_engine_rpm(),
			_car.get_engine_load(),
			_car.get_throttle_input()
		)
	_update_smoothed_operating_point(safe_delta)
	_update_engine_state(safe_delta)
	if force_full_runtime_generation or should_generate_procedural_audio(safe_delta):
		_fill_audio_buffer()
	_update_debug_state()


func _exit_tree() -> void:
	release_procedural_voice()
	stop()
	_playback = null
	stream = null


func generate_test_frames(
	frame_count: int,
	rpm: float,
	load: float,
	throttle: float
) -> PackedFloat32Array:
	_reset_synthesis_state()
	_rng.seed = 0x71A11E
	_engine_running = true
	_engine_state_gain = 1.0
	_startup_progress = 1.0
	_set_test_operating_point(rpm, load, throttle)
	return _generate_frames(frame_count)


func generate_stateful_test_frames(
	frame_count: int,
	rpm: float,
	load: float,
	throttle: float
) -> PackedFloat32Array:
	_set_test_operating_point(rpm, load, throttle)
	return _generate_frames(frame_count)


func trigger_engine_start() -> void:
	_engine_running = true
	_engine_state_gain = 0.0
	_startup_progress = 0.0
	_shutdown_progress = 0.0


func trigger_engine_shutdown() -> void:
	_shutdown_progress = 0.0001


func get_firing_frequency_hz(rpm: float) -> float:
	return profile.get_event_frequency_hz(rpm) if profile != null else 0.0


func get_firing_order() -> PackedInt32Array:
	return profile.firing_order.duplicate() if profile != null else PackedInt32Array()


func get_turbo_spool() -> float:
	return _turbo_spool


func get_release_envelope() -> float:
	return _release_envelope


func get_debug_state() -> Dictionary:
	return _debug_state.duplicate(true)


func _fill_audio_buffer() -> void:
	if _playback == null:
		return
	var frames_available: int = _playback.get_frames_available()
	for _frame_index: int in frames_available:
		var sample: float = _generate_sample()
		_playback.push_frame(Vector2(sample, sample))


func _generate_frames(frame_count: int) -> PackedFloat32Array:
	var frames := PackedFloat32Array()
	frames.resize(maxi(frame_count, 0))
	for index: int in frames.size():
		frames[index] = _generate_sample()
	_update_debug_state()
	return frames


func _set_test_operating_point(rpm: float, load: float, throttle: float) -> void:
	_set_target_operating_point(rpm, load, throttle)
	_smoothed_rpm = _target_rpm
	_smoothed_load = _target_load
	_smoothed_throttle = _target_throttle


func _set_target_operating_point(rpm: float, load: float, throttle: float) -> void:
	if profile == null:
		return
	_target_rpm = clampf(rpm, 0.0, profile.redline_rpm * 1.08)
	_target_load = clampf(load, 0.0, 1.0)
	_target_throttle = clampf(throttle, 0.0, 1.0)
	var real_pedal_drop: float = _previous_target_throttle - _target_throttle
	if real_pedal_drop > 0.18 and _turbo_spool > 0.18:
		_release_envelope = maxf(
			_release_envelope,
			real_pedal_drop * _turbo_spool
		)
	_previous_target_throttle = _target_throttle


func _update_smoothed_operating_point(delta: float) -> void:
	var rpm_alpha: float = 1.0 - exp(-maxf(rpm_smoothing_per_s, 0.01) * delta)
	var load_alpha: float = 1.0 - exp(-maxf(load_smoothing_per_s, 0.01) * delta)
	_smoothed_rpm = lerpf(_smoothed_rpm, _target_rpm, rpm_alpha)
	_smoothed_load = lerpf(_smoothed_load, _target_load, load_alpha)
	_smoothed_throttle = lerpf(_smoothed_throttle, _target_throttle, load_alpha)


func _update_engine_state(delta: float) -> void:
	if _shutdown_progress > 0.0:
		_shutdown_progress = minf(_shutdown_progress + delta / 0.8, 1.0)
		_engine_state_gain = 1.0 - _smoothstep(_shutdown_progress)
		if _shutdown_progress >= 1.0:
			_engine_running = false
			_engine_state_gain = 0.0
	elif _engine_running and _startup_progress < 1.0:
		_startup_progress = minf(_startup_progress + delta / 0.65, 1.0)
		_engine_state_gain = _smoothstep(_startup_progress)


func _generate_sample() -> float:
	if profile == null:
		return 0.0
	var sample_rate: float = float(clampi(mix_rate, MIN_MIX_RATE, MAX_MIX_RATE))
	var delta: float = 1.0 / sample_rate
	var rpm: float = _smoothed_rpm if _engine_running else 0.0
	var load: float = clampf(_smoothed_load, 0.0, 1.0)
	var throttle: float = clampf(_smoothed_throttle, 0.0, 1.0)
	var rpm_ratio: float = clampf(rpm / maxf(profile.redline_rpm, 1.0), 0.0, 1.08)
	var crank_frequency: float = maxf(rpm / 60.0, 0.0)
	var firing_frequency: float = profile.get_event_frequency_hz(rpm)

	var idle_variation: float = sin(_crank_phase * 0.47) * profile.idle_irregularity
	firing_frequency *= 1.0 + idle_variation * (1.0 - clampf(rpm_ratio * 4.0, 0.0, 1.0))
	var previous_event_phase: float = _event_phase
	_event_phase = fposmod(_event_phase + firing_frequency * delta, 1.0)
	if _event_phase < previous_event_phase:
		_event_index = (_event_index + 1) % maxi(profile.firing_order.size(), 1)
		var cylinder_number: int = profile.firing_order[_event_index]
		var collector_index: int = profile.collector_group_by_cylinder[cylinder_number - 1]
		var event_energy: float = 0.55 + load * 0.72
		if collector_index == 0:
			_collector_a_impulse += event_energy
		else:
			_collector_b_impulse += event_energy

	_crank_phase = fposmod(_crank_phase + TAU * crank_frequency * delta, TAU)
	_mechanical_phase = fposmod(
		_mechanical_phase + TAU * crank_frequency * profile.mechanical_order * delta,
		TAU
	)

	_limiter_active = rpm >= profile.redline_rpm * 0.985 and throttle > 0.65
	_limiter_phase = (
		fposmod(_limiter_phase + delta / maxf(profile.limiter_period_s, 0.01), 1.0)
		if _limiter_active
		else 0.0
	)
	var limiter_gate: float = 1.0
	if _limiter_active and _limiter_phase < profile.limiter_cut_fraction:
		limiter_gate = profile.limiter_residual_combustion

	var pulse_exponent: float = lerpf(1.8, 8.0, profile.combustion_sharpness)
	var pulse_base: float = maxf(sin(_event_phase * PI), 0.0)
	var combustion_pulse: float = pow(pulse_base, pulse_exponent)
	combustion_pulse *= limiter_gate * (0.45 + load * 0.75) * profile.combustion_level

	var white_noise: float = _rng.randf_range(-1.0, 1.0)
	_noise_low = lerpf(_noise_low, white_noise, _sample_rate_alpha(0.025, sample_rate))
	var high_noise: float = white_noise - _noise_low
	var noise_derivative: float = white_noise - _previous_noise
	_previous_noise = white_noise

	_collector_a_impulse *= exp(-delta * (28.0 + rpm_ratio * 32.0))
	_collector_b_impulse *= exp(-delta * (28.0 + rpm_ratio * 32.0))
	var collector_a: float = _process_exhaust_a(
		combustion_pulse + _collector_a_impulse * 0.22,
		profile.exhaust_resonance_hz * (0.72 + rpm_ratio * 0.55),
		sample_rate
	)
	var collector_b: float = _process_exhaust_b(
		combustion_pulse + _collector_b_impulse * 0.22,
		profile.exhaust_resonance_hz * (0.77 + rpm_ratio * 0.58),
		sample_rate
	)
	var collector_mix: float = lerpf(
		(collector_a + collector_b) * 0.5,
		collector_a * 0.58 + collector_b * 0.42,
		profile.collector_separation
	)

	var intake_input: float = (
		combustion_pulse * (0.32 + throttle * 0.42)
		+ high_noise * throttle * 0.18
	)
	var intake: float = _process_intake(
		intake_input,
		profile.intake_resonance_hz * (0.75 + rpm_ratio * 0.80),
		sample_rate
	)
	var mechanical_input: float = (
		sin(_mechanical_phase) * 0.55
		+ sin(_mechanical_phase * 2.0 + 0.21) * 0.20
		+ noise_derivative * 0.16
	)
	var mechanical: float = _process_mechanical(
		mechanical_input,
		180.0 + crank_frequency * profile.mechanical_order,
		sample_rate
	)

	var diesel_clatter: float = 0.0
	if profile.is_diesel():
		diesel_clatter = (
			combustion_pulse * high_noise * 0.55
			+ noise_derivative * (0.12 + load * 0.25)
		) * profile.diesel_clatter_level
	var injector: float = high_noise * sin(_mechanical_phase * 1.7) * profile.injector_level

	_update_turbo_state(rpm_ratio, load, throttle, delta)
	var turbo_layers: float = _generate_turbo_layers(sample_rate, rpm_ratio, load)
	_release_envelope *= exp(-delta * 8.0)
	_wastegate_envelope *= exp(-delta * 13.0)

	var total: float = (
		combustion_pulse * 0.42
		+ collector_mix * profile.exhaust_level
		+ intake * profile.intake_level
		+ mechanical * profile.mechanical_level
		+ diesel_clatter
		+ injector
		+ turbo_layers
	)
	total *= profile.synthesis_gain * _engine_state_gain
	if not is_finite(total):
		return 0.0
	var limit: float = clampf(profile.peak_limit, 0.01, 0.99)
	return tanh(total / limit) * limit


func _update_turbo_state(
	rpm_ratio: float,
	load: float,
	throttle: float,
	delta: float
) -> void:
	if not profile.is_turbocharged():
		_turbo_spool = move_toward(_turbo_spool, 0.0, delta * 4.0)
		_second_stage_spool = move_toward(_second_stage_spool, 0.0, delta * 4.0)
		return
	var exhaust_energy: float = clampf(load * 0.72 + throttle * 0.20 + rpm_ratio * load * 0.32, 0.0, 1.0)
	if profile.aspiration_type == TrafficRiderInlineEngineAudioProfile.AspirationType.VARIABLE_GEOMETRY_TURBO:
		exhaust_energy = clampf(exhaust_energy + (1.0 - rpm_ratio) * load * 0.22, 0.0, 1.0)
	var rate: float = profile.turbo_spool_rate_per_s if exhaust_energy > _turbo_spool else profile.turbo_release_rate_per_s
	_turbo_spool = move_toward(_turbo_spool, exhaust_energy, maxf(rate, 0.01) * delta)
	if profile.aspiration_type == TrafficRiderInlineEngineAudioProfile.AspirationType.SEQUENTIAL_TWIN_TURBO:
		var second_target: float = clampf(
			(_turbo_spool - profile.second_stage_threshold)
			/ maxf(1.0 - profile.second_stage_threshold, 0.01),
			0.0,
			1.0
		)
		_second_stage_spool = move_toward(
			_second_stage_spool,
			second_target,
			profile.turbo_spool_rate_per_s * 0.65 * delta
		)
	else:
		_second_stage_spool = 0.0
	if _turbo_spool > 0.82 and throttle > 0.78:
		_wastegate_envelope = maxf(_wastegate_envelope, (_turbo_spool - 0.82) / 0.18)


func _generate_turbo_layers(sample_rate: float, rpm_ratio: float, load: float) -> float:
	if not profile.is_turbocharged():
		return 0.0
	var compressor_hz: float = (
		profile.turbo_whine_base_hz
		+ profile.turbo_whine_range_hz * _turbo_spool
	)
	_turbo_phase = fposmod(_turbo_phase + TAU * compressor_hz / sample_rate, TAU)
	_second_turbo_phase = fposmod(
		_second_turbo_phase + TAU * compressor_hz * 1.17 / sample_rate,
		TAU
	)
	var compressor: float = sin(_turbo_phase) * profile.turbo_whine_level * _turbo_spool
	var turbine: float = (
		sin(_turbo_phase * 0.47 + 0.31) * 0.45
		+ (_rng.randf() * 2.0 - 1.0) * 0.18
	) * profile.turbine_level * _turbo_spool * (0.35 + load * 0.65)
	var second_stage: float = (
		sin(_second_turbo_phase) * profile.second_stage_level * _second_stage_spool
	)
	var wastegate: float = (
		(_rng.randf() * 2.0 - 1.0)
		* profile.wastegate_level
		* _wastegate_envelope
		* (0.35 + rpm_ratio * 0.65)
	)
	var release: float = (
		(_rng.randf() * 2.0 - 1.0)
		* profile.release_level
		* _release_envelope
	)
	return compressor + turbine + second_stage + wastegate + release


func _process_intake(input: float, frequency_hz: float, sample_rate: float) -> float:
	var alpha: float = _filter_alpha(frequency_hz, sample_rate)
	_intake_low = lerpf(_intake_low, input, alpha)
	return input - _intake_low * 0.55


func _process_exhaust_a(input: float, frequency_hz: float, sample_rate: float) -> float:
	_exhaust_a_low = lerpf(_exhaust_a_low, input, _filter_alpha(frequency_hz, sample_rate))
	return _exhaust_a_low + (input - _exhaust_a_low) * 0.35


func _process_exhaust_b(input: float, frequency_hz: float, sample_rate: float) -> float:
	_exhaust_b_low = lerpf(_exhaust_b_low, input, _filter_alpha(frequency_hz, sample_rate))
	return _exhaust_b_low + (input - _exhaust_b_low) * 0.35


func _process_mechanical(input: float, frequency_hz: float, sample_rate: float) -> float:
	_mechanical_low = lerpf(_mechanical_low, input, _filter_alpha(frequency_hz, sample_rate))
	return input - _mechanical_low * 0.40


func _filter_alpha(frequency_hz: float, sample_rate: float) -> float:
	return clampf(TAU * maxf(frequency_hz, 1.0) / maxf(sample_rate, 1.0), 0.0001, 0.95)


func _sample_rate_alpha(alpha_at_32k: float, sample_rate: float) -> float:
	var safe_alpha: float = clampf(alpha_at_32k, 0.0, 1.0)
	return 1.0 - pow(1.0 - safe_alpha, REFERENCE_SAMPLE_RATE / maxf(sample_rate, 1.0))


func _smoothstep(value: float) -> float:
	var x: float = clampf(value, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _reset_synthesis_state() -> void:
	_event_phase = 0.0
	_event_index = 0
	_crank_phase = 0.0
	_mechanical_phase = 0.0
	_turbo_phase = 0.0
	_second_turbo_phase = 0.0
	_limiter_phase = 0.0
	_limiter_active = false
	_turbo_spool = 0.0
	_second_stage_spool = 0.0
	_release_envelope = 0.0
	_wastegate_envelope = 0.0
	_collector_a_impulse = 0.0
	_collector_b_impulse = 0.0
	_intake_low = 0.0
	_exhaust_a_low = 0.0
	_exhaust_b_low = 0.0
	_mechanical_low = 0.0
	_noise_low = 0.0
	_previous_noise = 0.0
	_previous_target_throttle = 0.0
	_shutdown_progress = 0.0


func _update_debug_state() -> void:
	_debug_state = {
		"engine_family_id": str(profile.engine_family_id) if profile != null else "",
		"cylinder_count": profile.cylinder_count if profile != null else 0,
		"firing_frequency_hz": get_firing_frequency_hz(_smoothed_rpm),
		"limiter_active": _limiter_active,
		"turbo_spool": _turbo_spool,
		"second_stage_spool": _second_stage_spool,
		"release_envelope": _release_envelope,
		"engine_state_gain": _engine_state_gain,
	}
