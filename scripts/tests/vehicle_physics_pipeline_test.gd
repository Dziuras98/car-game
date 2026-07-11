extends Node

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var dry_floor: StaticBody3D = _create_floor("DrySurface", Vector3(-4.0, -0.1, 0.0), 1.0)
	var low_grip_floor: StaticBody3D = _create_floor("LowGripSurface", Vector3(4.0, -0.1, 0.0), 0.5)
	var specs: CarSpecs = _build_specs()
	var dry_car: PlayerCarController = _create_car("DryCar", Vector3(-4.0, 0.0, 0.0), specs)
	var low_grip_car: PlayerCarController = _create_car("LowGripCar", Vector3(4.0, 0.0, 0.0), specs)
	var airborne_car: PlayerCarController = _create_car("AirborneCar", Vector3(0.0, 3.0, 0.0), specs)

	await get_tree().physics_frame
	for car: PlayerCarController in [dry_car, low_grip_car, airborne_car]:
		car.set_external_input_enabled(true)
	dry_car.set_external_drive_inputs(1.0, 0.0, 0.0)
	low_grip_car.set_external_drive_inputs(1.0, 0.0, 0.0)
	airborne_car.set_external_drive_inputs(1.0, 0.0, 1.0)

	var airborne_basis_before: Basis = airborne_car.global_transform.basis
	dry_car._physics_process(0.10)
	low_grip_car._physics_process(0.10)
	airborne_car._physics_process(0.10)

	_expect(dry_car._runtime_state.ground_contact_count == 4, "dry car samples four current-frame contacts before powertrain integration")
	_expect(low_grip_car._runtime_state.ground_contact_count == 4, "low-grip car samples four current-frame contacts before powertrain integration")
	_expect(is_equal_approx(dry_car._runtime_state.surface_grip_multiplier, 1.0), "dry car reads the current asphalt grip value")
	_expect(is_equal_approx(low_grip_car._runtime_state.surface_grip_multiplier, 0.5), "low-grip car reads the current surface grip value")
	_expect(dry_car.get_forward_speed() > low_grip_car.get_forward_speed(), "current-frame low grip reduces acceleration without a one-frame delay")
	_expect(low_grip_car.get_forward_speed() > 0.0, "low-grip surface still transmits a reduced drive force")

	_expect(airborne_car._runtime_state.ground_contact_count == 0, "airborne car reports no tire contacts")
	_expect(is_zero_approx(airborne_car.get_forward_speed()), "airborne throttle does not accelerate vehicle translation")
	_expect(airborne_car.get_engine_rpm() > specs.idle_rpm, "airborne throttle can free-rev the engine")
	_expect(_bases_match(airborne_car.global_transform.basis, airborne_basis_before), "airborne steering input does not rotate the chassis")

	dry_car.queue_free()
	low_grip_car.queue_free()
	airborne_car.queue_free()
	dry_floor.queue_free()
	low_grip_floor.queue_free()
	await get_tree().process_frame
	_finish()


func _create_floor(
	floor_name: String,
	position: Vector3,
	grip_multiplier: float
) -> StaticBody3D:
	var floor: StaticBody3D = StaticBody3D.new()
	floor.name = floor_name
	floor.position = position
	floor.collision_layer = 1
	floor.collision_mask = 1
	floor.set_meta("surface_grip_multiplier", grip_multiplier)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(6.0, 0.2, 6.0)
	collision.shape = shape
	floor.add_child(collision)
	add_child(floor)
	return floor


func _create_car(
	car_name: String,
	position: Vector3,
	specs: CarSpecs
) -> PlayerCarController:
	var car: PlayerCarController = PlayerCarController.new()
	car.name = car_name
	car.position = position
	car.collision_layer = 1
	car.collision_mask = 1
	car.car_specs = specs
	add_child(car)
	car.set_physics_process(false)
	return car


func _build_specs() -> CarSpecs:
	var specs: CarSpecs = CarSpecs.new()
	specs.display_name = "Vehicle physics pipeline test"
	specs.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	specs.engine_force = 30.0
	specs.brake_deceleration = 30.0
	specs.reverse_acceleration = 10.0
	specs.coast_deceleration = 0.0
	specs.engine_brake_force = 0.0
	specs.handbrake_deceleration = 18.0
	specs.max_forward_speed = 40.0
	specs.max_reverse_speed = 10.0
	specs.drag_coefficient = 0.0
	specs.rolling_resistance_coefficient = 0.0
	specs.suspension_stiffness = 0.0
	specs.suspension_damping = 0.0
	return specs


func _bases_match(left: Basis, right: Basis) -> bool:
	return (
		left.x.distance_to(right.x) <= 0.001
		and left.y.distance_to(right.y) <= 0.001
		and left.z.distance_to(right.z) <= 0.001
	)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[VEHICLE_PHYSICS_PIPELINE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[VEHICLE_PHYSICS_PIPELINE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[VEHICLE_PHYSICS_PIPELINE_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[VEHICLE_PHYSICS_PIPELINE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[VEHICLE_PHYSICS_PIPELINE_TEST] - %s" % failure_message)
	get_tree().quit(1)
