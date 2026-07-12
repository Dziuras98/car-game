extends SceneTree

const FRAME_COUNT: int = 16384
const ANALYSIS_START: int = 4096
const MIX_RATE: float = 32000.0
const STANDARD_PROFILE_PATH: String = "res://resources/audio/370z_stock_audio_profile.tres"
const NISMO_PROFILE_PATH: String = "res://resources/audio/370z_nismo_audio_profile.tres"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var standard_profile := load(STANDARD_PROFILE_PATH) as EngineAudioProfile
	var nismo_profile := load(NISMO_PROFILE_PATH) as EngineAudioProfile
	_expect(standard_profile != null, "the standard 370Z audio profile loads as typed data")
	_expect(nismo_profile != null, "the NISMO audio profile loads as typed data")
	if standard_profile == null or nismo_profile == null:
		_finish()
		return

	var standard_audio := EngineAudioSynthesizer.new()
	var nismo_audio := EngineAudioSynthesizer.new()
	standard_profile.apply_to(standard_audio)
	nismo_profile.apply_to(nismo_audio)

	_expect(nismo_audio.intake_presence > standard_audio.intake_presence, "the NISMO profile has stronger induction presence")
	_expect(nismo_audio.exhaust_resonance > standard_audio.exhaust_resonance, "the NISMO profile has fuller exhaust resonance")
	_expect(nismo_audio.exhaust_bank_separation > standard_audio.exhaust_bank_separation, "the NISMO profile has stronger bank separation")
	_expect(nismo_audio.limiter_residual_combustion > standard_audio.limiter_residual_combustion, "the NISMO limiter retains more residual combustion")

	var operating_points: Array[Dictionary] = [
		{"name": "idle", "rpm": 850.0, "load": 0.08, "throttle": 0.04},
		{"name": "part_load", "rpm": 3500.0, "load": 0.55, "throttle": 0.55},
		{"name": "high_load", "rpm": 6500.0, "load": 1.0, "throttle": 1.0},
		{"name": "overrun", "rpm": 4200.0, "load": 0.18, "throttle": 0.0},
		{"name": "limiter", "rpm": 7550.0, "load": 1.0, "throttle": 1.0},
	]

	var materially_different_points: int = 0
	for point: Dictionary in operating_points:
		var standard_frames: PackedFloat32Array = standard_audio.generate_test_frames(
			FRAME_COUNT, float(point.rpm), float(point.load), float(point.throttle)
		)
		var nismo_frames: PackedFloat32Array = nismo_audio.generate_test_frames(
			FRAME_COUNT, float(point.rpm), float(point.load), float(point.throttle)
		)
		var label: String = str(point.name)
		_expect(_all_finite(standard_frames), "%s standard signal remains finite" % label)
		_expect(_all_finite(nismo_frames), "%s NISMO signal remains finite" % label)
		_expect(_max_abs(standard_frames) <= 1.0001, "%s standard signal stays inside normalized bounds" % label)
		_expect(_max_abs(nismo_frames) <= 1.0001, "%s NISMO signal stays inside normalized bounds" % label)

		var standard_rms: float = _rms(standard_frames)
		var nismo_rms: float = _rms(nismo_frames)
		var standard_crest: float = _crest_factor(standard_frames)
		var nismo_crest: float = _crest_factor(nismo_frames)
		_expect(standard_rms > 0.0005, "%s standard signal remains audible" % label)
		_expect(nismo_rms > 0.0005, "%s NISMO signal remains audible" % label)
		_expect(nismo_rms > standard_rms * 0.45 and nismo_rms < standard_rms * 1.65, "%s NISMO loudness stays within a controlled range" % label)
		_expect(standard_crest > 1.0 and standard_crest < 12.0, "%s standard crest factor remains plausible" % label)
		_expect(nismo_crest > 1.0 and nismo_crest < 12.0, "%s NISMO crest factor remains plausible" % label)

		var firing_frequency: float = EngineAudioSynthesizer.firing_frequency_hz(float(point.rpm), 6)
		var standard_fundamental: float = _goertzel_energy(standard_frames, firing_frequency)
		var nismo_fundamental: float = _goertzel_energy(nismo_frames, firing_frequency)
		var standard_upper: float = _goertzel_energy(standard_frames, firing_frequency * 4.0)
		var nismo_upper: float = _goertzel_energy(nismo_frames, firing_frequency * 4.0)
		_expect(standard_fundamental > 0.0 and nismo_fundamental > 0.0, "%s preserves the V6 firing fundamental" % label)
		if absf(nismo_rms - standard_rms) > 0.0005 or absf(nismo_upper - standard_upper) > maxf(standard_upper, 0.000001) * 0.08:
			materially_different_points += 1
		print("[370Z_NISMO_AUDIO_PROFILE_TEST] %s standard_rms=%.7f nismo_rms=%.7f standard_crest=%.3f nismo_crest=%.3f standard_h4=%.8f nismo_h4=%.8f" % [label, standard_rms, nismo_rms, standard_crest, nismo_crest, standard_upper, nismo_upper])

	_expect(materially_different_points >= 3, "the NISMO profile is measurably distinct in multiple operating states")
	standard_audio.free()
	nismo_audio.free()
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


func _crest_factor(samples: PackedFloat32Array) -> float:
	var rms_value: float = _rms(samples)
	if rms_value <= 0.000001:
		return 0.0
	return _max_abs(samples) / rms_value


func _goertzel_energy(samples: PackedFloat32Array, frequency: float) -> float:
	if samples.size() <= ANALYSIS_START or frequency <= 0.0 or frequency >= MIX_RATE * 0.5:
		return 0.0
	var omega: float = TAU * frequency / MIX_RATE
	var coefficient: float = 2.0 * cos(omega)
	var previous: float = 0.0
	var previous_two: float = 0.0
	for index: int in range(ANALYSIS_START, samples.size()):
		var current: float = samples[index] + coefficient * previous - previous_two
		previous_two = previous
		previous = current
	return maxf(previous_two * previous_two + previous * previous - coefficient * previous * previous_two, 0.0) / float(samples.size() - ANALYSIS_START)


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
