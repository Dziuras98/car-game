extends SceneTree

const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const STEP: float = 1.0 / 120.0
const SIMULATION_SECONDS: float = 2.5
const STEERING_INPUT: float = 0.28
const TEST_SPEED_MPS: float = 13.888889

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_expect(CATALOG != null, "production car catalog loads")
	if CATALOG == null:
		_finish()
		return
	var variants: Array[CarVariantDefinition] = CATALOG.get_all_variants()
	_expect(not variants.is_empty(), "production catalog exposes variants for lateral calibration")
	for variant: CarVariantDefinition in variants:
		_test_variant(variant)
	print("[CATALOG_LATERAL_DYNAMICS] calibrated_variants=%d" % variants.size())
	_finish()


func _test_variant(variant: CarVariantDefinition) -> void:
	var label: String = str(variant.variant_id) if variant != null else "<null>"
	_expect(variant != null and variant.specs != null, "%s exposes specs" % label)
	if variant == null or variant.specs == null:
		return
	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(variant.specs)
	_expect(config != null, "%s builds a lateral dynamics configuration" % label)
	if config == null:
		return

	var chassis := CarChassisController.new()
	chassis.configure(config)
	var state := CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	state.forward_speed = minf(TEST_SPEED_MPS, config.max_forward_speed * 0.72)
	state.forward_speed = maxf(state.forward_speed, 6.0)
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	state.surface_grip_multiplier = 1.0
	state.synchronize_wheel_contacts_from_aggregate()

	var initial_speed: float = state.forward_speed
	var simulation_steps: int = int(round(SIMULATION_SECONDS / STEP))
	for _step_index: int in range(simulation_steps):
		state.forward_speed = initial_speed
		chassis.update_tire_dynamics(state, STEERING_INPUT, false, STEP)

	var force_acceleration: float = _get_total_lateral_force(state) / maxf(config.vehicle_mass, 1.0)
	var geometric_center_angle: float = deg_to_rad(config.max_steering_angle_degrees) * STEERING_INPUT
	var geometric_radius: float = config.wheel_base / maxf(tan(absf(geometric_center_angle)), 0.001)
	var dynamic_radius: float = initial_speed / maxf(absf(state.yaw_rate_rad_s), 0.001)
	var maximum_calibrated_acceleration: float = maxf(
		config.front_lateral_grip,
		config.rear_lateral_grip
	) * 1.20

	_expect(state.yaw_rate_rad_s > 0.005, "%s produces right-turn yaw from right-steered tire forces" % label)
	_expect(force_acceleration > 0.02, "%s produces rightward lateral force from the front slip angles" % label)
	_expect(absf(state.yaw_rate_rad_s) <= config.steering_speed + 0.001, "%s remains inside its calibrated yaw-rate safety envelope" % label)
	_expect(absf(force_acceleration) <= maximum_calibrated_acceleration, "%s lateral force remains inside tire grip calibration" % label)
	_expect(dynamic_radius >= geometric_radius * 0.45, "%s does not turn unrealistically tighter than its steering geometry" % label)
	_expect(dynamic_radius <= geometric_radius * 4.5, "%s responds within the catalog steering calibration envelope" % label)
	_expect(_wheel_states_are_finite(state), "%s keeps every wheel force and slip state finite" % label)
	_expect(
		state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT).steering_angle_rad
		> state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).steering_angle_rad,
		"%s applies Ackermann geometry to the inner front wheel" % label
	)
	_expect(is_zero_approx(state.get_wheel_state(WheelTireState.Position.REAR_LEFT).steering_angle_rad), "%s keeps rear wheels unsteered" % label)

	print(
		"[CATALOG_LATERAL_DYNAMICS] id=%s speed_kmh=%.2f yaw_rate=%.4f lateral_accel=%.4f radius=%.2f geometric_radius=%.2f"
		% [
			label,
			initial_speed * 3.6,
			state.yaw_rate_rad_s,
			force_acceleration,
			dynamic_radius,
			geometric_radius,
		]
	)


func _get_total_lateral_force(state: CarRuntimeState) -> float:
	var total_force: float = 0.0
	for wheel: WheelTireState in state.wheel_states:
		total_force += wheel.lateral_force_n
	return total_force


func _wheel_states_are_finite(state: CarRuntimeState) -> bool:
	if not is_finite(state.yaw_rate_rad_s) or not is_finite(state.lateral_speed):
		return false
	for wheel: WheelTireState in state.wheel_states:
		if (
			not is_finite(wheel.steering_angle_rad)
			or not is_finite(wheel.lateral_slip_angle_rad)
			or not is_finite(wheel.lateral_force_n)
			or not is_finite(wheel.lateral_slip_intensity)
		):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CATALOG_LATERAL_DYNAMICS_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CATALOG_LATERAL_DYNAMICS_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CATALOG_LATERAL_DYNAMICS_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CATALOG_LATERAL_DYNAMICS_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CATALOG_LATERAL_DYNAMICS_TEST] - %s" % failure_message)
	quit(1)
