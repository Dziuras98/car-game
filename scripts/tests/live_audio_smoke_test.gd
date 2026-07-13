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
	var audio: ProfiledEngineAudioSynthesizer = car.get_node_or_null("EngineAudio") as ProfiledEngineAudioSynthesizer
	_expect(audio != null, "the player car uses the profiled live engine synthesizer")
	if audio == null:
		await _cleanup(car)
		return
	_expect(audio.profile != null and audio.profile.is_valid(), "the player synthesizer has a valid engine profile")
	_expect(audio.force_full_runtime_generation, "the player synthesizer bypasses distance LOD and shared voice budgeting")
	_expect(audio.should_generate_procedural_audio(1.0 / 60.0), "full player synthesis remains enabled for every runtime update")

	if DisplayServer.get_name() == "headless":
		_expect(not audio.is_processing(), "headless runtime disables audible synthesis updates")
		_expect(audio.stream == null, "headless runtime does not allocate an AudioStreamGenerator")
		await _cleanup(car)
		return

	await get_tree().create_timer(0.10).timeout
	_expect(audio.is_processing(), "windowed runtime updates the live synthesis controller")
	_expect(audio.stream is AudioStreamGenerator, "windowed runtime allocates an AudioStreamGenerator")
	_expect(audio.playing, "windowed runtime starts procedural engine playback")
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
