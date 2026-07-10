extends Control
class_name Minimap

@export var target_path: NodePath
@export var track_path: NodePath
@export var map_padding: float = 16.0
@export var participant_radius: float = 4.5
@export_range(1.0, 60.0, 1.0) var redraw_hz: float = 20.0

var _player: PlayerCarController
var _track: GeneratedTrack
var _opponents: Array[PlayerCarController] = []
var _track_points: Array[Vector3] = []
var _mapped_track_points: PackedVector2Array = PackedVector2Array()
var _min_x: float = 0.0
var _max_x: float = 1.0
var _min_z: float = 0.0
var _max_z: float = 1.0
var _redraw_timer: float = 0.0
var _redraw_request_count: int = 0
var _track_revision: int = 0


func set_target_node(target: PlayerCarController) -> void:
	if _player == target:
		return
	_player = target
	if is_inside_tree() and target != null:
		target_path = get_path_to(target)
	visible = target != null
	set_process(target != null)
	_request_redraw()


func set_track_node(track: GeneratedTrack) -> void:
	if _track == track and not _track_points.is_empty():
		return
	_disconnect_track_geometry_signal()
	_track = track
	if is_inside_tree() and track != null:
		track_path = get_path_to(track)
	_connect_track_geometry_signal()
	_refresh_track_points()
	_request_redraw()


func set_opponents(opponents: Array[PlayerCarController]) -> void:
	if _same_opponents(opponents):
		return
	_opponents = opponents.duplicate()
	_request_redraw()


func _ready() -> void:
	_player = get_node_or_null(target_path) as PlayerCarController
	_track = get_node_or_null(track_path) as GeneratedTrack
	resized.connect(_on_resized)
	_connect_track_geometry_signal()
	_refresh_track_points()
	visible = _player != null
	set_process(_player != null)


func _exit_tree() -> void:
	_disconnect_track_geometry_signal()


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		set_process(false)
		return
	if _track_points.is_empty():
		_refresh_track_points()
	if not visible:
		return

	_redraw_timer -= maxf(delta, 0.0)
	if _redraw_timer > 0.0:
		return
	_redraw_timer = 1.0 / maxf(redraw_hz, 1.0)
	_request_redraw()


func _draw() -> void:
	var background_rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(background_rect, Color(0.02, 0.025, 0.03, 0.74), true)
	draw_rect(background_rect, Color(0.78, 0.84, 0.9, 0.28), false, 1.0)

	if _mapped_track_points.size() >= 2:
		draw_polyline(_mapped_track_points, Color(0.17, 0.19, 0.21, 1.0), 9.0, true)
		draw_polyline(_mapped_track_points, Color(0.82, 0.86, 0.9, 1.0), 2.2, true)
		draw_circle(_mapped_track_points[0], 3.6, Color(0.9, 0.95, 1.0, 1.0))

	for opponent: PlayerCarController in _opponents:
		if is_instance_valid(opponent):
			draw_circle(_world_to_map(opponent.global_position), participant_radius, Color(1.0, 0.18, 0.12, 1.0))

	if is_instance_valid(_player):
		_draw_player_marker(_player)


func get_redraw_request_count() -> int:
	return _redraw_request_count


func get_track_revision() -> int:
	return _track_revision


func _refresh_track_points() -> void:
	_track_points.clear()
	_mapped_track_points.clear()
	if not is_instance_valid(_track):
		return

	for local_point: Vector3 in _track.get_racing_line_points():
		_track_points.append(_track.to_global(local_point))
	_track_revision += 1
	_recalculate_bounds()
	_rebuild_mapped_track_points()


func _connect_track_geometry_signal() -> void:
	if not is_instance_valid(_track):
		return
	var callback: Callable = Callable(self, "_on_track_geometry_rebuilt")
	if not _track.geometry_rebuilt.is_connected(callback):
		_track.geometry_rebuilt.connect(callback)


func _disconnect_track_geometry_signal() -> void:
	if not is_instance_valid(_track):
		return
	var callback: Callable = Callable(self, "_on_track_geometry_rebuilt")
	if _track.geometry_rebuilt.is_connected(callback):
		_track.geometry_rebuilt.disconnect(callback)


func _on_track_geometry_rebuilt(_revision: int) -> void:
	_refresh_track_points()
	_request_redraw()


func _recalculate_bounds() -> void:
	if _track_points.is_empty():
		_min_x = 0.0
		_max_x = 1.0
		_min_z = 0.0
		_max_z = 1.0
		return

	_min_x = _track_points[0].x
	_max_x = _track_points[0].x
	_min_z = _track_points[0].z
	_max_z = _track_points[0].z
	for point: Vector3 in _track_points:
		_min_x = minf(_min_x, point.x)
		_max_x = maxf(_max_x, point.x)
		_min_z = minf(_min_z, point.z)
		_max_z = maxf(_max_z, point.z)


func _rebuild_mapped_track_points() -> void:
	_mapped_track_points.clear()
	for point: Vector3 in _track_points:
		_mapped_track_points.append(_world_to_map(point))
	if not _mapped_track_points.is_empty():
		_mapped_track_points.append(_mapped_track_points[0])


func _world_to_map(world_position: Vector3) -> Vector2:
	var usable_size: Vector2 = Vector2(
		maxf(size.x - map_padding * 2.0, 1.0),
		maxf(size.y - map_padding * 2.0, 1.0)
	)
	var world_size: Vector2 = Vector2(maxf(_max_x - _min_x, 1.0), maxf(_max_z - _min_z, 1.0))
	var scale: float = minf(usable_size.x / world_size.x, usable_size.y / world_size.y)
	var drawn_size: Vector2 = world_size * scale
	var origin: Vector2 = (size - drawn_size) * 0.5
	var normalized_position: Vector2 = Vector2(world_position.x - _min_x, world_position.z - _min_z)
	return origin + normalized_position * scale


func _draw_player_marker(car: PlayerCarController) -> void:
	var center: Vector2 = _world_to_map(car.global_position)
	var forward: Vector3 = -car.global_transform.basis.z.normalized()
	var heading: Vector2 = Vector2(forward.x, forward.z).normalized()
	if heading.length_squared() < 0.01:
		heading = Vector2.UP
	var side: Vector2 = Vector2(-heading.y, heading.x)
	var marker_size: float = participant_radius + 3.0
	var points: PackedVector2Array = PackedVector2Array([
		center + heading * marker_size,
		center - heading * marker_size * 0.78 + side * marker_size * 0.62,
		center - heading * marker_size * 0.78 - side * marker_size * 0.62,
	])
	var outline_points: PackedVector2Array = points.duplicate()
	outline_points.append(points[0])
	draw_colored_polygon(points, Color(1.0, 0.9, 0.16, 1.0))
	draw_polyline(outline_points, Color(0.08, 0.07, 0.02, 0.8), 1.0, true)


func _request_redraw() -> void:
	_redraw_request_count += 1
	queue_redraw()


func _on_resized() -> void:
	_rebuild_mapped_track_points()
	_request_redraw()


func _same_opponents(opponents: Array[PlayerCarController]) -> bool:
	if opponents.size() != _opponents.size():
		return false
	for index: int in range(opponents.size()):
		if opponents[index] != _opponents[index]:
			return false
	return true
