extends RefCounted
class_name ResistanceModel

var vehicle_mass: float = 1200.0
var drag_coefficient: float = 0.30
var frontal_area: float = 2.05
var air_density: float = 1.225
var rolling_resistance_coefficient: float = 0.015


func configure(
	target_vehicle_mass: float,
	target_drag_coefficient: float,
	target_frontal_area: float,
	target_air_density: float,
	target_rolling_resistance_coefficient: float
) -> void:
	vehicle_mass = target_vehicle_mass
	drag_coefficient = target_drag_coefficient
	frontal_area = target_frontal_area
	air_density = target_air_density
	rolling_resistance_coefficient = target_rolling_resistance_coefficient


func apply(forward_speed: float, delta: float, has_ground_contact: bool = true) -> float:
	if absf(forward_speed) < 0.01:
		return forward_speed

	var direction: float = signf(forward_speed)
	var safe_mass: float = maxf(vehicle_mass, 1.0)
	var drag_force: float = 0.5 * air_density * drag_coefficient * frontal_area * forward_speed * forward_speed
	var drag_acceleration: float = drag_force / safe_mass
	var rolling_acceleration: float = (
		rolling_resistance_coefficient * 9.81
		if has_ground_contact
		else 0.0
	)
	var resistance_delta: float = (drag_acceleration + rolling_acceleration) * maxf(delta, 0.0)

	if absf(forward_speed) <= resistance_delta:
		return 0.0

	return forward_speed - direction * resistance_delta
