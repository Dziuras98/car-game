extends SceneTree

const FRAME_COUNT: int = 16384
const ANALYSIS_START: int = 4096

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var car_root := Node.new()
	root.add_child(car_root)

	var engine_audio := EngineAudioSynthesizer.new()
	engine_audio.name = "EngineAudio"
	car_root.add_child(engine_audio)

	var profile := Node.new()
	profile.set_script(load("res://scripts/car/370z_audio_profile.gd"))
	car_root.add_child(profile)
	await process_frame

	_expect(is_equal_approx(engine_audio.idle_volume_db, -10.0), "370Z profile raises the closed-throttle player level")
	_expect(is_equal_approx(engine_audio.load_volume_db, -5.0), "370Z full-load player level remains unchanged")
	_expect(engine_audio.load_volume_db - engine_audio.idle_volume_db <= 5.1, "player-volume range cannot mute zero-load operation")

	var no_load_frames: PackedFloat32Array = engine_audio.generate_test_frames(FRAME_COUNT, 3000.0, 0.0, 0.0)
	var loaded_frames: PackedFloat32Array = engine_audio.generate_test_frames(FRAME_COUNT, 3000.0, 0.50, 0.50)
	var idle_frames: PackedFloat32Array = engine_audio.generate_test_frames(FRAME_COUNT, 700.0, 0.0, 0.0)

	var no_load_output_rms: float = _rms(no_load_frames) * db_to_linear(
		engine_audio.idle_volume_db + engine_audio.output_volume_boost_db
	)
	var loaded_loudness: float = clampf(0.50 * 0.90 + 0.50 * 0.26, 0.0, 1.0)
	var loaded_volume_db: float = lerpf(
		engine_audio.idle_volume_db,
		engine_audio.load_volume_db,
		loaded_loudness
	) + engine_audio.output_volume_boost_db
	var loaded_output_rms: float = _rms(loaded_frames) * db_to_linear(loaded_volume_db)
	var idle_output_rms: float = _rms(idle_frames) * db_to_linear(
		engine_audio.idle_volume_db + engine_audio.output_volume_boost_db
	)

	print(
		"[370Z_CLOSED_THROTTLE_AUDIO_TEST] idle_rms=%.7f no_load_3000_rms=%.7f loaded_3000_rms=%.7f ratio=%.3f" % [
			idle_output_rms,
			no_load_output_rms,
			loaded_output_rms,
			no_load_output_rms / maxf(loaded_output_rms, 0.000000001),
		]
	)
	_expect(idle_output_rms > 0.003, "zero-input idle remains clearly above the silence floor")
	_expect(no_load_output_rms > 0.004, "closed-throttle engine braking remains audible at 3000 RPM")
	_expect(no_load_output_rms > loaded_output_rms * 0.25, "closed-throttle output stays within 12 dB of moderate load")

	car_root.queue_free()
	await process_frame
	_finish()


func _rms(samples: PackedFloat32Array) -> float:
	if samples.size() <= ANALYSIS_START:
		return 0.0
	var sum_squares: float = 0.0
	for index: int in range(ANALYSIS_START, samples.size()):
		var sample: float = samples[index]
		sum_squares += sample * sample
	return sqrt(sum_squares / float(samples.size() - ANALYSIS_START))


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[370Z_CLOSED_THROTTLE_AUDIO_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[370Z_CLOSED_THROTTLE_AUDIO_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[370Z_CLOSED_THROTTLE_AUDIO_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[370Z_CLOSED_THROTTLE_AUDIO_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[370Z_CLOSED_THROTTLE_AUDIO_TEST] - %s" % failure_message)
	quit(1)
