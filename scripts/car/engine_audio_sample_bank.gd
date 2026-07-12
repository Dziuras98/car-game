extends Resource
class_name EngineAudioSampleBank

const MIN_VOLUME_DB: float = -80.0
const MAX_VOLUME_DB: float = 16.0

@export var sample_rpms: PackedFloat32Array = PackedFloat32Array()
@export var coast_streams: Array[AudioStream] = []
@export var load_streams: Array[AudioStream] = []
@export_range(0.1, 10.0, 0.01) var loop_seconds: float = 1.0
@export_range(-80.0, 12.0, 0.5) var idle_volume_db: float = -10.0
@export_range(-80.0, 12.0, 0.5) var load_volume_db: float = 0.0
@export_range(0.0, 16.0, 0.5) var output_volume_boost_db: float = 0.0


func is_valid() -> bool:
	return validate().is_empty()


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if sample_rpms.size() < 2:
		errors.append("sample_rpms must contain at least two anchors")
	if coast_streams.size() != sample_rpms.size():
		errors.append("coast_streams must match sample_rpms")
	if load_streams.size() != sample_rpms.size():
		errors.append("load_streams must match sample_rpms")
	var previous_rpm: float = -INF
	for index: int in range(sample_rpms.size()):
		var rpm: float = sample_rpms[index]
		if not is_finite(rpm) or rpm <= 0.0 or rpm <= previous_rpm:
			errors.append("sample_rpms must be finite, positive and strictly increasing")
			break
		previous_rpm = rpm
		if index < coast_streams.size() and coast_streams[index] == null:
			errors.append("coast_streams contains a null entry at index %d" % index)
		if index < load_streams.size() and load_streams[index] == null:
			errors.append("load_streams contains a null entry at index %d" % index)
	if not is_finite(loop_seconds) or loop_seconds <= 0.0:
		errors.append("loop_seconds must be finite and positive")
	_append_volume_error(errors, "idle_volume_db", idle_volume_db)
	_append_volume_error(errors, "load_volume_db", load_volume_db)
	_append_volume_error(errors, "output_volume_boost_db", output_volume_boost_db)
	return errors


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


func get_coast_stream(index: int) -> AudioStream:
	return coast_streams[index] if index >= 0 and index < coast_streams.size() else null


func get_load_stream(index: int) -> AudioStream:
	return load_streams[index] if index >= 0 and index < load_streams.size() else null


func _append_volume_error(errors: PackedStringArray, property_name: String, value: float) -> void:
	if not is_finite(value) or value < MIN_VOLUME_DB or value > MAX_VOLUME_DB:
		errors.append("%s must be finite and between %s and %s" % [property_name, MIN_VOLUME_DB, MAX_VOLUME_DB])
