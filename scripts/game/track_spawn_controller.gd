extends RefCounted
class_name TrackSpawnController

var _container: Node3D
var _current_track: GeneratedTrack
var _current_definition: TrackDefinition


func configure(container: Node3D) -> void:
	_container = container


func get_current_track() -> GeneratedTrack:
	return _current_track


func get_current_definition() -> TrackDefinition:
	return _current_definition


func spawn_track(definition: TrackDefinition) -> GeneratedTrack:
	if _container == null or definition == null or not definition.is_valid():
		return null

	clear_track()
	var track: GeneratedTrack = definition.instantiate_track()
	if track == null:
		return null

	track.name = "ActiveTrack"
	_container.add_child(track)
	_current_track = track
	_current_definition = definition
	return track


func clear_track() -> void:
	if is_instance_valid(_current_track):
		var parent: Node = _current_track.get_parent()
		if parent != null:
			parent.remove_child(_current_track)
		_current_track.queue_free()
	_current_track = null
	_current_definition = null
