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
	var invalid_track_scene: PackedScene = _make_invalid_generated_track_scene()
	if invalid_track_scene == null:
		_finish()
		return
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
	var invalid_definition: TrackDefinition = _make_definition(
		&"invalid_generated_track",
		"Niepoprawny tor",
		invalid_track_scene,
		9
	)
	var catalog: TrackCatalog = TrackCatalog.new()
	catalog.tracks = [simple_definition, alternate_definition, invalid_definition]
	catalog.default_track_id = &"simple_oval"
	_expect(catalog.validate().is_empty(), "runtime catalog with a failing generation fixture is structurally valid")

	_test_track_spawn_transaction(simple_definition, alternate_definition)

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
		menu.emit_signal("selection_completed", &"free_drive", &"alternate_track", variants[0].variant_id)
		await get_tree().process_frame
		await get_tree().physics_frame

	var selected_track: Node3D = main.call("get_active_track") as Node3D
	_expect(selected_track != null, "selected alternate track is instantiated")
	_expect(
		selected_track != null and selected_track.get_instance_id() != initial_instance_id,
		"selecting another track replaces the active track instance"
	)
	_expect(main.call("get_selected_track_id") == &"alternate_track", "game state stores the selected track id")
	_expect(main.call("get_active_lap_count") == 5, "selected track recommended lap count reconfigures the race session")
	_expect(main.get_node_or_null("TrackContainer/ActiveTrack") == selected_track, "track container exposes exactly the selected active track")
	_expect(main.call("get_current_car") != null, "player car is spawned against the selected track runtime")

	var failed_activation: bool = bool(main.call("_activate_track", invalid_definition))
	await get_tree().process_frame
	var track_after_failed_activation: Node3D = main.call("get_active_track") as Node3D
	_expect(not failed_activation, "track activation reports failed generated content")
	_expect(track_after_failed_activation == selected_track, "failed activation preserves the previous active track reference")
	_expect(main.call("get_active_lap_count") == 5, "failed activation preserves the previous lap configuration")
	_expect(main.get_node_or_null("TrackContainer/ActiveTrack") == selected_track, "failed activation preserves the previous active track node")
	_expect(main.get_node_or_null("TrackContainer/PendingTrack") == null, "failed activation removes the rejected pending track")
	_expect(main.call("get_current_car") != null, "failed activation leaves the current driving session intact")

	initial_track = null
	menu = null
	variants.clear()
	selected_track = null
	track_after_failed_activation = null
	main.queue_free()
	main = null
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_finish()


func _test_track_spawn_transaction(
	simple_definition: TrackDefinition,
	alternate_definition: TrackDefinition
) -> void:
	var container: Node3D = Node3D.new()
	container.name = "TransactionalTrackContainer"
	add_child(container)
	var controller: TrackSpawnController = TrackSpawnController.new()
	controller.configure(container)

	var initial_track: GeneratedTrack = controller.spawn_track(simple_definition)
	_expect(initial_track != null, "transaction fixture commits an initial track")
	var staged_track: GeneratedTrack = controller.stage_track(alternate_definition)
	_expect(staged_track != null, "valid replacement track can be staged")
	_expect(controller.get_current_track() == initial_track, "staging leaves the committed track active")
	_expect(container.get_node_or_null("ActiveTrack") == initial_track, "staging preserves the active-track node")
	_expect(container.get_node_or_null("PendingTrack") == staged_track, "staged replacement remains explicitly pending")

	var promoted_track: GeneratedTrack = controller.commit_staged_track()
	_expect(promoted_track == staged_track, "commit promotes the staged replacement")
	_expect(controller.get_current_track() == promoted_track, "promoted replacement becomes the provisional current track")
	_expect(initial_track.get_parent() == null, "previous track is retained outside the tree until finalization")
	controller.rollback_track_transaction()
	_expect(controller.get_current_track() == initial_track, "rollback restores the previous committed track")
	_expect(container.get_node_or_null("ActiveTrack") == initial_track, "rollback restores the previous active-track node")
	_expect(container.get_node_or_null("PendingTrack") == null, "rollback discards the rejected replacement")

	var final_staged_track: GeneratedTrack = controller.stage_track(alternate_definition)
	_expect(final_staged_track != null, "replacement can be staged again after rollback")
	_expect(controller.commit_staged_track() == final_staged_track, "replacement can be promoted after rollback")
	controller.finalize_track_commit()
	_expect(controller.get_current_track() == final_staged_track, "finalization retains the promoted replacement")
	_expect(not is_instance_valid(initial_track), "finalization disposes the superseded track")
	controller.clear_track()
	container.queue_free()


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


func _make_invalid_generated_track_scene() -> PackedScene:
	var invalid_layout: TrackLayoutResource = TrackLayoutResource.new()
	invalid_layout.track_id = &"invalid_generated_track"
	invalid_layout.display_name = "Invalid generated track"

	var invalid_track: GeneratedTrack = GeneratedTrack.new()
	invalid_track.track_layout = invalid_layout
	var packed_scene: PackedScene = PackedScene.new()
	var pack_result: Error = packed_scene.pack(invalid_track)
	invalid_track.free()
	_expect(pack_result == OK, "invalid generated-track fixture packs successfully")
	return packed_scene if pack_result == OK else null


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
		get_tree().call_deferred("quit", 0)
		return
	push_error("[TRACK_SELECTION_RUNTIME_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_SELECTION_RUNTIME_TEST] - %s" % failure_message)
	get_tree().call_deferred("quit", 1)
