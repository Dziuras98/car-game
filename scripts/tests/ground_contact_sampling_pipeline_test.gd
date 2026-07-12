extends SceneTree

const TEST_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


class CountingChassis:
	extends CarChassisController

	var sample_count: int = 0
	var tire_update_count: int = 0
	var apply_velocity_count: int = 0
	var skid_update_count: int = 0

	func sample_ground_contact(state: CarRuntimeState, _car: CharacterBody3D) -> void:
		sample_count += 1
		state.ground_contact_count = GroundContactModel.PROBE_COUNT
		state.ground_normal = Vector3.UP
		state.surface_grip_multiplier = 1.0
		state.suspension_acceleration = 0.0

	func update_tire_dynamics(
		state: CarRuntimeState,
		_steering: float,
		_handbrake_active: bool,
		_delta: float
	) -> void:
		tire_update_count += 1
		state.tire_slip_intensity = 0.0

	func update_steering(
		_state: CarRuntimeState,
		_steering: float,
		_car: CharacterBody3D,
		_delta: float
	) -> void:
		pass

	func apply_velocity(_state: CarRuntimeState, _car: CharacterBody3D, _delta: float) -> void:
		apply_velocity_count += 1

	func update_skid_marks(
		_state: CarRuntimeState,
		_car: CharacterBody3D,
		_skid_mark_emitter: SkidMarkEmitter,
		_delta: float
	) -> void:
		skid_update_count += 1


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var car: PlayerCarController = PlayerCarController.new()
	car.car_specs = TEST_SPECS
	root.add_child(car)
	car.set_physics_process(false)
	car.set_external_input_enabled(true)
	car.set_external_drive_inputs(0.5, 0.0, 0.25)

	var counting_chassis: CountingChassis = CountingChassis.new()
	car._chassis_controller = counting_chassis
	car._physics_process(0.10)

	_expect(counting_chassis.sample_count > 1, "a hitch-sized physics frame resamples ground contact for bounded substeps")
	_expect(
		counting_chassis.sample_count == counting_chassis.tire_update_count,
		"every hitch-sized contact sample feeds exactly one tire-dynamics step"
	)
	_expect(
		counting_chassis.sample_count == counting_chassis.apply_velocity_count,
		"every hitch-sized contact sample is followed by collision-resolved movement"
	)
	_expect(counting_chassis.skid_update_count == 1, "skid marks update once per physics frame")

	counting_chassis.sample_count = 0
	counting_chassis.tire_update_count = 0
	counting_chassis.apply_velocity_count = 0
	counting_chassis.skid_update_count = 0
	car._physics_process(1.0 / 120.0)
	_expect(counting_chassis.sample_count == 1, "a fine physics frame samples ground contact once")
	_expect(counting_chassis.tire_update_count == 1, "a fine frame needs one tire-dynamics step")
	_expect(counting_chassis.apply_velocity_count == 1, "a fine frame resolves movement once")
	_expect(counting_chassis.skid_update_count == 1, "a fine frame updates skid marks once")

	car.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[GROUND_CONTACT_SAMPLING_PIPELINE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[GROUND_CONTACT_SAMPLING_PIPELINE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[GROUND_CONTACT_SAMPLING_PIPELINE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[GROUND_CONTACT_SAMPLING_PIPELINE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[GROUND_CONTACT_SAMPLING_PIPELINE_TEST] - %s" % failure_message)
	quit(1)
