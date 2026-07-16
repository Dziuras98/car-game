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
	var production_tracks: Array[TrackDefinition] = PRODUCTION_CATALOG.get_tracks()
	_expect(
		not production_tracks.is_empty() and production_tracks[0].track_id == &"simple_oval",
		"production catalog preserves the established circuit order"
	)
	var infinite_grid: TrackDefinition = PRODUCTION_CATALOG.get_track_by_id(&"infinite_grid")
	_expect(infinite_grid != null and infinite_grid.is_valid(), "infinite grid map is a valid production track definition")
	_expect(
		infinite_grid != null and infinite_grid.supports_mode(GameModes.FREE_DRIVE),
		"infinite grid map is available in free drive"
	)
	_expect(
		infinite_grid != null and not infinite_grid.supports_mode(GameModes.RACE),
		"infinite grid map is excluded from races"
	)
	var simple_oval: TrackDefinition = PRODUCTION_CATALOG.get_track_by_id(&"simple_oval")
	_expect(
		simple_oval != null
		and simple_oval.supports_mode(GameModes.FREE_DRIVE)
		and simple_oval.supports_mode(GameModes.RACE),
		"existing tracks remain available in both gameplay modes by default"
	)
	var short_desert_track: TrackDefinition = PRODUCTION_CATALOG.get_track_by_id(&"short_desert_track")
	_expect(
		short_desert_track != null and short_desert_track.is_valid(),
		"short desert track is a valid production track definition"
	)
	_expect(
		short_desert_track != null
		and short_desert_track.supports_mode(GameModes.FREE_DRIVE)
		and short_desert_track.supports_mode(GameModes.RACE),
		"short desert track is available in free drive and race modes"
	)

	var explicit_default_catalog: TrackCatalog = TrackCatalog.new()
	explicit_default_catalog.tracks = [_build_definition(&"explicit")]
	explicit_default_catalog.default_track_id = &"explicit"
	_expect(explicit_default_catalog.validate().is_empty(), "explicit default id validates")
	_expect(explicit_default_catalog.get_default_track().track_id == &"explicit", "explicit default id resolves correctly")

	var missing_explicit_default: TrackCatalog = TrackCatalog.new()
	missing_explicit_default.tracks = [_build_definition(&"available")]
	missing_explicit_default.default_track_id = &"missing"
	_expect(
		_contains_error(missing_explicit_default.validate(), "does not reference"),
		"missing explicit default id is rejected"
	)
	_expect(missing_explicit_default.get_default_track() == null, "missing explicit default cannot resolve a fallback track")

	var no_default_catalog: TrackCatalog = TrackCatalog.new()
	no_default_catalog.tracks = [_build_definition(&"no_default")]
	_expect(
		_contains_error(no_default_catalog.validate(), "must define default_track_id"),
		"catalog without an explicit default id is rejected"
	)
	_expect(no_default_catalog.get_default_track() == null, "catalog without an explicit default does not select the first entry")

	var duplicate_id_catalog: TrackCatalog = TrackCatalog.new()
	duplicate_id_catalog.tracks = [
		_build_definition(&"duplicate"),
		_build_definition(&"duplicate"),
	]
	duplicate_id_catalog.default_track_id = &"duplicate"
	_expect(
		_contains_error(duplicate_id_catalog.validate(), "duplicated"),
		"catalog with duplicate track ids is rejected"
	)

	var unsupported_mode_definition: TrackDefinition = _build_definition(&"unsupported_mode")
	unsupported_mode_definition.supported_modes = [&"unsupported"]
	_expect(not unsupported_mode_definition.is_valid(), "track definitions reject unsupported gameplay modes")

	var duplicate_modes_definition: TrackDefinition = _build_definition(&"duplicate_modes")
	duplicate_modes_definition.supported_modes = [GameModes.FREE_DRIVE, GameModes.FREE_DRIVE]
	_expect(not duplicate_modes_definition.is_valid(), "track definitions reject duplicated gameplay modes")
	_finish()


func _build_definition(track_id: StringName) -> TrackDefinition:
	var definition: TrackDefinition = TrackDefinition.new()
	definition.track_id = track_id
	definition.display_name = str(track_id)
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
