extends SceneTree

const GRID_SCENE: PackedScene = preload("res://scenes/tracks/infinite_grid.tscn")
const BMW_MODEL: BmwE46ModelDefinition = preload("res://resources/cars/bmw/e46_sedan/model.tres")
const VARIANT_ID: StringName = &"bmw_e46_sedan_330i_5at"
const POWERED_SECONDS: float = 10.0
const TOTAL_SECONDS: float = 60.0
const SPEED_TOLERANCE_MPS: float = 0.35
const FINAL_SETTLE_SPEED_MPS: float = 0.02
const MAX_FULL_LOCK_SPEED_MPS: float = 20.0
const MAX_TOTAL_YAW_CHANGE_RAD: float = TAU * 2.0

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var track: Node3D = GRID_SCENE.instantiate() as Node3D
	root.add_child(track)

	var variant: CarVariantDefinition = BMW_MODEL.get_variant_by_id(VARIANT_ID)
	_expect(variant != null, "BMW E46 330i 5AT RWD variant exists")
	if variant == null:
		_finish(track, null)
		return
	_expect(variant.drivetrain_label == "RWD", "selected BMW E46 variant is rear-wheel drive")
	_expect(variant.specs.drive_layout == CarSpecs.DriveLayout.REAR_WHEEL_DRIVE, "runtime specs retain RWD layout")

	var car: PlayerCarController = variant.car_scene.instantiate() as PlayerCarController
	_expect(car != null, "BMW E46 player scene instantiates as PlayerCarController")
	if car == null:
		_finish(track, null)
		return
	car.car_specs = variant.specs
	car.position = Vector3(0.0, 0.72, 0.0)
	root.add_child(car)
	car.set_player_input_enabled(false)
	car.set_external_input_enabled(true)
	car.capture_current_transform_as_start()

	for _settle_frame: int in range(20):
		await physics_frame

	var tick_rate: int = Engine.physics_ticks_per_second
	var powered_ticks: int = int(round(POWERED_SECONDS * float(tick_rate)))
	var total_ticks: int = int(round(TOTAL_SECONDS * float(tick_rate)))
	var sample_interval: int = maxi(tick_rate, 1)
	var delta: float = 1.0 / float(tick_rate)
	var previous_position: Vector3 = car.global_position
	var start_position: Vector3 = car.global_position
	var previous_forward: Vector3 = -car.global_basis.z
	previous_forward.y = 0.0
	previous_forward = previous_forward.normalized()
	var total_yaw_change_rad: float = 0.0
	var max_center_speed: float = 0.0
	var speed_at_release: float = 0.0
	var final_center_speed: float = 0.0
	var max_reported_center_error: float = 0.0
	var max_snapshot_center_error: float = 0.0
	var max_velocity_displacement_error: float = 0.0
	var max_lateral_speed: float = 0.0
	var max_slip: float = 0.0
	var min_contacts: int = 4
	var max_rpm: float = 0.0
	var max_gear: int = 0
	var gear_change_count: int = 0
	var previous_gear: int = car.get_current_gear()
	var coast_speed_samples: PackedFloat32Array = PackedFloat32Array()

	print("[BMW_E46_RWD_FULL_LOCK_COAST_TEST] variant=%s tick_rate=%d powered=%.1fs total=%.1fs" % [str(VARIANT_ID), tick_rate, POWERED_SECONDS, TOTAL_SECONDS])

	for tick: int in range(total_ticks):
		var powered: bool = tick < powered_ticks
		car.set_external_drive_inputs(1.0 if powered else 0.0, 0.0, 1.0 if powered else 0.0)
		await physics_frame

		var telemetry: CarTelemetrySnapshot = car.get_telemetry_snapshot()
		var position: Vector3 = car.global_position
		var displacement: Vector3 = position - previous_position
		displacement.y = 0.0
		var displacement_speed: float = displacement.length() / delta
		var velocity_speed: float = Vector2(car.velocity.x, car.velocity.z).length()
		var component_speed: float = Vector2(telemetry.get_forward_speed(), telemetry.get_lateral_speed()).length()
		var reported_speed: float = car.get_speed_mps()
		var snapshot_speed: float = telemetry.get_speed_mps()
		var reported_error: float = absf(reported_speed - displacement_speed)
		var snapshot_error: float = absf(snapshot_speed - displacement_speed)
		var velocity_error: float = absf(velocity_speed - displacement_speed)
		var current_forward: Vector3 = -car.global_basis.z
		current_forward.y = 0.0
		if current_forward.length_squared() > 0.000001:
			current_forward = current_forward.normalized()
			total_yaw_change_rad += acos(clampf(previous_forward.dot(current_forward), -1.0, 1.0))
			previous_forward = current_forward

		max_center_speed = maxf(max_center_speed, displacement_speed)
		max_reported_center_error = maxf(max_reported_center_error, reported_error)
		max_snapshot_center_error = maxf(max_snapshot_center_error, snapshot_error)
		max_velocity_displacement_error = maxf(max_velocity_displacement_error, velocity_error)
		max_lateral_speed = maxf(max_lateral_speed, absf(telemetry.get_lateral_speed()))
		max_slip = maxf(max_slip, telemetry.get_tire_slip_intensity())
		min_contacts = mini(min_contacts, telemetry.get_ground_contact_count())
		max_rpm = maxf(max_rpm, telemetry.get_engine_rpm())
		max_gear = maxi(max_gear, telemetry.get_current_gear())
		if telemetry.get_current_gear() != previous_gear:
			gear_change_count += 1
			previous_gear = telemetry.get_current_gear()
		final_center_speed = displacement_speed
		if tick == powered_ticks - 1:
			speed_at_release = displacement_speed
		if tick >= powered_ticks and tick % sample_interval == 0:
			coast_speed_samples.append(displacement_speed)

		_expect_finite(position, "position", tick)
		_expect_finite(car.velocity, "velocity", tick)
		_expect_finite_scalar(telemetry.get_forward_speed(), "forward speed", tick)
		_expect_finite_scalar(telemetry.get_lateral_speed(), "lateral speed", tick)
		_expect_finite_scalar(telemetry.get_engine_rpm(), "engine RPM", tick)
		_expect_finite_scalar(telemetry.get_tire_slip_intensity(), "tire slip", tick)
		_expect_finite_scalar(telemetry.get_surface_grip_multiplier(), "surface grip", tick)
		_expect_finite_scalar(telemetry.get_suspension_acceleration(), "suspension acceleration", tick)

		if tick % sample_interval == 0 or tick == powered_ticks - 1 or tick == total_ticks - 1:
			print("[BMW_E46_RWD_FULL_LOCK_COAST_TEST][SAMPLE] t=%.1f phase=%s pos=(%.3f,%.3f,%.3f) center=%.3f velocity=%.3f components=%.3f reported=%.3f snapshot=%.3f forward=%.3f lateral=%.3f yaw_total_deg=%.2f rpm=%.1f gear=%d throttle=%.2f brake=%.2f slip=%.3f grip=%.3f contacts=%d" % [
				float(tick + 1) * delta,
				"powered" if powered else "coast",
				position.x,
				position.y,
				position.z,
				displacement_speed,
				velocity_speed,
				component_speed,
				reported_speed,
				snapshot_speed,
				telemetry.get_forward_speed(),
				telemetry.get_lateral_speed(),
				rad_to_deg(total_yaw_change_rad),
				telemetry.get_engine_rpm(),
				telemetry.get_current_gear(),
				telemetry.get_throttle_input(),
				telemetry.get_brake_input(),
				telemetry.get_tire_slip_intensity(),
				telemetry.get_surface_grip_multiplier(),
				telemetry.get_ground_contact_count(),
			])

		previous_position = position

	car.set_external_drive_inputs(0.0, 0.0, 0.0)
	var final_telemetry: CarTelemetrySnapshot = car.get_telemetry_snapshot()
	var travelled_distance: float = Vector2(car.global_position.x - start_position.x, car.global_position.z - start_position.z).length()

	_expect(max_center_speed > 2.0, "full throttle produces meaningful center-of-mass movement")
	_expect(max_center_speed <= MAX_FULL_LOCK_SPEED_MPS, "full-lock tire dynamics do not create implausible center speed")
	_expect(speed_at_release > 1.0, "car is moving when controls are released after ten seconds")
	_expect(max_lateral_speed > 0.25, "full steering lock creates a measurable lateral velocity component")
	_expect(total_yaw_change_rad > deg_to_rad(30.0), "full steering lock produces a substantial change of heading")
	_expect(total_yaw_change_rad <= MAX_TOTAL_YAW_CHANGE_RAD, "full-lock run does not accumulate runaway chassis rotation")
	_expect(max_slip > 0.05, "RWD full-throttle turn creates measurable tire slip")
	_expect(final_telemetry.get_tire_slip_intensity() <= 0.05, "tire slip clears after the stopped wheels settle")
	_expect(min_contacts >= 3, "car retains at least three ground contacts throughout the run")
	_expect(max_rpm <= variant.specs.rev_limiter_rpm + 150.0, "engine RPM remains bounded by the configured limiter")
	_expect(max_gear <= variant.specs.gear_ratios.size(), "automatic transmission never exceeds its configured top gear")
	_expect(gear_change_count <= 8, "automatic transmission does not hunt repeatedly between gears")
	_expect(final_telemetry.get_throttle_input() <= 0.001, "throttle snapshot clears during the coast phase")
	_expect(final_telemetry.get_brake_input() <= 0.001, "brake remains released during the coast phase")
	_expect(final_center_speed < speed_at_release, "car slows after all controls are released")
	_expect(final_center_speed <= FINAL_SETTLE_SPEED_MPS, "car center fully settles after fifty seconds without input")
	_expect(absf(final_telemetry.get_lateral_speed()) <= FINAL_SETTLE_SPEED_MPS, "residual lateral creep disappears after the coast phase")
	_expect(travelled_distance > 1.0, "the center of the car changes world position")
	_expect(max_velocity_displacement_error <= SPEED_TOLERANCE_MPS, "CharacterBody velocity matches measured center displacement speed")
	_expect(max_reported_center_error <= SPEED_TOLERANCE_MPS, "controller speed is the measured movement speed of the car center")
	_expect(max_snapshot_center_error <= SPEED_TOLERANCE_MPS, "telemetry speed is the measured movement speed of the car center")
	_expect(_mostly_non_increasing(coast_speed_samples), "coast-speed trend is predominantly non-increasing")

	print("[BMW_E46_RWD_FULL_LOCK_COAST_TEST][SUMMARY] max_center=%.3f release=%.3f final=%.3f max_lateral=%.3f final_lateral=%.3f yaw_total_deg=%.2f max_slip=%.3f final_slip=%.3f min_contacts=%d max_rpm=%.1f max_gear=%d gear_changes=%d travelled=%.3f max_reported_error=%.3f max_snapshot_error=%.3f max_velocity_error=%.3f" % [
		max_center_speed,
		speed_at_release,
		final_center_speed,
		max_lateral_speed,
		final_telemetry.get_lateral_speed(),
		rad_to_deg(total_yaw_change_rad),
		max_slip,
		final_telemetry.get_tire_slip_intensity(),
		min_contacts,
		max_rpm,
		max_gear,
		gear_change_count,
		travelled_distance,
		max_reported_center_error,
		max_snapshot_center_error,
		max_velocity_displacement_error,
	])
	_finish(track, car)


func _mostly_non_increasing(samples: PackedFloat32Array) -> bool:
	if samples.size() < 3:
		return false
	var increases: int = 0
	for index: int in range(1, samples.size()):
		if samples[index] > samples[index - 1] + 0.25:
			increases += 1
	return increases <= maxi(2, int(samples.size() * 0.12))


func _expect_finite(value: Vector3, label: String, tick: int) -> void:
	if value.is_finite():
		return
	_expect(false, "%s remains finite at tick %d" % [label, tick])


func _expect_finite_scalar(value: float, label: String, tick: int) -> void:
	if is_finite(value):
		return
	_expect(false, "%s remains finite at tick %d" % [label, tick])


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BMW_E46_RWD_FULL_LOCK_COAST_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[BMW_E46_RWD_FULL_LOCK_COAST_TEST][FAIL] %s" % message)


func _finish(track: Node, car: Node) -> void:
	if car != null:
		car.queue_free()
	if track != null:
		track.queue_free()
	await process_frame
	if _failures.is_empty():
		print("[BMW_E46_RWD_FULL_LOCK_COAST_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BMW_E46_RWD_FULL_LOCK_COAST_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[BMW_E46_RWD_FULL_LOCK_COAST_TEST] - %s" % failure_message)
	quit(1)
