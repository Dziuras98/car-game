extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if main_scene == null:
		_fail("Could not load the simplified main scene.")
		return
	var game: Node = main_scene.instantiate()
	if game == null:
		_fail("Could not instantiate the simplified main scene.")
		return
	root.add_child(game)
	await process_frame
	await process_frame

	if not game.has_method("is_ready_for_input") or not bool(game.call("is_ready_for_input")):
		_fail("The free-drive runtime did not reach its ready state.")
		return
	if not game.has_method("get_active_track"):
		_fail("The free-drive runtime does not expose its active grid.")
		return
	var active_track: GeneratedTrack = game.call("get_active_track") as GeneratedTrack
	if not active_track is InfiniteGridTrack:
		_fail("The active runtime surface is not InfiniteGridTrack.")
		return
	if game.find_child("Minimap", true, false) != null:
		_fail("The removed minimap is still present in the main runtime.")
		return
	if game.find_child("RaceHud", true, false) != null:
		_fail("The removed race HUD is still present in the main runtime.")
		return
	if game.find_child("TrackContainer", true, false) != null:
		_fail("The removed track-selection container is still present.")
		return

	game.queue_free()
	await process_frame
	print("Free-drive smoke test passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
