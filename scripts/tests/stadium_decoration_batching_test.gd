extends Node

const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	layout.has_stadium = true
	var track: GeneratedTrack = SIMPLE_OVAL_SCENE.instantiate() as GeneratedTrack
	track.track_layout = layout
	add_child(track)
	await get_tree().process_frame
	_validate_stadium(track, "initial generation")

	layout.stadium_section_step = maxi(layout.stadium_section_step - 1, 4)
	await get_tree().process_frame
	await get_tree().process_frame
	_validate_stadium(track, "rebuilt generation")

	track.queue_free()
	await get_tree().process_frame
	_finish()


func _validate_stadium(track: GeneratedTrack, stage: String) -> void:
	var stadium: Node3D = track.get_node_or_null("GeneratedContent/Stadium") as Node3D
	_expect(stadium != null, "%s creates the stadium root" % stage)
	if stadium == null:
		return
	var batches: Array[MultiMeshInstance3D] = []
	var individual_box_meshes: int = 0
	for child: Node in stadium.get_children():
		if child is MultiMeshInstance3D:
			batches.append(child as MultiMeshInstance3D)
		elif child is MeshInstance3D and child.name in ["StandStep", "SeatRow", "Spectator", "GrandstandRoof", "LightPole", "Floodlights"]:
			individual_box_meshes += 1

	_expect(batches.size() >= 4 and batches.size() <= 10, "%s keeps stadium boxes in a bounded set of render batches" % stage)
	_expect(individual_box_meshes == 0, "%s does not recreate one render node per seat, spectator or stand step" % stage)
	var total_instances: int = 0
	for batch: MultiMeshInstance3D in batches:
		if batch.multimesh != null:
			total_instances += batch.multimesh.instance_count
	_expect(total_instances > 30, "%s preserves the complete stadium population inside batches" % stage)
	_expect(stadium.get_node_or_null("StadiumBackWall") is MeshInstance3D, "%s keeps one combined back-wall mesh" % stage)
	_expect(stadium.get_node_or_null("WallDirectionArrows") is MeshInstance3D, "%s keeps one combined direction-arrow mesh" % stage)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[STADIUM_DECORATION_BATCHING_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[STADIUM_DECORATION_BATCHING_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[STADIUM_DECORATION_BATCHING_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[STADIUM_DECORATION_BATCHING_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[STADIUM_DECORATION_BATCHING_TEST] - %s" % failure_message)
	get_tree().quit(1)
