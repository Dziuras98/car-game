extends RefCounted
class_name TrackSpawnController

const ACTIVE_TRACK_NAME: String = "ActiveTrack"
const PENDING_TRACK_NAME: String = "PendingTrack"

var _container: Node3D
var _current_track: GeneratedTrack
var _current_definition: TrackDefinition
var _staged_track: GeneratedTrack
var _staged_definition: TrackDefinition
var _staged_reuses_current: bool = false
var _previous_track: GeneratedTrack
var _previous_definition: TrackDefinition
var _has_unfinalized_commit: bool = false
var _unfinalized_reuses_current: bool = false


func configure(container: Node3D) -> void:
	_container = container


func get_current_track() -> GeneratedTrack:
	return _current_track


func get_current_definition() -> TrackDefinition:
	return _current_definition


func get_staged_track() -> GeneratedTrack:
	return _staged_track


func get_staged_definition() -> TrackDefinition:
	return _staged_definition


func stage_track(definition: TrackDefinition) -> GeneratedTrack:
	if _container == null or definition == null or not definition.is_valid():
		return null

	rollback_track_transaction()
	if (
		_current_definition != null
		and _current_definition.track_id == definition.track_id
		and is_instance_valid(_current_track)
	):
		_staged_track = _current_track
		_staged_definition = definition
		_staged_reuses_current = true
		return _staged_track

	var pending_track: GeneratedTrack = definition.instantiate_track()
	if pending_track == null:
		return null

	pending_track.name = PENDING_TRACK_NAME
	_container.add_child(pending_track)
	if pending_track.get_parent() != _container or not pending_track.has_committed_generation():
		_discard_track_node(pending_track)
		push_warning(
			"Track definition %s did not produce valid generated content; keeping the current track."
			% str(definition.track_id)
		)
		return null

	_staged_track = pending_track
	_staged_definition = definition
	_staged_reuses_current = false
	return _staged_track


func commit_staged_track() -> GeneratedTrack:
	if not is_instance_valid(_staged_track) or _staged_definition == null:
		return null
	if _staged_reuses_current:
		_previous_track = _current_track
		_previous_definition = _current_definition
		_current_definition = _staged_definition
		_clear_staged_references()
		_has_unfinalized_commit = true
		_unfinalized_reuses_current = true
		return _current_track

	_previous_track = _current_track
	_previous_definition = _current_definition
	if is_instance_valid(_previous_track):
		var previous_parent: Node = _previous_track.get_parent()
		if previous_parent != null:
			previous_parent.remove_child(_previous_track)

	_staged_track.name = ACTIVE_TRACK_NAME
	_current_track = _staged_track
	_current_definition = _staged_definition
	_clear_staged_references()
	_has_unfinalized_commit = true
	_unfinalized_reuses_current = false
	return _current_track


func finalize_track_commit() -> void:
	if not _unfinalized_reuses_current and is_instance_valid(_previous_track):
		_previous_track.free()
	_clear_previous_references()


func rollback_track_transaction() -> void:
	if not _has_unfinalized_commit:
		discard_staged_track()
		return

	if _unfinalized_reuses_current:
		_current_track = _previous_track
		_current_definition = _previous_definition
		_clear_previous_references()
		return

	var rejected_track: GeneratedTrack = _current_track
	if is_instance_valid(rejected_track):
		var rejected_parent: Node = rejected_track.get_parent()
		if rejected_parent != null:
			rejected_parent.remove_child(rejected_track)

	_current_track = _previous_track
	_current_definition = _previous_definition
	if is_instance_valid(_current_track):
		if _current_track.get_parent() == null and _container != null:
			_container.add_child(_current_track)
		_current_track.name = ACTIVE_TRACK_NAME
	else:
		_current_track = null
		_current_definition = null

	if is_instance_valid(rejected_track) and rejected_track != _current_track:
		rejected_track.free()
	_clear_previous_references()


func discard_staged_track() -> void:
	if is_instance_valid(_staged_track) and not _staged_reuses_current:
		_discard_track_node(_staged_track)
	_clear_staged_references()


func spawn_track(definition: TrackDefinition) -> GeneratedTrack:
	if stage_track(definition) == null:
		return null
	var committed_track: GeneratedTrack = commit_staged_track()
	if committed_track == null:
		rollback_track_transaction()
		return null
	finalize_track_commit()
	return committed_track


func clear_track() -> void:
	rollback_track_transaction()
	if is_instance_valid(_current_track):
		_discard_track_node(_current_track)
	_current_track = null
	_current_definition = null


func _clear_staged_references() -> void:
	_staged_track = null
	_staged_definition = null
	_staged_reuses_current = false


func _clear_previous_references() -> void:
	_previous_track = null
	_previous_definition = null
	_has_unfinalized_commit = false
	_unfinalized_reuses_current = false


func _discard_track_node(track: GeneratedTrack) -> void:
	if not is_instance_valid(track):
		return
	var parent: Node = track.get_parent()
	if parent != null:
		parent.remove_child(track)
	track.free()
