extends RefCounted
class_name SkidMarkEmitter

const LEFT_REAR_MARK_POSITION: Vector3 = Vector3(-0.9, 0.03, 1.25)
const RIGHT_REAR_MARK_POSITION: Vector3 = Vector3(0.9, 0.03, 1.25)

var min_slip: float = 0.45
var interval: float = 0.055
var lifetime: float = 10.0
var mark_width: float = 0.22
var mark_length: float = 0.9

var _timer: float = 0.0
var _parent: Node3D
var _material: StandardMaterial3D


func configure(owner_node: Node, target_min_slip: float, target_interval: float, target_lifetime: float, target_width: float, target_length: float) -> void:
	min_slip = target_min_slip
	interval = target_interval
	lifetime = target_lifetime
	mark_width = target_width
	mark_length = target_length
	_prepare_parent(owner_node)
	_prepare_material()


func reset_timer() -> void:
	_timer = 0.0


func update(delta: float, slip_intensity: float, source_transform: Transform3D) -> void:
	if slip_intensity < min_slip:
		_timer = 0.0
		return

	_timer -= delta
	if _timer > 0.0:
		return

	_timer = interval
	_spawn_mark(source_transform, LEFT_REAR_MARK_POSITION)
	_spawn_mark(source_transform, RIGHT_REAR_MARK_POSITION)


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
		skid_mark_owner.call_deferred("add_child", _parent)


func _prepare_material() -> void:
	if _material != null:
		return

	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.015, 0.014, 0.012, 0.72)
	_material.roughness = 0.96
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func _spawn_mark(source_transform: Transform3D, local_position: Vector3) -> void:
	if _parent == null or _material == null:
		return

	var skid_mark: MeshInstance3D = MeshInstance3D.new()
	var mark_mesh: BoxMesh = BoxMesh.new()
	mark_mesh.size = Vector3(mark_width, 0.012, mark_length)
	skid_mark.mesh = mark_mesh
	skid_mark.material_override = _material
	skid_mark.global_transform = source_transform * Transform3D(Basis(), local_position)
	_parent.add_child(skid_mark)

	var tween: Tween = skid_mark.create_tween()
	tween.tween_property(skid_mark, "transparency", 1.0, lifetime)
	tween.finished.connect(skid_mark.queue_free)
