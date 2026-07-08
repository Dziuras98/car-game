extends AudioStreamPlayer3D

@export var cylinders: int = 6
@export var mix_rate: int = 22050
@export var idle_volume_db: float = -23.0
@export var load_volume_db: float = -7.0
@export var rpm_smoothing: float = 12.0
@export var throttle_smoothing: float = 18.0
@export var exhaust_roughness: float = 0.09
@export var intake_presence: float = 0.18
@export var exhaust_resonance: float = 0.32
@export var mechanical_noise: float = 0.08
@export var overrun_crackle: float = 0.16

var _car: PlayerCarController
var _playback: AudioStreamGeneratorPlayback
var _smoothed_rpm: float = 900.0
var _smoothed_load: float = 0.0
var _smoothed_throttle: float = 0.0
var _previous_throttle: float = 0.0
var _overrun_amount: float = 0.0
var _crackle_timer: float = 0.0
var _phase_primary: float = 0.0
var _phase_crank: float = 0.0
var _phase_secondary: float = 0.0
var _phase_intake: float = 0.0
var _phase_exhaust: float = 0.0
var _phase_valvetrain: float = 0.0
var _noise_state: float = 0.0
var _rasp_noise_state: float = 0.0
var _crackle_state: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_car = get_parent() as PlayerCarController
	_rng.randomize()

	var generator: AudioStreamGenerator = AudioStreamGenerator.new()
	generator.mix_rate = mix_rate
	generator.buffer_length = 0.08
	stream = generator
	unit_size = 6.0
	max_distance = 70.0
	volume_db = idle_volume_db
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func _process(delta: float) -> void:
	if _car == null:
		return

	_smoothed_rpm = lerpf(_smoothed_rpm, _car.get_engine_rpm(), 1.0 - exp(-rpm_smoothing * delta))
	_smoothed_load = lerpf(_smoothed_load, _car.get_engine_load(), 1.0 - exp(-throttle_smoothing * delta))
	_smoothed_throttle = lerpf(_smoothed_throttle, _car.get_throttle_input(), 1.0 - exp(-throttle_smoothing * delta))
	_update_overrun(delta)
	volume_db = lerpf(idle_volume_db, load_volume_db, clampf(_smoothed_load + _overrun_amount * 0.22, 0.0, 1.0))
	_fill_audio_buffer()


func _exit_tree() -> void:
	stop()
	_playback = null
	stream = null


func _fill_audio_buffer() -> void:
	if _playback == null:
		return

	var frames_available: int = _playback.get_frames_available()
	for frame_index in frames_available:
		var sample: float = _generate_sample()
		_playback.push_frame(Vector2(sample, sample))


