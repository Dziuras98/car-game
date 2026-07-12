extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var container: Node3D = Node3D.new()
	root.add_child(container)
	var controller: TrackSpawnController = TrackSpawnController.new()
	controller.configure(container)

	var first_scene: PackedScene = _pack_generated_track_scene()
	var first_definition: TrackDefinition = _build_definition(&"shared_id", first_scene, "First")
	var first_track: GeneratedTrack = controller.spawn_track(first_definition)
	_expect(first_track != null, "initial generated track spawns")
	if first_track == null:
		container.queue_free()
		_finish()
		return

	var metadata_update: TrackDefinition = _build_definition(&"shared_id", first_scene, "Metadata update")
	var reused_track: GeneratedTrack = controller.stage_track(metadata_update)
	_expect(reused_track == first_track, "same id and same PackedScene reuse the active generated track")
	controller.rollback_track_transaction()

	var replacement_scene: PackedScene = _pack_generated_track_scene()
	var replacement_definition: TrackDefinition = _build_definition(&"shared_id", replacement_scene, "Replacement")
	var staged_replacement: GeneratedTrack = controller.stage_track(replacement_definition)
	_expect(staged_replacement != null, "replacement definition stages successfully")
	_expect(staged_replacement != first_track, "same id with a different PackedScene does not reuse stale geometry")
	var committed_replacement: GeneratedTrack = controller.commit_staged_track()
	_expect(committed_replacement == staged_replacement, "replacement geometry commits atomically")
	controller.finalize_track_commit()
	_expect(controller.get_current_definition() == replacement_definition, "active metadata matches the committed replacement scene")

	controller.clear_track()
	container.queue_free()
	_finish()


func _build_definition(track_id: StringName, scene: PackedScene, label: String) -> TrackDefinition:
	var definition: TrackDefinition = TrackDefinition.new()
	definition.track_id = track_id
	definition.display_name = label
	definition.recommended_laps = 3
	definition.track_scene = scene
	assert(definition.is_valid())
	return definition


func _pack_generated_track_scene() -> PackedScene:
	var track: GeneratedTrack = GeneratedTrack.new()
	var scene: PackedScene = PackedScene.new()
	var result: Error = scene.pack(track)
	track.free()
	assert(result == OK)
	return scene


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_SPAWN_REUSE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_SPAWN_REUSE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_SPAWN_REUSE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRACK_SPAWN_REUSE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_SPAWN_REUSE_TEST] - %s" % failure_message)
	quit(1)
