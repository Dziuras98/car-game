extends RefCounted
class_name SkidMarkEmitter

const LEFT_REAR_MARK_POSITION: Vector3 = Vector3(-0.9, 0.03, 1.25)
const RIGHT_REAR_MARK_POSITION: Vector3 = Vector3(0.9, 0.03, 1.25)
const MIN_CAPACITY: int = 16
const MAX_CAPACITY: int = 512

var min_slip: float = 0.45
var interval: float = 0.055
var lifetime: float = 10.0
var mark_width: float = 0.22
var mark_length: float = 0.9

var _timer: float = 0.0
var _clock: float = 0.0
var _parent: Node3D
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _material: StandardMaterial3D
var _spawn_times: PackedFloat32Array = PackedFloat32Array()
var _active_instances: PackedByteArray = PackedByteArray()
var _write_index: int = 0


func configure(
	owner_node: Node,
	target_min_slip: float,
	target_interval: float,
	target_lifetime: float,
	target_width: float,
	target_length: float
) -> void:
	min_slip = clampf(target_min_slip, 0.0, 1.0)
	interval = maxf(target_interval, 0.001)
	lifetime = maxf(target_lifetime, 0.01)
	mark_width = maxf(target_width, 0.01)
	mark_length = maxf(target_length, 0.01)
	_prepare_parent(owner_node)
	_prepare_material()
	_prepare_multimesh()


func reset_timer() -> void:
	_timer = 0.0
	_clock = 0.0
	_write_index = 0
	if _multimesh == null:
		return
	for index: int in range(_multimesh.instance_count):
		_active_instances[index] = 0
		_spawn_times[index] = -INF
		_multimesh.set_instance_transform(index, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
		_multimesh.set_instance_color(index, Color(1.0, 1.0, 1.0, 0.0))


func update(delta: float, slip_intensity: float, source_transform: Transform3D) -> void:
	if _multimesh == null or not is_instance_valid(_parent):
		return
	var safe_delta: float = maxf(delta, 0.0)
	_clock += safe_delta
	_update_instance_lifetimes()

	if slip_intensity < min_slip:
		_timer = 0.0
		return

	_timer -= safe_delta
	if _timer > 0.0:
		return
	_timer = interval
	_spawn_mark(source_transform, LEFT_REAR_MARK_POSITION)
	_spawn_mark(source_transform, RIGHT_REAR_MARK_POSITION)


func dispose() -> void:
	if is_instance_valid(_parent):
		_parent.queue_free()
	_parent = null
	_multimesh_instance = null
	_multimesh = null
	_spawn_times.clear()
	_active_instances.clear()


func get_capacity_for_test() -> int:
	return _multimesh.instance_count if _multimesh != null else 0


func get_active_count_for_test() -> int:
	var count: int = 0
	for active: int in _active_instances:
		if active != 0:
			count += 1
	return count


func get_render_node_count_for_test() -> int:
	if not is_instance_valid(_parent):
		return 0
	return _parent.get_child_count()


func _prepare_parent(owner_node: Node) -> void:
	if is_instance_valid(_parent):
		return
	_parent = Node3D.new()
	_parent.name = "SkidMarks"

	var skid_mark_owner: Node = null
	if owner_node != null and owner_node.is_inside_tree():
		skid_mark_owner = owner_node.get_tree().current_scene
		if skid_mark_owner == null:
			skid_mark_owner = owner_node.get_tree().root
	if skid_mark_owner != null:
		skid_mark_owner.add_child(_parent)


func _prepare_material() -> void:
	if _material != null:
		return
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.015, 0.014, 0.012, 0.72)
	_material.roughness = 0.96
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.vertex_color_use_as_albedo = true


func _prepare_multimesh() -> void:
	if not is_instance_valid(_parent):
		return
	var required_capacity: int = clampi(ceili(lifetime / interval) * 2 + 4, MIN_CAPACITY, MAX_CAPACITY)
	if _multimesh != null and _multimesh.instance_count == required_capacity:
		return

	if is_instance_valid(_multimesh_instance):
		_multimesh_instance.queue_free()
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "SkidMarkMultiMesh"
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = required_capacity

	var mark_mesh: BoxMesh = BoxMesh.new()
	mark_mesh.size = Vector3(mark_width, 0.012, mark_length)
	mark_mesh.material = _material
	_multimesh.mesh = mark_mesh
	_multimesh_instance.multimesh = _multimesh
	_parent.add_child(_multimesh_instance)

	_spawn_times.resize(required_capacity)
	_active_instances.resize(required_capacity)
	reset_timer()


func _spawn_mark(source_transform: Transform3D, local_position: Vector3) -> void:
	if _multimesh == null or not is_instance_valid(_parent):
		return
	var global_mark_transform: Transform3D = source_transform * Transform3D(Basis(), local_position)
	var local_mark_transform: Transform3D = _parent.global_transform.affine_inverse() * global_mark_transform
	_multimesh.set_instance_transform(_write_index, local_mark_transform)
	_multimesh.set_instance_color(_write_index, Color(1.0, 1.0, 1.0, 1.0))
	_spawn_times[_write_index] = _clock
	_active_instances[_write_index] = 1
	_write_index = (_write_index + 1) % _multimesh.instance_count


func _update_instance_lifetimes() -> void:
	for index: int in range(_active_instances.size()):
		if _active_instances[index] == 0:
			continue
		var age: float = _clock - _spawn_times[index]
		if age >= lifetime:
			_active_instances[index] = 0
			_multimesh.set_instance_transform(index, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
			_multimesh.set_instance_color(index, Color(1.0, 1.0, 1.0, 0.0))
			continue
		var alpha: float = 1.0 - clampf(age / lifetime, 0.0, 1.0)
		_multimesh.set_instance_color(index, Color(1.0, 1.0, 1.0, alpha))
