extends Node

const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const TRACK_CATALOG: TrackCatalog = preload("res://resources/tracks/catalog.tres")
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
	_test_menu_options_use_catalog_metadata()
	_test_track_scene_uses_resource()
	await _test_atomic_generated_content_replacement()
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
	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build(
		TrackGenerationConfig.from_layout(SIMPLE_OVAL_LAYOUT)
	)
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


func _test_menu_options_use_catalog_metadata() -> void:
	_expect(TRACK_CATALOG != null and TRACK_CATALOG.is_valid(), "production track catalog is valid")
	var track_options: Array[TrackMenuOption] = MenuOptionsBuilder.build_track_options(TRACK_CATALOG)
	_expect(track_options.size() == TRACK_CATALOG.get_tracks().size(), "menu exposes one option per valid catalog track")
	if track_options.is_empty():
		return

	var definition: TrackDefinition = TRACK_CATALOG.get_default_track()
	var option: TrackMenuOption = track_options[0]
	_expect(option != null and option.is_valid(), "catalog metadata produces a valid typed track option")
	_expect(option.track_id == definition.track_id, "menu track id comes from the track definition")
	_expect(
		option.label == TranslationServer.translate(definition.display_name),
		"menu label is the localized track definition display name"
	)
	_expect(option.recommended_laps == definition.recommended_laps, "menu lap metadata comes from the track definition")


func _test_track_scene_uses_resource() -> void:
	var track_instance: GeneratedTrack = SIMPLE_OVAL_SCENE.instantiate() as GeneratedTrack
	_expect(track_instance != null, "simple oval scene instantiates as GeneratedTrack")
	if track_instance == null:
		return
	_expect(track_instance.get_track_layout() == SIMPLE_OVAL_LAYOUT, "scene references the authoritative simple oval resource")
	track_instance.free()


func _test_atomic_generated_content_replacement() -> void:
	var track: GeneratedTrack = SIMPLE_OVAL_SCENE.instantiate() as GeneratedTrack
	_expect(track != null, "track instantiates for rebuild replacement testing")
	if track == null:
		return

	var mutable_layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	track.track_layout = mutable_layout
	add_child(track)
	await get_tree().process_frame

	var first_content: Node = track.get_node_or_null("GeneratedContent")
	_expect(first_content != null, "initial generation creates one GeneratedContent root")
	var first_instance_id: int = first_content.get_instance_id() if first_content != null else 0

	mutable_layout.track_width += 0.5
	await get_tree().process_frame
	await get_tree().process_frame

	var replacement_content: Node = track.get_node_or_null("GeneratedContent")
	_expect(replacement_content != null, "rebuild creates a replacement GeneratedContent root")
	_expect(
		replacement_content != null and replacement_content.get_instance_id() != first_instance_id,
		"rebuild atomically replaces the generated subtree"
	)
	_expect(_count_named_children(track, "GeneratedContent") == 1, "track exposes exactly one generated subtree after rebuild")
	_expect(_has_collision_shape(replacement_content, "Grass"), "rebuilt grass keeps its collision shape")
	_expect(_has_collision_shape(replacement_content, "RoadsideTerrain"), "rebuilt roadside keeps its collision shape")
	_expect(_has_collision_shape(replacement_content, "TrackSurface"), "rebuilt asphalt keeps its collision shape")

	track.queue_free()
	await get_tree().process_frame


func _count_named_children(parent: Node, child_name: String) -> int:
	var count: int = 0
	for child: Node in parent.get_children():
		if child.name == child_name:
			count += 1
	return count


func _has_collision_shape(generated_content: Node, body_name: String) -> bool:
	if generated_content == null:
		return false
	var body: Node = generated_content.get_node_or_null(body_name)
	if body == null:
		return false
	return body.get_node_or_null("CollisionShape3D") is CollisionShape3D


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
