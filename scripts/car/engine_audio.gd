extends AudioStreamPlayer3D

@export var cylinders: int = 6
@export var mix_rate: int = 22050
@export var idle_volume_db: float = -23.0
@export var load_volume_db: float = -7.0
@export var rpm_smoothing: float = 12.0
@export var throttle_smoothing: float = 18.0
@export var exhaust_roughness: float = 0.09

var _car: PlayerCarController
var _playback: AudioStreamGeneratorPlayback
var _smoothed_rpm: float = 900.0
var _smoothed_load: float = 0.0
var _phase_primary: float = 0.0
var _phase_crank: float = 0.0
var _phase_secondary: float = 0.0
var _noise_state: float = 0.0
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
	volume_db = lerpf(idle_volume_db, load_volume_db, clampf(_smoothed_load, 0.0, 1.0))
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
	var secondary_frequency: float = firing_frequency * 1.5

	_phase_primary = fmod(_phase_primary + TAU * firing_frequency * delta, TAU)
	_phase_crank = fmod(_phase_crank + TAU * crank_frequency * delta, TAU)
	_phase_secondary = fmod(_phase_secondary + TAU * secondary_frequency * delta, TAU)

	var pulse: float = sin(_phase_primary)
	var pulse_shaped: float = signf(pulse) * pow(absf(pulse), 0.45)
	var harmonic: float = sin(_phase_primary * 2.0) * 0.28 + sin(_phase_primary * 3.0) * 0.13
	var crank: float = sin(_phase_crank) * 0.22
	var secondary: float = sin(_phase_secondary) * 0.12
	var intake_noise: float = _next_smooth_noise() * exhaust_roughness * (0.35 + _smoothed_load)
	var load_gain: float = lerpf(0.33, 1.0, _smoothed_load)
	var rpm_gain: float = clampf(_smoothed_rpm / 7000.0, 0.2, 1.0)

	return clampf((pulse_shaped + harmonic + crank + secondary + intake_noise) * load_gain * rpm_gain * 0.34, -0.9, 0.9)


func _next_smooth_noise() -> float:
	var target_noise: float = _rng.randf_range(-1.0, 1.0)
	_noise_state = lerpf(_noise_state, target_noise, 0.08)
	return _noise_state
