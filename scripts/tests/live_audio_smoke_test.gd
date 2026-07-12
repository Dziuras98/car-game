extends Node

const TEST_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")
const TEST_PROFILE: EngineAudioProfile = preload("res://resources/audio/370z_stock_audio_profile.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var car: PlayerCarController = PlayerCarController.new()
	car.name = "LiveAudioTestCar"
	car.car_specs = TEST_SPECS
	var synthesizer: ProfiledEngineAudioSynthesizer = ProfiledEngineAudioSynthesizer.new()
	synthesizer.name = "EngineAudio"
	synthesizer.profile = TEST_PROFILE
	car.add_child(synthesizer)
	add_child(car)
	await get_tree().process_frame
	await get_tree().process_frame

	if DisplayServer.get_name() == "headless":
		_expect(synthesizer.stream == null, "headless runtime does not initialize live audio playback")
		_expect(not synthesizer.is_processing(), "headless runtime disables procedural audio processing")
		_cleanup(car)
		return

	_expect(synthesizer.stream is AudioStreamGenerator, "windowed runtime initializes an AudioStreamGenerator")
	var playback: AudioStreamGeneratorPlayback = synthesizer.get_stream_playback() as AudioStreamGeneratorPlayback
	_expect(playback != null, "windowed runtime exposes generator playback")
	_expect(synthesizer.is_processing(), "windowed runtime keeps procedural audio processing enabled")
	if playback == null:
		_cleanup(car)
		return

	synthesizer.set_process(false)
	await get_tree().create_timer(0.12).timeout
	var first_available_before: int = playback.get_frames_available()
	synthesizer.call("_fill_audio_buffer")
	var first_available_after: int = playback.get_frames_available()
	_expect(
		first_available_before > first_available_after,
		"live generator fills frames after the audio server drains its buffer"
	)

	await get_tree().create_timer(0.08).timeout
	var second_available_before: int = playback.get_frames_available()
	synthesizer.call("_fill_audio_buffer")
	var second_available_after: int = playback.get_frames_available()
	_expect(
		second_available_before > second_available_after,
		"live generator refills the buffer repeatedly without losing playback"
	)
	_expect(synthesizer.playing, "procedural audio player remains active throughout the refill cycle")
	_cleanup(car)


func _cleanup(car: PlayerCarController) -> void:
	if is_instance_valid(car):
		car.queue_free()
	await get_tree().process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[LIVE_AUDIO_SMOKE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[LIVE_AUDIO_SMOKE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LIVE_AUDIO_SMOKE_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[LIVE_AUDIO_SMOKE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[LIVE_AUDIO_SMOKE_TEST] - %s" % failure_message)
	get_tree().quit(1)
