extends Node
class_name AiRaceDriver

signal driver_fault(message: String)

enum DriverState {
	FOLLOW_LINE,
	RECOVERY_BRAKE_TO_STOP,
	RECOVERY_ENGAGE_REVERSE,
	RECOVERY_REVERSE_UNTIL_CLEAR,
	RECOVERY_RETURN_TO_FORWARD,
}

const MIN_RACING_LINE_POINT_COUNT: int = 3

var _car: PlayerCarController
var _track: GeneratedTrack
var _profile: AiDriverProfile
var _points: Array[Vector3] = []
var _target_index: int = -1
var _enabled: bool = false
var _configured: bool = false
var _fault_reported: bool = false
var _index_search: RacingLineIndexSearch = RacingLineIndexSearch.new()
var _driver_state: DriverState = DriverState.FOLLOW_LINE
var _stuck_timer: float = 0.0
var _recovery_timer: float = 0.0
var _recovery_start_position: Vector3 = Vector3.ZERO
var _last_steering: float = 0.0
var _point_revision: int = 0


func configure(
	car: PlayerCarController,
	track: GeneratedTrack,
	profile: AiDriverProfile
) -> bool:
	if is_inside_tree():
		push_error("AiRaceDriver must be configured before entering the scene tree.")
		return false
	if car == null:
		push_error("AiRaceDriver requires a PlayerCarController.")
		return false
	if track == null or not track.has_committed_generation():
		push_error("AiRaceDriver requires a committed GeneratedTrack.")
		return false
	if profile == null:
		push_error("AiRaceDriver requires an AiDriverProfile.")
		return false
	var profile_errors: PackedStringArray = profile.validate()
	if not profile_errors.is_empty():
		push_error("AiRaceDriver received an invalid profile: %s" % "; ".join(profile_errors))
		return false
	if not _has_usable_racing_line(track):
		push_error("AiRaceDriver requires at least three finite racing-line points.")
		return false

	_car = car
	_track = track
	_profile = profile.duplicate_profile()
	_index_search.configure(
		_profile.search_points_behind,
		_profile.search_points_ahead,
		_profile.recovery_search_distance,
		_profile.full_search_interval_updates
	)
	_fault_reported = false
	_configured = true
	return true


func _ready() -> void:
	set_physics_process(false)
	if not _has_valid_runtime_contract():
		_fail_driver("AiRaceDriver entered the scene tree without a valid runtime contract.")
		return

	_connect_track_geometry_signal()
	if not _refresh_points():
		_fail_driver("AiRaceDriver could not refresh its validated racing line.")
		return

	_car.set_external_input_enabled(true)
	_neutralize_car_input(false)
	set_physics_process(_enabled)


func _exit_tree() -> void:
	_disconnect_track_geometry_signal()
	_neutralize_car_input(true)


func set_driver_enabled(enabled: bool) -> void:
	_enabled = enabled
	_reset_driver_state()
	if not enabled:
		set_physics_process(false)
		_neutralize_car_input(false)
		return
	if not _has_valid_runtime_contract() or _points.size() < MIN_RACING_LINE_POINT_COUNT:
		_fail_driver("AiRaceDriver cannot be enabled without a valid car, track, profile and racing line.")
		return
	_fault_reported = false
	_car.set_external_input_enabled(true)
	set_physics_process(true)


func is_configured() -> bool:
	return _has_valid_runtime_contract()


func get_profile() -> AiDriverProfile:
	return _profile.duplicate_profile() if _profile != null else null


func get_last_search_check_count() -> int:
	return _index_search.get_last_distance_check_count()


func get_point_revision() -> int:
	return _point_revision


func get_cached_point_count() -> int:
	return _points.size()


func get_driver_state() -> DriverState:
	return _driver_state


