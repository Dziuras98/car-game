extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run()
	_finish()


func _run() -> void:
	ProceduralAudioPlayer3D.reset_voice_budget_for_test()
	for source_id: int in range(1, 7):
		ProceduralAudioPlayer3D.report_voice_distance_for_test(
			&"engine",
			source_id,
			float(source_id * source_id),
			3
		)

	_expect(
		ProceduralAudioPlayer3D.report_voice_distance_for_test(&"engine", 1, 1.0, 3),
		"nearest engine voice remains inside the synthesis budget"
	)
	_expect(
		ProceduralAudioPlayer3D.report_voice_distance_for_test(&"engine", 3, 9.0, 3),
		"third-nearest engine voice remains inside the synthesis budget"
	)
	_expect(
		not ProceduralAudioPlayer3D.report_voice_distance_for_test(&"engine", 4, 16.0, 3),
		"fourth-nearest engine voice is excluded from a three-voice budget"
	)
	_expect(
		ProceduralAudioPlayer3D.report_voice_distance_for_test(&"tire", 4, 16.0, 1),
		"voice limits are isolated between engine and tire groups"
	)

	ProceduralAudioPlayer3D.reset_voice_budget_for_test()
	_expect(
		ProceduralAudioPlayer3D.report_voice_distance_for_test(&"engine", 99, 10000.0, 3),
		"reset clears stale voice registrations"
	)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PROCEDURAL_AUDIO_VOICE_BUDGET_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[PROCEDURAL_AUDIO_VOICE_BUDGET_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PROCEDURAL_AUDIO_VOICE_BUDGET_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[PROCEDURAL_AUDIO_VOICE_BUDGET_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[PROCEDURAL_AUDIO_VOICE_BUDGET_TEST] - %s" % failure_message)
	quit(1)
