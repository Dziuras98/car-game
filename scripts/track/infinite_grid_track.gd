extends GeneratedTrack
class_name InfiniteGridTrack

@export var visual_floor_path: NodePath = NodePath("VisualFloor")
@export_range(16.0, 1024.0, 1.0) var visual_snap_size: float = 256.0
@export_range(100.0, 5000.0, 10.0) var minimap_extent: float = 1000.0

var _visual_floor: MeshInstance3D
var _committed: bool = false
var _revision: int = 0
var _runtime_locked: bool = false
var _map_center_local: Vector3 = Vector3.ZERO
var _has_visual_center: bool = false


func _ready() -> void:
	_visual_floor = get_node_or_null(visual_floor_path) as MeshInstance3D
	_committed = _validate_runtime_content()
	if not _committed:
		push_error("InfiniteGridTrack requires a visual plane and an infinite world-boundary collision.")
		set_process(false)
		return
	_update_visual_floor_position(true)
	set_process(true)


func _process(_delta: float) -> void:
	_update_visual_floor_position()


func get_racing_line_points() -> Array[Vector3]:
	var extent: float = maxf(minimap_extent, 100.0)
	return [
		_map_center_local + Vector3(-extent, 0.0, -extent),
		_map_center_local + Vector3(extent, 0.0, -extent),
		_map_center_local + Vector3(extent, 0.0, extent),
		_map_center_local + Vector3(-extent, 0.0, extent),
	]


func get_track_layout() -> TrackLayoutResource:
	return null


func get_checkpoint_count() -> int:
	return 0


func get_checkpoint_gate_count() -> int:
	return 0


func get_geometry_revision() -> int:
	return _revision


func get_rebuild_count() -> int:
	return _revision


func has_committed_generation() -> bool:
	return _committed


func set_runtime_rebuild_locked(locked: bool) -> void:
	_runtime_locked = locked


func is_runtime_rebuild_locked() -> bool:
	return _runtime_locked


func request_rebuild() -> void:
	if _runtime_locked:
		return
	_committed = _validate_runtime_content()
	if _committed:
		_update_visual_floor_position(true)


func _validate_runtime_content() -> bool:
	if _visual_floor == null or _visual_floor.mesh == null:
		return false
	var surface_body: TrackSurfaceBody = get_node_or_null("Surface") as TrackSurfaceBody
	var collision_shape: CollisionShape3D = get_node_or_null("Surface/CollisionShape3D") as CollisionShape3D
	return (
		surface_body != null
		and collision_shape != null
		and collision_shape.shape is WorldBoundaryShape3D
	)


func _update_visual_floor_position(force: bool = false) -> void:
	if _visual_floor == null:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	var target_position: Vector3 = camera.global_position if camera != null else global_position
	var snapped_center := Vector3(
		snappedf(target_position.x, visual_snap_size),
		0.0,
		snappedf(target_position.z, visual_snap_size)
	)
	if not force and _has_visual_center and _visual_floor.global_position.is_equal_approx(snapped_center):
		return
	_visual_floor.global_position = snapped_center
	_map_center_local = to_local(snapped_center)
	_has_visual_center = true
	_revision += 1
	geometry_rebuilt.emit(_revision)