func _physics_process(delta: float) -> void:
	if not _enabled:
		set_physics_process(false)
		return
	if not _has_valid_runtime_contract():
		_fail_driver("AiRaceDriver lost its runtime contract.")
		return
	if _points.size() < MIN_RACING_LINE_POINT_COUNT:
		if not _refresh_points():
			_fail_driver("AiRaceDriver lost its racing-line cache.")
			return

	var safe_delta: float = maxf(delta, 0.0)
	if _driver_state != DriverState.FOLLOW_LINE:
		_update_recovery(safe_delta)
		return

	if not _update_target_index():
		_fail_driver("AiRaceDriver could not resolve a valid racing-line target.")
		return
	var lookahead_index: int = posmod(_target_index + _profile.lookahead_points, _points.size())
	var target_point: Vector3 = _get_lane_point(lookahead_index)
	var local_target: Vector3 = _car.to_local(target_point)
	var steering: float = clampf(local_target.x / maxf(absf(local_target.z), 8.0), -1.0, 1.0)
	_last_steering = steering
	var turn_pressure: float = clampf(absf(steering) * 1.45, 0.0, 1.0)
	var speed_limit: float = lerpf(_profile.target_speed_kmh, _profile.corner_speed_kmh, turn_pressure)
	var speed_kmh: float = absf(_car.get_speed_kmh())
	var throttle: float = 0.92
	var brake: float = 0.0

	if speed_kmh > speed_limit:
		throttle = 0.0
		brake = clampf((speed_kmh - speed_limit) / 30.0, 0.0, 0.75)
	elif absf(steering) > 0.75:
		throttle = 0.45

	_car.set_external_drive_inputs(throttle, brake, steering)
	_update_stuck_detection(speed_kmh, throttle, local_target, safe_delta)


func _has_valid_runtime_contract() -> bool:
	return (
		_configured
		and is_instance_valid(_car)
		and is_instance_valid(_track)
		and _track.has_committed_generation()
		and _profile != null
		and _profile.is_valid()
	)


func _reset_driver_state() -> void:
	_stuck_timer = 0.0
	_recovery_timer = 0.0
	_recovery_start_position = Vector3.ZERO
	_driver_state = DriverState.FOLLOW_LINE
	_last_steering = 0.0


func _neutralize_car_input(disable_external_input: bool) -> void:
	if not is_instance_valid(_car):
		return
	_car.set_external_drive_inputs(0.0, 0.0, 0.0, false)
	if disable_external_input:
		_car.set_external_input_enabled(false)


func _fail_driver(message: String) -> void:
	_enabled = false
	set_physics_process(false)
	if is_instance_valid(_car):
		_car.set_external_input_enabled(true)
		if _car.get_current_gear() < 0 or _car.get_speed_kmh() < 0.0:
			_car.set_external_drive_inputs(1.0, 0.0, 0.0, false)
		else:
			_car.set_external_drive_inputs(0.0, 0.85, 0.0, false)
	if _fault_reported:
		return
	_fault_reported = true
	push_error(message)
	driver_fault.emit(message)


func _update_stuck_detection(speed_kmh: float, throttle: float, local_target: Vector3, delta: float) -> void:
	var target_is_behind: bool = local_target.z > 4.0
	if (throttle > 0.4 and speed_kmh < 2.0) or target_is_behind:
		_stuck_timer += delta
	else:
		_stuck_timer = maxf(_stuck_timer - delta * 2.0, 0.0)
	if _stuck_timer >= _profile.stuck_detection_seconds:
		_begin_recovery()


func _begin_recovery() -> void:
	_driver_state = DriverState.RECOVERY_BRAKE_TO_STOP
	_recovery_timer = maxf(_profile.reverse_engage_timeout_seconds, 0.01)
	_recovery_start_position = _car.global_position
	_stuck_timer = 0.0


