extends RefCounted
class_name ManualTransmissionModel


func get_requested_gear(current_gear: int, forward_gear_count: int) -> int:
	var next_gear: int = current_gear

	if Input.is_action_just_pressed("gear-up"):
		next_gear = mini(next_gear + 1, forward_gear_count)

	if Input.is_action_just_pressed("gear-down"):
		next_gear = maxi(next_gear - 1, -1)

	return next_gear
