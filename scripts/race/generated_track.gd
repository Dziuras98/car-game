@tool
extends Node3D
class_name GeneratedTrack

signal checkpoint_crossed(car: PlayerCarController, checkpoint_index: int, is_forward: bool)
signal geometry_rebuilt(revision: int)

const DEFAULT_TRACK_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")

@export var track_layout: TrackLayoutResource = DEFAULT_TRACK_LAYOUT:
	set(value):
		if track_layout == value:
			return
		_disconnect_layout_changed()
		track_layout = value
		_connect_layout_changed()
		_request_rebuild()

var _content_root: TrackGeneratedContentRoot
var _layout_builder: TrackLayoutBuilder
var _material_factory: TrackMaterialFactory
var _surface_builder: TrackSurfaceMeshBuilder
var _collision_builder: TrackCollisionBuilder
var _marker_builder: TrackMarkerBuilder
var _barrier_builder: TrackBarrierBuilder
var _decoration_builder: TrackDecorationBuilder
var _checkpoint_builder: TrackCheckpointBuilder
var _geometry: TrackGeometryData
var _checkpoint_gates: Array[TrackCheckpointGate] = []
var _committed_track_layout: TrackLayoutResource
var _rebuild_pending: bool = false
var _runtime_rebuild_locked: bool = false
var _queued_rebuild_while_locked: bool = false
var _has_generation_signature: bool = false
var _has_committed_generation: bool = false
var _last_generation_signature: int = 0
var _rebuild_count: int = 0


func _ready() -> void:
	_ensure_builders()
	_connect_layout_changed()
	_rebuild_track(true)


func _exit_tree() -> void:
	_disconnect_layout_changed()


func _request_rebuild() -> void:
	if not is_inside_tree():
		return
	if _runtime_rebuild_locked:
		_queued_rebuild_while_locked = true
		return
	if _rebuild_pending:
		return
	_rebuild_pending = true
	call_deferred("_perform_pending_rebuild")


func _perform_pending_rebuild() -> void:
	_rebuild_pending = false
	if _runtime_rebuild_locked:
		_queued_rebuild_while_locked = true
		return
	_rebuild_track(false)


func _rebuild_track(force: bool = false) -> bool:
	if not is_inside_tree() or track_layout == null or not track_layout.is_valid():
		return false
	if _runtime_rebuild_locked and not force:
		_queued_rebuild_while_locked = true
		return false

	var generation_signature: int = _get_generation_signature()
	if not force and _has_generation_signature and generation_signature == _last_generation_signature:
		return true

	_ensure_builders()
	var config: TrackGenerationConfig = _build_track_generation_config()
	var next_geometry: TrackGeometryData = _layout_builder.build(config)
	if not _is_geometry_valid(next_geometry):
		push_warning("GeneratedTrack layout generation failed; keeping the previous generated content.")
		return false

	var staged_content: Node3D = _content_root.create_staging_container()
	var generated_meshes: TrackGeneratedMeshes = _surface_builder.build_surfaces(
		staged_content,
		next_geometry,
		_material_factory,
		config
	)
	if not _are_generated_meshes_valid(generated_meshes):
		_discard_staged_content(staged_content)
		push_warning("GeneratedTrack surface generation failed; keeping the previous generated content.")
		return false

	_collision_builder.build_collisions(staged_content, next_geometry, config, generated_meshes)
	_marker_builder.build_markers(staged_content, next_geometry, _material_factory, config)
	_barrier_builder.build_barriers(staged_content, next_geometry, _material_factory, config)
	_decoration_builder.build_decorations(staged_content, next_geometry, _material_factory, config)
	var next_checkpoint_gates: Array[TrackCheckpointGate] = _checkpoint_builder.build(
		staged_content,
		next_geometry,
		track_layout,
		Callable(self, "_on_checkpoint_gate_crossed")
	)
	if next_checkpoint_gates.size() != track_layout.get_checkpoint_gate_count():
		_discard_staged_content(staged_content)
		push_warning("GeneratedTrack checkpoint generation failed; keeping the previous generated content.")
		return false

	if _content_root.commit(self, staged_content) == null:
		_discard_staged_content(staged_content)
		push_warning("GeneratedTrack could not commit generated content; keeping the previous generated content.")
		return false

	_geometry = next_geometry
	_checkpoint_gates = next_checkpoint_gates
	_committed_track_layout = track_layout.duplicate(true) as TrackLayoutResource
	_last_generation_signature = generation_signature
	_has_generation_signature = true
	_has_committed_generation = true
	_rebuild_count += 1
	geometry_rebuilt.emit(_rebuild_count)
	return true


