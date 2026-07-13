extends SceneTree

const AUDIO_PROFILE: EngineAudioProfile = preload("res://resources/audio/370z_stock_audio_profile.tres")
const AI_CAR_SCENE: PackedScene = preload("res://scenes/cars/370z_ai.tscn")
const OPERATING_RPM: float = 5200.0
const OPERATING_LOAD: float = 0.82
const OPERATING_THROTTLE: float = 0.78
const MIX_RATE: int = 32000
const PHYSICS_FPS: int = 60
const STARTUP_BUFFER_SECONDS: float = 0.09
const STEADY_WINDOW_SECONDS: float = 0.25
const AI_VOICE_COUNT: int = 3
const WARMUP_FRAMES: int = 256
const SAMPLE_COUNT: int = 3
const AI_MEASUREMENT_REPETITIONS: int = 20
const MAX_PLAYER_MAIN_THREAD_FRACTION: float = 0.80
const MAX_RACE_MAIN_THREAD_FRACTION: float = 0.85
const REPORT_PATH: String = "res://build/test-logs/engine-audio-fleet-benchmark.json"

var _ai_cars: Array[PlayerCarController] = []
var _ai_audio_players: Array[BakedEngineAudioPlayer] = []
var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _prepare_ai_fixture()
	if not _failures.is_empty():
		await _cleanup_fixture()
		_finish()
		return

	var startup_frames: int = maxi(roundi(float(MIX_RATE) * STARTUP_BUFFER_SECONDS), 1)
	var steady_frames: int = maxi(roundi(float(MIX_RATE) * STEADY_WINDOW_SECONDS), 1)
	var startup_updates: int = maxi(ceili(STARTUP_BUFFER_SECONDS * float(PHYSICS_FPS)), 1)
	var steady_updates: int = maxi(ceili(STEADY_WINDOW_SECONDS * float(PHYSICS_FPS)), 1)

	var player_startup: Dictionary = _benchmark_player_generation(startup_frames)
	var player_steady: Dictionary = _benchmark_player_generation(steady_frames)
	var ai_startup: Dictionary = _benchmark_baked_ai_runtime(startup_updates, STARTUP_BUFFER_SECONDS)
	var ai_steady: Dictionary = _benchmark_baked_ai_runtime(steady_updates, STEADY_WINDOW_SECONDS)
	var race_startup: Dictionary = _combine_race_cost(player_startup, ai_startup, STARTUP_BUFFER_SECONDS)
	var race_steady: Dictionary = _combine_race_cost(player_steady, ai_steady, STEADY_WINDOW_SECONDS)

	_expect(bool(player_startup.get("valid", false)), "procedural player startup benchmark completes")
	_expect(bool(player_steady.get("valid", false)), "procedural player steady benchmark completes")
	_expect(bool(ai_startup.get("valid", false)), "three baked AI startup updates complete")
	_expect(bool(ai_steady.get("valid", false)), "three baked AI steady updates complete")
	_expect(bool(race_startup.get("valid", false)), "production race startup benchmark completes")
	_expect(bool(race_steady.get("valid", false)), "production race steady benchmark completes")
	_expect(_ai_audio_players.size() == AI_VOICE_COUNT, "race benchmark contains exactly three AI audio players")
	for audio: BakedEngineAudioPlayer in _ai_audio_players:
		_expect(audio.is_using_baked_bank(), "AI benchmark voice uses a prepared baked bank")
		_expect(not audio.uses_audio_stream_generator(), "AI benchmark voice does not allocate a procedural generator")

	_expect(
		float(player_startup.get("main_thread_fraction", INF)) <= MAX_PLAYER_MAIN_THREAD_FRACTION,
		"procedural player startup remains inside its protected CPU budget"
	)
	_expect(
		float(player_steady.get("main_thread_fraction", INF)) <= MAX_PLAYER_MAIN_THREAD_FRACTION,
		"procedural player steady generation remains inside its protected CPU budget"
	)
	_expect(
		float(race_startup.get("main_thread_fraction", INF)) <= MAX_RACE_MAIN_THREAD_FRACTION,
		"production race startup audio remains inside its main-thread budget"
	)
	_expect(
		float(race_steady.get("main_thread_fraction", INF)) <= MAX_RACE_MAIN_THREAD_FRACTION,
		"production race steady audio remains inside its main-thread budget"
	)

	var report: Dictionary = {
		"configuration": {
			"player_backend": "ProfiledEngineAudioSynthesizer",
			"player_voice_count": 1,
			"ai_backend": "BakedEngineAudioPlayer",
			"ai_voice_count": AI_VOICE_COUNT,
			"mix_rate": MIX_RATE,
			"physics_fps": PHYSICS_FPS,
		},
		"budgets": {
			"max_player_main_thread_fraction": MAX_PLAYER_MAIN_THREAD_FRACTION,
			"max_race_main_thread_fraction": MAX_RACE_MAIN_THREAD_FRACTION,
		},
		"startup_buffer_seconds": STARTUP_BUFFER_SECONDS,
		"steady_window_seconds": STEADY_WINDOW_SECONDS,
		"player_startup": player_startup,
		"player_steady": player_steady,
		"baked_ai_startup": ai_startup,
		"baked_ai_steady": ai_steady,
		"production_race_startup": race_startup,
		"production_race_steady": race_steady,
	}

	var serialized: String = JSON.stringify(report, "\t")
	print("[ENGINE_AUDIO_FLEET_BENCHMARK] %s" % JSON.stringify(report))
	_write_report(serialized)
	await _cleanup_fixture()
	_finish()


