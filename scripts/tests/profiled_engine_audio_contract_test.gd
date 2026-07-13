extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var audio: ProfiledEngineAudioSynthesizer = ProfiledEngineAudioSynthesizer.new()
	audio.cylinders = 8
	audio.force_full_runtime_generation = true
	root.add_child(audio)
	await process_frame
	_expect(
		audio.cylinders == 8,
		"profiled engine audio preserves an explicitly configured V8 cylinder count"
	)
	_expect(
		EngineAudioSynthesizer.firing_frequency_hz(3000.0, audio.cylinders) == 200.0,
		"the configured V8 produces four firing events per crankshaft revolution"
	)
	_expect(
		audio.should_generate_procedural_audio(1.0 / 60.0),
		"full runtime generation bypasses procedural distance and voice limits"
	)
	audio.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PROFILED_ENGINE_AUDIO_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[PROFILED_ENGINE_AUDIO_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PROFILED_ENGINE_AUDIO_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[PROFILED_ENGINE_AUDIO_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[PROFILED_ENGINE_AUDIO_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
