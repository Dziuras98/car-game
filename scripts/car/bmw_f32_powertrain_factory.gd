extends RefCounted
class_name BmwF32PowertrainFactory


static func create(row: Dictionary, engine: Dictionary) -> TrafficRiderPowertrainDefinition:
	var definition := TrafficRiderPowertrainDefinition.new()
	var transmission: String = str(row.get("transmission_type", "6mt"))
	var drivetrain: String = str(row.get("drivetrain", "RWD"))
	var fuel: String = str(engine.get("fuel", "petrol"))
	var torque_nm: float = _number(engine, "torque_nm", 300.0)
	definition.resource_name = "BMW F32 %s %s simulated powertrain controls" % [transmission, drivetrain]

	if transmission == "8at":
		definition.planetary_automatic_enabled = true
		definition.torque_reduction_duration_s = 0.050 if fuel == "petrol" else 0.060
		definition.handover_duration_s = 0.048
		definition.inertia_duration_s = 0.078 if torque_nm < 500.0 else 0.092
		definition.reapply_duration_s = 0.085
		definition.minimum_torque_factor = 0.24 if fuel == "petrol" else 0.29
		definition.handover_torque_factor = 0.42
		definition.inertia_torque_factor = 0.66
		definition.maximum_skip_gears = 4
		definition.stall_torque_multiplier = 1.82 if fuel == "petrol" else 1.94
		definition.coupling_speed_ratio = 0.88
		definition.lockup_minimum_speed_mps = 3.5 if fuel == "petrol" else 3.0
		definition.lockup_minimum_gear = 2
		definition.lockup_maximum_throttle = 0.91
		definition.lockup_engage_rate_per_s = 3.8
		definition.lockup_release_rate_per_s = 7.0
		definition.commanded_lockup_slip_rpm = 55.0 if fuel == "petrol" else 75.0

	if drivetrain == "xDrive":
		definition.on_demand_awd_enabled = true
		definition.base_front_torque_fraction = 0.28
		definition.maximum_front_torque_fraction = 0.50
		definition.launch_clutch_command = 0.78
		definition.throttle_command_gain = 0.36
		definition.slip_command_gain = 1.30
		definition.stability_command_gain = 0.48
		definition.clutch_engage_rate_per_s = 6.5
		definition.clutch_release_rate_per_s = 3.2
		definition.maximum_transfer_clutch_capacity_nm = maxf(850.0, torque_nm * 2.15)
		definition.high_speed_release_start_mps = 44.0
		definition.high_speed_release_end_mps = 69.0
		definition.transfer_clutch_thermal_mass_j_per_c = 10500.0
		definition.transfer_clutch_cooling_w_per_c = 52.0
		definition.transfer_clutch_derate_start_c = 145.0
		definition.transfer_clutch_shutdown_c = 205.0
	return definition


static func _number(row: Dictionary, field: String, fallback: float) -> float:
	var text: String = str(row.get(field, "")).strip_edges()
	return text.to_float() if text.is_valid_float() else fallback
