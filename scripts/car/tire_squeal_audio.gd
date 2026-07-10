extends "res://scripts/car/procedural_audio_player_3d.gd"

@export var mix_rate: int = 22050
@export var minimum_slip: float = 0.18
@export var quiet_volume_db: float = -80.0
@export var loud_volume_db: float = -10.0
@export var slip_smoothing: float = 18.0
@export var hiss_amount: float = 0.62
@export var scrape_amount: float = 0.36
@export var rumble_amount: float = 0.24

var _car: PlayerCarController
var _playback: AudioStreamGeneratorPlayback
var _smoothed_slip: float = 0.0
var _hiss_state: float = 0.0
var _scrape_state: float = 0.0
var _rumble_state: float = 0.0
var _flutter_state: float = 0.0
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
	procedural_generation_distance = max_distance + 5.0
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
		return
	if not should_generate_procedural_audio(delta):
		return

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
	var slip_gain: float = clampf((_smoothed_slip - minimum_slip) / maxf(1.0 - minimum_slip, 0.01), 0.0, 1.0)
	var speed_gain: float = 0.35
	if _car != null:
		speed_gain = lerpf(0.35, 1.0, clampf(absf(_car.get_forward_speed()) / maxf(_car.max_forward_speed, 1.0), 0.0, 1.0))

	_hiss_state = lerpf(_hiss_state, _rng.randf_range(-1.0, 1.0), 0.56)
	_scrape_state = lerpf(_scrape_state, _rng.randf_range(-1.0, 1.0), 0.16)
	_rumble_state = lerpf(_rumble_state, _rng.randf_range(-1.0, 1.0), 0.035)
	_flutter_state = lerpf(_flutter_state, _rng.randf_range(0.0, 1.0), 0.055)

	var flutter: float = lerpf(0.72, 1.0, _flutter_state)
	var surface_noise: float = (
		_hiss_state * hiss_amount
		+ _scrape_state * scrape_amount
		+ _rumble_state * rumble_amount
	)

	return clampf(surface_noise * slip_gain * speed_gain * flutter * 0.58, -0.85, 0.85)