func get_racing_line_points() -> Array[Vector3]:
	return _geometry.get_racing_line_points_array() if _is_geometry_valid(_geometry) else []


func get_track_layout() -> TrackLayoutResource:
	return _committed_track_layout


func get_checkpoint_count() -> int:
	return _committed_track_layout.get_checkpoint_count() if _committed_track_layout != null else 0


func get_geometry_revision() -> int:
	return _rebuild_count


func get_checkpoint_gate_count() -> int:
	var valid_gate_count: int = 0
	for gate: TrackCheckpointGate in _checkpoint_gates:
		if is_instance_valid(gate):
			valid_gate_count += 1
	return valid_gate_count


func get_rebuild_count() -> int:
	return _rebuild_count


func has_committed_generation() -> bool:
	return _has_committed_generation


func set_runtime_rebuild_locked(locked: bool) -> void:
	if _runtime_rebuild_locked == locked:
		return
	_runtime_rebuild_locked = locked
	if not locked and _queued_rebuild_while_locked:
		_queued_rebuild_while_locked = false
		_request_rebuild()


func is_runtime_rebuild_locked() -> bool:
	return _runtime_rebuild_locked


func request_rebuild() -> void:
	_request_rebuild()


func _ensure_builders() -> void:
	if _content_root == null:
		_content_root = TrackGeneratedContentRoot.new()
	if _layout_builder == null:
		_layout_builder = TrackLayoutBuilder.new()
	if _material_factory == null:
		_material_factory = TrackMaterialFactory.new()
	if _surface_builder == null:
		_surface_builder = TrackSurfaceMeshBuilder.new()
	if _collision_builder == null:
		_collision_builder = TrackCollisionBuilder.new()
	if _marker_builder == null:
		_marker_builder = TrackMarkerBuilder.new()
	if _barrier_builder == null:
		_barrier_builder = TrackBarrierBuilder.new()
	if _decoration_builder == null:
		_decoration_builder = TrackDecorationBuilder.new()
	if _checkpoint_builder == null:
		_checkpoint_builder = TrackCheckpointBuilder.new()


func _build_track_generation_config() -> TrackGenerationConfig:
	return TrackGenerationConfig.from_layout(track_layout)


func _get_generation_signature() -> int:
	if track_layout == null:
		return 0
	return hash([
		track_layout.track_id,
		track_layout.control_points,
		track_layout.samples_per_segment,
		track_layout.track_width,
		track_layout.width_variation,
		track_layout.shoulder_width,
		track_layout.grass_size,
		track_layout.barrier_distance_from_road,
		track_layout.track_width_profile,
		track_layout.shoulder_width_profile,
		track_layout.barrier_distance_profile,
		track_layout.racing_line_offset_profile,
		track_layout.banking_degrees_profile,
		track_layout.checkpoint_progresses,
		track_layout.checkpoint_depth,
		track_layout.checkpoint_height,
		track_layout.checkpoint_width_margin,
		track_layout.has_stadium,
		track_layout.stadium_section_step,
		track_layout.stadium_distance_from_barrier,
	])


func _is_geometry_valid(geometry: TrackGeometryData) -> bool:
	return geometry != null and geometry.is_valid()


func _are_generated_meshes_valid(generated_meshes: TrackGeneratedMeshes) -> bool:
	return (
		generated_meshes != null
		and generated_meshes.track_mesh != null
		and generated_meshes.track_mesh.get_surface_count() > 0
		and generated_meshes.shoulder_mesh != null
		and generated_meshes.shoulder_mesh.get_surface_count() > 0
	)


func _discard_staged_content(staged_content: Node3D) -> void:
	if is_instance_valid(staged_content):
		staged_content.free()


func _connect_layout_changed() -> void:
	if track_layout == null:
		return
	var callback: Callable = Callable(self, "_on_track_layout_changed")
	if not track_layout.is_connected("changed", callback):
		track_layout.connect("changed", callback)


func _disconnect_layout_changed() -> void:
	if track_layout == null:
		return
	var callback: Callable = Callable(self, "_on_track_layout_changed")
	if track_layout.is_connected("changed", callback):
		track_layout.disconnect("changed", callback)


func _on_track_layout_changed() -> void:
	_request_rebuild()


func _on_checkpoint_gate_crossed(
	car: PlayerCarController,
	checkpoint_index: int,
	is_forward: bool
) -> void:
	checkpoint_crossed.emit(car, checkpoint_index, is_forward)
