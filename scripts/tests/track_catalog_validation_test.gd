extends SceneTree

const PRODUCTION_CATALOG: TrackCatalog = preload("res://resources/tracks/catalog.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_expect(PRODUCTION_CATALOG.validate().is_empty(), "production catalog has exactly one valid default track")
	_expect(PRODUCTION_CATALOG.get_default_track() != null, "production catalog resolves its default track")

	var no_default_catalog: TrackCatalog = TrackCatalog.new()
	no_default_catalog.tracks = [_build_definition(&"no_default", false)]
	_expect(
		_contains_error(no_default_catalog.validate(), "exactly one default"),
		"catalog without a default track is rejected"
	)

	var two_defaults_catalog: TrackCatalog = TrackCatalog.new()
	two_defaults_catalog.tracks = [
		_build_definition(&"first_default", true),
		_build_definition(&"second_default", true),
	]
	_expect(
		_contains_error(two_defaults_catalog.validate(), "exactly one default"),
		"catalog with two default tracks is rejected"
	)

	var duplicate_id_catalog: TrackCatalog = TrackCatalog.new()
	duplicate_id_catalog.tracks = [
		_build_definition(&"duplicate", true),
		_build_definition(&"duplicate", false),
	]
	_expect(
		_contains_error(duplicate_id_catalog.validate(), "duplicated"),
		"catalog with duplicate track ids is rejected"
	)
	_finish()


func _build_definition(track_id: StringName, is_default: bool) -> TrackDefinition:
	var definition: TrackDefinition = TrackDefinition.new()
	definition.track_id = track_id
	definition.display_name = str(track_id)
	definition.is_default = is_default
	definition.recommended_laps = 3
	definition.track_scene = SIMPLE_OVAL_SCENE
	return definition


func _contains_error(errors: PackedStringArray, fragment: String) -> bool:
	for error_text: String in errors:
		if fragment in error_text:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_CATALOG_VALIDATION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_CATALOG_VALIDATION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_CATALOG_VALIDATION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRACK_CATALOG_VALIDATION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_CATALOG_VALIDATION_TEST] - %s" % failure_message)
	quit(1)
