extends Camera3D

@export var target_path: NodePath
@export var follow_distance: float = 9.0
@export var follow_height: float = 5.0
@export var look_ahead_distance: float = 3.0
@export var position_smoothing: float = 8.0

@onready var _target := get_node_or_null(target_path) as Node3D


func _process(delta: float) -> void:
	if _target == null:
		return

	var target_transform := _target.global_transform
	var target_position := target_transform.origin
	var behind := target_transform.basis.z.normalized()
	var desired_position := target_position + behind * follow_distance + Vector3.UP * follow_height
	var blend := 1.0 - exp(-position_smoothing * delta)

	global_position = global_position.lerp(desired_position, blend)
	look_at(target_position - behind * look_ahead_distance + Vector3.UP * 1.2, Vector3.UP)