func _prepare_ai_fixture() -> void:
	for ai_index: int in range(AI_VOICE_COUNT):
		var car: PlayerCarController = AI_CAR_SCENE.instantiate() as PlayerCarController
		if car == null:
			_failures.append("could not instantiate baked AI car %d" % ai_index)
			continue
		car.name = "AudioBenchmarkAi%d" % (ai_index + 1)
		car.global_position = Vector3(float(ai_index) * 4.0, 1.0, 0.0)
		root.add_child(car)
		_ai_cars.append(car)
	await process_frame
	await physics_frame

	for car: PlayerCarController in _ai_cars:
		car.set_process(false)
		car.set_physics_process(false)
		var audio: BakedEngineAudioPlayer = car.get_node_or_null("EngineAudio") as BakedEngineAudioPlayer
		if audio == null:
			_failures.append("AI benchmark car does not expose BakedEngineAudioPlayer")
			continue
		audio.set_process(false)
		_ai_audio_players.append(audio)

	for _warmup_index: int in range(4):
		for audio: BakedEngineAudioPlayer in _ai_audio_players:
			audio._process(1.0 / float(PHYSICS_FPS))


func _benchmark_player_generation(frames_per_sample: int) -> Dictionary:
	var elapsed_samples: Array[int] = []
	var checksum: float = 0.0
	for _sample_index: int in range(SAMPLE_COUNT):
		var synthesizer: EngineAudioSynthesizer = EngineAudioSynthesizer.new()
		synthesizer.cylinders = 6
		if AUDIO_PROFILE == null or not AUDIO_PROFILE.apply_to(synthesizer):
			synthesizer.free()
			return {"valid": false, "reason": "profile_apply_failed"}
		synthesizer.generate_test_frames(
			WARMUP_FRAMES,
			OPERATING_RPM,
			OPERATING_LOAD,
			OPERATING_THROTTLE
		)
		var started_usec: int = Time.get_ticks_usec()
		var generated: PackedFloat32Array = synthesizer.generate_test_frames(
			frames_per_sample,
			OPERATING_RPM,
			OPERATING_LOAD,
			OPERATING_THROTTLE
		)
		elapsed_samples.append(Time.get_ticks_usec() - started_usec)
		var sample_stride: int = maxi(generated.size() / 64, 1)
		for sample_index: int in range(0, generated.size(), sample_stride):
			checksum += absf(generated[sample_index])
		synthesizer.free()

	elapsed_samples.sort()
	var elapsed_usec: int = elapsed_samples[elapsed_samples.size() / 2]
	var represented_seconds: float = float(frames_per_sample) / float(MIX_RATE)
	return {
		"valid": elapsed_usec > 0 and is_finite(checksum),
		"backend": "ProfiledEngineAudioSynthesizer",
		"voice_count": 1,
		"frames": frames_per_sample,
		"represented_seconds": represented_seconds,
		"elapsed_usec": elapsed_usec,
		"elapsed_ms": float(elapsed_usec) / 1000.0,
		"main_thread_fraction": _safe_ratio(
			float(elapsed_usec),
			represented_seconds * 1_000_000.0
		),
		"sample_count": SAMPLE_COUNT,
		"checksum": checksum,
	}


