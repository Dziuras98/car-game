extends Resource
class_name TrackDefinition

@export_group("Identity")
@export var track_id: StringName = &""
@export var display_name: String = ""
@export_range(1, 99, 1) var recommended_laps: int = 3

@export_group("Runtime")
@export var track_scene: PackedScene


func is_valid() -> bool:
	return (
		track_id != &""
		and not display_name.strip_edges().is_empty()
		and recommended_laps >= 1
		and _scene_has_generated_track_root(track_scene)
	)


func instantiate_track() -> GeneratedTrack:
	if track_scene == null:
		return null
	var track: GeneratedTrack = track_scene.instantiate() as GeneratedTrack
	if track == null:
		push_error("Track definition '%s' must instantiate a GeneratedTrack root." % str(track_id))
	return track


func _scene_has_generated_track_root(scene: PackedScene) -> bool:
	if scene == null or not scene.can_instantiate():
		return false
	var instance: Node = scene.instantiate()
	var is_valid_root: bool = instance is GeneratedTrack
	if instance != null:
		instance.free()
	return is_valid_root
