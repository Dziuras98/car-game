extends RefCounted
class_name VehicleMotionModel


func get_horizontal_velocity_vector(body_transform: Transform3D, forward_speed: float, lateral_speed: float) -> Vector3:
	var forward: Vector3 = get_forward_vector(body_transform)
	var right: Vector3 = get_right_vector(body_transform)
	return forward * forward_speed + right * lateral_speed


func get_local_speeds_from_horizontal_velocity(body_transform: Transform3D, horizontal_velocity: Vector3) -> Vector2:
	var forward: Vector3 = get_forward_vector(body_transform)
	var right: Vector3 = get_right_vector(body_transform)
	return Vector2(horizontal_velocity.dot(forward), horizontal_velocity.dot(right))


func get_forward_vector(body_transform: Transform3D) -> Vector3:
	return -body_transform.basis.z.normalized()


func get_right_vector(body_transform: Transform3D) -> Vector3:
	return body_transform.basis.x.normalized()
