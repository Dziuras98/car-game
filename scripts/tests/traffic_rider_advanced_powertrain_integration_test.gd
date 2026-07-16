extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_disabled_definition_is_explicit_and_valid()
	_test_incomplete_enabled_architecture_is_rejected()
	_test_planetary_shift_delays_engaged_gear()
	_test_planetary_shift_exposes_truthful_telemetry()
	_test_on_demand_awd_changes_axle_split()
	_test_controller_rejects_missing_definition()
	_finish()


func _test_disabled_definition_is_explicit_and_valid() -> void:
	var definition := TrafficRiderPowertrainDefinition.new()
	var config := _automatic_config(CarSpecs.DriveLayout.REAR_WHEEL_DRIVE)
	_expect(definition.validate_for(config).is_empty(), "explicit definition may disable optional advanced architectures")
	_expect(not definition.has_advanced_architecture(), "disabled definition does not infer architecture from gear count")


func _test_incomplete_enabled_architecture_is_rejected() -> void:
	var definition := TrafficRiderPowertrainDefinition.new()
	definition.planetary_automatic_enabled = true
	var errors: PackedStringArray = definition.validate_for(
		_automatic_config(CarSpecs.DriveLayout.REAR_WHEEL_DRIVE)
	)
	_expect(not errors.is_empty(), "enabled planetary automatic rejects absent phase/converter data")
	_expect(_contains_fragment(errors, "torque_reduction_duration_s"), "validation identifies missing phase duration")
	_expect(_contains_fragment(errors, "stall_torque_multiplier"), "validation identifies missing converter data")


func _test_planetary_shift_delays_engaged_gear() -> void:
	var controller := TrafficRiderPowertrainController.new()
	controller.set_powertrain_definition(_planetary_definition())
	controller.configure(_automatic_config(CarSpecs.DriveLayout.REAR_WHEEL_DRIVE))
	var state := _runtime_state(2)
	controller.reset(state)
	controller._set_transmission_gear(state, 4)
	_expect(state.current_gear == 2, "shift request does not swap the torque-carrying gear immediately")
	_expect(controller.get_selected_gear() == 4, "shift request records the selected target gear")
	controller.update(state, 0.0, 0.0, false, false, false, 0.05)
	_expect(state.current_gear == 2, "source gear remains engaged through reduction and early handover")
	controller.update(state, 0.0, 0.0, false, false, false, 0.06)
	_expect(state.current_gear == 4, "target gear engages only after handover completes")


func _test_planetary_shift_exposes_truthful_telemetry() -> void:
	var controller := TrafficRiderPowertrainController.new()
	controller.set_powertrain_definition(_planetary_definition())
	controller.configure(_automatic_config(CarSpecs.DriveLayout.REAR_WHEEL_DRIVE))
	var state := _runtime_state(3)
	controller.reset(state)
	controller._set_transmission_gear(state, 6)
	_expect(controller.get_gear_text(state) == "D3→D6", "gear display distinguishes source and selected gears")
	_expect(controller.get_shift_phase() == PlanetaryAutomaticRuntimeState.ShiftPhase.TORQUE_REDUCTION, "shift telemetry exposes the first phase")
	_expect(state.shift_timer > 0.0, "legacy shift-in-progress API receives truthful remaining time")
	controller.update(state, 0.35, 0.0, false, false, false, 0.02)
	_expect(controller.get_shift_progress() > 0.0, "shift progress advances with runtime integration")
	_expect(controller.get_converter_speed_ratio() >= 0.0, "converter telemetry remains finite")
	_expect(controller.get_converter_slip_rpm() >= 0.0, "converter slip telemetry remains non-negative")


func _test_on_demand_awd_changes_axle_split() -> void:
	var controller := TrafficRiderPowertrainController.new()
	controller.set_powertrain_definition(_awd_definition())
	controller.configure(_automatic_config(CarSpecs.DriveLayout.ALL_WHEEL_DRIVE))
	var state := _runtime_state(1)
	controller.reset(state)
	state.forward_speed = 4.0
	state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).angular_velocity_rad_s = 25.0
	state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT).angular_velocity_rad_s = 25.0
	state.get_wheel_state(WheelTireState.Position.REAR_LEFT).angular_velocity_rad_s = 70.0
	state.get_wheel_state(WheelTireState.Position.REAR_RIGHT).angular_velocity_rad_s = 70.0
	controller.update(state, 1.0, 0.0, false, false, false, 0.10)
	_expect(controller.get_dynamic_front_torque_fraction() > 0.0, "launch and rear overspeed command front-axle torque")
	_expect(controller.get_dynamic_front_torque_fraction() <= 0.50, "front torque stays within configured coupling limit")
	_expect(controller.get_transfer_clutch_temperature_c() >= 25.0, "transfer-clutch thermal telemetry is available")


