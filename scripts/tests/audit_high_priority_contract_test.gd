extends SceneTree

const DEFAULT_TRACK_DEFINITION: TrackDefinition = preload("res://resources/tracks/simple_oval_definition.tres")
const GAME_MANAGER_SCRIPT: Script = preload("res://scripts/game/game_manager.gd")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_ground_probe_configuration_contract()
	await _test_transactional_car_specs()
	await _test_same_track_definition_rollback()
	await _test_runtime_track_rebuild_lock()
	_test_geometry_validation_and_side_effect_free_getter()
	_test_lap_count_is_not_silently_corrected()
	_finish()


func _test_ground_probe_configuration_contract() -> void:
	var specs: CarSpecs = _build_valid_specs()
	specs.ground_probe_collision_mask = 0
	_expect(not specs.is_valid(), "ground probe mask rejects an empty layer selection")
	specs.ground_probe_collision_mask = 4
	specs.minimum_ground_normal_dot = 0.4
	_expect(specs.is_valid(), "ground probe mask and slope threshold accept explicit valid values")
	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(specs)
	_expect(config != null, "ground probe configuration maps into the runtime config")
	if config != null:
		_expect(config.ground_probe_collision_mask == 4, "runtime config preserves the dedicated probe mask")
		_expect(is_equal_approx(config.minimum_ground_normal_dot, 0.4), "runtime config preserves the ground-normal threshold")
	var chassis_source: String = FileAccess.get_file_as_string("res://scripts/car/car_chassis_controller.gd")
	_expect(chassis_source.contains("_ray_query.collision_mask = _config.ground_probe_collision_mask"), "chassis probes do not reuse the car collision mask")
	_expect(chassis_source.contains("as TrackSurfaceBody"), "chassis probes require a typed track surface")
	_expect(chassis_source.contains("hit_normal.dot(Vector3.UP) < _config.minimum_ground_normal_dot"), "chassis probes reject wall and inverted normals")


func _test_transactional_car_specs() -> void:
	var host: Node3D = Node3D.new()
	get_root().add_child(host)
	var initial_specs: CarSpecs = _build_valid_specs()
	initial_specs.display_name = "Initial valid specs"
	var car: PlayerCarController = PlayerCarController.new()
	car.car_specs = initial_specs
	host.add_child(car)
	await process_frame

	var invalid_specs: CarSpecs = initial_specs.duplicate(true) as CarSpecs
	invalid_specs.display_name = ""
	var invalid_result: PlayerCarController.SpecsApplyResult = car.try_apply_car_specs(invalid_specs)
	_expect(invalid_result == PlayerCarController.SpecsApplyResult.INVALID_SPECS, "invalid runtime specs return a typed rejection")
	_expect(car.car_specs == initial_specs, "invalid runtime specs preserve the committed specs resource")
	_expect(car.is_physics_processing(), "invalid runtime specs do not disable a working car")

	var replacement_specs: CarSpecs = initial_specs.duplicate(true) as CarSpecs
	replacement_specs.display_name = "Replacement valid specs"
	replacement_specs.max_forward_speed = initial_specs.max_forward_speed - 1.0
	var valid_result: PlayerCarController.SpecsApplyResult = car.try_apply_car_specs(replacement_specs)
	_expect(valid_result == PlayerCarController.SpecsApplyResult.OK, "valid runtime specs commit successfully")
	_expect(car.car_specs == replacement_specs, "valid runtime specs replace the committed resource")

	host.queue_free()
	await process_frame


