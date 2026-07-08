extends AudioStreamPlayer3D

@export var mix_rate: int = 22050
@export var minimum_slip: float = 0.18
@export var quiet_volume_db: float = -80.0
@export var loud_volume_db: float = -8.0
@export var slip_smoothing: float = 18.0
@export var base_frequency: float = 1250.0
@export var frequency_range: float = 1050.0
@export var noise_amount: float = 0.45

var _car: PlayerCarController
var _playback: AudioStreamGeneratorPlayback
var _smoothed_slip: float = 0.0
var _phase: float = 0.0
var _noise_state: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_car = get_parent() as PlayerCarController
	_rng.randomize()

	var generator: AudioStreamGenerator = AudioStreamGenerator.new()
	generator.mix_rate = mix_rate
	generator.buffer_length = 0.06
	stream = generator
	unit_size = 5.0
	max_distance = 55.0
	volume_db = quiet_volume_db
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func _process(delta: float) -> void:
	if _car == null:
		return

	var target_slip: float = _car.get_tire_slip_intensity()
	_smoothed_slip = lerpf(_smoothed_slip, target_slip, 1.0 - exp(-slip_smoothing * delta))

	if _smoothed_slip < minimum_slip:
		volume_db = quiet_volume_db
	else:
		var audible_slip: float = clampf((_smoothed_slip - minimum_slip) / (1.0 - minimum_slip), 0.0, 1.0)
		volume_db = lerpf(quiet_volume_db, loud_volume_db, audible_slip)

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
	var frequency: float = base_frequency + frequency_range * clampf(_smoothed_slip, 0.0, 1.0)
	_phase = fmod(_phase + TAU * frequency * delta, TAU)

	var tone: float = sin(_phase)
	var rough_tone: float = signf(tone) * pow(absf(tone), 0.32)
	var noise: float = _next_smooth_noise() * noise_amount
	var slip_gain: float = clampf(_smoothed_slip, 0.0, 1.0)

	return clampf((rough_tone * 0.75 + noise) * slip_gain * 0.42, -0.85, 0.85)


func _next_smooth_noise() -> float:
	var target_noise: float = _rng.randf_range(-1.0, 1.0)
	_noise_state = lerpf(_noise_state, target_noise, 0.18)
	return _noise_state