func _generate_sample() -> float:
	var delta: float = 1.0 / float(mix_rate)
	var firing_frequency: float = maxf(_smoothed_rpm / 60.0 * float(cylinders) * 0.5, 1.0)
	var crank_frequency: float = maxf(_smoothed_rpm / 60.0, 1.0)
	var secondary_frequency: float = firing_frequency * 2.0
	var intake_frequency: float = crank_frequency * 3.0
	var exhaust_frequency: float = firing_frequency * 0.5
	var valvetrain_frequency: float = crank_frequency * 6.0

	_phase_primary = fmod(_phase_primary + TAU * firing_frequency * delta, TAU)
	_phase_crank = fmod(_phase_crank + TAU * crank_frequency * delta, TAU)
	_phase_secondary = fmod(_phase_secondary + TAU * secondary_frequency * delta, TAU)
	_phase_intake = fmod(_phase_intake + TAU * intake_frequency * delta, TAU)
	_phase_exhaust = fmod(_phase_exhaust + TAU * exhaust_frequency * delta, TAU)
	_phase_valvetrain = fmod(_phase_valvetrain + TAU * valvetrain_frequency * delta, TAU)

	var rpm_ratio: float = clampf(_smoothed_rpm / 7000.0, 0.0, 1.15)
	var load: float = clampf(_smoothed_load, 0.0, 1.0)
	var throttle: float = clampf(_smoothed_throttle, 0.0, 1.0)
	var idle_lump: float = 1.0 - clampf((_smoothed_rpm - 850.0) / 1400.0, 0.0, 1.0)
	var high_rpm_blend: float = _smoothstep((rpm_ratio - 0.45) / 0.48)

	var firing_pulse: float = _combustion_pulse(_phase_primary)
	var bank_offset_pulse: float = _combustion_pulse(fmod(_phase_primary + PI * 0.33, TAU)) * 0.42
	var harmonic_stack: float = (
		sin(_phase_primary * 2.0) * 0.16
		+ sin(_phase_primary * 3.0) * 0.08
		+ sin(_phase_secondary) * 0.12 * high_rpm_blend
		+ sin(_phase_secondary * 1.5) * 0.055 * high_rpm_blend
	)
	var crank_body: float = sin(_phase_crank) * 0.16 + sin(_phase_crank * 2.0) * 0.08
	var exhaust_body: float = sin(_phase_exhaust) * exhaust_resonance * (0.24 + load * 0.34)
	var intake_tone: float = sin(_phase_intake) * intake_presence * throttle * high_rpm_blend
	var valvetrain_tick: float = sin(_phase_valvetrain) * mechanical_noise * (0.25 + rpm_ratio * 0.75)
	var exhaust_noise: float = _next_smooth_noise() * exhaust_roughness * (0.28 + load * 0.95)
	var rasp: float = _next_rasp_noise() * 0.055 * high_rpm_blend * (0.35 + load)
	var crackle: float = _next_crackle_sample()

	var load_gain: float = lerpf(0.3 + idle_lump * 0.12, 1.05, load)
	var rpm_gain: float = lerpf(0.42, 1.05, _smoothstep(rpm_ratio))
	var sample: float = (
		firing_pulse
		+ bank_offset_pulse
		+ harmonic_stack
		+ crank_body
		+ exhaust_body
		+ intake_tone
		+ valvetrain_tick
		+ exhaust_noise
		+ rasp
		+ crackle
	) * load_gain * rpm_gain * 0.28

	return clampf(sample, -0.92, 0.92)


func _update_overrun(delta: float) -> void:
	var throttle_drop: float = maxf(_previous_throttle - _smoothed_throttle, 0.0)
	var rpm_overrun: float = clampf((_smoothed_rpm - 3200.0) / 2600.0, 0.0, 1.0)
	var target_overrun: float = rpm_overrun if throttle_drop > 0.018 and _smoothed_load < 0.12 else 0.0
	_overrun_amount = lerpf(_overrun_amount, target_overrun, 1.0 - exp(-8.0 * delta))
	_previous_throttle = _smoothed_throttle


func _combustion_pulse(phase: float) -> float:
	var positive_lobe: float = maxf(sin(phase), 0.0)
	var pressure_spike: float = pow(positive_lobe, 0.22)
	var exhaust_tail: float = sin(phase * 0.5) * 0.18
	return pressure_spike + exhaust_tail - 0.23


func _next_smooth_noise() -> float:
	var target_noise: float = _rng.randf_range(-1.0, 1.0)
	_noise_state = lerpf(_noise_state, target_noise, 0.08)
	return _noise_state


func _next_rasp_noise() -> float:
	var target_noise: float = _rng.randf_range(-1.0, 1.0)
	_rasp_noise_state = lerpf(_rasp_noise_state, target_noise, 0.42)
	return _rasp_noise_state


func _next_crackle_sample() -> float:
	if _overrun_amount <= 0.01 or overrun_crackle <= 0.0:
		_crackle_timer = maxf(_crackle_timer - 1.0 / float(mix_rate), 0.0)
		_crackle_state = lerpf(_crackle_state, 0.0, 0.2)
		return _crackle_state

	var delta: float = 1.0 / float(mix_rate)
	_crackle_timer -= delta
	if _crackle_timer <= 0.0:
		var chance: float = overrun_crackle * _overrun_amount
		if _rng.randf() < chance:
			_crackle_state = _rng.randf_range(-1.0, 1.0) * _overrun_amount
			_crackle_timer = _rng.randf_range(0.018, 0.07)
		else:
			_crackle_timer = _rng.randf_range(0.015, 0.04)
	else:
		_crackle_state = lerpf(_crackle_state, 0.0, 0.09)

	return _crackle_state * 0.24


func _smoothstep(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return clamped_value * clamped_value * (3.0 - 2.0 * clamped_value)
