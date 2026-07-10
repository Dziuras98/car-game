extends Node

const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_material_cache()
	await _test_generated_batches()
	_finish()


func _test_material_cache() -> void:
	var factory: TrackMaterialFactory = TrackMaterialFactory.new()
	var first_asphalt: Material = factory.create_asphalt_material()
	var second_asphalt: Material = factory.create_asphalt_material()
	var first_barrier: Material = factory.create_barrier_material()
	var second_barrier: Material = factory.create_barrier_material()
	var first_audience: Array[StandardMaterial3D] = factory.create_audience_materials()
	var second_audience: Array[StandardMaterial3D] = factory.create_audience_materials()
	_expect(first_asphalt == second_asphalt, "asphalt material is reused inside one track material factory")
	_expect(first_barrier == second_barrier, "barrier material is reused inside one track material factory")
	_expect(first_audience.size() == second_audience.size(), "audience palette keeps a stable material count")
	_expect(not first_audience.is_empty() and first_audience[0] == second_audience[0], "audience materials are reused across rebuild requests")


func _test_generated_batches() -> void:
	var mutable_layout: TrackLayoutResource = SIMPLE_OVAL_LAYOUT.duplicate(true) as TrackLayoutResource
	var track: Node3D = SIMPLE_OVAL_SCENE.instantiate() as Node3D
	track.set("track_layout", mutable_layout)
	add_child(track)
	await get_tree().process_frame
	_validate_batches(track, "initial generation")

	mutable_layout.track_width += 0.4
	await get_tree().process_frame
	await get_tree().process_frame
	_validate_batches(track, "rebuilt generation")

	track.queue_free()
	await get_tree().process_frame


func _validate_batches(track: Node3D, stage: String) -> void:
	var generated: Node = track.get_node_or_null("GeneratedContent")
	_expect(generated != null, "%s creates generated content" % stage)
	if generated == null:
		return

	var edge_markers: MultiMeshInstance3D = generated.get_node_or_null("EdgeMarkers") as MultiMeshInstance3D
	var barrier_root: Node = generated.get_node_or_null("Barriers")
	var barrier_visuals: MultiMeshInstance3D = generated.get_node_or_null("Barriers/BarrierVisuals") as MultiMeshInstance3D
	_expect(edge_markers != null and edge_markers.multimesh != null, "%s batches edge markers into one MultiMesh" % stage)
	_expect(barrier_visuals != null and barrier_visuals.multimesh != null, "%s batches barriers into one MultiMesh" % stage)
	if edge_markers != null and edge_markers.multimesh != null:
		_expect(edge_markers.multimesh.instance_count > 2, "%s preserves all edge marker instances inside the batch" % stage)
	if barrier_visuals != null and barrier_visuals.multimesh != null:
		_expect(barrier_visuals.multimesh.instance_count > 2, "%s preserves all barrier instances inside the batch" % stage)

	_expect(
		_count_direct_named_batches(generated, "EdgeMarkers") == 1,
		"%s keeps exactly one edge-marker render batch" % stage
	)
	_expect(
		barrier_root != null and _count_nodes_of_type(barrier_root, "MultiMeshInstance3D") == 1,
		"%s keeps exactly one barrier render batch" % stage
	)


func _count_direct_named_batches(root: Node, node_name: String) -> int:
	var count: int = 0
	for child: Node in root.get_children():
		if child is MultiMeshInstance3D and child.name == node_name:
			count += 1
	return count


func _count_nodes_of_type(root: Node, class_name_text: String) -> int:
	if root == null:
		return 0
	var count: int = 1 if root.get_class() == class_name_text else 0
	for child: Node in root.get_children():
		count += _count_nodes_of_type(child, class_name_text)
	return count


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_RENDER_BATCHING_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_RENDER_BATCHING_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_RENDER_BATCHING_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[TRACK_RENDER_BATCHING_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_RENDER_BATCHING_TEST] - %s" % failure_message)
	get_tree().quit(1)
