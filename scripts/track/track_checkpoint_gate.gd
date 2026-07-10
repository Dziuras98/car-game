extends Area3D
class_name TrackCheckpointGate

signal crossed(car: PlayerCarController, checkpoint_index: int, is_forward: bool)

const MIN_FORWARD_CROSSING_SPEED: float = 0.05

var checkpoint_index: int = 0


func configure(index: int, local_transform: Transform3D, gate_size: Vector3) -> void:
	checkpoint_index = maxi(index, 0)
	transform = local_transform
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(
		maxf(gate_size.x, 0.1),
		maxf(gate_size.y, 0.1),
		maxf(gate_size.z, 0.1)
	)
	collision_shape.shape = box_shape
	add_child(collision_shape)
	body_entered.connect(_on_body_entered)


func is_body_moving_forward(body: Node3D) -> bool:
	var character_body: CharacterBody3D = body as CharacterBody3D
	if character_body == null:
		return false

	var forward_direction: Vector3 = (-global_transform.basis.z).normalized()
	return character_body.velocity.dot(forward_direction) > MIN_FORWARD_CROSSING_SPEED


func _on_body_entered(body: Node3D) -> void:
	var car: PlayerCarController = body as PlayerCarController
	if car == null:
		return

	crossed.emit(car, checkpoint_index, is_body_moving_forward(car))
