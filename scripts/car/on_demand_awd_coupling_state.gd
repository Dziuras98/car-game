extends RefCounted
class_name OnDemandAwdCouplingState

var clutch_command: float = 0.0
var clutch_engagement: float = 0.0
var front_torque_fraction: float = 0.0
var clutch_capacity_nm: float = 0.0
var transferred_torque_nm: float = 0.0
var axle_speed_difference_rad_s: float = 0.0
var thermal_energy_j: float = 0.0
var temperature_c: float = 25.0
var thermal_capacity_factor: float = 1.0
var simulation_remainder_s: float = 0.0


func reset(base_front_fraction: float = 0.0, ambient_temperature_c: float = 25.0) -> void:
	clutch_command = 0.0
	clutch_engagement = 0.0
	front_torque_fraction = clampf(base_front_fraction, 0.0, 1.0)
	clutch_capacity_nm = 0.0
	transferred_torque_nm = 0.0
	axle_speed_difference_rad_s = 0.0
	thermal_energy_j = 0.0
	temperature_c = ambient_temperature_c
	thermal_capacity_factor = 1.0
	simulation_remainder_s = 0.0
