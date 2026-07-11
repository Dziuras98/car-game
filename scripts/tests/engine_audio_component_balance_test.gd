extends SceneTree

const FRAME_COUNT: int = 16384
const ANALYSIS_START: int = 4096
const SAMPLE_RATE: float = 32000.0
const SILENCE_FLOOR: float = 0.000000001

const OPERATING_POINTS: Array[Dictionary] = [
	{"name": "idle", "rpm": 700.0, "load": 0.05, "throttle": 0.04},
	{"name": "cruise", "rpm": 2500.0, "load": 0.32, "throttle": 0.24},
	{"name": "mid_load", "rpm": 4500.0, "load": 0.78, "throttle": 0.72},
	{"name": "high_load", "rpm": 6500.0, "load": 1.0, "throttle": 1.0},
]

const ABLATIONS: Array[Dictionary] = [
	{"name": "intake_total", "values": {"intake_presence": 0.0}},
	{"name": "rasp", "values": {"high_rpm_rasp": 0.0}},
	{"name": "mechanical", "values": {"mechanical_noise": 0.0}},
	{"name": "overrun", "values": {"overrun_crackle": 0.0}},
	{"name": "bank_separation", "values": {"exhaust_bank_separation": 0.0}},
	{"name": "exhaust_reflection", "values": {"exhaust_reflection": 0.0}},
	{"name": "intake_plenum", "values": {"intake_plenum_detail": 0.0}},
	{"name": "airflow", "values": {"airflow_noise": 0.0}},
	{"name": "rotating_detail", "values": {"rotating_assembly_detail": 0.0}},
	{"name": "exhaust_resonance_control", "values": {"exhaust_resonance": 0.0}},
	{"name": "exhaust_roughness_control", "values": {"exhaust_roughness": 0.0}},
]


func _initialize() -> void:
	for point: Dictionary in OPERATING_POINTS:
		_report_operating_point(point)
	quit(0)


func _report_operating_point(point: Dictionary) -> void:
	var full_frames: PackedFloat32Array = _render(point, {})
	var full_rms: float = _rms(full_frames)
	var peak: float = _peak(full_frames)
	var bands: Dictionary = _band_levels(full_frames)
	print(
		"[ENGINE_AUDIO_COMPONENT_AUDIT] point=%s total_rms=%.7f total_dbfs=%.2f peak=%.7f peak_dbfs=%.2f low_dbfs=%.2f mid_dbfs=%.2f high_dbfs=%.2f low_energy_pct=%.1f mid_energy_pct=%.1f high_energy_pct=%.1f" % [
			String(point.name),
			full_rms,
			_to_dbfs(full_rms),
			peak,
			_to_dbfs(peak),
			float(bands.low_dbfs),
			float(bands.mid_dbfs),
			float(bands.high_dbfs),
			float(bands.low_energy_pct),
			float(bands.mid_energy_pct),
			float(bands.high_energy_pct),
		]
	)

	for ablation: Dictionary in ABLATIONS:
		var ablated_frames: PackedFloat32Array = _render(point, ablation.values)
		var ablated_rms: float = _rms(ablated_frames)
		var marginal_rms: float = _difference_rms(full_frames, ablated_frames)
		print(
			"[ENGINE_AUDIO_COMPONENT_LEVEL] point=%s component=%s marginal_rms=%.7f marginal_db_relative=%.2f output_change_db=%.2f ablated_rms=%.7f" % [
				String(point.name),
				String(ablation.name),
				marginal_rms,
				linear_to_db(maxf(marginal_rms, SILENCE_FLOOR) / maxf(full_rms, SILENCE_FLOOR)),
				linear_to_db(maxf(ablated_rms, SILENCE_FLOOR) / maxf(full_rms, SILENCE_FLOOR)),
				ablated_rms,
			]
		)


func _render(point: Dictionary, overrides: Dictionary) -> PackedFloat32Array:
	var synthesizer := EngineAudioSynthesizer.new()
	for property_name: String in overrides:
		synthesizer.set(StringName(property_name), overrides[property_name])
	var frames: PackedFloat32Array = synthesizer.generate_test_frames(
		FRAME_COUNT,
		float(point.rpm),
		float(point.load),
		float(point.throttle)
	)
	synthesizer.free()
	return frames


func _rms(frames: PackedFloat32Array) -> float:
	if frames.size() <= ANALYSIS_START:
		return 0.0
	var sum_squares: float = 0.0
	var sample_count: int = frames.size() - ANALYSIS_START
	for index: int in range(ANALYSIS_START, frames.size()):
		var sample: float = frames[index]
		sum_squares += sample * sample
	return sqrt(sum_squares / float(sample_count))


func _peak(frames: PackedFloat32Array) -> float:
	var peak: float = 0.0
	for index: int in range(mini(ANALYSIS_START, frames.size()), frames.size()):
		peak = maxf(peak, absf(frames[index]))
	return peak


func _difference_rms(left: PackedFloat32Array, right: PackedFloat32Array) -> float:
	var frame_count: int = mini(left.size(), right.size())
	if frame_count <= ANALYSIS_START:
		return 0.0
	var sum_squares: float = 0.0
	for index: int in range(ANALYSIS_START, frame_count):
		var difference: float = left[index] - right[index]
		sum_squares += difference * difference
	return sqrt(sum_squares / float(frame_count - ANALYSIS_START))


func _band_levels(frames: PackedFloat32Array) -> Dictionary:
	var low_state: float = 0.0
	var mid_state: float = 0.0
	var low_sum: float = 0.0
	var mid_sum: float = 0.0
	var high_sum: float = 0.0
	var low_coefficient: float = 1.0 - exp(-TAU * 400.0 / SAMPLE_RATE)
	var mid_coefficient: float = 1.0 - exp(-TAU * 1800.0 / SAMPLE_RATE)
	var measured_samples: int = 0
	for index: int in frames.size():
		var sample: float = frames[index]
		low_state += low_coefficient * (sample - low_state)
		mid_state += mid_coefficient * (sample - mid_state)
		if index < ANALYSIS_START:
			continue
		var low_sample: float = low_state
		var mid_sample: float = mid_state - low_state
		var high_sample: float = sample - mid_state
		low_sum += low_sample * low_sample
		mid_sum += mid_sample * mid_sample
		high_sum += high_sample * high_sample
		measured_samples += 1
	var divisor: float = float(maxi(measured_samples, 1))
	var low_rms: float = sqrt(low_sum / divisor)
	var mid_rms: float = sqrt(mid_sum / divisor)
	var high_rms: float = sqrt(high_sum / divisor)
	var total_energy: float = maxf(low_rms * low_rms + mid_rms * mid_rms + high_rms * high_rms, SILENCE_FLOOR)
	return {
		"low_dbfs": _to_dbfs(low_rms),
		"mid_dbfs": _to_dbfs(mid_rms),
		"high_dbfs": _to_dbfs(high_rms),
		"low_energy_pct": low_rms * low_rms / total_energy * 100.0,
		"mid_energy_pct": mid_rms * mid_rms / total_energy * 100.0,
		"high_energy_pct": high_rms * high_rms / total_energy * 100.0,
	}


func _to_dbfs(value: float) -> float:
	return linear_to_db(maxf(absf(value), SILENCE_FLOOR))
