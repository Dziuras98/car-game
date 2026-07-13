extends SceneTree

const AUDIO_PROFILE: EngineAudioProfile = preload("res://resources/audio/370z_stock_audio_profile.tres")
const AI_CAR_SCENE: PackedScene = preload("res://scenes/cars/370z_ai.tscn")
const AI_CAR_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")
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

	var startup_frames: int = maxi(roundi(MIX_RATE * STARTUP_BUFFER_SECONDS), 1)
	var steady_frames: int = maxi(roundi(MIX_RATE * STEADY_WINDOW_SECONDS), 1)
	var startup_updates: int = maxi(ceili(STARTUP_BUFFER_SECONDS * PHYSICS_FPS), 1)
	var steady_updates: int = maxi(ceili(STEADY_WINDOW_SECONDS * PHYSICS_FPS), 1)

	var player_startup: Dictionary = _benchmark_player(startup_frames)
	var player_steady: Dictionary = _benchmark_player(steady_frames)
	var ai_startup: Dictionary = _benchmark_ai(startup_updates, STARTUP_BUFFER_SECONDS)
	var ai_steady: Dictionary = _benchmark_ai(steady_updates, STEADY_WINDOW_SECONDS)
	var race_startup: Dictionary = _combine(player_startup, ai_startup, STARTUP_BUFFER_SECONDS)
	var race_steady: Dictionary = _combine(player_steady, ai_steady, STEADY_WINDOW_SECONDS)

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
	print("[ENGINE_AUDIO_FLEET_BENCHMARK] %s" % JSON.stringify(report))
	_write_report(JSON.stringify(report, "\t"))
	await _cleanup_fixture()
	_finish()


func _prepare_ai_fixture() -> void:
	for ai_index: int in range(AI_VOICE_COUNT):
		var car: PlayerCarController = AI_CAR_SCENE.instantiate() as PlayerCarController
		if car == null:
			_failures.append("could not instantiate baked AI car %d" % ai_index)
			continue
		car.name = "AudioBenchmarkAi%d" % (ai_index + 1)
		car.car_specs = AI_CAR_SPECS
		root.add_child(car)
		car.global_position = Vector3(ai_index * 4.0, 1.0, 0.0)
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
		_update_ai_players(1.0 / PHYSICS_FPS)


func _benchmark_player(frame_count: int) -> Dictionary:
	var timings: Array[int] = []
	var checksum: float = 0.0
	for _sample_index: int in range(SAMPLE_COUNT):
		var synthesizer: EngineAudioSynthesizer = EngineAudioSynthesizer.new()
		synthesizer.cylinders = 6
		if AUDIO_PROFILE == null or not AUDIO_PROFILE.apply_to(synthesizer):
			synthesizer.free()
			return {"valid": false, "reason": "profile_apply_failed"}
		synthesizer.generate_test_frames(WARMUP_FRAMES, OPERATING_RPM, OPERATING_LOAD, OPERATING_THROTTLE)
		var started_usec: int = Time.get_ticks_usec()
		var generated: PackedFloat32Array = synthesizer.generate_test_frames(
			frame_count,
			OPERATING_RPM,
			OPERATING_LOAD,
			OPERATING_THROTTLE
		)
		timings.append(Time.get_ticks_usec() - started_usec)
		var stride: int = maxi(generated.size() / 64, 1)
		for sample_index: int in range(0, generated.size(), stride):
			checksum += absf(generated[sample_index])
		synthesizer.free()
	return _timed_result(
		"ProfiledEngineAudioSynthesizer",
		1,
		_median(timings),
		float(frame_count) / MIX_RATE,
		checksum,
		{"frames": frame_count}
	)


func _benchmark_ai(updates_per_voice: int, represented_seconds: float) -> Dictionary:
	if _ai_audio_players.size() != AI_VOICE_COUNT:
		return {"valid": false, "reason": "incomplete_ai_fixture"}
	var timings: Array[int] = []
	var checksum: float = 0.0
	for _sample_index: int in range(SAMPLE_COUNT):
		var started_usec: int = Time.get_ticks_usec()
		for _repetition: int in range(AI_MEASUREMENT_REPETITIONS):
			for _update_index: int in range(updates_per_voice):
				_update_ai_players(1.0 / PHYSICS_FPS)
		var measured_usec: int = Time.get_ticks_usec() - started_usec
		timings.append(maxi(roundi(float(measured_usec) / AI_MEASUREMENT_REPETITIONS), 1))
		for audio: BakedEngineAudioPlayer in _ai_audio_players:
			checksum += audio.get_selected_anchor_rpm() + audio.get_loaded_voice_stream_count()
	return _timed_result(
		"BakedEngineAudioPlayer",
		AI_VOICE_COUNT,
		_median(timings),
		represented_seconds,
		checksum,
		{
			"updates_per_voice": updates_per_voice,
			"measurement_repetitions": AI_MEASUREMENT_REPETITIONS,
		}
	)


func _update_ai_players(delta: float) -> void:
	for audio: BakedEngineAudioPlayer in _ai_audio_players:
		audio._process(delta)


func _timed_result(
	backend: String,
	voice_count: int,
	elapsed_usec: int,
	represented_seconds: float,
	checksum: float,
	extra: Dictionary
) -> Dictionary:
	var result: Dictionary = {
		"valid": elapsed_usec > 0 and is_finite(checksum),
		"backend": backend,
		"voice_count": voice_count,
		"represented_seconds": represented_seconds,
		"elapsed_usec": elapsed_usec,
		"elapsed_ms": elapsed_usec / 1000.0,
		"main_thread_fraction": _safe_ratio(elapsed_usec, represented_seconds * 1_000_000.0),
		"sample_count": SAMPLE_COUNT,
		"checksum": checksum,
	}
	result.merge(extra, true)
	return result


func _combine(player_result: Dictionary, ai_result: Dictionary, represented_seconds: float) -> Dictionary:
	var elapsed_usec: int = int(player_result.get("elapsed_usec", 0)) + int(ai_result.get("elapsed_usec", 0))
	return {
		"valid": bool(player_result.get("valid", false)) and bool(ai_result.get("valid", false)),
		"layout": "1 procedural player + 3 baked AI",
		"represented_seconds": represented_seconds,
		"elapsed_usec": elapsed_usec,
		"elapsed_ms": elapsed_usec / 1000.0,
		"main_thread_fraction": _safe_ratio(elapsed_usec, represented_seconds * 1_000_000.0),
	}


func _median(values: Array[int]) -> int:
	values.sort()
	return values[values.size() / 2] if not values.is_empty() else 0


func _safe_ratio(numerator: float, denominator: float) -> float:
	return numerator / denominator if denominator > 0.0 else INF


func _write_report(serialized: String) -> void:
	var file: FileAccess = FileAccess.open(ProjectSettings.globalize_path(REPORT_PATH), FileAccess.WRITE)
	if file == null:
		_failures.append("could not write benchmark report: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(serialized)
	file.close()


func _cleanup_fixture() -> void:
	_ai_audio_players.clear()
	for car: PlayerCarController in _ai_cars:
		if is_instance_valid(car):
			car.free()
	_ai_cars.clear()
	ProceduralAudioPlayer3D.reset_voice_budget()
	await process_frame
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
