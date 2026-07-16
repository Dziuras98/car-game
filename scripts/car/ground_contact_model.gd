extends RefCounted
class_name GroundContactModel

const PROBE_COUNT: int = 4


func get_probe_local_positions(
	wheel_base: float,
	front_track_width: float,
	rear_track_width: float,
	probe_height: float,
	front_static_load_fraction: float = 0.5
) -> Array[Vector3]:
	var safe_wheel_base: float = maxf(wheel_base, 0.1)
	var safe_front_fraction: float = clampf(front_static_load_fraction, 0.10, 0.90)
	var front_forward_offset: float = safe_wheel_base * (1.0 - safe_front_fraction)
	var rear_forward_offset: float = -safe_wheel_base * safe_front_fraction
	var half_front_track: float = maxf(front_track_width, 0.1) * 0.5
	var half_rear_track: float = maxf(rear_track_width, 0.1) * 0.5
	var height: float = maxf(probe_height, 0.0)
	return [
		Vector3(-half_front_track, height, -front_forward_offset),
		Vector3(half_front_track, height, -front_forward_offset),
		Vector3(-half_rear_track, height, -rear_forward_offset),
		Vector3(half_rear_track, height, -rear_forward_offset),
	]


func calculate_spring_acceleration(
	hit_distance: float,
	rest_length: float,
	travel: float,
	normal_velocity: float,
	stiffness: float,
	damping: float
) -> float:
	var safe_rest_length: float = maxf(rest_length, 0.01)
	var safe_travel: float = maxf(travel, 0.01)
	var maximum_length: float = safe_rest_length + safe_travel
	if hit_distance < 0.0 or hit_distance > maximum_length:
		return 0.0
	var compression: float = clampf((maximum_length - hit_distance) / safe_travel, 0.0, 1.0)
	var spring_force: float = compression * maxf(stiffness, 0.0)
	var damping_force: float = normal_velocity * maxf(damping, 0.0)
	return maxf(spring_force - damping_force, 0.0)


func calculate_average_normal(normals: Array[Vector3]) -> Vector3:
	if normals.is_empty():
		return Vector3.UP
	var total: Vector3 = Vector3.ZERO
	for normal: Vector3 in normals:
		if normal.length_squared() > 0.000001:
			total += normal.normalized()
	if total.length_squared() <= 0.000001:
		return Vector3.UP
	return total.normalized()


func calculate_average_grip(grip_values: Array[float]) -> float:
	if grip_values.is_empty():
		return 1.0
	var total: float = 0.0
	for grip: float in grip_values:
		total += clampf(grip, 0.05, 2.0)
	return total / float(grip_values.size())
