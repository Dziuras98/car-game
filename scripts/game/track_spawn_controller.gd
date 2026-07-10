extends RefCounted
class_name TrackSpawnController

const ACTIVE_TRACK_NAME: String = "ActiveTrack"
const PENDING_TRACK_NAME: String = "PendingTrack"

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

	var pending_track: GeneratedTrack = definition.instantiate_track()
	if pending_track == null:
		return null

	pending_track.name = PENDING_TRACK_NAME
	_container.add_child(pending_track)
	if pending_track.get_parent() != _container or not pending_track.has_committed_generation():
		_discard_pending_track(pending_track)
		push_warning(
			"Track definition %s did not produce valid generated content; keeping the current track."
			% str(definition.track_id)
		)
		return null

	var previous_track: GeneratedTrack = _current_track
	if is_instance_valid(previous_track):
		var previous_parent: Node = previous_track.get_parent()
		if previous_parent != null:
			previous_parent.remove_child(previous_track)

	pending_track.name = ACTIVE_TRACK_NAME
	_current_track = pending_track
	_current_definition = definition

	if is_instance_valid(previous_track):
		previous_track.queue_free()
	return pending_track


func clear_track() -> void:
	if is_instance_valid(_current_track):
		var parent: Node = _current_track.get_parent()
		if parent != null:
			parent.remove_child(_current_track)
		_current_track.queue_free()
	_current_track = null
	_current_definition = null


func _discard_pending_track(pending_track: GeneratedTrack) -> void:
	if not is_instance_valid(pending_track):
		return
	var parent: Node = pending_track.get_parent()
	if parent != null:
		parent.remove_child(pending_track)
	pending_track.queue_free()
