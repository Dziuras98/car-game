extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const TRACK_CATALOG: TrackCatalog = preload("res://resources/tracks/catalog.tres")
const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_expect(OS.has_feature("windows"), "exported executable reports the Windows platform feature")
	_expect(not OS.has_feature("editor"), "smoke test runs from an export template, not the editor")
	_expect(ProjectSettings.get_setting("application/config/name", "") == "Car Game", "exported project settings contain the application name")
	_expect(CAR_CATALOG != null and not CAR_CATALOG.get_all_variants().is_empty(), "car catalog is present in the exported package")
	_expect(TRACK_CATALOG != null and TRACK_CATALOG.is_valid(), "track catalog is present and valid")
	_expect(SIMPLE_OVAL_LAYOUT != null and SIMPLE_OVAL_LAYOUT.is_valid(), "track layout Resource is present and valid")
	_expect(ResourceLoader.exists("res://scenes/cars/370zat.tscn"), "automatic car scene is included in the export")
	_expect(ResourceLoader.exists("res://scenes/cars/370z.tscn"), "manual car scene is included in the export")

	var main_instance: Node = MAIN_SCENE.instantiate()
	_expect(main_instance != null, "main scene instantiates from the exported package")
	if main_instance == null:
		_finish()
		return

	add_child(main_instance)
	await get_tree().process_frame
	await get_tree().physics_frame

	_expect(main_instance.get_node_or_null("MainMenu") != null, "main menu exists in the exported main scene")
	_expect(main_instance.get_node_or_null("Camera3D") != null, "follow camera exists in the exported main scene")
	_expect(main_instance.get_node_or_null("Speedometer") != null, "speedometer exists in the exported main scene")
	_expect(main_instance.get_node_or_null("Minimap") != null, "minimap exists in the exported main scene")
	_expect(main_instance.get_node_or_null("TrackContainer") != null, "runtime track container exists in the exported main scene")

	var track: Node = main_instance.get_node_or_null("TrackContainer/ActiveTrack")
	_expect(track != null, "default catalog track is instantiated in the exported main scene")
	if track != null:
		_expect(track.has_method("get_racing_line_points"), "exported track exposes the racing-line API")
		_expect(track.has_method("get_checkpoint_count"), "exported track exposes checkpoint metadata")
		var racing_line: Array = track.call("get_racing_line_points")
		_expect(racing_line.size() == 108, "exported track generates the expected 108-point racing line")
		_expect(int(track.call("get_checkpoint_count")) == 3, "exported track exposes three intermediate checkpoints")
		_expect(int(track.call("get_checkpoint_gate_count")) == 4, "exported track builds the finish and checkpoint gates")
	_expect(main_instance.call("get_active_lap_count") == 3, "exported runtime applies track recommended lap metadata")

	main_instance.queue_free()
	await get_tree().process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[EXPORTED_BUILD_SMOKE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[EXPORTED_BUILD_SMOKE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[EXPORTED_BUILD_SMOKE_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[EXPORTED_BUILD_SMOKE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[EXPORTED_BUILD_SMOKE_TEST] - %s" % failure_message)
	get_tree().quit(1)
