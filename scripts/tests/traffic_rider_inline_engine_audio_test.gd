extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_profile_validation()
	_test_firing_frequency_by_layout()
	_test_deterministic_signal()
	_test_finite_bounded_output()
	_test_layouts_have_distinct_waveforms()
	_test_diesel_and_petrol_are_distinct()
	_test_limiter_preserves_turbo_state()
	_test_real_pedal_lift_triggers_release()
	_finish()


func _test_profile_validation() -> void:
	for cylinders: int in [3, 4, 6]:
		var profile := _profile(cylinders, false, true)
		_expect(profile.validate().is_empty(), "valid inline-%d profile passes architecture validation" % cylinders)
	var invalid := _profile(4, false, false)
	invalid.firing_order = PackedInt32Array([1, 3, 3, 2])
	_expect(not invalid.validate().is_empty(), "duplicate firing-order cylinder is rejected")


func _test_firing_frequency_by_layout() -> void:
	var rpm: float = 3000.0
	_expect(is_equal_approx(_profile(3, false, false).get_event_frequency_hz(rpm), 75.0), "inline-three firing frequency is cylinder-count correct")
	_expect(is_equal_approx(_profile(4, false, false).get_event_frequency_hz(rpm), 100.0), "inline-four firing frequency is cylinder-count correct")
	_expect(is_equal_approx(_profile(6, false, false).get_event_frequency_hz(rpm), 150.0), "inline-six firing frequency is cylinder-count correct")


func _test_deterministic_signal() -> void:
	var synth := TrafficRiderInlineEngineAudioSynthesizer.new()
	synth.profile = _profile(6, false, true)
	var first: PackedFloat32Array = synth.generate_test_frames(4096, 3200.0, 0.70, 0.68)
	var second: PackedFloat32Array = synth.generate_test_frames(4096, 3200.0, 0.70, 0.68)
	_expect(first == second, "fixed profile and operating point render deterministically")
	synth.free()


func _test_finite_bounded_output() -> void:
	for profile: TrafficRiderInlineEngineAudioProfile in [
		_profile(3, false, true),
		_profile(4, true, true),
		_profile(6, false, true),
	]:
		var synth := TrafficRiderInlineEngineAudioSynthesizer.new()
		synth.profile = profile
		var frames: PackedFloat32Array = synth.generate_test_frames(8192, profile.redline_rpm * 0.82, 1.0, 1.0)
		var maximum_peak: float = 0.0
		var finite: bool = true
		for sample: float in frames:
			finite = finite and is_finite(sample)
			maximum_peak = maxf(maximum_peak, absf(sample))
		_expect(finite, "%s output remains finite" % profile.display_name)
		_expect(maximum_peak <= profile.peak_limit + 0.0001, "%s obeys summed-output peak limit" % profile.display_name)
		synth.free()


func _test_layouts_have_distinct_waveforms() -> void:
	var i3 := TrafficRiderInlineEngineAudioSynthesizer.new()
	var i4 := TrafficRiderInlineEngineAudioSynthesizer.new()
	var i6 := TrafficRiderInlineEngineAudioSynthesizer.new()
	i3.profile = _profile(3, false, false)
	i4.profile = _profile(4, false, false)
	i6.profile = _profile(6, false, false)
	var i3_frames: PackedFloat32Array = i3.generate_test_frames(4096, 3000.0, 0.75, 0.70)
	var i4_frames: PackedFloat32Array = i4.generate_test_frames(4096, 3000.0, 0.75, 0.70)
	var i6_frames: PackedFloat32Array = i6.generate_test_frames(4096, 3000.0, 0.75, 0.70)
	_expect(_mean_absolute_difference(i3_frames, i4_frames) > 0.015, "inline-three is not a pitch-only inline-four waveform")
	_expect(_mean_absolute_difference(i4_frames, i6_frames) > 0.015, "inline-six is not a pitch-only inline-four waveform")
	_expect(_mean_absolute_difference(i3_frames, i6_frames) > 0.015, "inline-three and inline-six retain different event cadence")
	i3.free()
	i4.free()
	i6.free()


func _test_diesel_and_petrol_are_distinct() -> void:
	var petrol := TrafficRiderInlineEngineAudioSynthesizer.new()
	var diesel := TrafficRiderInlineEngineAudioSynthesizer.new()
	petrol.profile = _profile(4, false, true)
	diesel.profile = _profile(4, true, true)
	var petrol_frames: PackedFloat32Array = petrol.generate_test_frames(4096, 2600.0, 0.85, 0.72)
	var diesel_frames: PackedFloat32Array = diesel.generate_test_frames(4096, 2600.0, 0.85, 0.72)
	_expect(_mean_absolute_difference(petrol_frames, diesel_frames) > 0.012, "common-rail diesel is not a retuned petrol inline-four waveform")
	petrol.free()
	diesel.free()