func _test_controller_rejects_missing_definition() -> void:
	var controller := TrafficRiderPowertrainController.new()
	controller.configure(_automatic_config(CarSpecs.DriveLayout.REAR_WHEEL_DRIVE))
	_expect(not controller.has_valid_powertrain_definition(), "missing Traffic Rider definition is rejected")
	_expect(not controller.get_powertrain_definition_errors().is_empty(), "missing definition returns an actionable validation error")


func _automatic_config(layout: int) -> CarDriveConfig:
	var config := CarDriveConfig.new()
	config.transmission_type = CarSpecs.TransmissionType.AUTOMATIC
	config.gear_ratios = [4.714, 3.143, 2.106, 1.667, 1.285, 1.0, 0.839, 0.667]
	config.reverse_gear_ratio = 3.317
	config.final_drive_ratio = 3.154
	config.peak_engine_torque = 400.0
	config.idle_rpm = 700.0
	config.peak_torque_rpm = 3500.0
	config.redline_rpm = 7000.0
	config.rev_limiter_rpm = 7100.0
	config.automatic_upshift_rpm = 6500.0
	config.automatic_downshift_rpm = 1800.0
	config.automatic_kickdown_throttle = 0.80
	config.automatic_kickdown_rpm = 5200.0
	config.torque_converter_stall_rpm = 2400.0
	config.torque_converter_coupling_rpm = 4000.0
	config.torque_converter_stall_torque_multiplier = 1.85
	config.drive_layout = layout
	config.awd_front_torque_fraction = 0.0 if layout == CarSpecs.DriveLayout.ALL_WHEEL_DRIVE else 0.40
	config.vehicle_mass = 1600.0
	config.wheel_radius = 0.33
	config.max_forward_speed = 80.0
	config.max_drive_acceleration = 20.0
	config.sanitize()
	return config


func _planetary_definition() -> TrafficRiderPowertrainDefinition:
	var definition := TrafficRiderPowertrainDefinition.new()
	definition.planetary_automatic_enabled = true
	definition.torque_reduction_duration_s = 0.04
	definition.handover_duration_s = 0.06
	definition.inertia_duration_s = 0.08
	definition.reapply_duration_s = 0.07
	definition.minimum_torque_factor = 0.30
	definition.handover_torque_factor = 0.50
	definition.inertia_torque_factor = 0.72
	definition.maximum_skip_gears = 4
	definition.stall_torque_multiplier = 1.85
	definition.coupling_speed_ratio = 0.90
	definition.lockup_minimum_speed_mps = 7.0
	definition.lockup_minimum_gear = 2
	definition.lockup_maximum_throttle = 0.70
	definition.lockup_engage_rate_per_s = 4.0
	definition.lockup_release_rate_per_s = 10.0
	definition.commanded_lockup_slip_rpm = 35.0
	return definition


func _awd_definition() -> TrafficRiderPowertrainDefinition:
	var definition := TrafficRiderPowertrainDefinition.new()
	definition.on_demand_awd_enabled = true
	definition.base_front_torque_fraction = 0.0
	definition.maximum_front_torque_fraction = 0.50
	definition.launch_clutch_command = 0.65
	definition.throttle_command_gain = 0.45
	definition.slip_command_gain = 0.025
	definition.stability_command_gain = 0.70
	definition.clutch_engage_rate_per_s = 5.0
	definition.clutch_release_rate_per_s = 2.5
	definition.maximum_transfer_clutch_capacity_nm = 900.0
	definition.high_speed_release_start_mps = 45.0
	definition.high_speed_release_end_mps = 60.0
	definition.transfer_clutch_thermal_mass_j_per_c = 18000.0
	definition.transfer_clutch_cooling_w_per_c = 65.0
	definition.transfer_clutch_derate_start_c = 135.0
	definition.transfer_clutch_shutdown_c = 180.0
	return definition


func _runtime_state(initial_gear: int) -> CarRuntimeState:
	var state := CarRuntimeState.new()
	state.current_gear = initial_gear
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	state.ensure_wheel_states()
	for wheel: WheelTireState in state.wheel_states:
		wheel.has_contact = true
	return state


func _contains_fragment(errors: PackedStringArray, fragment: String) -> bool:
	for error_message: String in errors:
		if error_message.contains(fragment):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRAFFIC_RIDER_ADVANCED_POWERTRAIN_INTEGRATION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRAFFIC_RIDER_ADVANCED_POWERTRAIN_INTEGRATION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_ADVANCED_POWERTRAIN_INTEGRATION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_ADVANCED_POWERTRAIN_INTEGRATION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
