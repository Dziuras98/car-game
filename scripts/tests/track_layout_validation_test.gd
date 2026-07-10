extends SceneTree

const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")

var _checks: int = 0
var _failures: Array[String] = []
var _change_count: int = 0


func _initialize() -> void:
	_run()
	_finish()


func _run() -> void:
	_expect(SIMPLE_OVAL_LAYOUT.validate().is_empty(), "production track layout passes comprehensive validation")

	var mutable_layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	mutable_layout.changed.connect(_on_layout_changed)
	var original_width: float = mutable_layout.track_width
	mutable_layout.track_width = original_width + 1.0
	_expect(_change_count == 1, "assigning a generation property emits the Resource changed signal")
	mutable_layout.track_width = mutable_layout.track_width
	_expect(_change_count == 1, "assigning an unchanged value does not emit a duplicate signal")

	var overlapping_points: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	var points: PackedVector3Array = overlapping_points.control_points.duplicate()
	points[1] = points[0]
	overlapping_points.control_points = points
	_expect(_contains_error(overlapping_points.validate(), "must not overlap"), "overlapping adjacent control points are rejected")

	var invalid_road: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	invalid_road.track_width = 0.0
	invalid_road.shoulder_width = -1.0
	invalid_road.grass_size = Vector2(-10.0, 50.0)
	_expect(_contains_error(invalid_road.validate(), "track_width"), "non-positive road width is rejected")
	_expect(_contains_error(invalid_road.validate(), "shoulder_width"), "negative shoulder width is rejected")
	_expect(_contains_error(invalid_road.validate(), "grass_size"), "invalid grass dimensions are rejected")

	var invalid_checkpoints: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	invalid_checkpoints.checkpoint_progresses = PackedFloat32Array([0.25, 0.25, 0.8])
	_expect(_contains_error(invalid_checkpoints.validate(), "checkpoint_progresses"), "duplicate checkpoint progress is rejected")

	var invalid_decoration: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	invalid_decoration.stadium_section_step = 0
	invalid_decoration.stadium_distance_from_barrier = -1.0
	_expect(_contains_error(invalid_decoration.validate(), "stadium_section_step"), "zero stadium section step is rejected")
	_expect(_contains_error(invalid_decoration.validate(), "stadium_distance_from_barrier"), "negative stadium distance is rejected")


func _on_layout_changed() -> void:
	_change_count += 1


func _contains_error(errors: PackedStringArray, fragment: String) -> bool:
	for error_text: String in errors:
		if fragment in error_text:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_LAYOUT_VALIDATION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_LAYOUT_VALIDATION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_LAYOUT_VALIDATION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRACK_LAYOUT_VALIDATION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_LAYOUT_VALIDATION_TEST] - %s" % failure_message)
	quit(1)
