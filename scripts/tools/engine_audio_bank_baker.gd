extends RefCounted
class_name EngineAudioBankBaker

const LAYER_NAMES: Array[String] = ["coast", "load"]


func bake(preset: EngineAudioBakePreset) -> Dictionary:
	if preset == null:
		push_error("EngineAudioBankBaker requires an EngineAudioBakePreset.")
		return {}
	var validation_errors: PackedStringArray = preset.validate()
	if not validation_errors.is_empty():
		push_error("Invalid engine-audio bake preset: %s" % "; ".join(validation_errors))
		return {}

	var absolute_output_directory: String = ProjectSettings.globalize_path(preset.output_directory)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_output_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("Could not create engine-audio bake directory: %s" % preset.output_directory)
		return {}

	var synthesizer: Object = preset.synthesizer_script.new()
	if synthesizer == null or not synthesizer.has_method("generate_test_frames"):
		push_error("The configured synthesizer must expose generate_test_frames().")
		_dispose_synthesizer(synthesizer)
		return {}
	if _has_property(synthesizer, &"mix_rate"):
		synthesizer.set("mix_rate", preset.sample_rate)
	if not bool(preset.profile.call("apply_to", synthesizer)):
		_dispose_synthesizer(synthesizer)
		return {}

	_remove_previous_generated_files(preset.output_directory)
	var layer_files: Dictionary = {}
	for layer_name: String in LAYER_NAMES:
		var files: Array[String] = []
		var operating_point: Vector2 = _get_layer_operating_point(preset, layer_name)
		for rpm: int in preset.sample_rpms:
			var file_name: String = "%s_%04d.wav" % [layer_name, rpm]
			var resource_path: String = preset.output_directory.path_join(file_name)
			var samples: PackedFloat32Array = _render_loop(
				synthesizer,
				preset,
				float(rpm),
				operating_point.x,
				operating_point.y
			)
			if samples.is_empty() or not _write_pcm16_mono_wav(resource_path, samples, preset.sample_rate):
				_dispose_synthesizer(synthesizer)
				return {}
			files.append(file_name)
		layer_files[layer_name] = files

	var sample_rpm_values: Array[int] = []
	for rpm: int in preset.sample_rpms:
		sample_rpm_values.append(rpm)
	var manifest: Dictionary = {
		"bank_id": preset.bank_id,
		"sample_rate": preset.sample_rate,
		"loop_seconds": preset.loop_seconds,
		"sample_rpms": sample_rpm_values,
		"idle_volume_db": float(preset.profile.get("idle_volume_db")),
		"load_volume_db": float(preset.profile.get("load_volume_db")),
		"output_volume_boost_db": float(preset.profile.get("output_volume_boost_db")),
		"startup_duration": float(preset.profile.get("starter_duration")),
		"shutdown_duration": float(preset.profile.get("shutdown_duration")),
		"layers": layer_files,
	}
	var success: bool = (
		_write_manifest(preset.output_directory.path_join("bank_manifest.json"), manifest)
		and _write_bank_resource(preset, manifest)
	)
	_dispose_synthesizer(synthesizer)
	return manifest if success else {}


func _render_loop(
	synthesizer: Object,
	preset: EngineAudioBakePreset,
	rpm: float,
	load_value: float,
	throttle: float
) -> PackedFloat32Array:
	var warmup_frame_count: int = roundi(float(preset.sample_rate) * preset.warmup_seconds)
	var loop_frame_count: int = roundi(float(preset.sample_rate) * preset.loop_seconds)
	var generated: PackedFloat32Array = synthesizer.call(
		"generate_test_frames",
		warmup_frame_count + loop_frame_count,
		rpm,
		load_value,
		throttle
	)
	if generated.size() < warmup_frame_count + loop_frame_count:
		return PackedFloat32Array()

	var loop_samples: PackedFloat32Array = PackedFloat32Array()
	loop_samples.resize(loop_frame_count)
	for frame_index: int in range(loop_frame_count):
		loop_samples[frame_index] = generated[warmup_frame_count + frame_index]
	_rotate_to_best_seam(loop_samples)
	_close_loop_boundary(loop_samples, preset)
	return loop_samples


