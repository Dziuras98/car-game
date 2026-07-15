extends SceneTree

const SPECS: CarSpecs = preload("res://resources/cars/fiat/punto_176_1995/specs/punto_55_5mt_specs.tres")
const STEP: float = 1.0 / 120.0


func _initialize() -> void:
	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(SPECS)
	var state := CarRuntimeState.new()
	var controller := CarPowertrainController.new()
	controller.configure(config)
	state.reset_drive_state(config.idle_rpm)
	controller.reset(state)
	var elapsed: float = 0.0
	var next_sample: float = 0.0
	while elapsed < 24.0 and state.forward_speed < 100.0 / 3.6:
		state.ground_contact_count = GroundContactModel.PROBE_COUNT
		state.surface_grip_multiplier = 1.0
		var request_upshift: bool = false
		if state.shift_timer <= 0.0 and state.current_gear < config.gear_ratios.size():
			var upshift_rpm: float = minf(config.redline_rpm * 0.98, config.power_peak_rpm * 1.04)
			request_upshift = state.engine_rpm >= upshift_rpm
		controller.update(state, 1.0, 0.0, false, request_upshift, false, STEP)
		elapsed += STEP
		if elapsed + 0.0001 >= next_sample:
			var wheel: WheelTireState = state.get_wheel_state(WheelTireState.Position.FRONT_LEFT)
			print(
				"[WHEEL_DIAGNOSTIC] t=%.2f speed=%.2fkmh gear=%d rpm=%.0f clutch=%.3f omega=%.2f wheel_kmh=%.2f slip=%.3f requested=%.3f applied=%.3f drive_torque=%.1f tire_torque=%.1f"
				% [
					elapsed,
					state.forward_speed * 3.6,
					state.current_gear,
					state.engine_rpm,
					state.clutch_engagement,
					wheel.angular_velocity_rad_s,
					wheel.get_circumferential_speed_mps() * 3.6,
					wheel.longitudinal_slip_ratio,
					wheel.requested_longitudinal_acceleration,
					wheel.applied_longitudinal_acceleration,
					wheel.drive_torque_nm,
					wheel.tire_torque_nm,
				]
			)
			next_sample += 1.0
	print("[WHEEL_DIAGNOSTIC] completed t=%.2f speed=%.2fkmh" % [elapsed, state.forward_speed * 3.6])
	quit(0)
