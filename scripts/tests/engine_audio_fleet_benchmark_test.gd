extends SceneTree

const AUDIO_PROFILE: EngineAudioProfile = preload("res://resources/audio/370z_stock_audio_profile.tres")
const OPERATING_RPM: float = 5200.0
const OPERATING_LOAD: float = 0.82
const OPERATING_THROTTLE: float = 0.78
const MIX_RATE: int = 32000
const STARTUP_BUFFER_SECONDS: float = 0.09
const STEADY_WINDOW_SECONDS: float = 0.25
const PLAYER_VOICE_COUNT: int = 1
const RACE_VOICE_COUNT: int = 4
const WARMUP_FRAMES: int = 256
const REPORT_PATH: String = "res://build/test-logs/engine-audio-fleet-benchmark.json"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var startup_frames: int = maxi(roundi(float(MIX_RATE) * STARTUP_BUFFER_SECONDS), 1)
	var steady_frames: int = maxi(roundi(float(MIX_RATE) * STEADY_WINDOW_SECONDS), 1)

	var startup_single: Dictionary = _benchmark_generation(PLAYER_VOICE_COUNT, startup_frames)
	var startup_race: Dictionary = _benchmark_generation(RACE_VOICE_COUNT, startup_frames)
	var steady_single: Dictionary = _benchmark_generation(PLAYER_VOICE_COUNT, steady_frames)
	var steady_race: Dictionary = _benchmark_generation(RACE_VOICE_COUNT, steady_frames)

	_expect(bool(startup_single.get("valid", false)), "single-voice startup benchmark completes")
	_expect(bool(startup_race.get("valid", false)), "four-voice startup benchmark completes")
	_expect(bool(steady_single.get("valid", false)), "single-voice steady benchmark completes")
	_expect(bool(steady_race.get("valid", false)), "four-voice steady benchmark completes")

	var report: Dictionary = {
		"mix_rate": MIX_RATE,
		"startup_buffer_seconds": STARTUP_BUFFER_SECONDS,
		"steady_window_seconds": STEADY_WINDOW_SECONDS,
		"single_voice_startup": startup_single,
		"four_voice_startup": startup_race,
		"single_voice_steady": steady_single,
		"four_voice_steady": steady_race,
		"startup_four_to_one_ratio": _safe_ratio(
			float(startup_race.get("elapsed_usec", 0.0)),
			float(startup_single.get("elapsed_usec", 0.0))
		),
		"steady_four_to_one_ratio": _safe_ratio(
			float(steady_race.get("elapsed_usec", 0.0)),
			float(steady_single.get("elapsed_usec", 0.0))
		),
		"startup_main_thread_fraction": _safe_ratio(
			float(startup_race.get("elapsed_usec", 0.0)),
			STARTUP_BUFFER_SECONDS * 1_000_000.0
		),
		"steady_main_thread_fraction": _safe_ratio(
			float(steady_race.get("elapsed_usec", 0.0)),
			STEADY_WINDOW_SECONDS * 1_000_000.0
		),
	}

	var serialized: String = JSON.stringify(report, "\t")
	print("[ENGINE_AUDIO_FLEET_BENCHMARK] %s" % JSON.stringify(report))
	_write_report(serialized)
	_finish()


func _benchmark_generation(voice_count: int, frames_per_voice: int) -> Dictionary:
	var synthesizers: Array[EngineAudioSynthesizer] = []
	for _voice_index: int in range(voice_count):
		var synthesizer: EngineAudioSynthesizer = EngineAudioSynthesizer.new()
		synthesizer.cylinders = 6
		if AUDIO_PROFILE == null or not AUDIO_PROFILE.apply_to(synthesizer):
			for prepared: EngineAudioSynthesizer in synthesizers:
				prepared.free()
			synthesizer.free()
			return {"valid": false, "reason": "profile_apply_failed"}
		synthesizer.generate_test_frames(
			WARMUP_FRAMES,
			OPERATING_RPM,
			OPERATING_LOAD,
			OPERATING_THROTTLE
		)
		synthesizers.append(synthesizer)

	var checksum: float = 0.0
	var started_usec: int = Time.get_ticks_usec()
	for synthesizer: EngineAudioSynthesizer in synthesizers:
		var generated: PackedFloat32Array = synthesizer.generate_test_frames(
			frames_per_voice,
			OPERATING_RPM,
			OPERATING_LOAD,
			OPERATING_THROTTLE
		)
		var sample_stride: int = maxi(generated.size() / 64, 1)
		for sample_index: int in range(0, generated.size(), sample_stride):
			checksum += absf(generated[sample_index])
	var elapsed_usec: int = Time.get_ticks_usec() - started_usec

	for synthesizer: EngineAudioSynthesizer in synthesizers:
		synthesizer.free()

	var represented_seconds: float = float(frames_per_voice) / float(MIX_RATE)
	return {
		"valid": elapsed_usec > 0 and is_finite(checksum),
		"voice_count": voice_count,
		"frames_per_voice": frames_per_voice,
		"represented_seconds_per_voice": represented_seconds,
		"aggregate_generated_frames": frames_per_voice * voice_count,
		"elapsed_usec": elapsed_usec,
		"elapsed_ms": float(elapsed_usec) / 1000.0,
		"main_thread_fraction": _safe_ratio(
			float(elapsed_usec),
			represented_seconds * 1_000_000.0
		),
		"checksum": checksum,
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