func _rotate_to_best_seam(samples: PackedFloat32Array) -> void:
	if samples.size() < 8:
		return
	var best_index: int = 1
	var best_score: float = INF
	for index: int in range(1, samples.size() - 1):
		var incoming_slope: float = samples[index] - samples[index - 1]
		var outgoing_slope: float = samples[index + 1] - samples[index]
		var score: float = absf(incoming_slope) + absf(outgoing_slope - incoming_slope) * 0.35
		if score < best_score:
			best_score = score
			best_index = index
	if best_index <= 0:
		return
	var rotated := PackedFloat32Array()
	rotated.resize(samples.size())
	for index: int in samples.size():
		rotated[index] = samples[(best_index + index) % samples.size()]
	for index: int in samples.size():
		samples[index] = rotated[index]


func _close_loop_boundary(samples: PackedFloat32Array, preset: EngineAudioBakePreset) -> void:
	if samples.size() < 4 or preset.boundary_correction_seconds <= 0.0:
		return
	var correction_frame_count: int = clampi(
		roundi(float(preset.sample_rate) * preset.boundary_correction_seconds),
		2,
		maxi(samples.size() / 4, 2)
	)
	for offset_index: int in range(correction_frame_count):
		var ratio: float = float(offset_index + 1) / float(correction_frame_count + 1)
		var tail_weight: float = cos(ratio * PI * 0.5)
		var head_weight: float = sin(ratio * PI * 0.5)
		var sample_index: int = samples.size() - correction_frame_count + offset_index
		samples[sample_index] = (
			samples[sample_index] * tail_weight
			+ samples[offset_index] * head_weight
		)


func _write_pcm16_mono_wav(
	resource_path: String,
	samples: PackedFloat32Array,
	sample_rate: int
) -> bool:
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
	file.store_32(sample_rate)
	file.store_32(sample_rate * bytes_per_sample)
	file.store_16(bytes_per_sample)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(data_size)
	for sample: float in samples:
		var pcm_value: int = clampi(roundi(sample * 32767.0), -32768, 32767)
		file.store_16(pcm_value & 0xffff)
	file.close()
	return true


func _write_manifest(path: String, manifest: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write engine-audio manifest: %s" % path)
		return false
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	return true


func _write_bank_resource(preset: EngineAudioBakePreset, manifest: Dictionary) -> bool:
	var rpm_values: Array[String] = []
	for rpm: int in preset.sample_rpms:
		rpm_values.append(str(rpm))
	var resource_text: String = "\n".join([
		"[gd_resource type=\"Resource\" load_steps=2 format=3]",
		"",
		"[ext_resource type=\"Script\" path=\"res://scripts/car/engine_audio_sample_bank.gd\" id=\"1_bank\"]",
		"",
		"[resource]",
		"script = ExtResource(\"1_bank\")",
		"bank_directory = %s" % JSON.stringify(preset.output_directory),
		"sample_rpms = PackedFloat32Array(%s)" % ", ".join(rpm_values),
		"sample_rate = %d" % preset.sample_rate,
		"loop_seconds = %s" % preset.loop_seconds,
		"idle_volume_db = %s" % float(manifest["idle_volume_db"]),
		"load_volume_db = %s" % float(manifest["load_volume_db"]),
		"output_volume_boost_db = %s" % float(manifest["output_volume_boost_db"]),
		"startup_duration = %s" % float(manifest["startup_duration"]),
		"shutdown_duration = %s" % float(manifest["shutdown_duration"]),
		"",
	])
	var path: String = preset.output_directory.path_join("bank.tres")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write engine-audio bank resource: %s" % path)
		return false
	file.store_string(resource_text)
	file.close()
	return true


func _get_layer_operating_point(preset: EngineAudioBakePreset, layer_name: String) -> Vector2:
	if layer_name == "load":
		return Vector2(preset.loaded_load, preset.loaded_throttle)
	return Vector2(preset.coast_load, preset.coast_throttle)


func _remove_previous_generated_files(output_directory: String) -> void:
	var directory: DirAccess = DirAccess.open(output_directory)
	if directory == null:
		return
	for file_name: String in directory.get_files():
		if _is_generated_bank_file(file_name):
			directory.remove(file_name)


func _is_generated_bank_file(file_name: String) -> bool:
	return (
		(file_name.begins_with("coast_") and file_name.ends_with(".wav"))
		or (file_name.begins_with("load_") and file_name.ends_with(".wav"))
		or file_name == "bank.tres"
		or file_name == "bank_manifest.json"
	)


func _has_property(target: Object, property_name: StringName) -> bool:
	for property_value: Variant in target.get_property_list():
		if not property_value is Dictionary:
			continue
		var property: Dictionary = property_value
		if StringName(property.get("name", &"")) == property_name:
			return true
	return false


func _dispose_synthesizer(synthesizer: Object) -> void:
	if synthesizer != null and is_instance_valid(synthesizer):
		synthesizer.free()
