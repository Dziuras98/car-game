extends SceneTree

const CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const TOR_POZNAN_SCENE: PackedScene = preload("res://scenes/tracks/tor_poznan.tscn")
const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_symmetric_opponent_layout()
	_test_loop_profile_endpoint_validation()

	var world: Node3D = Node3D.new()
	root.add_child(world)
	await _test_grid_track_width_validation(world)
	await _test_tor_poznan_geometry_refresh(world)
	world.queue_free()
	await process_frame
	_finish()


func _test_symmetric_opponent_layout() -> void:
	var layout: OpponentSpawnLayout = OpponentSpawnLayout.new()
	layout.configure(4.2, 7.0)
	_expect(is_equal_approx(layout.get_lane_offset(0), -2.1), "left opponent lane uses half spacing")
	_expect(is_equal_approx(layout.get_lane_offset(1), 2.1), "right opponent lane mirrors the left lane")
	_expect(
		is_equal_approx(absf(layout.get_lane_offset(0)), absf(layout.get_lane_offset(1))),
		"opponent grid lateral offsets are symmetric"
	)

	var marker: Node3D = Node3D.new()
	marker.global_transform = Transform3D(Basis(Vector3.UP, 0.37), Vector3(15.0, 2.0, -8.0))
	var inverse: Transform3D = marker.global_transform.affine_inverse()
	var left_local: Vector3 = inverse * layout.get_spawn_transform(marker, 0).origin
	var right_local: Vector3 = inverse * layout.get_spawn_transform(marker, 1).origin
	_expect(is_equal_approx(left_local.x, layout.get_lane_offset(0)), "left spawn transform uses the AI lane offset")
	_expect(is_equal_approx(right_local.x, layout.get_lane_offset(1)), "right spawn transform uses the AI lane offset")
	marker.free()


func _test_loop_profile_endpoint_validation() -> void:
	var invalid_layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	invalid_layout.track_width_profile = PackedVector2Array([
		Vector2(0.0, 12.0),
		Vector2(1.0, 16.0),
	])
	_expect(
		_contains_error(invalid_layout.validate(), "endpoint values"),
		"loop profiles reject mismatched values at progress zero and one"
	)

	var valid_layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	valid_layout.track_width_profile = PackedVector2Array([
		Vector2(0.0, 12.0),
		Vector2(0.5, 16.0),
		Vector2(1.0, 12.0),
	])
	_expect(
		not _contains_error(valid_layout.validate(), "endpoint values"),
		"loop profiles accept matching endpoint values"
	)
	_expect(
		is_equal_approx(valid_layout.get_track_width_at(0.0), valid_layout.get_track_width_at(1.0)),
		"validated loop profiles are continuous at the lap boundary"
	)


func _test_grid_track_width_validation(world: Node3D) -> void:
	var track: GeneratedTrack = SIMPLE_OVAL_SCENE.instantiate() as GeneratedTrack
	world.add_child(track)
	await process_frame

	var spawn_marker: Node3D = Node3D.new()
	world.add_child(spawn_marker)
	var default_spawner: CarSpawner = CarSpawner.new()
	_expect(
		default_spawner.configure(
			world,
			spawn_marker,
			track,
			CAR_CATALOG.get_all_variants(),
			4.2,
			7.0,
			123
		),
		"default grid configures against the generated track"
	)
	_expect(
		default_spawner.validate_opponent_spawn_request(3).is_empty(),
		"default symmetric grid fits inside the start-line track width"
	)

	var wide_spawner: CarSpawner = CarSpawner.new()
	_expect(
		wide_spawner.configure(
			world,
			spawn_marker,
			track,
			CAR_CATALOG.get_all_variants(),
			20.0,
			7.0,
			123
		),
		"wide grid reaches track-bound validation"
	)
	_expect(
		_contains_error(wide_spawner.validate_opponent_spawn_request(2), "usable start-line track width"),
		"opponent grids extending beyond the track are rejected"
	)

	spawn_marker.queue_free()
	track.queue_free()
	await process_frame


func _test_tor_poznan_geometry_refresh(world: Node3D) -> void:
	var track: GeneratedTrack = TOR_POZNAN_SCENE.instantiate() as GeneratedTrack
	track.track_layout = track.track_layout.duplicate(true) as TrackLayoutResource
	world.add_child(track)
	await _frames(5)

	var environment: TorPoznanEnvironment = track.get_node_or_null("TrackEnvironment") as TorPoznanEnvironment
	var original_curbs: Node = environment.get_node_or_null("CornerCurbs") if environment != null else null
	_expect(environment != null, "Tor Poznan environment is available")
	_expect(original_curbs != null, "Tor Poznan initially builds geometry-dependent curbs")
	var original_curb_id: int = original_curbs.get_instance_id() if original_curbs != null else 0
	var original_revision: int = track.get_geometry_revision()

	track.track_layout.banking_degrees_profile = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(0.5, 1.0),
		Vector2(1.0, 0.0),
	])
	await _frames(5)

	var rebuilt_curbs: Node = environment.get_node_or_null("CornerCurbs") if environment != null else null
	_expect(track.get_geometry_revision() > original_revision, "Tor Poznan rebuilds after its layout changes")
	_expect(rebuilt_curbs != null, "geometry-dependent curbs exist after rebuild")
	_expect(
		rebuilt_curbs != null and rebuilt_curbs.get_instance_id() != original_curb_id,
		"Tor Poznan replaces stale curbs after geometry rebuild"
	)

	track.queue_free()
	await process_frame


func _frames(count: int) -> void:
	for _frame_index: int in range(count):
		await process_frame


func _contains_error(errors: PackedStringArray, fragment: String) -> bool:
	for error_text: String in errors:
		if fragment in error_text:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_AND_GRID_REGRESSION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_AND_GRID_REGRESSION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_AND_GRID_REGRESSION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[TRACK_AND_GRID_REGRESSION_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[TRACK_AND_GRID_REGRESSION_TEST] - %s" % failure_message)
	quit(1)