func _update_recovery(delta: float) -> void:
	var recovery_steering: float = _get_recovery_steering()
	var signed_speed_kmh: float = _car.get_speed_kmh()
	var stop_speed: float = _profile.recovery_stop_speed_kmh
	match _driver_state:
		DriverState.RECOVERY_BRAKE_TO_STOP:
			if signed_speed_kmh < -stop_speed:
				_car.set_external_drive_inputs(1.0, 0.0, recovery_steering)
			else:
				_car.set_external_drive_inputs(0.0, 0.8, recovery_steering)
			if absf(signed_speed_kmh) <= stop_speed:
				_driver_state = DriverState.RECOVERY_ENGAGE_REVERSE
				_recovery_timer = _profile.reverse_engage_timeout_seconds
				return
			_recovery_timer -= delta
			if _recovery_timer <= 0.0:
				_fail_driver("AiRaceDriver could not stop before engaging reverse during recovery.")
		DriverState.RECOVERY_ENGAGE_REVERSE:
			_car.set_external_drive_inputs(0.0, 0.8, recovery_steering)
			if (
				_car.get_current_gear() < 0
				and signed_speed_kmh < -stop_speed * 0.25
			):
				_driver_state = DriverState.RECOVERY_REVERSE_UNTIL_CLEAR
				_recovery_start_position = _car.global_position
				_recovery_timer = _profile.reverse_recovery_seconds
				return
			_recovery_timer -= delta
			if _recovery_timer <= 0.0:
				_fail_driver("AiRaceDriver could not engage reverse during recovery.")
		DriverState.RECOVERY_REVERSE_UNTIL_CLEAR:
			_car.set_external_drive_inputs(0.0, 0.8, recovery_steering)
			var displacement: Vector3 = _car.global_position - _recovery_start_position
			displacement.y = 0.0
			var reverse_is_confirmed: bool = (
				_car.get_current_gear() < 0
				and signed_speed_kmh < -stop_speed * 0.25
			)
			if reverse_is_confirmed and displacement.length() >= _profile.reverse_recovery_distance:
				_driver_state = DriverState.RECOVERY_RETURN_TO_FORWARD
				_recovery_timer = _profile.reverse_engage_timeout_seconds
				return
			_recovery_timer -= delta
			if _recovery_timer <= 0.0:
				_fail_driver("AiRaceDriver did not achieve the required reverse recovery distance.")
		DriverState.RECOVERY_RETURN_TO_FORWARD:
			_car.set_external_drive_inputs(1.0, 0.0, recovery_steering)
			if _car.get_current_gear() > 0 and signed_speed_kmh >= -stop_speed * 0.25:
				_finish_recovery()
				return
			_recovery_timer -= delta
			if _recovery_timer <= 0.0:
				_fail_driver("AiRaceDriver could not return to a forward gear after recovery.")
		_:
			_finish_recovery()


func _get_recovery_steering() -> float:
	var recovery_steering: float = -signf(_last_steering)
	if is_zero_approx(recovery_steering):
		return 0.65
	return recovery_steering


func _finish_recovery() -> void:
	_driver_state = DriverState.FOLLOW_LINE
	_recovery_timer = 0.0
	_recovery_start_position = Vector3.ZERO
	_target_index = -1
	_index_search.reset()


func _refresh_points() -> bool:
	_points.clear()
	_target_index = -1
	_index_search.reset()
	if not _has_valid_runtime_contract():
		return false

	for local_point: Vector3 in _track.get_racing_line_points():
		var global_point: Vector3 = _track.to_global(local_point)
		if not _is_finite_vector3(global_point):
			_points.clear()
			return false
		_points.append(global_point)
	if _points.size() < MIN_RACING_LINE_POINT_COUNT:
		_points.clear()
		return false
	_point_revision += 1
	return true


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
	var refreshed: bool = _refresh_points()
	if not refreshed:
		_fail_driver("AiRaceDriver could not refresh after a track geometry rebuild.")
		return
	set_physics_process(_enabled and _has_valid_runtime_contract())


func _update_target_index() -> bool:
	if _points.size() < MIN_RACING_LINE_POINT_COUNT:
		return false
	_target_index = _index_search.find_nearest_index(
		_points,
		_car.global_position,
		_target_index
	)
	if _target_index < 0 or _target_index >= _points.size():
		return false
	if _car.global_position.distance_to(_get_lane_point(_target_index)) < _profile.waypoint_reach_distance:
		_target_index = (_target_index + 1) % _points.size()
	return true


func _get_lane_point(index: int) -> Vector3:
	var safe_index: int = posmod(index, _points.size())
	var previous: Vector3 = _points[posmod(safe_index - 1, _points.size())]
	var current: Vector3 = _points[safe_index]
	var next: Vector3 = _points[(safe_index + 1) % _points.size()]
	var tangent: Vector3 = (next - previous).normalized()
	var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
	return current + side * _profile.lane_offset + Vector3.UP * 0.05


func _has_usable_racing_line(track: GeneratedTrack) -> bool:
	var local_points: Array[Vector3] = track.get_racing_line_points()
	if local_points.size() < MIN_RACING_LINE_POINT_COUNT:
		return false
	for local_point: Vector3 in local_points:
		if not _is_finite_vector3(track.to_global(local_point)):
			return false
	return true


func _is_finite_vector3(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
