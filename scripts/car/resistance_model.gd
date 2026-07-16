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
	return apply_local_velocity(
		Vector2(forward_speed, 0.0),
		delta,
		has_ground_contact,
		1.0
	).x


func apply_local_velocity(
	local_velocity: Vector2,
	delta: float,
	has_ground_contact: bool = true,
	lateral_area_multiplier: float = 1.0
) -> Vector2:
	var safe_delta: float = maxf(delta, 0.0)
	if safe_delta <= 0.0 or local_velocity.length_squared() < 0.0000001:
		return local_velocity
	var safe_mass: float = maxf(vehicle_mass, 1.0)
	var speed: float = local_velocity.length()
	var lateral_fraction: float = absf(local_velocity.y) / maxf(speed, 0.0001)
	var effective_area: float = frontal_area * lerpf(
		1.0,
		maxf(lateral_area_multiplier, 0.01),
		lateral_fraction
	)
	var drag_acceleration: float = (
		0.5
		* maxf(air_density, 0.0)
		* maxf(drag_coefficient, 0.0)
		* maxf(effective_area, 0.0)
		* speed
		* speed
		/ safe_mass
	)
	var rolling_acceleration: float = (
		maxf(rolling_resistance_coefficient, 0.0) * TireModel.STANDARD_GRAVITY
		if has_ground_contact
		else 0.0
	)
	var speed_reduction: float = (drag_acceleration + rolling_acceleration) * safe_delta
	if speed <= speed_reduction:
		return Vector2.ZERO
	return local_velocity * ((speed - speed_reduction) / speed)
