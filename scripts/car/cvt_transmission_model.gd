extends RefCounted
class_name CvtTransmissionModel

const MIN_DYNAMIC_RATIO: float = 0.01
const DIRECTION_CHANGE_SPEED_THRESHOLD: float = 0.55

var idle_rpm: float = 900.0
var max_ratio: float = 2.50
var reverse_ratio: float = 2.50
var final_drive_ratio: float = 4.00
var wheel_radius: float = 0.28
var peak_engine_torque: float = 100.0
var drivetrain_efficiency: float = 0.82
var vehicle_mass: float = 900.0
var target_rpm_min: float = 1800.0
var target_rpm_max: float = 5500.0
var ratio_response: float = 8.0
var clutch_engagement_rpm: float = 1250.0
var clutch_full_rpm: float = 2200.0

var _current_ratio: float = 2.50
var _target_rpm: float = 1800.0


func configure(
	target_idle_rpm: float,
	target_max_ratio: float,
	target_reverse_ratio: float,
	target_final_drive_ratio: float,
	target_wheel_radius: float,
	target_peak_engine_torque: float,
	target_drivetrain_efficiency: float,
	target_vehicle_mass: float,
	target_rpm_floor: float,
	target_rpm_ceiling: float,
	target_ratio_response: float,
	target_clutch_engagement_rpm: float,
	target_clutch_full_rpm: float
) -> void:
	idle_rpm = maxf(target_idle_rpm, 1.0)
	max_ratio = maxf(target_max_ratio, MIN_DYNAMIC_RATIO)
	reverse_ratio = maxf(target_reverse_ratio, MIN_DYNAMIC_RATIO)
	final_drive_ratio = maxf(target_final_drive_ratio, MIN_DYNAMIC_RATIO)
	wheel_radius = maxf(target_wheel_radius, 0.01)
	peak_engine_torque = maxf(target_peak_engine_torque, 0.0)
	drivetrain_efficiency = clampf(target_drivetrain_efficiency, 0.0001, 1.0)
	vehicle_mass = maxf(target_vehicle_mass, 1.0)
	target_rpm_min = maxf(target_rpm_floor, idle_rpm)
	target_rpm_max = maxf(target_rpm_ceiling, target_rpm_min)
	ratio_response = maxf(target_ratio_response, 0.01)
	clutch_engagement_rpm = maxf(target_clutch_engagement_rpm, idle_rpm)
	clutch_full_rpm = maxf(target_clutch_full_rpm, clutch_engagement_rpm + 1.0)
	reset()


func reset() -> void:
	_current_ratio = max_ratio
	_target_rpm = target_rpm_min


func update_ratio(forward_speed: float, throttle: float, delta: float) -> float:
	_target_rpm = get_commanded_engine_rpm(throttle)
	var wheel_rpm: float = _get_wheel_rpm(forward_speed)
	var desired_ratio: float = max_ratio
	if wheel_rpm > 0.01:
		desired_ratio = _target_rpm / (wheel_rpm * final_drive_ratio)
	# There is intentionally no configurable minimum ratio. The epsilon exists only
	# to keep divisions finite; as speed increases the ratio may continue toward zero.
	desired_ratio = clampf(desired_ratio, MIN_DYNAMIC_RATIO, max_ratio)
	var blend: float = 1.0 - exp(-ratio_response * maxf(delta, 0.0))
	_current_ratio = lerpf(_current_ratio, desired_ratio, blend)
	_current_ratio = clampf(_current_ratio, MIN_DYNAMIC_RATIO, max_ratio)
	return _current_ratio


func get_commanded_engine_rpm(throttle: float) -> float:
	var load: float = pow(clampf(throttle, 0.0, 1.0), 0.62)
	return lerpf(target_rpm_min, target_rpm_max, load)


func get_coupled_engine_rpm(forward_speed: float, current_gear: int) -> float:
	var ratio: float = reverse_ratio if current_gear < 0 else _current_ratio
	return maxf(idle_rpm, _get_wheel_rpm(forward_speed) * ratio * final_drive_ratio)


func get_clutch_factor(engine_rpm: float) -> float:
	var span: float = maxf(clutch_full_rpm - clutch_engagement_rpm, 1.0)
	var normalized: float = clampf((engine_rpm - clutch_engagement_rpm) / span, 0.0, 1.0)
	return normalized * normalized * (3.0 - 2.0 * normalized)


func get_drive_acceleration(
	throttle: float,
	current_gear: int,
	drive_blocked: bool,
	engine_rpm: float,
	torque_multiplier: float,
	rev_limiter_multiplier: float
) -> float:
	if current_gear == 0 or drive_blocked:
		return 0.0
	var ratio: float = reverse_ratio if current_gear < 0 else _current_ratio
	var clutch_factor: float = get_clutch_factor(engine_rpm)
	var engine_torque: float = (
		peak_engine_torque
		* maxf(torque_multiplier, 0.0)
		* maxf(rev_limiter_multiplier, 0.0)
		* clampf(throttle, 0.0, 1.0)
		* clutch_factor
	)
	var wheel_torque: float = engine_torque * ratio * final_drive_ratio * drivetrain_efficiency
	var wheel_force: float = wheel_torque / wheel_radius
	var direction: float = -1.0 if current_gear < 0 else 1.0
	return wheel_force / vehicle_mass * direction


func get_current_ratio() -> float:
	return _current_ratio


func get_target_rpm() -> float:
	return _target_rpm


func _get_wheel_rpm(forward_speed: float) -> float:
	var circumference: float = TAU * wheel_radius
	if circumference <= 0.0:
		return 0.0
	return absf(forward_speed) / circumference * 60.0
