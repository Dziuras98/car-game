extends Node

const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var track: Node3D = SIMPLE_OVAL_SCENE.instantiate() as Node3D
	_expect(track != null, "track instantiates for barrier collision validation")
	if track == null:
		_finish()
		return

	var mutable_layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	track.set("track_layout", mutable_layout)
	add_child(track)
	await get_tree().process_frame
	_validate_barriers(track, "initial generation")

	mutable_layout.track_width += 0.75
	await get_tree().process_frame
	await get_tree().process_frame
	_validate_barriers(track, "rebuilt generation")

	track.queue_free()
	await get_tree().process_frame
	_finish()


func _validate_barriers(track: Node3D, stage: String) -> void:
	var barriers: Node = track.get_node_or_null("GeneratedContent/Barriers")
	_expect(barriers is StaticBody3D, "%s uses a StaticBody3D barrier root" % stage)
	if barriers == null:
		return

	var visual: MultiMeshInstance3D = barriers.get_node_or_null("BarrierVisuals") as MultiMeshInstance3D
	var collision_count: int = 0
	for child: Node in barriers.get_children():
		if child is CollisionShape3D:
			collision_count += 1

	_expect(visual != null and visual.multimesh != null, "%s creates one batched barrier visual node" % stage)
	_expect(collision_count > 0, "%s creates physical barrier segments" % stage)
	if visual != null and visual.multimesh != null:
		_expect(
			visual.multimesh.instance_count == collision_count,
			"%s keeps one collision per batched visible barrier instance" % stage
		)
	_expect(_count_multimesh_nodes(barriers) == 1, "%s keeps barrier visuals to one MultiMesh draw source" % stage)


func _count_multimesh_nodes(parent: Node) -> int:
	var count: int = 0
	for child: Node in parent.get_children():
		if child is MultiMeshInstance3D:
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_BARRIER_COLLISION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_BARRIER_COLLISION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_BARRIER_COLLISION_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[TRACK_BARRIER_COLLISION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_BARRIER_COLLISION_TEST] - %s" % failure_message)
	get_tree().quit(1)
