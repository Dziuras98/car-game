extends Area3D
class_name TrackCheckpointGate

signal crossed(car: PlayerCarController, checkpoint_index: int, is_forward: bool)

const MIN_FORWARD_CROSSING_SPEED: float = 0.05
const PLANE_EPSILON: float = 0.05

class GateBodyState:
	var car: PlayerCarController
	var stable_position: Vector3
	var stable_side: int

	func _init(target_car: PlayerCarController, position: Vector3, side: int) -> void:
		car = target_car
		stable_position = position
		stable_side = side

var checkpoint_index: int = 0
var _body_states: Dictionary = {}


func configure(index: int, local_transform: Transform3D, gate_size: Vector3) -> void:
	checkpoint_index = maxi(index, 0)
	transform = local_transform
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	set_physics_process(false)

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = Vector3(
		maxf(gate_size.x, 0.1),
		maxf(gate_size.y, 0.1),
		maxf(gate_size.z, 0.1)
	)
	collision_shape.shape = box_shape
	add_child(collision_shape)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func is_body_moving_forward(body: Node3D) -> bool:
	var character_body: CharacterBody3D = body as CharacterBody3D
	if character_body == null:
		return false
	return character_body.velocity.dot(_get_forward_direction()) > MIN_FORWARD_CROSSING_SPEED


func evaluate_segment_crossing_for_test(
	previous_position: Vector3,
	current_position: Vector3,
	velocity: Vector3
) -> int:
	return _evaluate_segment_crossing(previous_position, current_position, velocity)


func _physics_process(_delta: float) -> void:
	for body_id: int in _body_states.keys():
		var state: GateBodyState = _body_states.get(body_id) as GateBodyState
		if state == null or not is_instance_valid(state.car):
			_body_states.erase(body_id)
			continue

		var current_position: Vector3 = state.car.global_position
		var current_side: int = _get_stable_side(current_position)
		if current_side == 0:
			continue
		if state.stable_side == 0:
			state.stable_side = current_side
			state.stable_position = current_position
			continue
		if current_side == state.stable_side:
			state.stable_position = current_position
			continue

		var crossing_direction: int = _evaluate_segment_crossing(
			state.stable_position,
			current_position,
			state.car.velocity
		)
		state.stable_side = current_side
		state.stable_position = current_position
		if crossing_direction != 0:
			crossed.emit(state.car, checkpoint_index, crossing_direction > 0)

	if _body_states.is_empty():
		set_physics_process(false)


func _on_body_entered(body: Node3D) -> void:
	var car: PlayerCarController = body as PlayerCarController
	if car == null:
		return

	var body_id: int = car.get_instance_id()
	if _body_states.has(body_id):
		return
	var position: Vector3 = car.global_position
	var side: int = _get_stable_side(position)
	if side == 0:
		var previous_position: Vector3 = position - car.velocity * maxf(get_physics_process_delta_time(), 0.001)
		side = _get_stable_side(previous_position)
		position = previous_position if side != 0 else position
	_body_states[body_id] = GateBodyState.new(car, position, side)
	set_physics_process(true)


func _on_body_exited(body: Node3D) -> void:
	if body == null:
		return
	_body_states.erase(body.get_instance_id())
	if _body_states.is_empty():
		set_physics_process(false)


func _evaluate_segment_crossing(
	previous_position: Vector3,
	current_position: Vector3,
	velocity: Vector3
) -> int:
	var evaluation_transform: Transform3D = _get_evaluation_transform()
	var inverse_transform: Transform3D = evaluation_transform.affine_inverse()
	var previous_distance: float = (inverse_transform * previous_position).z
	var current_distance: float = (inverse_transform * current_position).z
	var velocity_alignment: float = velocity.dot(_get_forward_direction(evaluation_transform))

	if (
		previous_distance > PLANE_EPSILON
		and current_distance < -PLANE_EPSILON
		and velocity_alignment > MIN_FORWARD_CROSSING_SPEED
	):
		return 1
	if (
		previous_distance < -PLANE_EPSILON
		and current_distance > PLANE_EPSILON
		and velocity_alignment < -MIN_FORWARD_CROSSING_SPEED
	):
		return -1
	return 0


func _get_stable_side(world_position: Vector3) -> int:
	var inverse_transform: Transform3D = _get_evaluation_transform().affine_inverse()
	var plane_distance: float = (inverse_transform * world_position).z
	if plane_distance > PLANE_EPSILON:
		return 1
	if plane_distance < -PLANE_EPSILON:
		return -1
	return 0


func _get_evaluation_transform() -> Transform3D:
	return global_transform if is_inside_tree() else transform


func _get_forward_direction(evaluation_transform: Transform3D = Transform3D.IDENTITY) -> Vector3:
	var active_transform: Transform3D = evaluation_transform
	if active_transform == Transform3D.IDENTITY and is_inside_tree():
		active_transform = global_transform
	elif active_transform == Transform3D.IDENTITY:
		active_transform = transform
	return (-active_transform.basis.z).normalized()
