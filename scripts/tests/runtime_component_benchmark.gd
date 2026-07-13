extends SceneTree

const TRACK_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const AI_CAR_SCENE: PackedScene = preload("res://scenes/cars/370z_ai.tscn")
const AUTOMATIC_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

const PHYSICS_FPS: int = 60
const AI_COUNT: int = 3
const PARTICIPANT_COUNT: int = 4
const SUBSTEPS_PER_FRAME: int = 2
const AI_UPDATES_PER_SECOND: int = AI_COUNT * PHYSICS_FPS
const PARTICIPANT_UPDATES_PER_SECOND: int = PARTICIPANT_COUNT * PHYSICS_FPS
const VEHICLE_SUBSTEP_UPDATES_PER_SECOND: int = PARTICIPANT_COUNT * PHYSICS_FPS * SUBSTEPS_PER_FRAME
const AUDIO_BUDGET_CHECKS_PER_SECOND: int = PARTICIPANT_COUNT * 5
const SAMPLE_COUNT: int = 5

var _track: GeneratedTrack
var _car: PlayerCarController
var _points: Array[Vector3] = []
var _profile: AiDriverProfile = AiDriverProfile.new()
var _searches: Array[RacingLineIndexSearch] = []
var _search_indices: Array[int] = []
var _projector: RacingLineProjector = RacingLineProjector.new()
var _projection_buffers: Array[RacingLineProjection] = []
var _projection_indices: Array[int] = []
var _projection_positions: Array[Vector3] = []
var _projection_validity: Array[bool] = []
var _tire_model: TireModel = TireModel.new()
var _powertrains: Array[CarPowertrainController] = []
var _powertrain_states: Array[CarRuntimeState] = []
var _chassis: CarChassisController = CarChassisController.new()
var _chassis_state: CarRuntimeState = CarRuntimeState.new()
var _skid_emitter: SkidMarkEmitter = SkidMarkEmitter.new()
var _drive_config: CarDriveConfig

var _sink_bool: bool = false
var _sink_int: int = 0
var _sink_float: float = 0.0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _prepare_fixture()
	if not _failures.is_empty():
		_finish()
		return

	var results: Array[Dictionary] = []
	_warm_up()
	results.append(_measure_component(
		"track_runtime_contract",
		AI_UPDATES_PER_SECOND,
		Callable(self, "_benchmark_track_runtime_contract")
	))
	results.append(_measure_component(
		"profile_validation",
		AI_UPDATES_PER_SECOND,
		Callable(self, "_benchmark_profile_validation")
	))
	results.append(_measure_component(
		"racing_line_index_search",
		AI_UPDATES_PER_SECOND,
		Callable(self, "_benchmark_racing_line_search")
	))
	results.append(_measure_component(
		"lap_progress_projection",
		PARTICIPANT_UPDATES_PER_SECOND,
		Callable(self, "_benchmark_lap_projection")
	))
	results.append(_measure_component(
		"ai_control_math",
		AI_UPDATES_PER_SECOND,
		Callable(self, "_benchmark_ai_control_math")
	))
	results.append(_measure_component(
		"ground_contact_rays",
		VEHICLE_SUBSTEP_UPDATES_PER_SECOND,
		Callable(self, "_benchmark_ground_contact")
	))
	results.append(_measure_component(
		"powertrain_update",
		VEHICLE_SUBSTEP_UPDATES_PER_SECOND,
		Callable(self, "_benchmark_powertrain")
	))
	results.append(_measure_component(
		"tire_dynamics_math",
		VEHICLE_SUBSTEP_UPDATES_PER_SECOND,
		Callable(self, "_benchmark_tire_dynamics")
	))
	results.append(_measure_component(
		"skid_mark_lifetime_scan",
		PARTICIPANT_UPDATES_PER_SECOND,
		Callable(self, "_benchmark_skid_mark_lifetime_scan")
	))
	results.append(_measure_component(
		"audio_voice_budget",
		AUDIO_BUDGET_CHECKS_PER_SECOND,
		Callable(self, "_benchmark_audio_voice_budget")
	))

	_print_results(results)
	_cleanup_fixture()
	await process_frame
	_finish()


