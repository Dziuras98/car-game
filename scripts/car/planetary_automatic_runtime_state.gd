extends RefCounted
class_name PlanetaryAutomaticRuntimeState

enum ShiftPhase {
	IDLE,
	TORQUE_REDUCTION,
	HANDOVER,
	INERTIA,
	REAPPLY,
}

var selected_gear: int = 1
var engaged_gear: int = 1
var source_gear: int = 1
var target_gear: int = 1
var shift_phase: int = ShiftPhase.IDLE
var phase_elapsed_s: float = 0.0
var shift_progress: float = 1.0
var torque_transfer_factor: float = 1.0
var converter_speed_ratio: float = 1.0
var converter_slip_rpm: float = 0.0
var converter_torque_multiplier: float = 1.0
var lockup_engagement: float = 0.0
var lockup_target: float = 0.0
var simulation_remainder_s: float = 0.0


func reset(initial_gear: int = 1) -> void:
	selected_gear = initial_gear
	engaged_gear = initial_gear
	source_gear = initial_gear
	target_gear = initial_gear
	shift_phase = ShiftPhase.IDLE
	phase_elapsed_s = 0.0
	shift_progress = 1.0
	torque_transfer_factor = 1.0
	converter_speed_ratio = 1.0
	converter_slip_rpm = 0.0
	converter_torque_multiplier = 1.0
	lockup_engagement = 0.0
	lockup_target = 0.0
	simulation_remainder_s = 0.0


func is_shifting() -> bool:
	return shift_phase != ShiftPhase.IDLE
