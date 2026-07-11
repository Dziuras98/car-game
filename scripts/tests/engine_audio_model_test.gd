extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_operating_point_sanitization()
	_test_v6_firing_frequency()
	_test_limiter_gate()
	_test_generated_signal_bounds()
	_test_load_changes_signal_energy()
	_finish()


func _test_operating_point_sanitization() -> void:
	var point: Dictionary = EngineAudioSynthesizer.sanitize_operating_point(NAN, INF, -INF, 650.0, 7600.0)
	_expect(is_equal_approx(float(point.rpm), 650.0), "non-finite RPM falls back to idle")
	_expect(is_zero_approx(float(point.load)), "non-finite load falls back to zero")
	_expect(is_zero_approx(float(point.throttle)), "non-finite throttle falls back to zero")
	var clamped: Dictionary = EngineAudioSynthesizer.sanitize_operating_point(20000.0, 2.0, -1.0, 650.0, 7600.0)
	_expect(float(clamped.rpm) <= 7600.0 * 1.08, "RPM is bounded above the limiter")
	_expect(is_equal_approx(float(clamped.load), 1.0), "load is clamped")
	_expect(is_zero_approx(float(clamped.throttle)), "throttle is clamped")


func _test_v6_firing_frequency() -> void:
	_expect(is_equal_approx(EngineAudioSynthesizer.firing_frequency_hz(600.0, 6), 30.0), "even-fire V6 produces three firing events per revolution")
	_expect(is_equal_approx(EngineAudioSynthesizer.firing_frequency_hz(7600.0, 6), 380.0), "limiter firing frequency is calculated correctly")
	_expect(is_zero_approx(EngineAudioSynthesizer.firing_frequency_hz(-100.0, 6)), "negative RPM cannot create a negative firing frequency")


func _test_limiter_gate() -> void:
	_expect(is_equal_approx(EngineAudioSynthesizer.limiter_gate(7000.0, 1.0, 7600.0, 0.1, 0.46, 0.08), 1.0), "ignition remains enabled below limiter entry")
	_expect(is_equal_approx(EngineAudioSynthesizer.limiter_gate(7580.0, 0.5, 7600.0, 0.1, 0.46, 0.08), 1.0), "limiter does not cut at low throttle")
	_expect(is_equal_approx(EngineAudioSynthesizer.limiter_gate(7580.0, 1.0, 7600.0, 0.1, 0.46, 0.08), 0.08), "limiter cut retains configured residual combustion")
	_expect(is_equal_approx(EngineAudioSynthesizer.limiter_gate(7580.0, 1.0, 7600.0, 0.8, 0.46, 0.08), 1.0), "limiter restores ignition outside the cut window")


func _test_generated_signal_bounds() -> void:
	var synthesizer := EngineAudioSynthesizer.new()
	var frames: PackedFloat32Array = synthesizer.generate_test_frames(8192, 7600.0, 1.0, 1.0)
	_expect(frames.size() == 8192, "test renderer returns the requested frame count")
	var peak: float = 0.0
	var all_finite: bool = true
	for sample: float in frames:
		all_finite = all_finite and is_finite(sample)
		peak = maxf(peak, absf(sample))
	_expect(all_finite, "generated samples remain finite")
	_expect(peak > 0.01, "generated signal is not silent")
	_expect(peak <= 0.961, "soft saturation keeps samples bounded")
	synthesizer.free()


func _test_load_changes_signal_energy() -> void:
	var synthesizer := EngineAudioSynthesizer.new()
	var idle_frames: PackedFloat32Array = synthesizer.generate_test_frames(8192, 700.0, 0.05, 0.04)
	var load_frames: PackedFloat32Array = synthesizer.generate_test_frames(8192, 4500.0, 0.9, 0.9)
	var idle_rms: float = _rms(idle_frames)
	var load_rms: float = _rms(load_frames)
	_expect(idle_rms > 0.001, "idle contains audible combustion energy")
	_expect(load_rms > idle_rms * 1.10, "high-load operation has greater signal energy than idle")
	synthesizer.free()


func _rms(samples: PackedFloat32Array) -> float:
	if samples.is_empty():
		return 0.0
	var sum: float = 0.0
	for sample: float in samples:
		sum += sample * sample
	return sqrt(sum / float(samples.size()))


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[ENGINE_AUDIO_MODEL_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[ENGINE_AUDIO_MODEL_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ENGINE_AUDIO_MODEL_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[ENGINE_AUDIO_MODEL_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[ENGINE_AUDIO_MODEL_TEST] - %s" % failure_message)
	quit(1)
