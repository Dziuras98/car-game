extends SceneTree

const AI_CAR_SCENE: PackedScene = preload("res://scenes/cars/370z_ai.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var car: PlayerCarController = AI_CAR_SCENE.instantiate() as PlayerCarController
	_expect(car != null, "AI car fixture instantiates")
	if car == null:
		_finish()
		return
	car.car_specs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")
	root.add_child(car)
	await process_frame
	car.set_physics_process(false)

	var audio: BakedEngineAudioPlayer = car.get_node_or_null("EngineAudio") as BakedEngineAudioPlayer
	_expect(audio != null, "AI car exposes baked engine audio")
	if audio != null:
		_expect(audio is ProceduralAudioPlayer3D, "baked engine audio participates in the shared distance and voice budget")
		_expect(audio.procedural_voice_group == &"engine", "baked and procedural engines share the engine voice group")
		_expect(audio.max_procedural_voices <= 6, "baked engine voices use the global six-source cap")
		_expect(
			is_equal_approx(audio.procedural_generation_distance, audio.max_distance + 5.0),
			"baked engine generation stops outside the spatial-audio range"
		)

	ProceduralAudioPlayer3D.reset_voice_budget()
	for source_id: int in range(8):
		ProceduralAudioPlayer3D.report_voice_distance(&"engine", source_id + 1000, float(source_id), 6)
	for source_id: int in range(8):
		var active: bool = ProceduralAudioPlayer3D.report_voice_distance(
			&"engine",
			source_id + 1000,
			float(source_id),
			6
		)
		_expect(active == (source_id < 6), "engine voice budget retains only the six nearest sources (%d)" % source_id)
	ProceduralAudioPlayer3D.reset_voice_budget()

	car.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BAKED_AUDIO_BUDGET_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[BAKED_AUDIO_BUDGET_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BAKED_AUDIO_BUDGET_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BAKED_AUDIO_BUDGET_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[BAKED_AUDIO_BUDGET_TEST] - %s" % failure_message)
	quit(1)
