extends RefCounted
class_name ManualTransmissionModel


func get_requested_gear(current_gear: int, forward_gear_count: int, gear_up_pressed: bool, gear_down_pressed: bool) -> int:
	var next_gear: int = current_gear

	if gear_up_pressed:
		next_gear = mini(next_gear + 1, forward_gear_count)

	if gear_down_pressed:
		next_gear = maxi(next_gear - 1, -1)

	return next_gear