func _prepare_fixture() -> void:
	_track = TRACK_SCENE.instantiate() as GeneratedTrack
	if _track == null:
		_failures.append("Could not instantiate the benchmark track.")
		return
	root.add_child(_track)
	await process_frame
	await physics_frame
	if not _track.has_committed_generation():
		_failures.append("Benchmark track did not commit generated geometry.")
		return

	for local_point: Vector3 in _track.get_racing_line_points():
		_points.append(_track.to_global(local_point))
	if _points.size() < 3:
		_failures.append("Benchmark track exposes fewer than three racing-line points.")
		return

	_profile.lane_offset = 0.6
	_profile.lookahead_points = 5
	_profile.target_speed_kmh = 118.0
	_profile.corner_speed_kmh = 78.0
	if not _profile.is_valid():
		_failures.append("Benchmark AI profile is invalid.")
		return

	for ai_index: int in range(AI_COUNT):
		var search: RacingLineIndexSearch = RacingLineIndexSearch.new()
		search.configure(
			_profile.search_points_behind,
			_profile.search_points_ahead,
			_profile.recovery_search_distance,
			_profile.full_search_interval_updates
		)
		_searches.append(search)
		_search_indices.append(-1)

	var cumulative_distances: PackedFloat32Array = PackedFloat32Array()
	var track_length: float = 0.0
	for point_index: int in range(_points.size()):
		cumulative_distances.append(track_length)
		var next_index: int = (point_index + 1) % _points.size()
		track_length += _points[point_index].distance_to(_points[next_index])
	_projector.configure(_points, cumulative_distances, track_length)
	if not _projector.is_configured():
		_failures.append("Benchmark racing-line projector is not configured.")
		return

	for participant_index: int in range(PARTICIPANT_COUNT):
		_projection_buffers.append(RacingLineProjection.new())
		_projection_indices.append(-1)
		_projection_positions.append(Vector3.ZERO)
		_projection_validity.append(false)

	_drive_config = CarDriveConfigBuilder.build_from_specs(AUTOMATIC_SPECS)
	if _drive_config == null:
		_failures.append("Could not build the benchmark drive configuration.")
		return
	for participant_index: int in range(PARTICIPANT_COUNT):
		var state: CarRuntimeState = CarRuntimeState.new()
		state.reset_drive_state(_drive_config.idle_rpm)
		state.ground_contact_count = 4
		var powertrain: CarPowertrainController = CarPowertrainController.new()
		powertrain.configure(_drive_config)
		powertrain.reset(state)
		_powertrain_states.append(state)
		_powertrains.append(powertrain)

	_car = AI_CAR_SCENE.instantiate() as PlayerCarController
	if _car == null:
		_failures.append("Could not instantiate the benchmark car.")
		return
	_car.car_specs = AUTOMATIC_SPECS
	_car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 0.0))
	root.add_child(_car)
	await process_frame
	await physics_frame
	_car.set_physics_process(false)

	_chassis.configure(_drive_config)
	_chassis_state.reset_drive_state(_drive_config.idle_rpm)
	_chassis_state.ground_contact_count = 4

	_skid_emitter.configure(
		_car,
		_drive_config.skid_mark_min_slip,
		_drive_config.skid_mark_interval,
		_drive_config.skid_mark_lifetime,
		_drive_config.skid_mark_width,
		_drive_config.skid_mark_length
	)


func _warm_up() -> void:
	_benchmark_track_runtime_contract()
	_benchmark_profile_validation()
	_benchmark_racing_line_search()
	_benchmark_lap_projection()
	_benchmark_ai_control_math()
	_benchmark_ground_contact()
	_benchmark_powertrain()
	_benchmark_tire_dynamics()
	_benchmark_skid_mark_lifetime_scan()
	_benchmark_audio_voice_budget()


func _measure_component(label: String, operations: int, benchmark: Callable) -> Dictionary:
	var samples: Array[int] = []
	for _sample_index: int in range(SAMPLE_COUNT):
		var started_usec: int = Time.get_ticks_usec()
		benchmark.call()
		var elapsed_usec: int = Time.get_ticks_usec() - started_usec
		samples.append(elapsed_usec)
	samples.sort()
	var median_index: int = floori(float(samples.size()) * 0.5)
	var median_usec: int = samples[median_index]
	return {
		"component": label,
		"operations": operations,
		"median_usec": median_usec,
		"min_usec": samples[0],
		"max_usec": samples[samples.size() - 1],
	}


func _benchmark_track_runtime_contract() -> void:
	for _operation_index: int in range(AI_UPDATES_PER_SECOND):
		_sink_bool = _track.has_committed_generation()


