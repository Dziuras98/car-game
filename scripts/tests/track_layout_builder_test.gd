extends Node

const DEFAULT_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const EPSILON: float = 0.001
const EXPECTED_POINT_COUNT: int = 108

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_default_layout_topology()
	_test_edge_and_shoulder_geometry()
	_test_curvature_driven_width_profile()
	_test_config_sanitization()
	_test_build_is_deterministic()
	_test_generated_mesh_bundle()
	_finish()


func _test_default_layout_topology() -> void:
	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build(TrackGenerationConfig.from_layout(DEFAULT_LAYOUT))
	_expect(geometry != null, "layout builder returns geometry")
	if geometry == null:
		return
	var point_count: int = geometry.center_points.size()
	_expect(point_count == EXPECTED_POINT_COUNT, "layout samples 18 control points into 108 points")
	_expect(geometry.racing_line_points.size() == point_count, "racing line has one point per center point")
	_expect(geometry.forward_vectors.size() == point_count, "layout has one forward vector per point")
	_expect(geometry.right_vectors.size() == point_count, "layout has one right vector per point")
	_expect(geometry.half_widths.size() == point_count, "layout has one half-width per point")
	_expect(_packed_vector3_array_equal_approx(geometry.racing_line_points, geometry.center_points), "current racing line follows the sampled center line")
	_expect(_vector3_equal_approx(geometry.center, _calculate_center(geometry.center_points)), "layout center is the arithmetic mean of sampled points")
	_expect(geometry.is_valid(), "default generated geometry satisfies deep topology validation")

	var minimum_segment: float = INF
	var maximum_segment: float = 0.0
	for index: int in range(point_count):
		var next_index: int = (index + 1) % point_count
		var segment_length: float = geometry.center_points[index].distance_to(geometry.center_points[next_index])
		minimum_segment = minf(minimum_segment, segment_length)
		maximum_segment = maxf(maximum_segment, segment_length)
	_expect(minimum_segment > 0.01, "sampled layout has no duplicate consecutive points")
	_expect(maximum_segment < 20.0, "sampled layout has no discontinuous segment")


func _test_edge_and_shoulder_geometry() -> void:
	var config: TrackGenerationConfig = TrackGenerationConfig.from_layout(DEFAULT_LAYOUT)
	config.track_width = 14.0
	config.width_variation = 0.28
	config.shoulder_width = 10.0
	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build(config)
	var frames_are_valid: bool = true
	var edges_match_width: bool = true
	var shoulders_match_width: bool = true
	var minimum_half_width: float = INF
	var maximum_half_width: float = 0.0

	for index: int in range(geometry.center_points.size()):
		var center_point: Vector3 = geometry.center_points[index]
		var forward: Vector3 = geometry.forward_vectors[index]
		var right: Vector3 = geometry.right_vectors[index]
		var half_width: float = geometry.half_widths[index]
		minimum_half_width = minf(minimum_half_width, half_width)
		maximum_half_width = maxf(maximum_half_width, half_width)
		frames_are_valid = frames_are_valid and absf(forward.length() - 1.0) <= EPSILON
		frames_are_valid = frames_are_valid and absf(right.length() - 1.0) <= EPSILON
		frames_are_valid = frames_are_valid and absf(forward.dot(right)) <= EPSILON
		edges_match_width = edges_match_width and absf(center_point.distance_to(geometry.left_edge_points[index]) - half_width) <= EPSILON
		edges_match_width = edges_match_width and absf(center_point.distance_to(geometry.right_edge_points[index]) - half_width) <= EPSILON
		shoulders_match_width = shoulders_match_width and absf(geometry.left_edge_points[index].distance_to(geometry.left_shoulder_outer_points[index]) - 10.0) <= EPSILON
		shoulders_match_width = shoulders_match_width and absf(geometry.right_edge_points[index].distance_to(geometry.right_shoulder_outer_points[index]) - 10.0) <= EPSILON

	_expect(frames_are_valid, "all generated track frames are normalized and perpendicular")
	_expect(edges_match_width, "road edges use the generated width profile")
	_expect(shoulders_match_width, "shoulders use the typed configuration width")
	_expect(minimum_half_width >= 7.0 - EPSILON, "road never becomes narrower than its base width")
	_expect(maximum_half_width > minimum_half_width, "width variation widens curved sections")


func _test_curvature_driven_width_profile() -> void:
	var builder: TrackLayoutBuilder = TrackLayoutBuilder.new()
	var straight_width: float = builder.get_half_width_for_curvature(14.0, 0.28, 0.0)
	var curved_width: float = builder.get_half_width_for_curvature(
		14.0,
		0.28,
		TrackLayoutBuilder.CURVATURE_FOR_FULL_WIDTH_VARIATION
	)
	_expect(is_equal_approx(straight_width, 7.0), "zero curvature preserves the base half-width")
	_expect(curved_width > straight_width, "higher curvature widens the road independently of loop progress")
	var builder_source: String = FileAccess.get_file_as_string("res://scripts/track/track_layout_builder.gd")
	_expect(not builder_source.contains("progress - 0.29"), "width generation no longer targets the first oval-specific progress constant")
	_expect(not builder_source.contains("progress - 0.79"), "width generation no longer targets the second oval-specific progress constant")


