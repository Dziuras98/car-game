extends SceneTree

const FRAME_COUNT: int = 16384
const ANALYSIS_START: int = 4096
const ORIGINAL_SYNTHESIS_GAIN_DB: float = 3.5
const ORIGINAL_OUTPUT_BOOST_DB: float = 4.0
const REQUESTED_GLOBAL_INCREASE_DB: float = 5.0
const EXPECTED_COMBINED_GAIN_DB: float = ORIGINAL_SYNTHESIS_GAIN_DB + ORIGINAL_OUTPUT_BOOST_DB + REQUESTED_GLOBAL_INCREASE_DB

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

	_expect(is_equal_approx(engine_audio.synthesis_gain_db, 1.0), "370Z profile reduces internal saturation drive")
	_expect(is_equal_approx(engine_audio.output_volume_boost_db, 11.5), "370Z profile moves compensating gain to the linear player stage")
	_expect(
		is_equal_approx(engine_audio.synthesis_gain_db + engine_audio.output_volume_boost_db, EXPECTED_COMBINED_GAIN_DB),
		"370Z profile preserves the requested overall +5 dB increase"
	)
	_expect(is_equal_approx(engine_audio.idle_volume_db, -10.0), "370Z minimum player level keeps closed-throttle operation audible")
	_expect(is_equal_approx(engine_audio.load_volume_db, 0.0), "370Z maximum player level remains 0 dB")
	_expect(is_equal_approx(engine_audio.load_volume_db - engine_audio.idle_volume_db, 10.0), "370Z player-volume range remains exactly 10 dB")

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
		"[370Z_CLOSED_THROTTLE_AUDIO_TEST] idle_rms=%.7f no_load_3000_rms=%.7f loaded_3000_rms=%.7f ratio=%.3f synthesis_gain_db=%.1f output_boost_db=%.1f combined_gain_db=%.1f volume_span_db=%.1f" % [
			idle_output_rms,
			no_load_output_rms,
			loaded_output_rms,
			no_load_output_rms / maxf(loaded_output_rms, 0.000000001),
			engine_audio.synthesis_gain_db,
			engine_audio.output_volume_boost_db,
			engine_audio.synthesis_gain_db + engine_audio.output_volume_boost_db,
			engine_audio.load_volume_db - engine_audio.idle_volume_db,
		]
	)
	_expect(idle_output_rms > 0.005, "zero-input idle remains clearly above the silence floor")
	_expect(no_load_output_rms > 0.007, "closed-throttle engine braking remains audible at 3000 RPM")
	_expect(no_load_output_rms > loaded_output_rms * 0.20, "closed-throttle output remains within 14 dB of moderate load")

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