func _benchmark_profile_validation() -> void:
	for _operation_index: int in range(AI_UPDATES_PER_SECOND):
		_sink_bool = _profile.is_valid()


func _benchmark_racing_line_search() -> void:
	for ai_index: int in range(AI_COUNT):
		_searches[ai_index].reset()
		_search_indices[ai_index] = -1
	for frame_index: int in range(PHYSICS_FPS):
		for ai_index: int in range(AI_COUNT):
			var simulated_point_index: int = (
				frame_index + ai_index * 7
			) % _points.size()
			_search_indices[ai_index] = _searches[ai_index].find_nearest_index(
				_points,
				_points[simulated_point_index],
				_search_indices[ai_index]
			)
			_sink_int = _search_indices[ai_index]


func _benchmark_lap_projection() -> void:
	for participant_index: int in range(PARTICIPANT_COUNT):
		_projection_indices[participant_index] = -1
		_projection_positions[participant_index] = Vector3.ZERO
		_projection_validity[participant_index] = false

	for frame_index: int in range(PHYSICS_FPS):
		for participant_index: int in range(PARTICIPANT_COUNT):
			var point_index: int = (
				frame_index + participant_index * 13
			) % _points.size()
			var position: Vector3 = _points[point_index]
			var projection: RacingLineProjection = _projector.project(
				position,
				_projection_indices[participant_index],
				_projection_positions[participant_index],
				_projection_validity[participant_index],
				_projection_buffers[participant_index]
			)
			if projection == null:
				continue
			_projection_indices[participant_index] = projection.segment_index
			_projection_positions[participant_index] = position
			_projection_validity[participant_index] = true
			_sink_float = projection.progress_distance


func _benchmark_ai_control_math() -> void:
	for frame_index: int in range(PHYSICS_FPS):
		for ai_index: int in range(AI_COUNT):
			var target_index: int = (
				frame_index + ai_index * 7 + _profile.lookahead_points
			) % _points.size()
			var previous: Vector3 = _points[posmod(target_index - 1, _points.size())]
			var current: Vector3 = _points[target_index]
			var next: Vector3 = _points[(target_index + 1) % _points.size()]
			var tangent: Vector3 = (next - previous).normalized()
			var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
			var target_point: Vector3 = current + side * _profile.lane_offset + Vector3.UP * 0.05
			var car_point_index: int = posmod(target_index - _profile.lookahead_points, _points.size())
			var car_basis: Basis = Basis(Vector3.UP, float(frame_index + ai_index) * 0.002)
			var car_transform: Transform3D = Transform3D(car_basis, _points[car_point_index])
			var local_target: Vector3 = car_transform.affine_inverse() * target_point
			var steering: float = clampf(
				local_target.x / maxf(absf(local_target.z), 8.0),
				-1.0,
				1.0
			)
			var turn_pressure: float = clampf(absf(steering) * 1.45, 0.0, 1.0)
			var speed_limit: float = lerpf(
				_profile.target_speed_kmh,
				_profile.corner_speed_kmh,
				turn_pressure
			)
			var speed_kmh: float = 95.0 + float(ai_index) * 4.0
			var throttle: float = 0.92
			var brake: float = 0.0
			if speed_kmh > speed_limit:
				throttle = 0.0
				brake = clampf((speed_kmh - speed_limit) / 30.0, 0.0, 0.75)
			elif absf(steering) > 0.75:
				throttle = 0.45
			_sink_float = throttle + brake + steering


func _benchmark_ground_contact() -> void:
	for _operation_index: int in range(VEHICLE_SUBSTEP_UPDATES_PER_SECOND):
		_chassis.sample_ground_contact(_chassis_state, _car)
		_sink_int = _chassis_state.ground_contact_count


func _benchmark_powertrain() -> void:
	for participant_index: int in range(PARTICIPANT_COUNT):
		var state: CarRuntimeState = _powertrain_states[participant_index]
		state.reset_drive_state(_drive_config.idle_rpm)
		state.ground_contact_count = 4
		_powertrains[participant_index].reset(state)

	for _frame_index: int in range(PHYSICS_FPS):
		for _substep_index: int in range(SUBSTEPS_PER_FRAME):
			for participant_index: int in range(PARTICIPANT_COUNT):
				var state: CarRuntimeState = _powertrain_states[participant_index]
				_powertrains[participant_index].update(
					state,
					0.88,
					0.0,
					false,
					false,
					false,
					1.0 / 120.0
				)
				_sink_float = state.forward_speed + state.engine_rpm


