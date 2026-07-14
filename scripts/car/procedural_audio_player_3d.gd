extends AudioStreamPlayer3D
class_name ProceduralAudioPlayer3D

@export var procedural_generation_distance: float = 75.0
@export var procedural_distance_check_interval: float = 0.2
@export var procedural_voice_group: StringName = &"default"
@export_range(1, 32, 1) var max_procedural_voices: int = 6
@export_range(1, 8, 1) var procedural_voice_cost: int = 1

# Entries use {"distance_squared": float, "cost": int}. Keeping the historic
# variable name avoids invalidating old test and debug tooling.
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


func get_procedural_voice_cost() -> int:
	return maxi(procedural_voice_cost, 1)


func release_procedural_voice() -> void:
	var group_key: String = str(procedural_voice_group)
	var group_entries: Dictionary = _voice_distances_by_group.get(group_key, {})
	group_entries.erase(get_instance_id())
	if group_entries.is_empty():
		_voice_distances_by_group.erase(group_key)
	else:
		_voice_distances_by_group[group_key] = group_entries


func is_procedural_generation_active() -> bool:
	return _procedural_generation_active


static func report_voice_distance(
	group: StringName,
	source_id: int,
	distance_squared: float,
	max_voices: int,
	voice_cost: int = 1
) -> bool:
	return _report_voice_distance(group, source_id, distance_squared, max_voices, voice_cost)


static func reset_voice_budget() -> void:
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
		max_procedural_voices,
		get_procedural_voice_cost()
	)


static func _report_voice_distance(
	group: StringName,
	source_id: int,
	distance_squared: float,
	max_voices: int,
	voice_cost: int = 1
) -> bool:
	var group_key: String = str(group)
	var group_entries: Dictionary = _voice_distances_by_group.get(group_key, {})
	group_entries[source_id] = {
		"distance_squared": maxf(distance_squared, 0.0),
		"cost": maxi(voice_cost, 1),
	}
	_voice_distances_by_group[group_key] = group_entries

	var source_ids: Array = group_entries.keys()
	source_ids.sort_custom(func(left: Variant, right: Variant) -> bool:
		return float(group_entries[left].get("distance_squared", INF)) < float(
			group_entries[right].get("distance_squared", INF)
		)
	)
	var spent_budget: int = 0
	var safe_budget: int = maxi(max_voices, 1)
	for candidate_id: Variant in source_ids:
		var entry: Dictionary = group_entries[candidate_id]
		var candidate_cost: int = maxi(int(entry.get("cost", 1)), 1)
		if candidate_id == source_id:
			return spent_budget + candidate_cost <= safe_budget
		spent_budget += candidate_cost
	return false
