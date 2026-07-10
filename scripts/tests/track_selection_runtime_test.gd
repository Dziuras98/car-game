extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const ALTERNATE_TRACK_SCENE: PackedScene = preload("res://scenes/tracks/test_track.tscn")
const CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var simple_definition: TrackDefinition = _make_definition(
		&"simple_oval",
		"Prosty owal",
		SIMPLE_OVAL_SCENE,
		3
	)
	var alternate_definition: TrackDefinition = _make_definition(
		&"alternate_track",
		"Tor alternatywny",
		ALTERNATE_TRACK_SCENE,
		5
	)
	var catalog: TrackCatalog = TrackCatalog.new()
	catalog.tracks = [simple_definition, alternate_definition]
	catalog.default_track_id = &"simple_oval"
	_expect(catalog.validate().is_empty(), "two-track runtime catalog is valid")

	var main: Node3D = MAIN_SCENE.instantiate() as Node3D
	_expect(main != null, "main scene instantiates for track selection testing")
	if main == null:
		_finish()
		return
	main.set("track_catalog", catalog)
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame

	var initial_track: Node3D = main.call("get_active_track") as Node3D
	_expect(initial_track != null, "explicit default catalog track is instantiated at startup")
	_expect(main.call("get_active_lap_count") == 3, "default track recommended lap count is applied")
	var initial_instance_id: int = initial_track.get_instance_id() if initial_track != null else 0

	var menu: Node = main.get_node_or_null("MainMenu")
	var variants: Array[CarVariantDefinition] = CAR_CATALOG.get_all_variants()
	_expect(menu != null and menu.has_signal("selection_completed"), "main menu exposes the selection signal")
	_expect(not variants.is_empty(), "car catalog exposes a variant for integration testing")
	if menu != null and not variants.is_empty():
		menu.emit_signal("selection_completed", "free_drive", "alternate_track", variants[0].variant_id)
		await get_tree().process_frame
		await get_tree().physics_frame

	var selected_track: Node3D = main.call("get_active_track") as Node3D
	_expect(selected_track != null, "selected alternate track is instantiated")
	_expect(
		selected_track != null and selected_track.get_instance_id() != initial_instance_id,
		"selecting another track replaces the active track instance"
	)
	_expect(main.call("get_selected_track_id") == "alternate_track", "game state stores the selected track id")
	_expect(main.call("get_active_lap_count") == 5, "selected track recommended lap count reconfigures the race session")
	_expect(main.get_node_or_null("TrackContainer/ActiveTrack") == selected_track, "track container exposes exactly the selected active track")
	_expect(main.call("get_current_car") != null, "player car is spawned against the selected track runtime")

	main.queue_free()
	await get_tree().process_frame
	_finish()


func _make_definition(
	track_id: StringName,
	display_name: String,
	scene: PackedScene,
	recommended_laps: int
) -> TrackDefinition:
	var definition: TrackDefinition = TrackDefinition.new()
	definition.track_id = track_id
	definition.display_name = display_name
	definition.track_scene = scene
	definition.recommended_laps = recommended_laps
	return definition


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_SELECTION_RUNTIME_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_SELECTION_RUNTIME_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_SELECTION_RUNTIME_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[TRACK_SELECTION_RUNTIME_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_SELECTION_RUNTIME_TEST] - %s" % failure_message)
	get_tree().quit(1)
