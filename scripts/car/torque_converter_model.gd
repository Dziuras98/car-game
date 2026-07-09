extends RefCounted
class_name TorqueConverterModel

var idle_rpm: float = 900.0
var stall_rpm: float = 2600.0
var coupling_rpm: float = 4200.0
var stall_torque_multiplier: float = 1.65


func configure(
	target_idle_rpm: float,
	target_stall_rpm: float,
	target_coupling_rpm: float,
	target_stall_torque_multiplier: float
) -> void:
	idle_rpm = target_idle_rpm
	stall_rpm = target_stall_rpm
	coupling_rpm = target_coupling_rpm
	stall_torque_multiplier = target_stall_torque_multiplier


func get_coupled_rpm(coupled_rpm: float, drive_input: float) -> float:
	var stall_target_rpm: float = lerpf(idle_rpm, stall_rpm, clampf(drive_input, 0.0, 1.0))
	var unlocked_rpm: float = maxf(coupled_rpm, stall_target_rpm)
	var coupling_range: float = maxf(coupling_rpm - idle_rpm, 1.0)
	var coupling_ratio: float = clampf((coupled_rpm - idle_rpm) / coupling_range, 0.0, 1.0)

	return lerpf(unlocked_rpm, coupled_rpm, coupling_ratio)


func get_torque_multiplier(engine_rpm: float, drive_input: float) -> float:
	var coupling_range: float = maxf(coupling_rpm - idle_rpm, 1.0)
	var coupling_ratio: float = clampf((engine_rpm - idle_rpm) / coupling_range, 0.0, 1.0)
	var safe_stall_multiplier: float = maxf(stall_torque_multiplier, 1.0)
	var slipping_multiplier: float = lerpf(safe_stall_multiplier, 1.0, coupling_ratio)

	return lerpf(1.0, slipping_multiplier, clampf(drive_input, 0.0, 1.0))
