extends SceneTree

const AUTOMATIC_CAR_SCENE: PackedScene = preload("res://scenes/cars/370zat.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var test_root: Node3D = Node3D.new()
	test_root.name = "TireSquealAudioBindingTestRoot"
	get_root().add_child(test_root)

	var car: PlayerCarController = AUTOMATIC_CAR_SCENE.instantiate() as PlayerCarController
	_expect(car != null, "automatic 370Z scene instantiates as PlayerCarController")
	if car == null:
		test_root.queue_free()
		_finish()
		return

	test_root.add_child(car)
	await process_frame
	await process_frame

	var tire_audio: AudioStreamPlayer3D = car.get_node_or_null("TireSquealAudio") as AudioStreamPlayer3D
	_expect(tire_audio != null, "automatic 370Z contains tire squeal audio")
	_expect(car.car_specs != null, "automatic 370Z provides CarSpecs")

	if tire_audio != null and car.car_specs != null:
		var reference_speed: Variant = tire_audio.call("_get_reference_speed")
		_expect(reference_speed is float, "tire audio exposes a numeric reference speed")
		if reference_speed is float:
			_expect(
				is_equal_approx(float(reference_speed), car.car_specs.max_forward_speed),
				"tire audio reference speed comes from the selected car specs"
			)

		tire_audio.set("_smoothed_slip", 0.85)
		for sample_index: int in range(32):
			var sample: Variant = tire_audio.call("_generate_sample")
			_expect(sample is float, "generated tire squeal sample is numeric")
			if sample is float:
				_expect(is_finite(float(sample)), "generated tire squeal sample is finite")
				_expect(absf(float(sample)) <= 0.8501, "generated tire squeal sample stays in range")

	test_root.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TIRE_SQUEAL_AUDIO_TEST][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[TIRE_SQUEAL_AUDIO_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TIRE_SQUEAL_AUDIO_TEST] Passed: %d checks" % _checks)
		quit(0)
		return

	push_error(
		"[TIRE_SQUEAL_AUDIO_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[TIRE_SQUEAL_AUDIO_TEST] - %s" % failure_message)
	quit(1)
