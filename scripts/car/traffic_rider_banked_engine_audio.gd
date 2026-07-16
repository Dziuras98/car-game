extends ProceduralAudioPlayer3D
class_name TrafficRiderBankedEngineAudioSynthesizer

const REFERENCE_SAMPLE_RATE: float = 32000.0
const MIN_MIX_RATE: int = 16000
const MAX_MIX_RATE: int = 48000

@export var profile: TrafficRiderBankedEngineAudioProfile
@export_range(MIN_MIX_RATE, MAX_MIX_RATE, 1000) var mix_rate: int = 32000
@export_range(0.08, 0.30, 0.01) var generator_buffer_length_s: float = 0.15
@export var force_full_runtime_generation: bool = false

@export_group("Debug")
@export var debug_override_enabled: bool = false
@export var debug_rpm: float = 650.0
@export_range(0.0, 1.0, 0.01) var debug_load: float = 0.0
@export_range(0.0, 1.0, 0.01) var debug_throttle: float = 0.0

var _car: PlayerCarController
var _playback: AudioStreamGeneratorPlayback
var _rng := RandomNumberGenerator.new()
var _rpm: float = 0.0
var _load: float = 0.0
var _throttle: float = 0.0
var _target_rpm: float = 0.0
var _target_load: float = 0.0
var _target_throttle: float = 0.0
var _event_phase: float = 0.0
var _event_index: int = 0
var _crank_phase: float = 0.0
var _cam_phase: float = 0.0
var _injector_phase: float = 0.0
var _limiter_phase: float = 0.0
var _bank_impulse := PackedFloat32Array([0.0, 0.0])
var _collector_impulse := PackedFloat32Array([0.0, 0.0])
var _bank_low := PackedFloat32Array([0.0, 0.0])
var _intake_low: float = 0.0
var _mechanical_low: float = 0.0
var _noise_low: float = 0.0
var _previous_noise: float = 0.0
var _deactivation_blend: float = 0.0
var _previous_deactivation_blend: float = 0.0
var _afm_transition_envelope: float = 0.0
var _debug_state: Dictionary = {}


func _ready() -> void:
	_car = get_parent() as PlayerCarController
	_rng.seed = int(get_instance_id()) ^ 0xB4A9E0
	procedural_voice_group = &"engine"
	procedural_voice_cost = 2
	max_procedural_voices = mini(max_procedural_voices, 8)
	if profile == null or not profile.validate().is_empty():
		push_error("TrafficRiderBankedEngineAudioSynthesizer requires a valid physical profile.")
		set_process(false)
		return
	_rpm = profile.idle_rpm
	_target_rpm = profile.idle_rpm
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = clampi(mix_rate, MIN_MIX_RATE, MAX_MIX_RATE)
	generator.buffer_length = clampf(generator_buffer_length_s, 0.08, 0.30)
	stream = generator
	unit_size = 6.0
	max_distance = 80.0
	procedural_generation_distance = max_distance + 5.0
	volume_db = 0.0
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback
	if DisplayServer.get_name() == "headless":
		set_process(false)


func _process(delta: float) -> void:
	if profile == null: return
	if debug_override_enabled:
		_set_target(debug_rpm, debug_load, debug_throttle)
	elif _car != null:
		_set_target(_car.get_engine_rpm(), _car.get_engine_load(), _car.get_throttle_input())
	var safe_delta: float = maxf(delta, 0.0)
	var alpha: float = 1.0 - exp(-14.0 * safe_delta)
	_rpm = lerpf(_rpm, _target_rpm, alpha)
	_load = lerpf(_load, _target_load, alpha)
	_throttle = lerpf(_throttle, _target_throttle, alpha)
	if force_full_runtime_generation or should_generate_procedural_audio(safe_delta):
		_fill_buffer()
	_update_debug_state()


func _exit_tree() -> void:
	release_procedural_voice()
	stop()
	_playback = null
	stream = null


func generate_test_frames(frame_count: int, rpm: float, load: float, throttle: float) -> PackedFloat32Array:
	_reset_state()
	_rng.seed = 0xB4A9E0
	_set_target(rpm, load, throttle)
	_rpm = _target_rpm
	_load = _target_load
	_throttle = _target_throttle
	var frames := PackedFloat32Array()
	frames.resize(maxi(frame_count, 0))
	for index: int in frames.size():
		frames[index] = _generate_sample()
	_update_debug_state()
	return frames


func get_firing_order() -> PackedInt32Array:
	return profile.firing_order.duplicate() if profile != null else PackedInt32Array()


