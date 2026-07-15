extends SceneTree

const MANUAL_SPECS: CarSpecs = preload("res://resources/cars/ford/mustang_shelby_gt500_1967/specs/gt500_428_4mt_specs.tres")
const AUTOMATIC_SPECS: CarSpecs = preload("res://resources/cars/ford/mustang_shelby_gt500_1967/specs/gt500_428_3at_specs.tres")
const STEP: float = 1.0 / 120.0
const SIXTY_MPH_MPS: float = 26.8224


func _initialize() -> void:
	_run_case("manual", MANUAL_SPECS, true)
	_run_case("automatic", AUTOMATIC_SPECS, false)
	# Stop the calibration workflow immediately so its diagnostic artifact is available.
	quit(1)


func _run_case(label: String, specs: CarSpecs, request_manual_shifts: bool) -> void:
	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(specs)
	var state := CarRuntimeState.new()
	var controller := CarPowertrainController.new()
	controller.configure(config)
	state.reset_drive_state(config.idle_rpm)
	controller.reset(state)
	var elapsed: float = 0.0
	var next_sample: float = 0.0
	var zero_to_sixty: float = -1.0
	while elapsed < 30.0:
		state.ground_contact_count = GroundContactModel.PROBE_COUNT
		state.surface_grip_multiplier = 1.0
		var request_upshift: bool = false
		if request_manual_shifts and state.shift_timer <= 0.0 and state.current_gear < config.gear_ratios.size():
			request_upshift = state.engine_rpm >= 5700.0
		controller.update(state, 1.0, 0.0, false, request_upshift, false, STEP)
		elapsed += STEP
		if zero_to_sixty < 0.0 and state.forward_speed >= SIXTY_MPH_MPS:
			zero_to_sixty = elapsed
		if elapsed + 0.0001 >= next_sample:
			var wheel: WheelTireState = state.get_wheel_state(WheelTireState.Position.REAR_LEFT)
			print(
				"[MUSTANG_WHEEL_DIAGNOSTIC] case=%s t=%.2f speed=%.2fkmh gear=%d rpm=%.0f clutch=%.3f wheel_kmh=%.2f slip=%.3f requested=%.3f applied=%.3f drive_torque=%.1f tire_torque=%.1f"
				% [
					label,
					elapsed,
					state.forward_speed * 3.6,
					state.current_gear,
					state.engine_rpm,
					state.clutch_engagement,
					wheel.get_circumferential_speed_mps() * 3.6,
					wheel.longitudinal_slip_ratio,
					wheel.requested_longitudinal_acceleration,
					wheel.applied_longitudinal_acceleration,
					wheel.drive_torque_nm,
					wheel.tire_torque_nm,
				]
			)
			next_sample += 0.5
		if zero_to_sixty > 0.0 and elapsed >= zero_to_sixty + 1.0:
			break
	print("[MUSTANG_WHEEL_DIAGNOSTIC] case=%s completed zero_to_sixty=%.3f speed=%.2fkmh" % [label, zero_to_sixty, state.forward_speed * 3.6])