func _benchmark_baked_ai_runtime(updates_per_voice: int, represented_seconds: float) -> Dictionary:
	if _ai_audio_players.size() != AI_VOICE_COUNT:
		return {"valid": false, "reason": "incomplete_ai_fixture"}
	var elapsed_samples: Array[int] = []
	var checksum: float = 0.0
	for _sample_index: int in range(SAMPLE_COUNT):
		var started_usec: int = Time.get_ticks_usec()
		for _repetition: int in range(AI_MEASUREMENT_REPETITIONS):
			for _update_index: int in range(updates_per_voice):
				for audio: BakedEngineAudioPlayer in _ai_audio_players:
					audio._process(1.0 / float(PHYSICS_FPS))
		var total_elapsed_usec: int = Time.get_ticks_usec() - started_usec
		elapsed_samples.append(maxi(roundi(float(total_elapsed_usec) / float(AI_MEASUREMENT_REPETITIONS)), 1))
		for audio: BakedEngineAudioPlayer in _ai_audio_players:
			checksum += audio.get_selected_anchor_rpm() + float(audio.get_loaded_voice_stream_count())

	elapsed_samples.sort()
	var elapsed_usec: int = elapsed_samples[elapsed_samples.size() / 2]
	return {
		"valid": elapsed_usec > 0 and is_finite(checksum),
		"backend": "BakedEngineAudioPlayer",
		"voice_count": AI_VOICE_COUNT,
		"updates_per_voice": updates_per_voice,
		"represented_seconds": represented_seconds,
		"elapsed_usec": elapsed_usec,
		"elapsed_ms": float(elapsed_usec) / 1000.0,
		"main_thread_fraction": _safe_ratio(
			float(elapsed_usec),
			represented_seconds * 1_000_000.0
		),
		"sample_count": SAMPLE_COUNT,
		"measurement_repetitions": AI_MEASUREMENT_REPETITIONS,
		"checksum": checksum,
	}


func _combine_race_cost(
	player_result: Dictionary,
	ai_result: Dictionary,
	represented_seconds: float
) -> Dictionary:
	var elapsed_usec: int = int(player_result.get("elapsed_usec", 0)) + int(ai_result.get("elapsed_usec", 0))
	return {
		"valid": bool(player_result.get("valid", false)) and bool(ai_result.get("valid", false)),
		"layout": "1 procedural player + 3 baked AI",
		"represented_seconds": represented_seconds,
		"elapsed_usec": elapsed_usec,
		"elapsed_ms": float(elapsed_usec) / 1000.0,
		"main_thread_fraction": _safe_ratio(
			float(elapsed_usec),
			represented_seconds * 1_000_000.0
		),
	}


func _safe_ratio(numerator: float, denominator: float) -> float:
	if denominator <= 0.0:
		return INF
	return numerator / denominator


func _write_report(serialized: String) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(REPORT_PATH)
	var file: FileAccess = FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not write benchmark report: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(serialized)
	file.close()


func _cleanup_fixture() -> void:
	for car: PlayerCarController in _ai_cars:
		if is_instance_valid(car):
			car.queue_free()
	_ai_audio_players.clear()
	_ai_cars.clear()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[ENGINE_AUDIO_FLEET_BENCHMARK][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[ENGINE_AUDIO_FLEET_BENCHMARK][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ENGINE_AUDIO_FLEET_BENCHMARK] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[ENGINE_AUDIO_FLEET_BENCHMARK] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[ENGINE_AUDIO_FLEET_BENCHMARK] - %s" % failure_message)
	quit(1)
