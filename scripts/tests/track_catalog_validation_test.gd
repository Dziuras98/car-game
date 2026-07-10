extends SceneTree

const PRODUCTION_CATALOG: TrackCatalog = preload("res://resources/tracks/catalog.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_expect(PRODUCTION_CATALOG.validate().is_empty(), "production catalog is valid")
	_expect(PRODUCTION_CATALOG.default_track_id == &"simple_oval", "production catalog declares its default id explicitly")
	_expect(
		PRODUCTION_CATALOG.get_default_track() != null
		and PRODUCTION_CATALOG.get_default_track().track_id == &"simple_oval",
		"production catalog resolves the explicit default track"
	)

	var explicit_default_catalog: TrackCatalog = TrackCatalog.new()
	explicit_default_catalog.tracks = [_build_definition(&"explicit", false)]
	explicit_default_catalog.default_track_id = &"explicit"
	_expect(explicit_default_catalog.validate().is_empty(), "explicit default id does not require a legacy boolean")
	_expect(explicit_default_catalog.get_default_track().track_id == &"explicit", "explicit default id resolves correctly")

	var missing_explicit_default: TrackCatalog = TrackCatalog.new()
	missing_explicit_default.tracks = [_build_definition(&"available", false)]
	missing_explicit_default.default_track_id = &"missing"
	_expect(
		_contains_error(missing_explicit_default.validate(), "does not reference"),
		"missing explicit default id is rejected"
	)

	var no_default_catalog: TrackCatalog = TrackCatalog.new()
	no_default_catalog.tracks = [_build_definition(&"no_default", false)]
	_expect(
		_contains_error(no_default_catalog.validate(), "default_track_id"),
		"legacy catalog without a default track is rejected"
	)

	var two_defaults_catalog: TrackCatalog = TrackCatalog.new()
	two_defaults_catalog.tracks = [
		_build_definition(&"first_default", true),
		_build_definition(&"second_default", true),
	]
	_expect(
		_contains_error(two_defaults_catalog.validate(), "default_track_id"),
		"legacy catalog with two default tracks is rejected"
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


func _build_definition(track_id: StringName, legacy_default: bool) -> TrackDefinition:
	var definition: TrackDefinition = TrackDefinition.new()
	definition.track_id = track_id
	definition.display_name = str(track_id)
	definition.is_default = legacy_default
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
