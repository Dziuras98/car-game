extends Node

const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")

var _checks: int = 0
var _failures: Array[String] = []


class FailingSurfaceBuilder:
	extends TrackSurfaceMeshBuilder

	func build_surfaces(
		_parent: Node3D,
		_geometry: TrackGeometryData,
		_material_factory: TrackMaterialFactory,
		_config: TrackGenerationConfig
	) -> TrackGeneratedMeshes:
		return null


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var mutable_layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	var track: GeneratedTrack = SIMPLE_OVAL_SCENE.instantiate() as GeneratedTrack
	track.name = "Track"
	track.track_layout = mutable_layout
	add_child(track)
	await get_tree().process_frame

	_expect(track.has_committed_generation(), "initial track generation is committed")
	var initial_revision: int = track.get_geometry_revision()
	var initial_gate_count: int = track.get_checkpoint_gate_count()
	var initial_content: Node3D = track.get_node_or_null(
		TrackGeneratedContentRoot.GENERATED_CONTENT_NAME
	) as Node3D
	_expect(initial_content != null, "initial generated content exists")

	track._surface_builder = FailingSurfaceBuilder.new()
	mutable_layout.track_width += 0.5
	await get_tree().process_frame
	await get_tree().process_frame

	var content_after_failure: Node3D = track.get_node_or_null(
		TrackGeneratedContentRoot.GENERATED_CONTENT_NAME
	) as Node3D
	_expect(track.get_geometry_revision() == initial_revision, "failed rebuild does not publish a geometry revision")
	_expect(content_after_failure == initial_content, "failed rebuild preserves the previous generated subtree")
	_expect(initial_content != null and initial_content.is_inside_tree(), "previous generated content remains active after failure")
	_expect(track.get_checkpoint_gate_count() == initial_gate_count, "failed rebuild preserves the previous checkpoint gates")
	_expect(track.has_committed_generation(), "failed rebuild leaves the track in a committed state")

	track._surface_builder = TrackSurfaceMeshBuilder.new()
	mutable_layout.track_width += 0.5
	await get_tree().process_frame
	await get_tree().process_frame

	var replacement_content: Node3D = track.get_node_or_null(
		TrackGeneratedContentRoot.GENERATED_CONTENT_NAME
	) as Node3D
	_expect(track.get_geometry_revision() == initial_revision + 1, "successful retry publishes exactly one geometry revision")
	_expect(replacement_content != null and replacement_content != initial_content, "successful retry swaps in a new generated subtree")
	_expect(not is_instance_valid(initial_content), "previous generated subtree is released after a successful swap")
	_expect(track.get_checkpoint_gate_count() == initial_gate_count, "successful retry commits a complete checkpoint set")
	_expect(track.has_committed_generation(), "successful retry leaves the track in a committed state")

	track.queue_free()
	await get_tree().process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[ATOMIC_TRACK_REBUILD_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[ATOMIC_TRACK_REBUILD_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ATOMIC_TRACK_REBUILD_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[ATOMIC_TRACK_REBUILD_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[ATOMIC_TRACK_REBUILD_TEST] - %s" % failure_message)
	get_tree().quit(1)
