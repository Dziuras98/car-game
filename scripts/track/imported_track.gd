extends GeneratedTrack
class_name ImportedTrack

@export_file("*.json") var racing_line_json_path: String = ""
@export var collision_source_path: NodePath = NodePath("CollisionSources")

const SURFACE_GRIP: Dictionary = {
	"TARMAC": 0.99,
	"PITLANE": 0.95,
	"KERB": 0.94,
	"SAND": 0.80,
	"GRASS": 0.76,
	"OFFTRACK": 0.90,
	"CONCRETE": 0.94,
	"WALL": 1.00,
	"DEFAULT": 1.00,
}

var _racing_points: Array[Vector3] = []
var _imported_checkpoint_gates: Array[TrackCheckpointGate] = []
var _collision_bodies: Array[TrackSurfaceBody] = []
var _committed: bool = false
var _revision: int = 0
var _runtime_locked: bool = false


func _ready() -> void:
	_rebuild_imported_track()


func _rebuild_imported_track() -> bool:
	if _runtime_locked:
		return false
	_clear_runtime_content()
	if not _load_racing_line():
		push_error("ImportedTrack could not load a valid racing line from '%s'." % racing_line_json_path)
		return false
	if not _build_collision_bodies():
		push_error("ImportedTrack could not build collision bodies.")
		return false
	_build_checkpoint_gates()
	_committed = (
		_racing_points.size() >= 3
		and not _collision_bodies.is_empty()
		and not _imported_checkpoint_gates.is_empty()
	)
	if not _committed:
		return false
	_revision += 1
	geometry_rebuilt.emit(_revision)
	return true


func get_racing_line_points() -> Array[Vector3]:
	return _racing_points.duplicate()


func get_track_layout() -> TrackLayoutResource:
	return track_layout


func get_checkpoint_count() -> int:
	return track_layout.get_checkpoint_count() if track_layout != null else 0


func get_checkpoint_gate_count() -> int:
	var count: int = 0
	for gate: TrackCheckpointGate in _imported_checkpoint_gates:
		if is_instance_valid(gate):
			count += 1
	return count


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
	if not _runtime_locked:
		_rebuild_imported_track()


func _load_racing_line() -> bool:
	_racing_points.clear()
	if racing_line_json_path.is_empty() or not FileAccess.file_exists(racing_line_json_path):
		return false
	var file: FileAccess = FileAccess.open(racing_line_json_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var raw_points: Variant = (parsed as Dictionary).get("points", [])
	if not raw_points is Array:
		return false
	for raw_point: Variant in raw_points:
		if not raw_point is Array or (raw_point as Array).size() != 3:
			return false
		var values: Array = raw_point as Array
		var point: Vector3 = Vector3(float(values[0]), float(values[1]), float(values[2]))
		if not is_finite(point.x) or not is_finite(point.y) or not is_finite(point.z):
			return false
		_racing_points.append(point)
	return _racing_points.size() >= 3


func _build_collision_bodies() -> bool:
	var collision_source: Node = get_node_or_null(collision_source_path)
	if collision_source == null:
		return false
	var mesh_instances: Array[MeshInstance3D] = []
	_collect_mesh_instances(collision_source, mesh_instances)
	for mesh_instance: MeshInstance3D in mesh_instances:
		if mesh_instance.mesh == null:
			continue
		var shape: ConcavePolygonShape3D = mesh_instance.mesh.create_trimesh_shape()
		if shape == null:
			continue
		var surface_key: String = mesh_instance.name.trim_prefix("COLLISION_").to_upper()
		var body: TrackSurfaceBody = TrackSurfaceBody.new()
		body.name = "Surface_%s" % surface_key
		body.collision_layer = 1
		body.collision_mask = 0
		body.grip_multiplier = float(SURFACE_GRIP.get(surface_key, SURFACE_GRIP["DEFAULT"]))
		body.set_meta("surface_key", surface_key)
		add_child(body)
		body.global_transform = mesh_instance.global_transform
		var collision_shape: CollisionShape3D = CollisionShape3D.new()
		collision_shape.shape = shape
		body.add_child(collision_shape)
		_collision_bodies.append(body)
	for mesh_instance: MeshInstance3D in mesh_instances:
		mesh_instance.visible = false
	return not _collision_bodies.is_empty()


func _collect_mesh_instances(root: Node, output: Array[MeshInstance3D]) -> void:
	if root is MeshInstance3D:
		output.append(root as MeshInstance3D)
	for child: Node in root.get_children():
		_collect_mesh_instances(child, output)


func _build_checkpoint_gates() -> void:
	if track_layout == null or _racing_points.size() < 3:
		return
	_append_checkpoint_gate(0, 0.0)
	for checkpoint_offset: int in track_layout.checkpoint_progresses.size():
		_append_checkpoint_gate(checkpoint_offset + 1, track_layout.checkpoint_progresses[checkpoint_offset])


func _append_checkpoint_gate(sequence_index: int, progress: float) -> void:
	var point_count: int = _racing_points.size()
	var sample_index: int = clampi(floori(fposmod(progress, 1.0) * float(point_count)), 0, point_count - 1)
	var next_index: int = (sample_index + 1) % point_count
	var forward: Vector3 = (_racing_points[next_index] - _racing_points[sample_index]).normalized()
	if forward.length_squared() <= 0.000001:
		return
	var right: Vector3 = forward.cross(Vector3.UP).normalized()
	if right.length_squared() <= 0.000001:
		right = Vector3.RIGHT
	var z_axis: Vector3 = -forward
	var up: Vector3 = z_axis.cross(right).normalized()
	if up.length_squared() <= 0.000001:
		up = Vector3.UP
	var basis: Basis = Basis(right, up, z_axis).orthonormalized()
	var height: float = maxf(track_layout.checkpoint_height, 0.1)
	var width: float = track_layout.get_track_width_at(progress) + maxf(track_layout.checkpoint_width_margin, 0.0) * 2.0
	var gate: TrackCheckpointGate = TrackCheckpointGate.new()
	gate.name = "FinishLine" if sequence_index == 0 else "Checkpoint%02d" % sequence_index
	gate.configure(
		sequence_index,
		Transform3D(basis, _racing_points[sample_index] + up * height * 0.5),
		Vector3(width, height, maxf(track_layout.checkpoint_depth, 0.1))
	)
	gate.crossed.connect(_on_imported_gate_crossed)
	add_child(gate)
	_imported_checkpoint_gates.append(gate)


func _on_imported_gate_crossed(car: PlayerCarController, checkpoint_index: int, is_forward: bool) -> void:
	checkpoint_crossed.emit(car, checkpoint_index, is_forward)


func _clear_runtime_content() -> void:
	_committed = false
	for gate: TrackCheckpointGate in _imported_checkpoint_gates:
		if is_instance_valid(gate):
			gate.queue_free()
	_imported_checkpoint_gates.clear()
	for body: TrackSurfaceBody in _collision_bodies:
		if is_instance_valid(body):
			body.queue_free()
	_collision_bodies.clear()
