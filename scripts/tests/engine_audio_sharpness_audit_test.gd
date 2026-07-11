extends SceneTree

const FRAME_COUNT: int = 32768
const ANALYSIS_START: int = 8192
const SAMPLE_RATE: float = 32000.0
const SILENCE_FLOOR: float = 0.000000001

const PRODUCTION_PROFILE: Dictionary = {
	"output_volume_boost_db": 9.0,
	"idle_volume_db": -10.0,
	"load_volume_db": 0.0,
	"exhaust_roughness": 0.16,
	"intake_presence": 0.20,
	"exhaust_resonance": 0.52,
	"mechanical_noise": 0.045,
	"overrun_crackle": 0.10,
	"high_rpm_rasp": 0.12,
	"exhaust_bank_separation": 0.30,
	"exhaust_reflection": 0.12,
	"intake_plenum_detail": 0.16,
	"airflow_noise": 0.08,
	"rotating_assembly_detail": 0.04,
}

const OPERATING_POINTS: Array[Dictionary] = [
	{"name": "idle", "rpm": 700.0, "load": 0.0, "throttle": 0.0},
	{"name": "engine_braking", "rpm": 3000.0, "load": 0.0, "throttle": 0.0},
	{"name": "cruise", "rpm": 3000.0, "load": 0.45, "throttle": 0.40},
	{"name": "mid_load", "rpm": 4500.0, "load": 0.78, "throttle": 0.72},
	{"name": "high_load", "rpm": 6500.0, "load": 1.0, "throttle": 1.0},
	{"name": "limiter", "rpm": 7600.0, "load": 1.0, "throttle": 1.0},
]


func _initialize() -> void:
	for point: Dictionary in OPERATING_POINTS:
		_report(point)
	quit(0)


func _report(point: Dictionary) -> void:
	var synthesizer := EngineAudioSynthesizer.new()
	for property_name: String in PRODUCTION_PROFILE:
		synthesizer.set(StringName(property_name), PRODUCTION_PROFILE[property_name])
	var frames: PackedFloat32Array = synthesizer.generate_test_frames(
		FRAME_COUNT,
		float(point.rpm),
		float(point.load),
		float(point.throttle)
	)
	var rms: float = _rms(frames)
	var peak: float = _peak(frames)
	var difference_rms: float = _difference_rms(frames)
	var high_ratio: float = _high_band_energy_ratio(frames)
	var loudness: float = clampf(float(point.load) * 0.90 + float(point.throttle) * 0.26, 0.0, 1.0)
	var player_db: float = lerpf(
		float(PRODUCTION_PROFILE.idle_volume_db),
		float(PRODUCTION_PROFILE.load_volume_db),
		loudness
	) + float(PRODUCTION_PROFILE.output_volume_boost_db)
	var projected_peak: float = peak * db_to_linear(player_db)
	print(
		"[ENGINE_AUDIO_SHARPNESS_AUDIT] point=%s rms_dbfs=%.2f peak_dbfs=%.2f crest_db=%.2f difference_ratio=%.3f high_energy_pct=%.1f player_db=%.2f projected_peak_dbfs=%.2f" % [
			String(point.name),
			_to_dbfs(rms),
			_to_dbfs(peak),
			linear_to_db(maxf(peak, SILENCE_FLOOR) / maxf(rms, SILENCE_FLOOR)),
			difference_rms / maxf(rms, SILENCE_FLOOR),
			high_ratio * 100.0,
			player_db,
			_to_dbfs(projected_peak),
		]
	)
	synthesizer.free()


func _rms(frames: PackedFloat32Array) -> float:
	var sum_squares: float = 0.0
	for index: int in range(ANALYSIS_START, frames.size()):
		var sample: float = frames[index]
		sum_squares += sample * sample
	return sqrt(sum_squares / float(maxi(frames.size() - ANALYSIS_START, 1)))


func _peak(frames: PackedFloat32Array) -> float:
	var result: float = 0.0
	for index: int in range(ANALYSIS_START, frames.size()):
		result = maxf(result, absf(frames[index]))
	return result


func _difference_rms(frames: PackedFloat32Array) -> float:
	var sum_squares: float = 0.0
	var previous: float = frames[ANALYSIS_START]
	for index: int in range(ANALYSIS_START + 1, frames.size()):
		var difference: float = frames[index] - previous
		sum_squares += difference * difference
		previous = frames[index]
	return sqrt(sum_squares / float(maxi(frames.size() - ANALYSIS_START - 1, 1)))


func _high_band_energy_ratio(frames: PackedFloat32Array) -> float:
	var low_pass: float = 0.0
	var coefficient: float = 1.0 - exp(-TAU * 2200.0 / SAMPLE_RATE)
	var high_energy: float = 0.0
	var total_energy: float = 0.0
	for index: int in frames.size():
		var sample: float = frames[index]
		low_pass += coefficient * (sample - low_pass)
		if index < ANALYSIS_START:
			continue
		var high: float = sample - low_pass
		high_energy += high * high
		total_energy += sample * sample
	return high_energy / maxf(total_energy, SILENCE_FLOOR)


func _to_dbfs(value: float) -> float:
	return linear_to_db(maxf(absf(value), SILENCE_FLOOR))
