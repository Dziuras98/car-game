extends AudioStreamPlayer3D
class_name ProceduralAudioPlayer3D

@export var procedural_generation_distance: float = 75.0
@export var procedural_distance_check_interval: float = 0.2
@export var procedural_voice_group: StringName = &"default"
@export_range(1, 32, 1) var max_procedural_voices: int = 6

static var _voice_distances_by_group: Dictionary = {}

var _audio_lod_check_timer: float = 0.0
var _procedural_generation_active: bool = true


func should_generate_procedural_audio(delta: float) -> bool:
	_audio_lod_check_timer -= maxf(delta, 0.0)
	if _audio_lod_check_timer > 0.0:
		return _procedural_generation_active

	_audio_lod_check_timer = maxf(procedural_distance_check_interval, 0.02)
	_procedural_generation_active = _resolve_audibility_and_budget()
	return _procedural_generation_active


func is_position_audible(source_position: Vector3, listener_position: Vector3) -> bool:
	var safe_distance: float = maxf(procedural_generation_distance, 0.0)
	return source_position.distance_squared_to(listener_position) <= safe_distance * safe_distance


func release_procedural_voice() -> void:
	var group_key: String = str(procedural_voice_group)
	var group_distances: Dictionary = _voice_distances_by_group.get(group_key, {})
	group_distances.erase(get_instance_id())
	if group_distances.is_empty():
		_voice_distances_by_group.erase(group_key)
	else:
		_voice_distances_by_group[group_key] = group_distances


func is_procedural_generation_active_for_test() -> bool:
	return _procedural_generation_active


static func report_voice_distance_for_test(
	group: StringName,
	source_id: int,
	distance_squared: float,
	max_voices: int
) -> bool:
	return _report_voice_distance(group, source_id, distance_squared, max_voices)


static func reset_voice_budget_for_test() -> void:
	_voice_distances_by_group.clear()


func _resolve_audibility_and_budget() -> bool:
	if not is_inside_tree():
		return true
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return true
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return true

	var distance_squared: float = global_position.distance_squared_to(camera.global_position)
	var safe_distance: float = maxf(procedural_generation_distance, 0.0)
	if distance_squared > safe_distance * safe_distance:
		release_procedural_voice()
		return false
	return _report_voice_distance(
		procedural_voice_group,
		get_instance_id(),
		distance_squared,
		max_procedural_voices
	)


static func _report_voice_distance(
	group: StringName,
	source_id: int,
	distance_squared: float,
	max_voices: int
) -> bool:
	var group_key: String = str(group)
	var group_distances: Dictionary = _voice_distances_by_group.get(group_key, {})
	group_distances[source_id] = maxf(distance_squared, 0.0)
	_voice_distances_by_group[group_key] = group_distances

	var source_ids: Array = group_distances.keys()
	source_ids.sort_custom(func(left: Variant, right: Variant) -> bool:
		return float(group_distances[left]) < float(group_distances[right])
	)
	return source_ids.find(source_id) < maxi(max_voices, 1)