func _test_same_track_definition_rollback() -> void:
	var host: Node3D = Node3D.new()
	get_root().add_child(host)
	var controller: TrackSpawnController = TrackSpawnController.new()
	controller.configure(host)
	var original_definition: TrackDefinition = DEFAULT_TRACK_DEFINITION
	var original_track: GeneratedTrack = controller.spawn_track(original_definition)
	_expect(is_instance_valid(original_track), "baseline track can be committed")
	if not is_instance_valid(original_track):
		host.queue_free()
		await process_frame
		return

	var replacement_definition: TrackDefinition = original_definition.duplicate(true) as TrackDefinition
	replacement_definition.recommended_laps = original_definition.recommended_laps + 2
	_expect(controller.stage_track(replacement_definition) == original_track, "same-ID replacement stages the active track instance")
	_expect(controller.commit_staged_track() == original_track, "same-ID replacement can be provisionally committed")
	_expect(controller.get_current_definition() == replacement_definition, "provisional same-ID commit exposes the replacement definition")
	controller.rollback_track_transaction()
	_expect(controller.get_current_track() == original_track, "same-ID rollback preserves the active track instance")
	_expect(controller.get_current_definition() == original_definition, "same-ID rollback restores the original definition object")

	host.queue_free()
	await process_frame


func _test_runtime_track_rebuild_lock() -> void:
	var host: Node3D = Node3D.new()
	get_root().add_child(host)
	var track: GeneratedTrack = DEFAULT_TRACK_DEFINITION.instantiate_track()
	track.track_layout = track.track_layout.duplicate(true) as TrackLayoutResource
	host.add_child(track)
	await process_frame
	var initial_rebuild_count: int = track.get_rebuild_count()
	_expect(initial_rebuild_count > 0, "track has committed geometry before the lock test")
	track.set_runtime_rebuild_locked(true)
	track.track_layout.track_width += 0.5
	await process_frame
	await process_frame
	_expect(track.get_rebuild_count() == initial_rebuild_count, "runtime rebuild lock defers layout mutations")
	track.set_runtime_rebuild_locked(false)
	await process_frame
	await process_frame
	_expect(track.get_rebuild_count() == initial_rebuild_count + 1, "unlock applies one coalesced deferred rebuild")

	host.queue_free()
	await process_frame


func _test_geometry_validation_and_side_effect_free_getter() -> void:
	var empty_track: GeneratedTrack = GeneratedTrack.new()
	_expect(empty_track.get_racing_line_points().is_empty(), "racing-line getter returns no provisional geometry")
	_expect(empty_track.get_rebuild_count() == 0, "racing-line getter does not trigger generation")
	empty_track.free()

	var invalid_geometry: TrackGeometryData = TrackGeometryData.new()
	invalid_geometry.center_points = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.RIGHT])
	invalid_geometry.left_edge_points = PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
	invalid_geometry.right_edge_points = PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
	invalid_geometry.left_shoulder_outer_points = PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
	invalid_geometry.right_shoulder_outer_points = PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
	invalid_geometry.racing_line_points = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.RIGHT])
	invalid_geometry.forward_vectors = PackedVector3Array([Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD])
	invalid_geometry.right_vectors = PackedVector3Array([Vector3.RIGHT, Vector3.RIGHT, Vector3.RIGHT])
	invalid_geometry.half_widths = PackedFloat32Array([1.0, 1.0, 1.0])
	_expect(not invalid_geometry.is_valid(), "deep geometry validation rejects degenerate segments and collapsed edges")


func _test_lap_count_is_not_silently_corrected() -> void:
	var manager: Node = GAME_MANAGER_SCRIPT.new()
	manager.set("use_track_recommended_laps", false)
	manager.set("race_lap_count", 0)
	_expect(int(manager.call("_resolve_lap_count", DEFAULT_TRACK_DEFINITION)) == 0, "invalid configured lap count is preserved for rejection")
	manager.free()


func _build_valid_specs() -> CarSpecs:
	var specs: CarSpecs = CarSpecs.new()
	specs.display_name = "Audit regression specs"
	specs.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	specs.engine_force = 30.0
	specs.brake_deceleration = 30.0
	specs.reverse_acceleration = 10.0
	specs.max_forward_speed = 30.0
	specs.max_reverse_speed = 10.0
	return specs


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[AUDIT_HIGH_PRIORITY_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[AUDIT_HIGH_PRIORITY_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[AUDIT_HIGH_PRIORITY_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[AUDIT_HIGH_PRIORITY_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[AUDIT_HIGH_PRIORITY_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
