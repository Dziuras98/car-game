extends Node
class_name AiRaceDriver

enum DriverState {
	FOLLOW_LINE,
	RECOVER_REVERSE,
}

@export var car_path: NodePath
@export var track_path: NodePath
@export var lane_offset: float = 0.0
@export var lookahead_points: int = 5
@export var target_speed_kmh: float = 118.0
@export var corner_speed_kmh: float = 78.0
@export var waypoint_reach_distance: float = 8.0
@export_range(0, 64, 1) var search_points_behind: int = 4
@export_range(0, 64, 1) var search_points_ahead: int = 14
@export var recovery_search_distance: float = 45.0
@export_range(1, 600, 1) var full_search_interval_updates: int = 120
@export_range(0.1, 10.0, 0.1) var stuck_detection_seconds: float = 1.5
@export_range(0.1, 5.0, 0.1) var reverse_recovery_seconds: float = 1.0

var _car: PlayerCarController
var _track: Node3D
var _points: Array[Vector3] = []
var _target_index: int = -1
var _enabled: bool = false
var _index_search: RacingLineIndexSearch = RacingLineIndexSearch.new()
var _driver_state: DriverState = DriverState.FOLLOW_LINE
var _stuck_timer: float = 0.0
var _recovery_timer: float = 0.0
var _last_steering: float = 0.0
var _point_revision: int = 0


func _ready() -> void:
	_car = get_node_or_null(car_path) as PlayerCarController
	_track = get_node_or_null(track_path) as Node3D
	_index_search.configure(
		search_points_behind,
		search_points_ahead,
		recovery_search_distance,
		full_search_interval_updates
	)
	_connect_track_geometry_signal()
	_refresh_points()

	if _car != null:
		_car.set_external_input_enabled(true)
		_car.set_external_drive_inputs(0.0, 0.0, 0.0)
	set_physics_process(false)


func _exit_tree() -> void:
	_disconnect_track_geometry_signal()


func set_driver_enabled(enabled: bool) -> void:
	_enabled = enabled
	_stuck_timer = 0.0
	_recovery_timer = 0.0
	_driver_state = DriverState.FOLLOW_LINE
	set_physics_process(enabled and is_instance_valid(_car))
	if is_instance_valid(_car):
		_car.set_external_drive_inputs(0.0, 0.0, 0.0)


func _physics_process(delta: float) -> void:
	if not _enabled or not is_instance_valid(_car):
		return
	if _points.is_empty():
		_refresh_points()
		if _points.is_empty():
			_car.set_external_drive_inputs(0.0, 0.0, 0.0)
			return

	if _driver_state == DriverState.RECOVER_REVERSE:
		_update_reverse_recovery(delta)
		return

	_update_target_index()
	var target_point: Vector3 = _get_lane_point((_target_index + lookahead_points) % _points.size())
	var local_target: Vector3 = _car.to_local(target_point)
	var steering: float = clampf(local_target.x / maxf(absf(local_target.z), 8.0), -1.0, 1.0)
	_last_steering = steering
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
	_update_stuck_detection(speed_kmh, throttle, local_target, delta)


func get_last_search_check_count_for_test() -> int:
	return _index_search.get_last_distance_check_count()


func get_point_revision_for_test() -> int:
	return _point_revision


func get_driver_state_for_test() -> DriverState:
	return _driver_state


func _update_stuck_detection(speed_kmh: float, throttle: float, local_target: Vector3, delta: float) -> void:
	var target_is_behind: bool = local_target.z > 4.0
	if (throttle > 0.4 and speed_kmh < 2.0) or target_is_behind:
		_stuck_timer += delta
	else:
		_stuck_timer = maxf(_stuck_timer - delta * 2.0, 0.0)
	if _stuck_timer >= stuck_detection_seconds:
		_driver_state = DriverState.RECOVER_REVERSE
		_recovery_timer = reverse_recovery_seconds
		_stuck_timer = 0.0


func _update_reverse_recovery(delta: float) -> void:
	_recovery_timer -= delta
	var recovery_steering: float = -signf(_last_steering)
	if is_zero_approx(recovery_steering):
		recovery_steering = 0.65
	_car.set_external_drive_inputs(0.0, 0.8, recovery_steering)
	if _recovery_timer <= 0.0:
		_driver_state = DriverState.FOLLOW_LINE
		_target_index = -1
		_index_search.reset()


func _refresh_points() -> void:
	_points.clear()
	_target_index = -1
	_index_search.reset()
	if not is_instance_valid(_track) or not _track.has_method("get_racing_line_points"):
		return
	var local_points: Array = _track.call("get_racing_line_points")
	for point: Variant in local_points:
		if point is Vector3:
			_points.append(_track.to_global(point))
	_point_revision += 1


func _connect_track_geometry_signal() -> void:
	if not is_instance_valid(_track) or not _track.has_signal("geometry_rebuilt"):
		return
	var callback: Callable = Callable(self, "_on_track_geometry_rebuilt")
	if not _track.is_connected("geometry_rebuilt", callback):
		_track.connect("geometry_rebuilt", callback)


func _disconnect_track_geometry_signal() -> void:
	if not is_instance_valid(_track) or not _track.has_signal("geometry_rebuilt"):
		return
	var callback: Callable = Callable(self, "_on_track_geometry_rebuilt")
	if _track.is_connected("geometry_rebuilt", callback):
		_track.disconnect("geometry_rebuilt", callback)


func _on_track_geometry_rebuilt(_revision: int) -> void:
	_refresh_points()


func _update_target_index() -> void:
	_target_index = _index_search.find_nearest_index(
		_points,
		_car.global_position,
		_target_index
	)
	if _car.global_position.distance_to(_get_lane_point(_target_index)) < waypoint_reach_distance:
		_target_index = (_target_index + 1) % _points.size()


func _get_lane_point(index: int) -> Vector3:
	var previous: Vector3 = _points[(index - 1 + _points.size()) % _points.size()]
	var current: Vector3 = _points[index]
	var next: Vector3 = _points[(index + 1) % _points.size()]
	var tangent: Vector3 = (next - previous).normalized()
	var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
	return current + side * lane_offset + Vector3.UP * 0.05
