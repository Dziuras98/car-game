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
var lateral_slip_intensity: float = 0.0
var longitudinal_slip_ratio: float = 0.0
var longitudinal_slip_intensity: float = 0.0
var tire_slip_intensity: float = 0.0
var requested_longitudinal_acceleration: float = 0.0
var applied_longitudinal_acceleration: float = 0.0


func _init(index: int = Position.FRONT_LEFT) -> void:
	wheel_index = clampi(index, 0, WHEEL_COUNT - 1)


func is_front() -> bool:
	return wheel_index == Position.FRONT_LEFT or wheel_index == Position.FRONT_RIGHT


func is_rear() -> bool:
	return not is_front()


func is_left() -> bool:
	return wheel_index == Position.FRONT_LEFT or wheel_index == Position.REAR_LEFT


func reset() -> void:
	reset_contact()
	reset_tire_dynamics()


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
	lateral_slip_intensity = 0.0
	reset_longitudinal_dynamics()
	tire_slip_intensity = 0.0


func reset_longitudinal_dynamics() -> void:
	longitudinal_slip_ratio = 0.0
	longitudinal_slip_intensity = 0.0
	requested_longitudinal_acceleration = 0.0
	applied_longitudinal_acceleration = 0.0
