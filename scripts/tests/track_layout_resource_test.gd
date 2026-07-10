extends Node

const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const EXPECTED_CONTROL_POINT_COUNT: int = 18
const EXPECTED_SAMPLE_COUNT: int = 108
const EPSILON: float = 0.001

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_resource_metadata()
	_test_builder_uses_resource_layout()
	_test_menu_options_use_resource_metadata()
	_test_track_scene_uses_resource()
	_finish()


func _test_resource_metadata() -> void:
	_expect(SIMPLE_OVAL_LAYOUT != null, "simple oval layout resource loads")
	if SIMPLE_OVAL_LAYOUT == null:
		return

	_expect(SIMPLE_OVAL_LAYOUT.is_valid(), "simple oval layout is valid")
	_expect(SIMPLE_OVAL_LAYOUT.track_id == &"simple_oval", "layout exposes stable track id")
	_expect(SIMPLE_OVAL_LAYOUT.display_name == "Prosty owal", "layout exposes menu display name")
	_expect(SIMPLE_OVAL_LAYOUT.recommended_laps == 3, "layout exposes recommended lap count")
	_expect(SIMPLE_OVAL_LAYOUT.control_points.size() == EXPECTED_CONTROL_POINT_COUNT, "layout stores all 18 control points")
	_expect(SIMPLE_OVAL_LAYOUT.samples_per_segment == 6, "layout stores six samples per segment")
	_expect(is_equal_approx(SIMPLE_OVAL_LAYOUT.track_width, 16.0), "layout preserves scene track width")
	_expect(is_equal_approx(SIMPLE_OVAL_LAYOUT.shoulder_width, 16.0), "layout preserves scene shoulder width")
	_expect(SIMPLE_OVAL_LAYOUT.has_stadium, "layout preserves stadium configuration")


func _test_builder_uses_resource_layout() -> void:
	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build({
		"track_layout": SIMPLE_OVAL_LAYOUT,
	})
	_expect(geometry.center_points.size() == EXPECTED_SAMPLE_COUNT, "resource control points generate 108 sampled points")
	_expect(geometry.racing_line_points.size() == EXPECTED_SAMPLE_COUNT, "resource generates a complete racing line")

	var minimum_half_width: float = INF
	var shoulders_match_resource: bool = true
	for index: int in range(geometry.center_points.size()):
		minimum_half_width = minf(minimum_half_width, geometry.half_widths[index])
		shoulders_match_resource = shoulders_match_resource and absf(
			geometry.left_edge_points[index].distance_to(geometry.left_shoulder_outer_points[index])
			- SIMPLE_OVAL_LAYOUT.shoulder_width
		) <= EPSILON

	_expect(minimum_half_width >= SIMPLE_OVAL_LAYOUT.track_width * 0.5 - EPSILON, "resource track width drives generated road width")
	_expect(shoulders_match_resource, "resource shoulder width drives generated shoulders")


func _test_menu_options_use_resource_metadata() -> void:
	var invalid_layout: TrackLayoutResource = TrackLayoutResource.new()
	var layouts: Array[TrackLayoutResource] = [
		invalid_layout,
		SIMPLE_OVAL_LAYOUT,
		SIMPLE_OVAL_LAYOUT,
	]
	var track_options: Array[Dictionary] = MenuOptionsBuilder.build_track_options_from_layouts(layouts)

	_expect(track_options.size() == 1, "menu filters invalid and duplicate track resources")
	if track_options.is_empty():
		return

	var option: Dictionary = track_options[0]
	_expect(str(option.get("track_id", "")) == str(SIMPLE_OVAL_LAYOUT.track_id), "menu track id comes from resource")
	_expect(str(option.get("label", "")) == SIMPLE_OVAL_LAYOUT.display_name, "menu label comes from resource")
	_expect(int(option.get("recommended_laps", 0)) == SIMPLE_OVAL_LAYOUT.recommended_laps, "menu lap metadata comes from resource")


func _test_track_scene_uses_resource() -> void:
	var track_instance: Node = SIMPLE_OVAL_SCENE.instantiate()
	_expect(track_instance != null, "simple oval scene instantiates")
	if track_instance == null:
		return

	_expect(track_instance.has_method("get_track_layout"), "generated track exposes its layout resource")
	if track_instance.has_method("get_track_layout"):
		_expect(track_instance.call("get_track_layout") == SIMPLE_OVAL_LAYOUT, "scene references the authoritative simple oval resource")
	track_instance.free()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_LAYOUT_RESOURCE_TEST][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[TRACK_LAYOUT_RESOURCE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_LAYOUT_RESOURCE_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return

	push_error("[TRACK_LAYOUT_RESOURCE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_LAYOUT_RESOURCE_TEST] - %s" % failure_message)
	get_tree().quit(1)
