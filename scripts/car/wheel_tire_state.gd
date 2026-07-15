extends RefCounted
class_name WheelTireState

enum Position {
	FRONT_LEFT,
	FRONT_RIGHT,
	REAR_LEFT,
	REAR_RIGHT,
}

const WHEEL_COUNT: int = 4

var wheel_index: int = Position.FRONT_LEFT
var has_contact: bool = false
var surface_grip_multiplier: float = 1.0
var contact_normal: Vector3 = Vector3.UP
var suspension_acceleration: float = 0.0
var steering_angle_rad: float = 0.0
var lateral_slip_angle_rad: float = 0.0
var lateral_force_n: float = 0.0
var lateral_slip_intensity: float = 0.0
var longitudinal_slip_ratio: float = 0.0
var longitudinal_slip_intensity: float = 0.0
var tire_slip_intensity: float = 0.0
var requested_longitudinal_acceleration: float = 0.0
var applied_longitudinal_acceleration: float = 0.0
var wheel_radius_m: float = 0.34
var moment_of_inertia_kg_m2: float = 1.5
var angular_velocity_rad_s: float = 0.0
var angular_acceleration_rad_s2: float = 0.0
var angular_position_rad: float = 0.0
var drive_torque_nm: float = 0.0
var brake_torque_nm: float = 0.0
var tire_torque_nm: float = 0.0


func _init(index: int = Position.FRONT_LEFT) -> void:
	wheel_index = clampi(index, 0, WHEEL_COUNT - 1)


func is_front() -> bool:
	return wheel_index == Position.FRONT_LEFT or wheel_index == Position.FRONT_RIGHT


func is_rear() -> bool:
	return not is_front()


func is_left() -> bool:
	return wheel_index == Position.FRONT_LEFT or wheel_index == Position.REAR_LEFT


func configure_rotation(radius_m: float, inertia_kg_m2: float) -> void:
	wheel_radius_m = maxf(radius_m, 0.01)
	moment_of_inertia_kg_m2 = maxf(inertia_kg_m2, 0.01)


func get_circumferential_speed_mps() -> float:
	return angular_velocity_rad_s * wheel_radius_m


func get_rpm() -> float:
	return angular_velocity_rad_s * 60.0 / TAU


func set_rolling_speed(forward_speed_mps: float) -> void:
	angular_velocity_rad_s = forward_speed_mps / maxf(wheel_radius_m, 0.01)
	angular_acceleration_rad_s2 = 0.0


func integrate_rotation(delta: float) -> void:
	angular_position_rad = fposmod(
		angular_position_rad + angular_velocity_rad_s * maxf(delta, 0.0),
		TAU
	)


func reset() -> void:
	reset_contact()
	steering_angle_rad = 0.0
	reset_tire_dynamics()
	reset_rotation()


func reset_contact() -> void:
	has_contact = false
	surface_grip_multiplier = 1.0
	contact_normal = Vector3.UP
	suspension_acceleration = 0.0


func set_contact(
	grip_multiplier: float,
	normal: Vector3,
	support_acceleration: float
) -> void:
	has_contact = true
	surface_grip_multiplier = clampf(grip_multiplier, 0.05, 2.0)
	contact_normal = normal.normalized() if normal.length_squared() > 0.000001 else Vector3.UP
	suspension_acceleration = maxf(support_acceleration, 0.0)


func reset_tire_dynamics() -> void:
	reset_lateral_dynamics()
	reset_longitudinal_dynamics()
	tire_slip_intensity = 0.0


func reset_lateral_dynamics() -> void:
	lateral_slip_angle_rad = 0.0
	lateral_force_n = 0.0
	lateral_slip_intensity = 0.0


func reset_longitudinal_dynamics() -> void:
	longitudinal_slip_ratio = 0.0
	longitudinal_slip_intensity = 0.0
	requested_longitudinal_acceleration = 0.0
	applied_longitudinal_acceleration = 0.0
	drive_torque_nm = 0.0
	brake_torque_nm = 0.0
	tire_torque_nm = 0.0
	angular_acceleration_rad_s2 = 0.0


func reset_rotation() -> void:
	angular_velocity_rad_s = 0.0
	angular_acceleration_rad_s2 = 0.0
	angular_position_rad = 0.0
	drive_torque_nm = 0.0
	brake_torque_nm = 0.0
	tire_torque_nm = 0.0
