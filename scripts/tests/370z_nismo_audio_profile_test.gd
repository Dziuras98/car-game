extends SceneTree

const FRAME_COUNT: int = 16384
const ANALYSIS_START: int = 4096

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var standard_root := Node.new()
	standard_root.name = "Standard370ZAudioRoot"
	root.add_child(standard_root)
	var standard_audio := EngineAudioSynthesizer.new()
	standard_audio.name = "EngineAudio"
	standard_root.add_child(standard_audio)
	var standard_profile := Node.new()
	standard_profile.name = "StandardAudioProfile"
	standard_profile.set_script(load("res://scripts/car/370z_audio_profile.gd"))
	standard_root.add_child(standard_profile)

	var nismo_root := Node.new()
	nismo_root.name = "Nismo370ZAudioRoot"
	root.add_child(nismo_root)
	var nismo_audio := EngineAudioSynthesizer.new()
	nismo_audio.name = "EngineAudio"
	nismo_root.add_child(nismo_audio)
	var nismo_profile := Node.new()
	nismo_profile.name = "NismoAudioProfile"
	nismo_profile.set_script(load("res://scripts/car/370z_nismo_audio_profile.gd"))
	nismo_root.add_child(nismo_profile)

	await process_frame

	_expect(
		is_equal_approx(
			standard_audio.synthesis_gain_db + standard_audio.output_volume_boost_db,
			nismo_audio.synthesis_gain_db + nismo_audio.output_volume_boost_db
		),
		"standard and NISMO profiles retain the same combined gain"
	)
	_expect(nismo_audio.idle_volume_db > standard_audio.idle_volume_db, "the NISMO sport exhaust is more present at minimum load")
	_expect(nismo_audio.intake_presence > standard_audio.intake_presence, "the NISMO profile has stronger induction presence")
	_expect(nismo_audio.intake_plenum_detail > standard_audio.intake_plenum_detail, "the NISMO profile has more plenum detail")
	_expect(nismo_audio.high_rpm_rasp > standard_audio.high_rpm_rasp, "the NISMO profile has a stronger high-RPM edge")
	_expect(nismo_audio.exhaust_resonance > standard_audio.exhaust_resonance, "the NISMO profile has a fuller exhaust resonance")
	_expect(nismo_audio.exhaust_bank_separation > standard_audio.exhaust_bank_separation, "the NISMO profile separates the two exhaust banks more clearly")
	_expect(nismo_audio.overrun_crackle > standard_audio.overrun_crackle, "the NISMO profile has a stronger overrun signature")
	_expect(nismo_audio.limiter_residual_combustion > standard_audio.limiter_residual_combustion, "the NISMO limiter retains more residual combustion")

	var standard_frames: PackedFloat32Array = standard_audio.generate_test_frames(FRAME_COUNT, 6500.0, 1.0, 1.0)
	var nismo_frames: PackedFloat32Array = nismo_audio.generate_test_frames(FRAME_COUNT, 6500.0, 1.0, 1.0)
	_expect(_all_finite(standard_frames), "the standard comparison signal remains finite")
	_expect(_all_finite(nismo_frames), "the NISMO signal remains finite")
	_expect(_max_abs(nismo_frames) <= 1.0001, "the NISMO synthesis stays inside normalized sample bounds")

	var standard_rms: float = _rms(standard_frames)
	var nismo_rms: float = _rms(nismo_frames)
	_expect(standard_rms > 0.001, "the standard comparison signal is audible")
	_expect(nismo_rms > 0.001, "the NISMO signal is audible")
	_expect(nismo_rms > standard_rms * 0.50, "the NISMO profile does not lose the main VQ exhaust body")
	_expect(nismo_rms < standard_rms * 1.80, "the NISMO profile does not use an uncontrolled loudness increase")

	print(
		"[370Z_NISMO_AUDIO_PROFILE_TEST] standard_rms=%.7f nismo_rms=%.7f standard_peak=%.5f nismo_peak=%.5f" % [
			standard_rms,
			nismo_rms,
			_max_abs(standard_frames),
			_max_abs(nismo_frames),
		]
	)

	standard_root.queue_free()
	nismo_root.queue_free()
	await process_frame
	_finish()


func _all_finite(samples: PackedFloat32Array) -> bool:
	for sample: float in samples:
		if not is_finite(sample):
			return false
	return true


func _max_abs(samples: PackedFloat32Array) -> float:
	var result: float = 0.0
	for sample: float in samples:
		result = maxf(result, absf(sample))
	return result


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
		print("[370Z_NISMO_AUDIO_PROFILE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[370Z_NISMO_AUDIO_PROFILE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[370Z_NISMO_AUDIO_PROFILE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[370Z_NISMO_AUDIO_PROFILE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[370Z_NISMO_AUDIO_PROFILE_TEST] - %s" % failure_message)
	quit(1)
