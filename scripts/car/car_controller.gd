extends CharacterBody3D
class_name PlayerCarController

@export_group("Driving")
@export var acceleration: float = 22.0
@export var brake_deceleration: float = 34.0
@export var reverse_acceleration: float = 12.0
@export var coast_deceleration: float = 5.0
@export var handbrake_deceleration: float = 18.0
@export var max_forward_speed: float = 30.0
@export var max_reverse_speed: float = 10.0
@export var steering_speed: float = 2.7

@export_group("Grounding")
@export var gravity: float = 30.0
@export var floor_stick_force: float = 0.5

var _start_transform: Transform3D
var _forward_speed: float = 0.0


func _ready() -> void:
	_start_transform = global_transform


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset-car"):
		_reset_to_start()
		return

	var throttle := Input.get_action_strength("accelerate")
	var brake := Input.get_action_strength("brake")
	var steering := Input.get_action_strength("steer-right") - Input.get_action_strength("steer-left")
	var handbrake_active := Input.is_action_pressed("handbrake")

	_update_speed(throttle, brake, handbrake_active, delta)
	_update_steering(steering, delta)
	_apply_velocity(delta)


func _update_speed(throttle: float, brake: float, handbrake_active: bool, delta: float) -> void:
	if throttle > 0.0:
		_forward_speed += throttle * acceleration * delta

	if brake > 0.0:
		if _forward_speed > 0.25:
			_forward_speed = move_toward(_forward_speed, 0.0, brake_deceleration * brake * delta)
		else:
			_forward_speed -= reverse_acceleration * brake * delta

	if throttle == 0.0 and brake == 0.0:
		_forward_speed = move_toward(_forward_speed, 0.0, coast_deceleration * delta)

	if handbrake_active:
		_forward_speed = move_toward(_forward_speed, 0.0, handbrake_deceleration * delta)

	_forward_speed = clamp(_forward_speed, -max_reverse_speed, max_forward_speed)


func _update_steering(steering: float, delta: float) -> void:
	var speed_ratio := clamp(abs(_forward_speed) / max_forward_speed, 0.0, 1.0)
	if abs(steering) < 0.01 or speed_ratio < 0.02:
		return

	var direction := sign(_forward_speed)
	var low_speed_factor := lerp(0.45, 1.0, speed_ratio)
	rotate_y(-steering * steering_speed * low_speed_factor * direction * delta)


func _apply_velocity(delta: float) -> void:
	var forward := -global_transform.basis.z.normalized()
	velocity.x = forward.x * _forward_speed
	velocity.z = forward.z * _forward_speed

	if is_on_floor():
		velocity.y = -floor_stick_force
	else:
		velocity.y -= gravity * delta

	move_and_slide()


func _reset_to_start() -> void:
	global_transform = _start_transform
	velocity = Vector3.ZERO
	_forward_speed = 0.0
