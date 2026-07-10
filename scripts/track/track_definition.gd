extends Resource
class_name TrackDefinition

@export_group("Identity")
@export var track_id: StringName = &""
@export var display_name: String = ""
@export var is_default: bool = false
@export_range(1, 99, 1) var recommended_laps: int = 3

@export_group("Runtime")
@export var track_scene: PackedScene


func is_valid() -> bool:
	return (
		track_id != &""
		and not display_name.strip_edges().is_empty()
		and recommended_laps >= 1
		and track_scene != null
	)


func instantiate_track() -> Node3D:
	if track_scene == null:
		return null
	return track_scene.instantiate() as Node3D
