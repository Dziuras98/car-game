extends SceneTree

class LodBlockedSynthesizer extends EngineAudioSynthesizer:
	func should_generate_procedural_audio(_delta: float) -> bool:
		return false

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_shutdown_progresses_without_audio_generation()
	_test_shutdown_reaches_digital_silence()
	_test_vq_backend_is_explicitly_six_cylinder()
	_test_sample_rate_helpers()
	_test_turbo_levels_are_attenuated()
	_test_limiter_torque_cut_preserves_turbo_drive()
	_test_weighted_voice_budget()
	_finish()


func _test_shutdown_progresses_without_audio_generation() -> void:
	var synthesizer := LodBlockedSynthesizer.new()
	synthesizer.debug_override_enabled = true
	synthesizer.debug_rpm = 3200.0
	synthesizer.trigger_engine_shutdown()
	synthesizer._process(synthesizer.shutdown_duration + 0.05)
	var state: Dictionary = synthesizer.get_debug_state()
	_expect(not bool(state.get("engine_running", true)), "shutdown state advances while procedural LOD is blocked")
	_expect(float(state.get("engine_state_gain", 1.0)) <= 0.000001, "blocked shutdown reaches zero engine gain")
	synthesizer.free()


func _test_shutdown_reaches_digital_silence() -> void:
	var synthesizer := EngineAudioSynthesizer.new()
	synthesizer.generate_test_frames(2048, 3500.0, 0.7, 0.6)
	synthesizer.trigger_engine_shutdown()
	synthesizer.advance_engine_state(synthesizer.shutdown_duration + 0.05)
	var frames: PackedFloat32Array = synthesizer.generate_stateful_frames(4096)
	_expect(_peak(frames) <= 0.000001, "completed shutdown produces digital silence")
	synthesizer.free()


func _test_vq_backend_is_explicitly_six_cylinder() -> void:
	var four_setting := EngineAudioSynthesizer.new()
	four_setting.cylinders = 4
	var six_setting := EngineAudioSynthesizer.new()
	six_setting.cylinders = 6
	var four_frames: PackedFloat32Array = four_setting.generate_test_frames(4096, 3000.0, 0.5, 0.5)
	var six_frames: PackedFloat32Array = six_setting.generate_test_frames(4096, 3000.0, 0.5, 0.5)
	_expect(_mean_abs_difference(four_frames, six_frames) <= 0.000001, "base VQ backend does not pretend to model non-V6 firing geometry")
	four_setting.free()
	six_setting.free()


func _test_sample_rate_helpers() -> void:
	var alpha_16k: float = EngineAudioSynthesizer.sample_rate_invariant_alpha(0.03, 16000.0)
	var alpha_32k: float = EngineAudioSynthesizer.sample_rate_invariant_alpha(0.03, 32000.0)
	var alpha_48k: float = EngineAudioSynthesizer.sample_rate_invariant_alpha(0.03, 48000.0)
	_expect(alpha_16k > alpha_32k and alpha_32k > alpha_48k, "per-sample smoothing scales with sample rate")
	_expect(is_equal_approx(alpha_32k, 0.03), "32 kHz remains the calibrated reference response")
	_expect(EngineAudioSynthesizer.bandlimited_frequency(20000.0, 32000.0) <= 13440.001, "oscillator frequency stays below the configured anti-alias ceiling")


func _test_turbo_levels_are_attenuated() -> void:
	var synthesizer := FiatPuntoEngineAudioSynthesizer.new()
	synthesizer.turbo_whistle = 1.0
	synthesizer.turbo_flutter = 0.8
	synthesizer.turbo_blowoff = 0.6
	synthesizer.turbo_output_scale = 0.5
	synthesizer._apply_turbo_output_scale()
	_expect(is_equal_approx(synthesizer.turbo_whistle, 0.5), "turbo whistle is attenuated by the shared output scale")
	_expect(is_equal_approx(synthesizer.turbo_flutter, 0.4), "turbo flutter is attenuated by the shared output scale")
	_expect(is_equal_approx(synthesizer.turbo_blowoff, 0.3), "turbo blow-off is attenuated by the shared output scale")
	synthesizer._apply_turbo_output_scale()
	_expect(is_equal_approx(synthesizer.turbo_whistle, 0.5), "turbo output scaling is idempotent")
	synthesizer.free()


func _test_limiter_torque_cut_preserves_turbo_drive() -> void:
	var synthesizer := FiatPuntoEngineAudioSynthesizer.new()
	var limiter_rpm: float = synthesizer._get_rev_limit_rpm()
	synthesizer._smoothed_rpm = limiter_rpm * 0.99
	synthesizer._smoothed_load = 0.0
	synthesizer._smoothed_throttle = 0.0
	synthesizer._punto_previous_throttle = 1.0
	synthesizer._punto_turbo_spool = 0.8
	synthesizer._update_transient_envelopes(0.0, 1.0 / 60.0)
	_expect(synthesizer._smoothed_throttle >= 0.99, "limiter torque cut retains the driver's turbo throttle command")
	_expect(synthesizer._smoothed_load >= synthesizer.turbo_limiter_load_floor, "limiter torque cut retains a turbo load floor")
	_expect(synthesizer._punto_turbo_release <= 0.000001, "limiter torque cut does not trigger a false blow-off event")

	synthesizer._smoothed_rpm = limiter_rpm * 0.80
	synthesizer._smoothed_load = 0.0
	synthesizer._smoothed_throttle = 0.0
	synthesizer._punto_turbo_spool = 0.8
	synthesizer._update_transient_envelopes(0.0, 1.0 / 60.0)
	_expect(synthesizer._punto_previous_throttle <= 0.000001, "real pedal lift is accepted below the limiter window")
	_expect(synthesizer._punto_turbo_release > 0.0, "real pedal lift still triggers turbo release audio")
	synthesizer.free()


func _test_weighted_voice_budget() -> void:
	ProceduralAudioPlayer3D.reset_voice_budget()
	_expect(ProceduralAudioPlayer3D.report_voice_distance(&"engine-test", 1, 1.0, 6, 2), "first two-cost baked voice receives budget")
	_expect(ProceduralAudioPlayer3D.report_voice_distance(&"engine-test", 2, 4.0, 6, 2), "second two-cost baked voice receives budget")
	_expect(ProceduralAudioPlayer3D.report_voice_distance(&"engine-test", 3, 9.0, 6, 2), "third two-cost baked voice fills budget")
	_expect(not ProceduralAudioPlayer3D.report_voice_distance(&"engine-test", 4, 16.0, 6, 2), "fourth baked voice is rejected when stream cost exceeds budget")
	ProceduralAudioPlayer3D.reset_voice_budget()


func _peak(samples: PackedFloat32Array) -> float:
	var result: float = 0.0
	for sample: float in samples:
		result = maxf(result, absf(sample))
	return result


func _mean_abs_difference(left: PackedFloat32Array, right: PackedFloat32Array) -> float:
	var count: int = mini(left.size(), right.size())
	if count <= 0:
		return 0.0
	var total: float = 0.0
	for index: int in count:
		total += absf(left[index] - right[index])
	return total / float(count)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[ENGINE_AUDIO_RUNTIME_REGRESSION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[ENGINE_AUDIO_RUNTIME_REGRESSION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ENGINE_AUDIO_RUNTIME_REGRESSION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[ENGINE_AUDIO_RUNTIME_REGRESSION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[ENGINE_AUDIO_RUNTIME_REGRESSION_TEST] - %s" % failure_message)
	quit(1)
