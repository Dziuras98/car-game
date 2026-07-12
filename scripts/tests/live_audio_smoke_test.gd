extends Node

const TEST_CAR_SCENE: PackedScene = preload("res://scenes/cars/370zat.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var car: PlayerCarController = TEST_CAR_SCENE.instantiate() as PlayerCarController
	_expect(car != null, "the packaged 370Z automatic scene instantiates")
	if car == null:
		_finish()
		return
	add_child(car)
	await get_tree().process_frame
	await get_tree().process_frame
	var audio: BakedEngineAudioPlayer = car.get_node_or_null("EngineAudio") as BakedEngineAudioPlayer
	_expect(audio != null, "the production car uses the baked engine-audio player")
	if audio == null:
		await _cleanup(car)
		return
	_expect(audio.is_using_baked_bank(), "the production player prepares its committed WAV bank")
	_expect(not audio.uses_audio_stream_generator(), "the production player does not allocate an AudioStreamGenerator")

	if DisplayServer.get_name() == "headless":
		_expect(not audio.is_processing(), "headless runtime disables audible playback updates")
		_expect(audio.get_active_voice_count() == 0, "headless runtime starts no audio voices")
		await _cleanup(car)
		return

	await get_tree().create_timer(0.10).timeout
	_expect(audio.is_processing(), "windowed runtime updates the baked playback controller")
	_expect(audio.get_loaded_voice_stream_count() >= 2, "windowed runtime selects WAV streams for coast and load layers")
	_expect(audio.get_active_voice_count() >= 1, "windowed runtime plays at least one audible WAV voice")
	_expect(not audio.uses_audio_stream_generator(), "live playback remains sample-based after startup")
	await _cleanup(car)


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
