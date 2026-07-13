extends Node
class_name TorPoznanGeometryRefresh

var _track: GeneratedTrack
var _environment: TorPoznanEnvironment
var _refresh_pending: bool = false


func _ready() -> void:
	_track = get_parent() as GeneratedTrack
	if _track == null:
		push_error("TorPoznanGeometryRefresh requires a GeneratedTrack parent.")
		return
	_environment = _track.get_node_or_null("TrackEnvironment") as TorPoznanEnvironment
	if _environment == null:
		push_error("TorPoznanGeometryRefresh requires the Tor Poznan environment node.")
		return
	var callback: Callable = Callable(self, "_on_track_geometry_rebuilt")
	if not _track.geometry_rebuilt.is_connected(callback):
		_track.geometry_rebuilt.connect(callback)


func _exit_tree() -> void:
	if not is_instance_valid(_track):
		return
	var callback: Callable = Callable(self, "_on_track_geometry_rebuilt")
	if _track.geometry_rebuilt.is_connected(callback):
		_track.geometry_rebuilt.disconnect(callback)


func _on_track_geometry_rebuilt(_revision: int) -> void:
	if _refresh_pending:
		return
	_refresh_pending = true
	call_deferred("_refresh_geometry_dependent_content")


func _refresh_geometry_dependent_content() -> void:
	_refresh_pending = false
	if (
		not is_instance_valid(_track)
		or not _track.has_committed_generation()
		or not is_instance_valid(_environment)
	):
		return

	var existing_curbs: Node = _environment.get_node_or_null("CornerCurbs")
	if existing_curbs != null:
		_environment.remove_child(existing_curbs)
		existing_curbs.free()

	_environment._open_pit_lane_barrier(_track)
	_environment._create_corner_curbs(_track)
