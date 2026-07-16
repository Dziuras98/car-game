extends RefCounted
class_name VehicleMotionModel


func get_horizontal_velocity_vector(body_transform: Transform3D, forward_speed: float, lateral_speed: float) -> Vector3:
	return get_velocity_vector(body_transform, forward_speed, lateral_speed, Vector3.UP)


func get_velocity_vector(
	body_transform: Transform3D,
	forward_speed: float,
	lateral_speed: float,
	ground_normal: Vector3 = Vector3.UP
) -> Vector3:
	var forward: Vector3 = get_forward_vector(body_transform, ground_normal)
	var right: Vector3 = get_right_vector(body_transform, ground_normal)
	return forward * forward_speed + right * lateral_speed


func get_local_speeds_from_horizontal_velocity(body_transform: Transform3D, horizontal_velocity: Vector3) -> Vector2:
	return get_local_speeds_from_velocity(body_transform, horizontal_velocity, Vector3.UP)


func get_local_speeds_from_velocity(
	body_transform: Transform3D,
	velocity: Vector3,
	ground_normal: Vector3 = Vector3.UP
) -> Vector2:
	var forward: Vector3 = get_forward_vector(body_transform, ground_normal)
	var right: Vector3 = get_right_vector(body_transform, ground_normal)
	return Vector2(velocity.dot(forward), velocity.dot(right))


func get_forward_vector(body_transform: Transform3D, ground_normal: Vector3 = Vector3.UP) -> Vector3:
	var normal: Vector3 = ground_normal.normalized() if ground_normal.length_squared() > 0.000001 else Vector3.UP
	var projected: Vector3 = (-body_transform.basis.z).slide(normal)
	if projected.length_squared() <= 0.000001:
		projected = Vector3.FORWARD.slide(normal)
	return projected.normalized()


func get_right_vector(body_transform: Transform3D, ground_normal: Vector3 = Vector3.UP) -> Vector3:
	var normal: Vector3 = ground_normal.normalized() if ground_normal.length_squared() > 0.000001 else Vector3.UP
	var forward: Vector3 = get_forward_vector(body_transform, normal)
	var right: Vector3 = forward.cross(normal)
	if right.length_squared() <= 0.000001:
		right = body_transform.basis.x.slide(normal)
	return right.normalized()
