extends Camera3D
class_name FollowCamera

@export var target_path: NodePath
@export var follow_distance: float = 9.0
@export var follow_height: float = 5.0
@export var look_ahead_distance: float = 3.0
@export var rear_view_distance: float = 7.0
@export var position_smoothing: float = 8.0

@onready var _target: Node3D = get_node_or_null(target_path) as Node3D
var _rear_view_override: bool = false


func _ready() -> void:
	set_process(is_instance_valid(_target))


func set_target_node(target: Node3D) -> void:
	_target = target
	set_process(is_instance_valid(target))
	if not is_inside_tree():
		return
	if target != null and is_instance_valid(target) and target.is_inside_tree():
		target_path = get_path_to(target)


func set_rear_view_active(active: bool) -> void:
	_rear_view_override = active


func _process(delta: float) -> void:
	if not is_instance_valid(_target) or not _target.is_inside_tree():
		set_process(false)
		return

	var target_transform: Transform3D = _target.global_transform
	var target_position: Vector3 = target_transform.origin
	var behind: Vector3 = target_transform.basis.z.normalized()
	var rear_view_active: bool = _rear_view_override or Input.is_action_pressed("camera-back")
	var desired_position: Vector3
	var look_target: Vector3
	if rear_view_active:
		desired_position = target_position - behind * rear_view_distance + Vector3.UP * follow_height
		look_target = target_position + behind * look_ahead_distance + Vector3.UP * 1.2
	else:
		desired_position = target_position + behind * follow_distance + Vector3.UP * follow_height
		look_target = target_position - behind * look_ahead_distance + Vector3.UP * 1.2

	var blend: float = 1.0 - exp(-maxf(position_smoothing, 0.01) * maxf(delta, 0.0))
	global_position = global_position.lerp(desired_position, blend)
	look_at(look_target, Vector3.UP)