func _test_config_sanitization() -> void:
	var config: TrackGenerationConfig = TrackGenerationConfig.from_layout(DEFAULT_LAYOUT)
	config.track_width = -20.0
	config.width_variation = 8.0
	config.shoulder_width = -4.0
	var copy: TrackGenerationConfig = config.duplicate_config()
	_expect(copy.track_width >= 0.1, "typed config clamps invalid track width")
	_expect(copy.width_variation <= 0.45, "typed config clamps excessive width variation")
	_expect(is_zero_approx(copy.shoulder_width), "typed config clamps negative shoulder width")

	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build(config)
	var widths_are_positive: bool = true
	var shoulders_are_zero: bool = true
	for index: int in range(geometry.center_points.size()):
		widths_are_positive = widths_are_positive and geometry.half_widths[index] >= 0.05 - EPSILON
		shoulders_are_zero = shoulders_are_zero and geometry.left_edge_points[index].distance_to(geometry.left_shoulder_outer_points[index]) <= EPSILON
		shoulders_are_zero = shoulders_are_zero and geometry.right_edge_points[index].distance_to(geometry.right_shoulder_outer_points[index]) <= EPSILON
	_expect(widths_are_positive, "layout builder consumes sanitized track width")
	_expect(shoulders_are_zero, "layout builder consumes sanitized shoulder width")


func _test_build_is_deterministic() -> void:
	var config: TrackGenerationConfig = TrackGenerationConfig.from_layout(DEFAULT_LAYOUT)
	config.track_width = 17.5
	config.width_variation = 0.2
	config.shoulder_width = 6.0
	var builder: TrackLayoutBuilder = TrackLayoutBuilder.new()
	var first: TrackGeometryData = builder.build(config)
	var second: TrackGeometryData = builder.build(config)
	_expect(_packed_vector3_array_equal_approx(first.center_points, second.center_points), "repeated builds produce identical center points")
	_expect(_packed_vector3_array_equal_approx(first.left_edge_points, second.left_edge_points), "repeated builds produce identical left edges")
	_expect(_packed_float_array_equal_approx(first.half_widths, second.half_widths), "repeated builds produce identical width profiles")


func _test_generated_mesh_bundle() -> void:
	var config: TrackGenerationConfig = TrackGenerationConfig.from_layout(DEFAULT_LAYOUT)
	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build(config)
	var parent: Node3D = Node3D.new()
	add_child(parent)
	var meshes: TrackGeneratedMeshes = TrackSurfaceMeshBuilder.new().build_surfaces(
		parent,
		geometry,
		TrackMaterialFactory.new(),
		config
	)
	_expect(meshes != null and meshes.is_valid(), "surface builder returns a valid typed mesh bundle")
	if meshes != null and meshes.is_valid():
		_expect(meshes.track_mesh.get_surface_count() == 1, "typed bundle contains the asphalt mesh")
		_expect(meshes.shoulder_mesh.get_surface_count() == 1, "typed bundle contains the shoulder mesh")
		var track_arrays: Array = meshes.track_mesh.surface_get_arrays(0)
		var track_vertices: PackedVector3Array = track_arrays[Mesh.ARRAY_VERTEX]
		var track_normals: PackedVector3Array = track_arrays[Mesh.ARRAY_NORMAL]
		var track_uvs: PackedVector2Array = track_arrays[Mesh.ARRAY_TEX_UV]
		var track_tangents: PackedFloat32Array = track_arrays[Mesh.ARRAY_TANGENT]
		_expect(track_vertices.size() == (EXPECTED_POINT_COUNT + 1) * 2, "track mesh duplicates its first row at the UV seam")
		_expect(track_normals.size() == track_vertices.size(), "track mesh provides one normal per vertex")
		_expect(track_uvs.size() == track_vertices.size(), "track mesh provides one UV per vertex")
		_expect(track_tangents.size() == track_vertices.size() * 4, "track mesh provides one tangent per vertex")
	parent.queue_free()


func _calculate_center(points: PackedVector3Array) -> Vector3:
	var result: Vector3 = Vector3.ZERO
	for point: Vector3 in points:
		result += point
	return result / float(points.size())


func _packed_vector3_array_equal_approx(a: PackedVector3Array, b: PackedVector3Array) -> bool:
	if a.size() != b.size():
		return false
	for index: int in range(a.size()):
		if not _vector3_equal_approx(a[index], b[index]):
			return false
	return true


func _packed_float_array_equal_approx(a: PackedFloat32Array, b: PackedFloat32Array) -> bool:
	if a.size() != b.size():
		return false
	for index: int in range(a.size()):
		if absf(a[index] - b[index]) > EPSILON:
			return false
	return true


func _vector3_equal_approx(a: Vector3, b: Vector3) -> bool:
	return a.distance_to(b) <= EPSILON


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_LAYOUT_BUILDER_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_LAYOUT_BUILDER_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_LAYOUT_BUILDER_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[TRACK_LAYOUT_BUILDER_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_LAYOUT_BUILDER_TEST] - %s" % failure_message)
	get_tree().quit(1)
