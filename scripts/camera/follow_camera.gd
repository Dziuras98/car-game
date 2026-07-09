extends Camera3D

@export var target_path: NodePath
@export var follow_distance: float = 9.0
@export var follow_height: float = 5.0
@export var look_ahead_distance: float = 3.0
@export var position_smoothing: float = 8.0

@onready var _target: Node3D = get_node_or_null(target_path) as Node3D


func set_target_node(target: Node3D) -> void:
	_target = target
	if not is_inside_tree():
		return
	if target != null and is_instance_valid(target) and target.is_inside_tree():
		target_path = get_path_to(target)


func _process(delta: float) -> void:
	if not is_inside_tree():
		return

	if not is_instance_valid(_target):
		_target = get_node_or_null(target_path) as Node3D

	if not is_instance_valid(_target) or not _target.is_inside_tree():
		return

	var target_transform: Transform3D = _target.global_transform
	var target_position: Vector3 = target_transform.origin
	var behind: Vector3 = target_transform.basis.z.normalized()
	var desired_position: Vector3 = target_position + behind * follow_distance + Vector3.UP * follow_height
	var blend: float = 1.0 - exp(-position_smoothing * delta)

	global_position = global_position.lerp(desired_position, blend)
	look_at(target_position - behind * look_ahead_distance + Vector3.UP * 1.2, Vector3.UP)
