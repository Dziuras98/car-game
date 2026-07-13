extends SceneTree

const TOR_POZNAN_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/tor_poznan.tres")
const TOR_POZNAN_SCENE: PackedScene = preload("res://scenes/tracks/tor_poznan.tscn")
const TRACK_CATALOG: TrackCatalog = preload("res://resources/tracks/catalog.tres")
const OFFICIAL_LAP_LENGTH_METERS: float = 4083.0
const LENGTH_TOLERANCE_METERS: float = 1.0
const EXPECTED_CONTROL_POINTS: int = 240
const EXPECTED_GENERATED_POINTS: int = 480

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_resource_and_geometry()
	_test_catalog_registration()
	await _test_runtime_generation()
	_finish()


func _test_resource_and_geometry() -> void:
	_expect(TOR_POZNAN_LAYOUT != null, "Tor Poznań layout resource loads")
	if TOR_POZNAN_LAYOUT == null:
		return
	_expect(TOR_POZNAN_LAYOUT.is_valid(), "Tor Poznań layout resource is valid")
	_expect(TOR_POZNAN_LAYOUT.track_id == &"tor_poznan", "layout exposes the stable Tor Poznań id")
	_expect(
		TOR_POZNAN_LAYOUT.control_points.size() == EXPECTED_CONTROL_POINTS,
		"layout preserves the traced 240-point centerline"
	)
	_expect(is_equal_approx(TOR_POZNAN_LAYOUT.track_width, 12.0), "layout uses the nominal 12-metre road width")
	_expect(is_zero_approx(TOR_POZNAN_LAYOUT.width_variation), "real-world width is not modified automatically by curvature")

	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build(
		TrackGenerationConfig.from_layout(TOR_POZNAN_LAYOUT)
	)
	_expect(geometry != null and geometry.is_valid(), "generated Tor Poznań geometry passes topology validation")
	if geometry == null or geometry.center_points.is_empty():
		return
	_expect(
		geometry.center_points.size() == EXPECTED_GENERATED_POINTS,
		"the centerline produces 480 road samples"
	)
	var lap_length: float = _get_loop_length(geometry.center_points)
	_expect(
		absf(lap_length - OFFICIAL_LAP_LENGTH_METERS) <= LENGTH_TOLERANCE_METERS,
		"generated centerline is calibrated to the official 4083-metre lap length"
	)
	_expect(
		geometry.center_points[0].distance_to(Vector3.ZERO) <= 0.01,
		"start and finish line remains anchored at the world origin"
	)
	_expect(
		geometry.forward_vectors[0].dot(Vector3.FORWARD) > 0.99,
		"the start straight points along the game's forward axis"
	)
	var minimum_width: float = INF
	var maximum_width: float = 0.0
	for half_width: float in geometry.half_widths:
		minimum_width = minf(minimum_width, half_width * 2.0)
		maximum_width = maxf(maximum_width, half_width * 2.0)
	_expect(absf(minimum_width - 12.0) <= 0.01, "road never narrows below the nominal width")
	_expect(absf(maximum_width - 12.0) <= 0.01, "road remains at the traced nominal width")


func _test_catalog_registration() -> void:
	_expect(TRACK_CATALOG != null and TRACK_CATALOG.is_valid(), "production track catalog remains valid")
	if TRACK_CATALOG == null:
		return
	var definition: TrackDefinition = TRACK_CATALOG.get_track_by_id(&"tor_poznan")
	_expect(definition != null, "catalog exposes Tor Poznań")
	if definition != null:
		_expect(definition.display_name == "Tor Poznań", "catalog exposes the localized display name")
		_expect(definition.recommended_laps == 2, "catalog exposes the recommended lap count")


func _test_runtime_generation() -> void:
	var track: GeneratedTrack = TOR_POZNAN_SCENE.instantiate() as GeneratedTrack
	_expect(track != null, "Tor Poznań scene instantiates as GeneratedTrack")
	if track == null:
		return
	root.add_child(track)
	await process_frame
	_expect(track.has_committed_generation(), "Tor Poznań commits generated road content at runtime")
	_expect(
		track.get_checkpoint_gate_count() == TOR_POZNAN_LAYOUT.get_checkpoint_gate_count(),
		"runtime creates the complete checkpoint sequence"
	)
	_expect(
		track.get_racing_line_points().size() == EXPECTED_GENERATED_POINTS,
		"runtime exposes a complete AI racing line"
	)
	track.queue_free()
	await process_frame


func _get_loop_length(points: PackedVector3Array) -> float:
	var length: float = 0.0
	for point_index: int in range(points.size()):
		length += points[point_index].distance_to(points[(point_index + 1) % points.size()])
	return length


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TOR_POZNAN_LAYOUT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TOR_POZNAN_LAYOUT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TOR_POZNAN_LAYOUT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[TOR_POZNAN_LAYOUT_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[TOR_POZNAN_LAYOUT_TEST] - %s" % failure_message)
	quit(1)