func get_deactivation_blend() -> float:
	return _deactivation_blend


func get_debug_state() -> Dictionary:
	return _debug_state.duplicate(true)


func _set_target(rpm: float, load: float, throttle: float) -> void:
	if profile == null: return
	_target_rpm = clampf(rpm, 0.0, profile.redline_rpm * 1.08)
	_target_load = clampf(load, 0.0, 1.0)
	_target_throttle = clampf(throttle, 0.0, 1.0)


func _fill_buffer() -> void:
	if _playback == null: return
	for _index: int in _playback.get_frames_available():
		var sample: float = _generate_sample()
		_playback.push_frame(Vector2(sample, sample))


func _generate_sample() -> float:
	if profile == null: return 0.0
	var sample_rate: float = float(clampi(mix_rate, MIN_MIX_RATE, MAX_MIX_RATE))
	var delta: float = 1.0 / sample_rate
	var rpm_ratio: float = clampf(_rpm / maxf(profile.redline_rpm, 1.0), 0.0, 1.08)
	var crank_hz: float = maxf(_rpm / 60.0, 0.0)
	var event_hz: float = profile.get_event_frequency_hz(_rpm)
	_update_deactivation(delta)

	var previous_phase: float = _event_phase
	_event_phase = fposmod(_event_phase + event_hz * delta, 1.0)
	if _event_phase < previous_phase:
		_event_index = (_event_index + 1) % maxi(profile.firing_order.size(), 1)
		var cylinder: int = profile.firing_order[_event_index]
		var bank: int = profile.get_bank_for_cylinder(cylinder)
		var collector: int = profile.get_collector_for_cylinder(cylinder)
		var inactive_fraction: float = _deactivation_blend if profile.is_cylinder_deactivated(cylinder) else 0.0
		var combustion_energy: float = (0.55 + _load * 0.75) * (1.0 - inactive_fraction)
		_bank_impulse[bank] += combustion_energy
		_collector_impulse[collector] += combustion_energy
		if inactive_fraction > 0.0:
			_bank_impulse[bank] += inactive_fraction * 0.06

	_crank_phase = fposmod(_crank_phase + TAU * crank_hz * delta, TAU)
	_cam_phase = fposmod(_cam_phase + TAU * crank_hz * 0.5 * delta, TAU)
	_injector_phase = fposmod(_injector_phase + TAU * event_hz * delta, TAU)

	var limiter_active: bool = _rpm >= profile.redline_rpm * 0.985 and _throttle > 0.65
	_limiter_phase = fposmod(_limiter_phase + delta / maxf(profile.limiter_period_s, 0.01), 1.0) if limiter_active else 0.0
	var limiter_gate: float = profile.limiter_residual_combustion if limiter_active and _limiter_phase < profile.limiter_cut_fraction else 1.0
	var pulse_base: float = maxf(sin(_event_phase * PI), 0.0)
	var combustion_pulse: float = pow(pulse_base, lerpf(1.8, 8.0, profile.combustion_sharpness))
	combustion_pulse *= limiter_gate * (0.42 + _load * 0.78) * profile.combustion_level

	var white_noise: float = _rng.randf_range(-1.0, 1.0)
	_noise_low = lerpf(_noise_low, white_noise, _sample_rate_alpha(0.025, sample_rate))
	var high_noise: float = white_noise - _noise_low
	var derivative: float = white_noise - _previous_noise
	_previous_noise = white_noise

	for bank: int in 2:
		_bank_impulse[bank] *= exp(-delta * (25.0 + rpm_ratio * 29.0))
		_collector_impulse[bank] *= exp(-delta * (28.0 + rpm_ratio * 32.0))
		var bank_input: float = combustion_pulse + _bank_impulse[bank] * 0.22 + _collector_impulse[bank] * 0.16
		_bank_low[bank] = lerpf(_bank_low[bank], bank_input, _filter_alpha(profile.exhaust_resonance_hz * (0.76 + 0.06 * bank + rpm_ratio * 0.48), sample_rate))
	var exhaust_a: float = _bank_low[0] + (combustion_pulse - _bank_low[0]) * 0.32
	var exhaust_b: float = _bank_low[1] + (combustion_pulse - _bank_low[1]) * 0.32
	var exhaust: float = lerpf((exhaust_a + exhaust_b) * 0.5, exhaust_a * 0.57 + exhaust_b * 0.43, profile.bank_separation)

	var intake_input: float = combustion_pulse * (0.30 + _throttle * 0.46) + high_noise * _throttle * 0.14
	_intake_low = lerpf(_intake_low, intake_input, _filter_alpha(profile.intake_resonance_hz * (0.76 + rpm_ratio * 0.75), sample_rate))
	var intake: float = intake_input - _intake_low * 0.50
	var cam_order: float = float(profile.cylinder_count) * 0.5
	var valvetrain_input: float = sin(_cam_phase * cam_order) * 0.55 + sin(_cam_phase * cam_order * 2.0 + 0.27) * 0.20 + derivative * 0.12
	_mechanical_low = lerpf(_mechanical_low, valvetrain_input, _filter_alpha(170.0 + crank_hz * cam_order, sample_rate))
	var valvetrain: float = valvetrain_input - _mechanical_low * 0.38
	var injector: float = high_noise * sin(_injector_phase) * profile.injector_level
	var cross_plane_order: float = 2.0 if profile.crank_architecture == TrafficRiderBankedEngineAudioProfile.CrankArchitecture.CROSS_PLANE_V8 else 3.0
	var crank: float = (sin(_crank_phase * cross_plane_order) * 0.56 + sin(_crank_phase * 0.5 + 0.4) * 0.22) * profile.crank_level
	_afm_transition_envelope *= exp(-delta * 7.0)
	var transition: float = derivative * profile.afm_transition_level * _afm_transition_envelope

	var total: float = (
		combustion_pulse * 0.34
		+ exhaust * profile.exhaust_level
		+ intake * profile.intake_level
		+ valvetrain * profile.valvetrain_level
		+ injector
		+ crank
		+ transition
	)
	total *= profile.synthesis_gain
	if not is_finite(total): return 0.0
	var limit: float = clampf(profile.peak_limit, 0.01, 0.99)
	return tanh(total / limit) * limit


