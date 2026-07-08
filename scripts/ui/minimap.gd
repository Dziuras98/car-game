extends Control

@export var target_path: NodePath
@export var track_path: NodePath
@export var map_padding: float = 16.0
@export var participant_radius: float = 4.5

var _player: PlayerCarController
var _track: Node3D
var _opponents: Array[PlayerCarController] = []
var _track_points: Array[Vector3] = []
var _min_x: float = 0.0
var _max_x: float = 1.0
var _min_z: float = 0.0
var _max_z: float = 1.0


func set_target_node(target: PlayerCarController) -> void:
	_player = target
	if is_inside_tree() and target != null:
		target_path = get_path_to(target)
	visible = target != null
	queue_redraw()


func set_track_node(track: Node3D) -> void:
	_track = track
	if is_inside_tree() and track != null:
		track_path = get_path_to(track)
	_refresh_track_points()
	queue_redraw()


func set_opponents(opponents: Array[PlayerCarController]) -> void:
	_opponents = opponents.duplicate()
	queue_redraw()


func _ready() -> void:
	_player = get_node_or_null(target_path) as PlayerCarController
	_track = get_node_or_null(track_path) as Node3D
	_refresh_track_points()
	visible = _player != null


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_node_or_null(target_path) as PlayerCarController
	if _track_points.is_empty():
		_track = get_node_or_null(track_path) as Node3D
		_refresh_track_points()
	queue_redraw()


func _draw() -> void:
	var background_rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(background_rect, Color(0.02, 0.025, 0.03, 0.74), true)
	draw_rect(background_rect, Color(0.78, 0.84, 0.9, 0.28), false, 1.0)

	if _track_points.size() >= 2:
		var map_points: PackedVector2Array = PackedVector2Array()
		for point: Vector3 in _track_points:
			map_points.append(_world_to_map(point))
		map_points.append(_world_to_map(_track_points[0]))
		draw_polyline(map_points, Color(0.17, 0.19, 0.21, 1.0), 9.0, true)
		draw_polyline(map_points, Color(0.82, 0.86, 0.9, 1.0), 2.2, true)
		draw_circle(_world_to_map(_track_points[0]), 3.6, Color(0.9, 0.95, 1.0, 1.0))

	for opponent: PlayerCarController in _opponents:
		if is_instance_valid(opponent):
			draw_circle(_world_to_map(opponent.global_position), participant_radius, Color(1.0, 0.18, 0.12, 1.0))

	if is_instance_valid(_player):
		_draw_player_marker(_player)


func _refresh_track_points() -> void:
	_track_points.clear()
	if _track == null or not _track.has_method("get_racing_line_points"):
		return

	var local_points: Array = _track.call("get_racing_line_points")
	for point: Variant in local_points:
		if point is Vector3:
			_track_points.append(_track.to_global(point))

	_recalculate_bounds()


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
	return origin + Vector2(normalized_position.x, normalized_position.y) * scale


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
