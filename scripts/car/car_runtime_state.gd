extends RefCounted
class_name CarRuntimeState

var start_transform: Transform3D
var forward_speed: float = 0.0
var lateral_speed: float = 0.0
var engine_rpm: float = 900.0
var current_gear: int = 1
var shift_timer: float = 0.0
var clutch_engagement: float = 1.0
var throttle_input: float = 0.0
var brake_input: float = 0.0
var tire_slip_intensity: float = 0.0
var surface_grip_multiplier: float = 1.0
var ground_contact_count: int = 0
var ground_normal: Vector3 = Vector3.UP
var suspension_acceleration: float = 0.0


func reset_drive_state(idle_rpm: float) -> void:
	forward_speed = 0.0
	lateral_speed = 0.0
	engine_rpm = idle_rpm
	current_gear = 1
	shift_timer = 0.0
	clutch_engagement = 0.0
	throttle_input = 0.0
	brake_input = 0.0
	tire_slip_intensity = 0.0
	surface_grip_multiplier = 1.0
	ground_contact_count = 0
	ground_normal = Vector3.UP
	suspension_acceleration = 0.0


func reset_input_snapshot() -> void:
	throttle_input = 0.0
	brake_input = 0.0


func set_drive_input_snapshot(throttle: float, brake: float) -> void:
	throttle_input = clampf(throttle, 0.0, 1.0)
	brake_input = clampf(brake, 0.0, 1.0)
