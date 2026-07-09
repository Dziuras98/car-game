extends RefCounted
class_name ShiftTimerModel


func update_timer(current_timer: float, delta: float) -> float:
	if current_timer <= 0.0:
		return 0.0

	return maxf(current_timer - delta, 0.0)


func get_shift_delay(automatic_enabled: bool, automatic_delay: float, manual_delay: float) -> float:
	return automatic_delay if automatic_enabled else manual_delay