func _benchmark_tire_dynamics() -> void:
	var lateral_speeds: Array[float] = [0.4, -0.6, 0.9, -1.1]
	var forward_speeds: Array[float] = [12.0, 16.0, 20.0, 24.0]
	for _frame_index: int in range(PHYSICS_FPS):
		for _substep_index: int in range(SUBSTEPS_PER_FRAME):
			for participant_index: int in range(PARTICIPANT_COUNT):
				lateral_speeds[participant_index] = _tire_model.recover_lateral_speed(
					lateral_speeds[participant_index],
					10.0,
					0.28,
					false,
					1.0 / 120.0,
					1.0
				)
				_sink_float = _tire_model.calculate_slip_intensity(
					lateral_speeds[participant_index],
					forward_speeds[participant_index],
					0.35,
					0.85,
					2.2,
					30.0,
					false
				)


func _benchmark_skid_mark_lifetime_scan() -> void:
	for _operation_index: int in range(PARTICIPANT_UPDATES_PER_SECOND):
		_skid_emitter.update(
			1.0 / 60.0,
			0.0,
			Transform3D.IDENTITY
		)


func _benchmark_audio_voice_budget() -> void:
	ProceduralAudioPlayer3D.reset_voice_budget()
	for check_index: int in range(5):
		for participant_index: int in range(PARTICIPANT_COUNT):
			var source_id: int = participant_index + 1
			var distance_squared: float = float(
				(participant_index + 1) * (participant_index + 1) * 100
				+ check_index
			)
			_sink_bool = ProceduralAudioPlayer3D.report_voice_distance(
				&"benchmark_engine",
				source_id,
				distance_squared,
				6
			)


func _print_results(results: Array[Dictionary]) -> void:
	results.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("median_usec", 0)) > int(right.get("median_usec", 0))
	)
	var measured_total_usec: int = 0
	for result: Dictionary in results:
		measured_total_usec += int(result.get("median_usec", 0))

	print(
		"[RUNTIME_COMPONENT_BENCHMARK][CONFIG] points=%d physics_fps=%d ai=%d participants=%d substeps=%d samples=%d"
		% [
			_points.size(),
			PHYSICS_FPS,
			AI_COUNT,
			PARTICIPANT_COUNT,
			SUBSTEPS_PER_FRAME,
			SAMPLE_COUNT,
		]
	)
	for result_index: int in range(results.size()):
		var result: Dictionary = results[result_index]
		var median_usec: int = int(result.get("median_usec", 0))
		var operations: int = int(result.get("operations", 0))
		var measured_share: float = (
			float(median_usec) / float(measured_total_usec) * 100.0
			if measured_total_usec > 0
			else 0.0
		)
		var usec_per_operation: float = (
			float(median_usec) / float(operations)
			if operations > 0
			else 0.0
		)
		print(
			"[RUNTIME_COMPONENT_BENCHMARK][RESULT] rank=%d component=%s operations=%d median_usec=%d min_usec=%d max_usec=%d budget_ms=%.3f usec_per_op=%.3f measured_share=%.2f"
			% [
				result_index + 1,
				str(result.get("component", "")),
				operations,
				median_usec,
				int(result.get("min_usec", 0)),
				int(result.get("max_usec", 0)),
				float(median_usec) / 1000.0,
				usec_per_operation,
				measured_share,
			]
		)

	if not results.is_empty():
		var largest: Dictionary = results[0]
		print(
			"[RUNTIME_COMPONENT_BENCHMARK][SUMMARY] largest=%s budget_ms=%.3f measured_total_ms=%.3f"
			% [
				str(largest.get("component", "")),
				float(int(largest.get("median_usec", 0))) / 1000.0,
				float(measured_total_usec) / 1000.0,
			]
		)


func _cleanup_fixture() -> void:
	ProceduralAudioPlayer3D.reset_voice_budget()
	_skid_emitter.dispose()
	if is_instance_valid(_car):
		_car.queue_free()
	if is_instance_valid(_track):
		_track.queue_free()


func _finish() -> void:
	if _failures.is_empty():
		print(
			"[RUNTIME_COMPONENT_BENCHMARK] Completed successfully. sink=%s/%d/%.3f"
			% [str(_sink_bool), _sink_int, _sink_float]
		)
		quit(0)
		return
	for failure: String in _failures:
		push_error("[RUNTIME_COMPONENT_BENCHMARK][FAIL] %s" % failure)
	quit(1)
