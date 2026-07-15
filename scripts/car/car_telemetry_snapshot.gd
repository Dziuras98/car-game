extends RefCounted
class_name CarTelemetrySnapshot

var _forward_speed: float = 0.0
var _lateral_speed: float = 0.0
var _engine_rpm: float = 0.0
var _current_gear: int = 0
var _shift_timer: float = 0.0
var _clutch_engagement: float = 0.0
var _throttle_input: float = 0.0
var _brake_input: float = 0.0
var _tire_slip_intensity: float = 0.0
var _surface_grip_multiplier: float = 1.0
var _ground_contact_count: int = 0
var _ground_normal: Vector3 = Vector3.UP
var _suspension_acceleration: float = 0.0
var _wheel_angular_velocities: PackedFloat32Array = PackedFloat32Array()
var _wheel_angular_positions: PackedFloat32Array = PackedFloat32Array()
var _wheel_slip_ratios: PackedFloat32Array = PackedFloat32Array()


static func capture(state: CarRuntimeState) -> CarTelemetrySnapshot:
	var snapshot: CarTelemetrySnapshot = CarTelemetrySnapshot.new()
	if state == null:
		return snapshot
	snapshot._forward_speed = state.forward_speed
	snapshot._lateral_speed = state.lateral_speed
	snapshot._engine_rpm = state.engine_rpm
	snapshot._current_gear = state.current_gear
	snapshot._shift_timer = state.shift_timer
	snapshot._clutch_engagement = state.clutch_engagement
	snapshot._throttle_input = state.throttle_input
	snapshot._brake_input = state.brake_input
	snapshot._tire_slip_intensity = state.tire_slip_intensity
	snapshot._surface_grip_multiplier = state.surface_grip_multiplier
	snapshot._ground_contact_count = state.ground_contact_count
	snapshot._ground_normal = state.ground_normal
	snapshot._suspension_acceleration = state.suspension_acceleration
	snapshot._wheel_angular_velocities = state.get_wheel_angular_velocities()
	snapshot._wheel_angular_positions = state.get_wheel_angular_positions()
	for wheel: WheelTireState in state.wheel_states:
		snapshot._wheel_slip_ratios.append(wheel.longitudinal_slip_ratio)
	return snapshot


func get_forward_speed() -> float:
	return _forward_speed


func get_speed_kmh() -> float:
	return _forward_speed * 3.6


func get_lateral_speed() -> float:
	return _lateral_speed


func get_engine_rpm() -> float:
	return _engine_rpm


func get_current_gear() -> int:
	return _current_gear


func get_shift_timer() -> float:
	return _shift_timer


func get_clutch_engagement() -> float:
	return _clutch_engagement


func get_throttle_input() -> float:
	return _throttle_input


func get_brake_input() -> float:
	return _brake_input


func get_tire_slip_intensity() -> float:
	return _tire_slip_intensity


func get_surface_grip_multiplier() -> float:
	return _surface_grip_multiplier


func get_ground_contact_count() -> int:
	return _ground_contact_count


func get_ground_normal() -> Vector3:
	return _ground_normal


func get_suspension_acceleration() -> float:
	return _suspension_acceleration


func get_wheel_angular_velocities() -> PackedFloat32Array:
	return _wheel_angular_velocities.duplicate()


func get_wheel_angular_positions() -> PackedFloat32Array:
	return _wheel_angular_positions.duplicate()


func get_wheel_slip_ratios() -> PackedFloat32Array:
	return _wheel_slip_ratios.duplicate()
