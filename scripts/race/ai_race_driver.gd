extends Node

@export var car_path: NodePath
@export var track_path: NodePath
@export var lane_offset: float = 0.0
@export var lookahead_points: int = 5
@export var target_speed_kmh: float = 118.0
@export var corner_speed_kmh: float = 78.0
@export var waypoint_reach_distance: float = 8.0

var _car: PlayerCarController
var _track: Node3D
var _points: Array[Vector3] = []
var _target_index: int = 0
var _enabled: bool = false


func _ready() -> void:
	_car = get_node_or_null(car_path) as PlayerCarController
	_track = get_node_or_null(track_path) as Node3D
	_refresh_points()

	if _car != null:
		_car.set_external_input_enabled(true)
		_car.set_external_drive_inputs(0.0, 0.0, 0.0)


func set_driver_enabled(enabled: bool) -> void:
	_enabled = enabled
	if _car != null:
		_car.set_external_drive_inputs(0.0, 0.0, 0.0)


func _physics_process(_delta: float) -> void:
	if not _enabled or _car == null:
		return

	if _points.is_empty():
		_refresh_points()
		if _points.is_empty():
			_car.set_external_drive_inputs(0.0, 0.0, 0.0)
			return

	_update_target_index()
	var target_point: Vector3 = _get_lane_point((_target_index + lookahead_points) % _points.size())
	var local_target: Vector3 = _car.to_local(target_point)
	var steering: float = clampf(local_target.x / maxf(absf(local_target.z), 8.0), -1.0, 1.0)
	var turn_pressure: float = clampf(absf(steering) * 1.45, 0.0, 1.0)
	var speed_limit: float = lerpf(target_speed_kmh, corner_speed_kmh, turn_pressure)
	var speed_kmh: float = absf(_car.get_speed_kmh())
	var throttle: float = 0.92
	var brake: float = 0.0

	if speed_kmh > speed_limit:
		throttle = 0.0
		brake = clampf((speed_kmh - speed_limit) / 30.0, 0.0, 0.75)
	elif absf(steering) > 0.75:
		throttle = 0.45

	_car.set_external_drive_inputs(throttle, brake, steering)


func _refresh_points() -> void:
	_points.clear()
	if _track == null:
		return

	if _track.has_method("get_racing_line_points"):
		var local_points: Array = _track.call("get_racing_line_points")
		for point: Variant in local_points:
			if point is Vector3:
				_points.append(_track.to_global(point))


func _update_target_index() -> void:
	var closest_index: int = _target_index
	var closest_distance: float = INF
	var car_position: Vector3 = _car.global_position

	for offset in _points.size():
		var point_index: int = (_target_index + offset) % _points.size()
		var distance: float = car_position.distance_squared_to(_get_lane_point(point_index))
		if distance < closest_distance:
			closest_distance = distance
			closest_index = point_index

	_target_index = closest_index
	if car_position.distance_to(_get_lane_point(_target_index)) < waypoint_reach_distance:
		_target_index = (_target_index + 1) % _points.size()


func _get_lane_point(index: int) -> Vector3:
	var previous: Vector3 = _points[(index - 1 + _points.size()) % _points.size()]
	var current: Vector3 = _points[index]
	var next: Vector3 = _points[(index + 1) % _points.size()]
	var tangent: Vector3 = (next - previous).normalized()
	var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
	return current + side * lane_offset + Vector3.UP * 0.05
