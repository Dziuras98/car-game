extends SceneTree

const MUSTANG_SCENE: PackedScene = preload("res://scenes/cars/mustang_shelby_gt500_1967.tscn")
const FORD_PROFILE: EngineAudioProfile = preload("res://resources/audio/ford_428_fe_audio_profile.tres")
const TEST_FRAME_COUNT: int = 8192

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_ford_fe_firing_cadence()
	await _test_mustang_scene_contract()
	await _test_stereo_signal_character()
	_finish()


func _test_ford_fe_firing_cadence() -> void:
	_expect(
		CrossPlaneV8EngineAudioSynthesizer.get_firing_order()
		== PackedInt32Array([1, 5, 4, 2, 6, 3, 7, 8]),
		"Ford FE synthesis uses the 1-5-4-2-6-3-7-8 firing order"
	)
	_expect(
		CrossPlaneV8EngineAudioSynthesizer.get_bank_sequence()
		== PackedInt32Array([0, 1, 0, 0, 1, 0, 1, 1]),
		"Ford FE firing events retain the cross-plane bank sequence"
	)
	_expect(
		CrossPlaneV8EngineAudioSynthesizer.get_bank_event_intervals_degrees(0)
		== PackedFloat32Array([180.0, 90.0, 180.0, 270.0]),
		"right-bank exhaust cadence contains 90, 180 and 270 degree intervals"
	)
	_expect(
		CrossPlaneV8EngineAudioSynthesizer.get_bank_event_intervals_degrees(1)
		== PackedFloat32Array([270.0, 180.0, 90.0, 180.0]),
		"left-bank exhaust cadence contains the complementary cross-plane intervals"
	)


func _test_mustang_scene_contract() -> void:
	var car: PlayerCarController = MUSTANG_SCENE.instantiate() as PlayerCarController
	_expect(car != null, "the shared 1967 Shelby scene instantiates")
	if car == null:
		return
	root.add_child(car)
	await process_frame
	var audio: CrossPlaneV8EngineAudioSynthesizer = (
		car.get_node_or_null("EngineAudio") as CrossPlaneV8EngineAudioSynthesizer
	)
	_expect(audio != null, "the 1967 Shelby uses the dedicated cross-plane V8 synthesizer")
	_expect(audio == null or audio.cylinders == 8, "the dedicated synthesizer is fixed to eight cylinders")
	_expect(audio == null or audio.profile == FORD_PROFILE, "both Shelby variants retain the shared Ford 428 FE profile")
	car.queue_free()
	await process_frame


func _test_stereo_signal_character() -> void:
	var audio := CrossPlaneV8EngineAudioSynthesizer.new()
	audio.profile = FORD_PROFILE
	audio.force_full_runtime_generation = true
	root.add_child(audio)
	await process_frame

	var idle_frames: PackedVector2Array = audio.generate_test_stereo_frames(
		TEST_FRAME_COUNT,
		700.0,
		0.30,
		0.10
	)
	var load_frames: PackedVector2Array = audio.generate_test_stereo_frames(
		TEST_FRAME_COUNT,
		3200.0,
		0.90,
		0.82
	)
	var repeated_frames: PackedVector2Array = audio.generate_test_stereo_frames(
		TEST_FRAME_COUNT,
		3200.0,
		0.90,
		0.82
	)

	_expect(idle_frames.size() == TEST_FRAME_COUNT, "idle V8 synthesis returns the requested frame count")
	_expect(load_frames.size() == TEST_FRAME_COUNT, "loaded V8 synthesis returns the requested frame count")
	_expect(_all_frames_finite(idle_frames), "idle V8 synthesis remains finite")
	_expect(_all_frames_finite(load_frames), "loaded V8 synthesis remains finite")
	_expect(_peak(load_frames) <= 0.961, "loaded V8 output stays inside the synthesizer headroom")

	var idle_rms: float = _stereo_rms(idle_frames)
	var load_rms: float = _stereo_rms(load_frames)
	var difference_rms: float = _channel_difference_rms(load_frames)
	var correlation: float = _channel_correlation(load_frames)
	_expect(idle_rms > 0.005, "cross-plane idle produces an audible deterministic signal")
	_expect(load_rms > idle_rms * 1.05, "loaded Ford FE synthesis gains energy over idle")
	_expect(
		difference_rms > load_rms * 0.025,
		"separate bank pulse trains create meaningful left-right exhaust differences"
	)
	_expect(
		correlation > 0.10 and correlation < 0.999,
		"the two pipes remain related without collapsing to duplicated mono"
	)
	_expect(
		_frames_match(load_frames, repeated_frames, 0.000001),
		"cross-plane test synthesis is deterministic after a state reset"
	)

	audio.queue_free()
	await process_frame


func _all_frames_finite(frames: PackedVector2Array) -> bool:
	for frame: Vector2 in frames:
		if not is_finite(frame.x) or not is_finite(frame.y):
			return false
	return true


func _peak(frames: PackedVector2Array) -> float:
	var result: float = 0.0
	for frame: Vector2 in frames:
		result = maxf(result, maxf(absf(frame.x), absf(frame.y)))
	return result


func _stereo_rms(frames: PackedVector2Array) -> float:
	if frames.is_empty():
		return 0.0
	var energy: float = 0.0
	for frame: Vector2 in frames:
		energy += frame.x * frame.x + frame.y * frame.y
	return sqrt(energy / float(frames.size() * 2))


func _channel_difference_rms(frames: PackedVector2Array) -> float:
	if frames.is_empty():
		return 0.0
	var energy: float = 0.0
	for frame: Vector2 in frames:
		var difference: float = frame.x - frame.y
		energy += difference * difference
	return sqrt(energy / float(frames.size()))


func _channel_correlation(frames: PackedVector2Array) -> float:
	if frames.is_empty():
		return 0.0
	var dot_product: float = 0.0
	var left_energy: float = 0.0
	var right_energy: float = 0.0
	for frame: Vector2 in frames:
		dot_product += frame.x * frame.y
		left_energy += frame.x * frame.x
		right_energy += frame.y * frame.y
	var denominator: float = sqrt(left_energy * right_energy)
	return dot_product / denominator if denominator > 0.0000001 else 0.0


func _frames_match(
	left: PackedVector2Array,
	right: PackedVector2Array,
	tolerance: float
) -> bool:
	if left.size() != right.size():
		return false
	for index: int in left.size():
		if not left[index].is_equal_approx(right[index]):
			if left[index].distance_to(right[index]) > tolerance:
				return false
	return true


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CROSS_PLANE_V8_ENGINE_AUDIO_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CROSS_PLANE_V8_ENGINE_AUDIO_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CROSS_PLANE_V8_ENGINE_AUDIO_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[CROSS_PLANE_V8_ENGINE_AUDIO_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[CROSS_PLANE_V8_ENGINE_AUDIO_TEST] - %s" % failure_message)
	quit(1)
