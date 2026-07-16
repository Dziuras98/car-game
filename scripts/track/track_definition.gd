extends Resource
class_name TrackDefinition

@export_group("Identity")
@export var track_id: StringName = &""
@export var display_name: String = ""
@export_range(1, 99, 1) var recommended_laps: int = 3

@export_group("Availability")
@export var supported_modes: Array[StringName] = [
	GameModes.FREE_DRIVE,
	GameModes.RACE,
]

@export_group("Runtime")
@export var track_scene: PackedScene


func is_valid() -> bool:
	return (
		track_id != &""
		and not display_name.strip_edges().is_empty()
		and recommended_laps >= 1
		and _has_valid_supported_modes()
		and _scene_has_generated_track_root(track_scene)
	)


func supports_mode(mode_id: StringName) -> bool:
	return GameModes.is_supported(mode_id) and supported_modes.has(mode_id)


func instantiate_track() -> GeneratedTrack:
	if track_scene == null:
		return null
	var track: GeneratedTrack = track_scene.instantiate() as GeneratedTrack
	if track == null:
		push_error("Track definition '%s' must instantiate a GeneratedTrack root." % str(track_id))
	return track


func _has_valid_supported_modes() -> bool:
	if supported_modes.is_empty():
		return false
	var used_modes: Dictionary = {}
	for mode_id: StringName in supported_modes:
		if not GameModes.is_supported(mode_id):
			return false
		var mode_key: String = str(mode_id)
		if used_modes.has(mode_key):
			return false
		used_modes[mode_key] = true
	return true


func _scene_has_generated_track_root(scene: PackedScene) -> bool:
	if scene == null or not scene.can_instantiate():
		return false
	var instance: Node = scene.instantiate()
	var is_valid_root: bool = instance is GeneratedTrack
	if instance != null:
		instance.free()
	return is_valid_root
