extends SceneTree

const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const EPSILON: float = 0.01

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_profile_validation_and_sampling()
	_test_profiled_geometry()
	await _test_profile_change_rebuilds_track()
	_finish()


func _test_profile_validation_and_sampling() -> void:
	var layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	layout.track_width_profile = PackedVector2Array([
		Vector2(0.25, 10.0),
		Vector2(0.75, 20.0),
	])
	_expect(layout.is_valid(), "a sorted finite width profile is valid")
	_expect(
		absf(layout.get_track_width_at(0.5) - 15.0) <= EPSILON,
		"profile values interpolate between neighboring samples"
	)
	_expect(
		absf(layout.get_track_width_at(0.0) - 15.0) <= EPSILON,
		"profile interpolation wraps continuously across the lap seam"
	)

	layout.track_width_profile = PackedVector2Array([
		Vector2(0.5, 12.0),
		Vector2(0.25, 13.0),
	])
	_expect(not layout.is_valid(), "profile progress values must be strictly increasing")

	layout.track_width_profile = PackedVector2Array([Vector2(0.5, 0.0)])
	_expect(not layout.is_valid(), "profile road widths must remain positive")


func _test_profiled_geometry() -> void:
	var layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	layout.width_variation = 0.0
	layout.track_width_profile = PackedVector2Array([
		Vector2(0.0, 10.0),
		Vector2(0.5, 18.0),
		Vector2(1.0, 10.0),
	])
	layout.shoulder_width_profile = PackedVector2Array([
		Vector2(0.0, 2.0),
		Vector2(0.5, 5.0),
		Vector2(1.0, 2.0),
	])
	layout.barrier_distance_profile = PackedVector2Array([
		Vector2(0.0, 5.0),
		Vector2(0.5, 20.0),
		Vector2(1.0, 5.0),
	])
	layout.racing_line_offset_profile = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(0.5, 2.0),
		Vector2(1.0, 0.0),
	])
	layout.banking_degrees_profile = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(0.5, 6.0),
		Vector2(1.0, 0.0),
	])
	_expect(layout.is_valid(), "combined road profiles pass layout validation")

	var config: TrackGenerationConfig = TrackGenerationConfig.from_layout(layout)
	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build(config)
	_expect(geometry.is_valid(), "profiled road geometry passes topology validation")
	var midpoint: int = geometry.center_points.size() / 2
	_expect(absf(geometry.half_widths[0] - 5.0) <= EPSILON, "start width comes from the width profile")
	_expect(absf(geometry.half_widths[midpoint] - 9.0) <= EPSILON, "mid-lap width comes from the width profile")
	_expect(
		absf(
			geometry.left_edge_points[0].distance_to(geometry.left_shoulder_outer_points[0])
			- 2.0
		) <= EPSILON,
		"start shoulder width comes from the shoulder profile"
	)
	_expect(
		absf(
			geometry.left_edge_points[midpoint].distance_to(
				geometry.left_shoulder_outer_points[midpoint]
			)
			- 5.0
		) <= EPSILON,
		"mid-lap shoulder width comes from the shoulder profile"
	)
	_expect(
		absf(
			geometry.racing_line_points[midpoint].distance_to(geometry.center_points[midpoint])
			- 2.0
		) <= EPSILON,
		"racing-line offsets move the AI guide away from the center line"
	)
	_expect(
		absf(geometry.right_vectors[midpoint].y) > 0.05,
		"banking rotates the road cross-section out of the horizontal plane"
	)

	var transforms: Array[Transform3D] = TrackBarrierBuilder.new()._build_segment_transforms(
		geometry,
		config
	)
	var start_lateral_offset: float = absf(
		(transforms[0].origin - geometry.center_points[0]).dot(geometry.right_vectors[0])
	)
	var midpoint_transform_index: int = midpoint
	var midpoint_lateral_offset: float = absf(
		(transforms[midpoint_transform_index].origin - geometry.center_points[midpoint]).dot(
			geometry.right_vectors[midpoint]
		)
	)
	_expect(
		absf(start_lateral_offset - (geometry.half_widths[0] + 5.0)) <= EPSILON,
		"barrier placement consumes the start of the barrier profile"
	)
	_expect(
		absf(midpoint_lateral_offset - (geometry.half_widths[midpoint] + 20.0)) <= 0.1,
		"barrier placement consumes the middle of the barrier profile"
	)


func _test_profile_change_rebuilds_track() -> void:
	var track: GeneratedTrack = SIMPLE_OVAL_SCENE.instantiate() as GeneratedTrack
	var layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	track.track_layout = layout
	root.add_child(track)
	await process_frame
	var initial_rebuild_count: int = track.get_rebuild_count()

	layout.track_width_profile = PackedVector2Array([
		Vector2(0.0, 14.0),
		Vector2(0.5, 16.0),
		Vector2(1.0, 14.0),
	])
	await process_frame
	await process_frame
	_expect(
		track.get_rebuild_count() > initial_rebuild_count,
		"changing a road profile invalidates the generated-track signature"
	)

	track.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_PROGRESS_PROFILE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_PROGRESS_PROFILE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_PROGRESS_PROFILE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[TRACK_PROGRESS_PROFILE_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[TRACK_PROGRESS_PROFILE_TEST] - %s" % failure_message)
	quit(1)
