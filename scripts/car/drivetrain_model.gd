extends RefCounted
class_name DrivetrainModel

var idle_rpm: float = 900.0
var gear_ratios: Array[float] = []
var reverse_gear_ratio: float = 3.00
var final_drive_ratio: float = 3.70
var peak_engine_torque: float = 420.0
var wheel_radius: float = 0.34
var drivetrain_efficiency: float = 0.85
var vehicle_mass: float = 1200.0


func configure(
	target_idle_rpm: float,
	target_gear_ratios: Array[float],
	target_reverse_gear_ratio: float,
	target_final_drive_ratio: float,
	target_peak_engine_torque: float,
	target_wheel_radius: float,
	target_drivetrain_efficiency: float,
	target_vehicle_mass: float
) -> void:
	idle_rpm = target_idle_rpm
	gear_ratios.clear()
	gear_ratios.append_array(target_gear_ratios)
	reverse_gear_ratio = target_reverse_gear_ratio
	final_drive_ratio = target_final_drive_ratio
	peak_engine_torque = target_peak_engine_torque
	wheel_radius = target_wheel_radius
	drivetrain_efficiency = target_drivetrain_efficiency
	vehicle_mass = target_vehicle_mass


func get_coupled_engine_rpm_for_gear(gear: int, forward_speed: float) -> float:
	var wheel_circumference: float = TAU * wheel_radius
	if wheel_circumference <= 0.0:
		return idle_rpm

	var wheel_rpm: float = absf(forward_speed) / wheel_circumference * 60.0
	var gear_ratio: float = get_gear_ratio_for_gear(gear)
	return maxf(idle_rpm, wheel_rpm * gear_ratio * final_drive_ratio)


func get_drive_acceleration(
	throttle: float,
	current_gear: int,
	drive_blocked: bool,
	torque_multiplier: float,
	rev_limiter_multiplier: float,
	converter_multiplier: float
) -> float:
	if gear_ratios.is_empty() or current_gear == 0 or drive_blocked:
		return 0.0

	var wheel_force: float = get_wheel_drive_force(
		throttle,
		current_gear,
		torque_multiplier,
		rev_limiter_multiplier,
		converter_multiplier
	)
	if vehicle_mass <= 0.0:
		return 0.0

	return wheel_force / vehicle_mass


func get_wheel_drive_force(
	throttle: float,
	current_gear: int,
	torque_multiplier: float,
	rev_limiter_multiplier: float,
	converter_multiplier: float
) -> float:
	var engine_torque: float = peak_engine_torque * torque_multiplier * rev_limiter_multiplier * throttle * converter_multiplier
	var gear_ratio: float = get_gear_ratio_for_gear(current_gear)
	var wheel_torque: float = engine_torque * gear_ratio * final_drive_ratio * drivetrain_efficiency
	var safe_wheel_radius: float = maxf(wheel_radius, 0.01)

	return wheel_torque / safe_wheel_radius * get_drive_direction(current_gear)


func get_drive_direction(gear: int) -> float:
	if gear < 0:
		return -1.0

	return 1.0


func get_gear_ratio_for_gear(gear: int) -> float:
	if gear < 0:
		return reverse_gear_ratio

	if gear_ratios.is_empty():
		return 1.0

	var gear_index: int = clampi(gear - 1, 0, gear_ratios.size() - 1)
	return gear_ratios[gear_index]
