extends Resource
class_name EngineAudioSampleBank

const MIN_VOLUME_DB: float = -80.0
const MAX_VOLUME_DB: float = 16.0
const LAYER_NAMES: Array[String] = ["coast", "load"]

@export_dir var bank_directory: String = ""
@export var sample_rpms: PackedFloat32Array = PackedFloat32Array()
@export_range(8000, 48000, 1000) var sample_rate: int = 32000
@export_range(0.1, 10.0, 0.01) var loop_seconds: float = 1.0
@export_range(-80.0, 12.0, 0.5) var idle_volume_db: float = -10.0
@export_range(-80.0, 12.0, 0.5) var load_volume_db: float = 0.0
@export_range(0.0, 16.0, 0.5) var output_volume_boost_db: float = 0.0
@export_range(0.05, 3.0, 0.05) var startup_duration: float = 0.80
@export_range(0.05, 3.0, 0.05) var shutdown_duration: float = 1.10

var _coast_streams: Array[AudioStream] = []
var _load_streams: Array[AudioStream] = []
var _prepared: bool = false
var _prepare_attempted: bool = false


func is_valid() -> bool:
	return validate().is_empty()


func validate() -> PackedStringArray:
	var errors: PackedStringArray = _validate_definition()
	if not errors.is_empty():
		return errors
	for index: int in range(sample_rpms.size()):
		for layer_name: String in LAYER_NAMES:
			var clip_path: String = get_clip_path(layer_name, index)
			if not ResourceLoader.exists(clip_path):
				errors.append("missing baked engine-audio clip: %s" % clip_path)
	return errors


func prepare() -> bool:
	if _prepared:
		return true
	if _prepare_attempted:
		return false
	_prepare_attempted = true
	var validation_errors: PackedStringArray = validate()
	if not validation_errors.is_empty():
		push_error("Invalid baked engine-audio bank: %s" % "; ".join(validation_errors))
		return false

	_coast_streams.clear()
	_load_streams.clear()
	for index: int in range(sample_rpms.size()):
		var coast_path: String = get_clip_path("coast", index)
		var load_path: String = get_clip_path("load", index)
		var coast_stream: AudioStream = load(coast_path) as AudioStream
		var load_stream: AudioStream = load(load_path) as AudioStream
		if not _validate_loaded_stream(coast_stream, coast_path):
			return false
		if not _validate_loaded_stream(load_stream, load_path):
			return false
		_coast_streams.append(coast_stream)
		_load_streams.append(load_stream)
	_prepared = true
	return true


func clear_runtime_cache() -> void:
	_coast_streams.clear()
	_load_streams.clear()
	_prepared = false
	_prepare_attempted = false


func is_prepared() -> bool:
	return _prepared


func find_nearest_anchor_index(rpm: float) -> int:
	if sample_rpms.is_empty():
		return -1
	var safe_rpm: float = maxf(rpm, sample_rpms[0])
	var nearest_index: int = 0
	var nearest_distance: float = absf(sample_rpms[0] - safe_rpm)
	for index: int in range(1, sample_rpms.size()):
		var distance: float = absf(sample_rpms[index] - safe_rpm)
		if distance < nearest_distance:
			nearest_index = index
			nearest_distance = distance
	return nearest_index


func get_anchor_rpm(index: int) -> float:
	if index < 0 or index >= sample_rpms.size():
		return 1.0
	return maxf(sample_rpms[index], 1.0)


func get_clip_path(layer_name: String, index: int) -> String:
	if index < 0 or index >= sample_rpms.size():
		return ""
	return bank_directory.path_join(
		"%s_%04d.wav" % [layer_name, roundi(sample_rpms[index])]
	)


func get_coast_stream(index: int) -> AudioStream:
	if not _prepared and not prepare():
		return null
	return _coast_streams[index] if index >= 0 and index < _coast_streams.size() else null


func get_load_stream(index: int) -> AudioStream:
	if not _prepared and not prepare():
		return null
	return _load_streams[index] if index >= 0 and index < _load_streams.size() else null


func get_loaded_stream_count() -> int:
	return _coast_streams.size() + _load_streams.size() if _prepared else 0


func _validate_definition() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not bank_directory.begins_with("res://"):
		errors.append("bank_directory must use res:// so clips are included in exports")
	if sample_rpms.size() < 2:
		errors.append("sample_rpms must contain at least two anchors")
	var previous_rpm: float = -INF
	for rpm: float in sample_rpms:
		if not is_finite(rpm) or rpm <= 0.0 or rpm <= previous_rpm:
			errors.append("sample_rpms must be finite, positive and strictly increasing")
			break
		previous_rpm = rpm
	if sample_rate < 8000 or sample_rate > 48000:
		errors.append("sample_rate must be between 8000 and 48000")
	if not is_finite(loop_seconds) or loop_seconds <= 0.0:
		errors.append("loop_seconds must be finite and positive")
	_append_volume_error(errors, "idle_volume_db", idle_volume_db)
	_append_volume_error(errors, "load_volume_db", load_volume_db)
	_append_volume_error(errors, "output_volume_boost_db", output_volume_boost_db)
	if not is_finite(startup_duration) or startup_duration <= 0.0:
		errors.append("startup_duration must be finite and positive")
	if not is_finite(shutdown_duration) or shutdown_duration <= 0.0:
		errors.append("shutdown_duration must be finite and positive")
	return errors


func _validate_loaded_stream(audio_stream: AudioStream, path: String) -> bool:
	if not audio_stream is AudioStreamWAV:
		push_error("Baked engine-audio clip is not an AudioStreamWAV: %s" % path)
		return false
	var wav: AudioStreamWAV = audio_stream as AudioStreamWAV
	if wav.mix_rate != sample_rate:
		push_error(
			"Baked engine-audio clip has mix rate %d instead of %d: %s"
			% [wav.mix_rate, sample_rate, path]
		)
		return false
	if absf(wav.get_length() - loop_seconds) > 0.02:
		push_error("Baked engine-audio clip has an unexpected duration: %s" % path)
		return false
	return true


func _append_volume_error(errors: PackedStringArray, property_name: String, value: float) -> void:
	if not is_finite(value) or value < MIN_VOLUME_DB or value > MAX_VOLUME_DB:
		errors.append(
			"%s must be finite and between %s and %s"
			% [property_name, MIN_VOLUME_DB, MAX_VOLUME_DB]
		)
