extends RefCounted
class_name EngineAudioBankBaker

const SAMPLE_RATE: int = 32000
const WARMUP_SECONDS: float = 0.50
const LOOP_SECONDS: float = 1.00
const BOUNDARY_CORRECTION_SECONDS: float = 0.025
const RPM_POINTS: Array[int] = [700, 1200, 2000, 3000, 4000, 5000, 6000, 7000, 7600]
const LAYER_NAMES: Array[String] = ["coast", "load"]
const LAYER_LOADS: Array[float] = [0.08, 0.95]
const LAYER_THROTTLES: Array[float] = [0.02, 0.92]


func bake_profile(
	profile: EngineAudioProfile,
	output_directory: String,
	bank_id: String
) -> Dictionary:
	if profile == null or not profile.is_valid() or bank_id.is_empty():
		push_error("EngineAudioBankBaker requires a valid profile and non-empty bank ID.")
		return {}

	var absolute_output_directory: String = ProjectSettings.globalize_path(output_directory)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_output_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("Could not create engine-audio bake directory: %s" % output_directory)
		return {}

	var synthesizer: EngineAudioSynthesizer = EngineAudioSynthesizer.new()
	synthesizer.mix_rate = SAMPLE_RATE
	if not profile.apply_to(synthesizer):
		synthesizer.free()
		return {}

	var manifest: Dictionary = {
		"bank_id": bank_id,
		"sample_rate": SAMPLE_RATE,
		"loop_seconds": LOOP_SECONDS,
		"sample_rpms": RPM_POINTS.duplicate(),
		"idle_volume_db": profile.idle_volume_db,
		"load_volume_db": profile.load_volume_db,
		"output_volume_boost_db": profile.output_volume_boost_db,
		"layers": {},
	}
	var layer_files: Dictionary = {}
	for layer_index: int in range(LAYER_NAMES.size()):
		var layer_name: String = LAYER_NAMES[layer_index]
		var files: Array[String] = []
		for rpm: int in RPM_POINTS:
			var file_name: String = "%s_%04d.wav" % [layer_name, rpm]
			var resource_path: String = output_directory.path_join(file_name)
			var samples: PackedFloat32Array = _render_loop(
				synthesizer,
				float(rpm),
				LAYER_LOADS[layer_index],
				LAYER_THROTTLES[layer_index]
			)
			if samples.is_empty() or not _write_pcm16_mono_wav(resource_path, samples):
				synthesizer.free()
				return {}
			files.append(file_name)
		layer_files[layer_name] = files
	manifest["layers"] = layer_files

	var manifest_path: String = output_directory.path_join("bank_manifest.json")
	var manifest_file: FileAccess = FileAccess.open(manifest_path, FileAccess.WRITE)
	if manifest_file == null:
		push_error("Could not write engine-audio manifest: %s" % manifest_path)
		synthesizer.free()
		return {}
	manifest_file.store_string(JSON.stringify(manifest, "\t"))
	manifest_file.close()
	synthesizer.free()
	return manifest


func _render_loop(
	synthesizer: EngineAudioSynthesizer,
	rpm: float,
	load: float,
	throttle: float
) -> PackedFloat32Array:
	var warmup_frame_count: int = roundi(float(SAMPLE_RATE) * WARMUP_SECONDS)
	var loop_frame_count: int = roundi(float(SAMPLE_RATE) * LOOP_SECONDS)
	var generated: PackedFloat32Array = synthesizer.generate_test_frames(
		warmup_frame_count + loop_frame_count,
		rpm,
		load,
		throttle
	)
	if generated.size() < warmup_frame_count + loop_frame_count:
		return PackedFloat32Array()

	var loop_samples: PackedFloat32Array = PackedFloat32Array()
	loop_samples.resize(loop_frame_count)
	for frame_index: int in range(loop_frame_count):
		loop_samples[frame_index] = generated[warmup_frame_count + frame_index]
	_close_loop_boundary(loop_samples)
	return loop_samples


func _close_loop_boundary(samples: PackedFloat32Array) -> void:
	if samples.size() < 4:
		return
	var correction_frame_count: int = clampi(
		roundi(float(SAMPLE_RATE) * BOUNDARY_CORRECTION_SECONDS),
		2,
		samples.size() / 4
	)
	var endpoint_offset: float = samples[0] - samples[samples.size() - 1]
	for offset_index: int in range(correction_frame_count):
		var ratio: float = float(offset_index + 1) / float(correction_frame_count)
		var smooth_ratio: float = ratio * ratio * (3.0 - 2.0 * ratio)
		var sample_index: int = samples.size() - correction_frame_count + offset_index
		samples[sample_index] += endpoint_offset * smooth_ratio


func _write_pcm16_mono_wav(resource_path: String, samples: PackedFloat32Array) -> bool:
	var file: FileAccess = FileAccess.open(resource_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not create baked engine-audio WAV: %s" % resource_path)
		return false
	file.big_endian = false

	var bytes_per_sample: int = 2
	var data_size: int = samples.size() * bytes_per_sample
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + data_size)
	file.store_buffer("WAVE".to_ascii_buffer())
	file.store_buffer("fmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(SAMPLE_RATE)
	file.store_32(SAMPLE_RATE * bytes_per_sample)
	file.store_16(bytes_per_sample)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(data_size)
	for sample: float in samples:
		var pcm_value: int = clampi(roundi(sample * 32767.0), -32768, 32767)
		file.store_16(pcm_value & 0xffff)
	file.close()
	return true
