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
var _rebuild_pending: bool = false
var _has_generation_signature: bool = false
var _last_generation_signature: int = 0
var _rebuild_count: int = 0


func _ready() -> void:
	_ensure_builders()
	_connect_layout_changed()
	_rebuild_track(true)


func _exit_tree() -> void:
	_disconnect_layout_changed()


func _request_rebuild() -> void:
	if not is_inside_tree() or _rebuild_pending:
		return
	_rebuild_pending = true
	call_deferred("_perform_pending_rebuild")


func _perform_pending_rebuild() -> void:
	_rebuild_pending = false
	_rebuild_track(false)


func _rebuild_track(force: bool = false) -> void:
	if not is_inside_tree() or track_layout == null or not track_layout.is_valid():
		return

	var generation_signature: int = _get_generation_signature()
	if not force and _has_generation_signature and generation_signature == _last_generation_signature:
		return

	_ensure_builders()
	var config: Dictionary = _build_track_generation_config()
	_geometry = _layout_builder.build(config)
	var generated_content: Node3D = _content_root.clear(self)

	var surface_meshes: Dictionary = _surface_builder.build_surfaces(
		generated_content,
		_geometry,
		_material_factory,
		config
	)
	_collision_builder.build_collisions(generated_content, _geometry, config, surface_meshes)
	_marker_builder.build_markers(generated_content, _geometry, _material_factory, config)
	_barrier_builder.build_barriers(generated_content, _geometry, _material_factory, config)
	_decoration_builder.build_decorations(generated_content, _geometry, _material_factory, config)
	_checkpoint_gates = _checkpoint_builder.build(
		generated_content,
		_geometry,
		track_layout,
		Callable(self, "_on_checkpoint_gate_crossed")
	)

	_last_generation_signature = generation_signature
	_has_generation_signature = true
	_rebuild_count += 1
	geometry_rebuilt.emit(_rebuild_count)


func get_racing_line_points() -> Array[Vector3]:
	if _geometry == null:
		_ensure_builders()
		_geometry = _layout_builder.build(_build_track_generation_config())
	return _geometry.get_racing_line_points_array()


func get_track_layout() -> TrackLayoutResource:
	return track_layout


func get_checkpoint_count() -> int:
	return track_layout.get_checkpoint_count() if track_layout != null else 0


func get_geometry_revision() -> int:
	return _rebuild_count


func get_checkpoint_gate_count_for_test() -> int:
	var valid_gate_count: int = 0
	for gate: TrackCheckpointGate in _checkpoint_gates:
		if is_instance_valid(gate):
			valid_gate_count += 1
	return valid_gate_count


func get_rebuild_count_for_test() -> int:
	return _rebuild_count


func request_rebuild_for_test() -> void:
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


func _build_track_generation_config() -> Dictionary:
	if track_layout == null:
		return {}
	return {
		"track_layout": track_layout,
		"track_width": track_layout.track_width,
		"grass_size": track_layout.grass_size,
		"shoulder_width": track_layout.shoulder_width,
		"barrier_distance_from_road": track_layout.barrier_distance_from_road,
		"width_variation": track_layout.width_variation,
		"has_stadium": track_layout.has_stadium,
		"stadium_section_step": track_layout.stadium_section_step,
		"stadium_distance_from_barrier": track_layout.stadium_distance_from_barrier,
	}


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
		track_layout.checkpoint_progresses,
		track_layout.checkpoint_depth,
		track_layout.checkpoint_height,
		track_layout.checkpoint_width_margin,
		track_layout.has_stadium,
		track_layout.stadium_section_step,
		track_layout.stadium_distance_from_barrier,
	])


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