func _test_limiter_preserves_turbo_state() -> void:
	var synth := TrafficRiderInlineEngineAudioSynthesizer.new()
	var turbo_profile := _profile(4, false, true)
	synth.profile = turbo_profile
	synth.generate_test_frames(24000, turbo_profile.redline_rpm * 0.78, 1.0, 1.0)
	var spool_before_limiter: float = synth.get_turbo_spool()
	synth.generate_stateful_test_frames(6000, turbo_profile.redline_rpm, 1.0, 1.0)
	var spool_after_limiter: float = synth.get_turbo_spool()
	_expect(spool_before_limiter > 0.20, "loaded operation builds persistent turbo state")
	_expect(spool_after_limiter >= spool_before_limiter - 0.02, "limiter torque cut does not erase turbo spool")
	_expect(synth.get_release_envelope() <= 0.0001, "limiter does not create a false compressor-release event")
	synth.free()


func _test_real_pedal_lift_triggers_release() -> void:
	var synth := TrafficRiderInlineEngineAudioSynthesizer.new()
	var turbo_profile := _profile(6, false, true)
	synth.profile = turbo_profile
	synth.generate_test_frames(24000, 4200.0, 1.0, 1.0)
	synth.generate_stateful_test_frames(1, 4200.0, 0.10, 0.0)
	_expect(synth.get_release_envelope() > 0.10, "real pedal lift at boost triggers release envelope")
	synth.free()


func _profile(
	cylinders: int,
	diesel: bool,
	turbocharged: bool
) -> TrafficRiderInlineEngineAudioProfile:
	var profile := TrafficRiderInlineEngineAudioProfile.new()
	profile.engine_family_id = StringName("test_i%d_%s_%s" % [
		cylinders,
		"diesel" if diesel else "petrol",
		"turbo" if turbocharged else "na",
	])
	profile.display_name = str(profile.engine_family_id)
	profile.cylinder_count = cylinders
	match cylinders:
		3:
			profile.firing_order = PackedInt32Array([1, 2, 3])
			profile.collector_group_by_cylinder = PackedInt32Array([0, 0, 0])
		4:
			profile.firing_order = PackedInt32Array([1, 3, 4, 2])
			profile.collector_group_by_cylinder = PackedInt32Array([0, 1, 1, 0])
		6:
			profile.firing_order = PackedInt32Array([1, 5, 3, 6, 2, 4])
			profile.collector_group_by_cylinder = PackedInt32Array([0, 1, 0, 1, 0, 1])
	profile.combustion_type = (
		TrafficRiderInlineEngineAudioProfile.CombustionType.DIESEL_COMMON_RAIL
		if diesel
		else TrafficRiderInlineEngineAudioProfile.CombustionType.PETROL_DIRECT_INJECTION
	)
	profile.aspiration_type = (
		TrafficRiderInlineEngineAudioProfile.AspirationType.SINGLE_TURBO
		if turbocharged
		else TrafficRiderInlineEngineAudioProfile.AspirationType.NATURALLY_ASPIRATED
	)
	profile.idle_rpm = 720.0 if not diesel else 760.0
	profile.redline_rpm = 6800.0 if not diesel else 4800.0
	profile.limiter_period_s = 0.06
	profile.limiter_cut_fraction = 0.46
	profile.limiter_residual_combustion = 0.08
	profile.idle_irregularity = 0.018 if not diesel else 0.040
	profile.combustion_sharpness = 0.52 if not diesel else 0.82
	profile.combustion_level = 0.90
	profile.intake_level = 0.30
	profile.exhaust_level = 0.55
	profile.mechanical_level = 0.16 if not diesel else 0.28
	profile.injector_level = 0.04 if not diesel else 0.18
	profile.diesel_clatter_level = 0.0 if not diesel else 0.34
	profile.intake_resonance_hz = 420.0 + float(cylinders) * 25.0
	profile.exhaust_resonance_hz = 105.0 + float(cylinders) * 12.0
	profile.mechanical_order = 2.0 if cylinders <= 4 else 3.0
	profile.collector_separation = 0.45 if cylinders >= 4 else 0.10
	profile.synthesis_gain = 0.22
	profile.peak_limit = 0.90
	if turbocharged:
		profile.turbo_spool_rate_per_s = 2.8
		profile.turbo_release_rate_per_s = 1.25
		profile.turbo_whine_base_hz = 920.0
		profile.turbo_whine_range_hz = 4100.0
		profile.turbo_whine_level = 0.09
		profile.turbine_level = 0.08
		profile.wastegate_level = 0.07
		profile.release_level = 0.12
	return profile


func _mean_absolute_difference(
	left: PackedFloat32Array,
	right: PackedFloat32Array
) -> float:
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
		print("[TRAFFIC_RIDER_INLINE_ENGINE_AUDIO_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRAFFIC_RIDER_INLINE_ENGINE_AUDIO_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_INLINE_ENGINE_AUDIO_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_INLINE_ENGINE_AUDIO_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