func _update_deactivation(delta: float) -> void:
	if not profile.cylinder_deactivation_enabled:
		_deactivation_blend = move_toward(_deactivation_blend, 0.0, profile.deactivation_transition_rate_per_s * delta)
		return
	var rpm_in_range: bool = _rpm >= profile.deactivation_min_rpm and _rpm <= profile.deactivation_max_rpm
	var target: float = _deactivation_blend
	if not rpm_in_range or _load >= profile.deactivation_exit_load or _throttle >= profile.deactivation_exit_load:
		target = 0.0
	elif _load <= profile.deactivation_enter_load and _throttle <= profile.deactivation_enter_load:
		target = 1.0
	_previous_deactivation_blend = _deactivation_blend
	_deactivation_blend = move_toward(_deactivation_blend, target, profile.deactivation_transition_rate_per_s * delta)
	var transition_speed: float = absf(_deactivation_blend - _previous_deactivation_blend) / maxf(delta, 0.000001)
	if transition_speed > 0.01:
		_afm_transition_envelope = maxf(_afm_transition_envelope, clampf(transition_speed / profile.deactivation_transition_rate_per_s, 0.0, 1.0))


func _filter_alpha(frequency_hz: float, sample_rate: float) -> float:
	return clampf(TAU * maxf(frequency_hz, 1.0) / maxf(sample_rate, 1.0), 0.0001, 0.95)


func _sample_rate_alpha(alpha_at_32k: float, sample_rate: float) -> float:
	return 1.0 - pow(1.0 - clampf(alpha_at_32k, 0.0, 1.0), REFERENCE_SAMPLE_RATE / maxf(sample_rate, 1.0))


func _reset_state() -> void:
	_event_phase = 0.0
	_event_index = 0
	_crank_phase = 0.0
	_cam_phase = 0.0
	_injector_phase = 0.0
	_limiter_phase = 0.0
	_bank_impulse = PackedFloat32Array([0.0, 0.0])
	_collector_impulse = PackedFloat32Array([0.0, 0.0])
	_bank_low = PackedFloat32Array([0.0, 0.0])
	_intake_low = 0.0
	_mechanical_low = 0.0
	_noise_low = 0.0
	_previous_noise = 0.0
	_deactivation_blend = 0.0
	_previous_deactivation_blend = 0.0
	_afm_transition_envelope = 0.0


func _update_debug_state() -> void:
	_debug_state = {
		"engine_family_id": str(profile.engine_family_id) if profile != null else "",
		"cylinder_count": profile.cylinder_count if profile != null else 0,
		"bank_angle_degrees": profile.bank_angle_degrees if profile != null else 0.0,
		"crank_architecture": profile.crank_architecture if profile != null else -1,
		"deactivation_blend": _deactivation_blend,
	}
