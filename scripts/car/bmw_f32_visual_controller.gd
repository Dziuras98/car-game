extends CarVisualController
class_name BmwF32VisualController

const PROCESSED_MODEL_ROOT := "Detailed/ProcessedModel"
const FRONT_LEFT_PATH := PROCESSED_MODEL_ROOT + "/FrontLeftWheel"
const FRONT_RIGHT_PATH := PROCESSED_MODEL_ROOT + "/FrontRightWheel"
const REAR_LEFT_PATH := PROCESSED_MODEL_ROOT + "/RearLeftWheel"
const REAR_RIGHT_PATH := PROCESSED_MODEL_ROOT + "/RearRightWheel"

const FRONT_LEFT_HUB := Vector3(-0.7694282, 0.3279420, -1.4050000)
const FRONT_RIGHT_HUB := Vector3(0.7694282, 0.3279421, -1.4050000)
const REAR_LEFT_HUB := Vector3(-0.7694282, 0.3282699, 1.4050000)
const REAR_RIGHT_HUB := Vector3(0.7694282, 0.3282700, 1.4050000)


func _get_explicit_detailed_wheel_specs() -> Array[Dictionary]:
	return [
		_create_wheel_spec(&"front_left", FRONT_LEFT_HUB, true, FRONT_LEFT_PATH),
		_create_wheel_spec(&"front_right", FRONT_RIGHT_HUB, true, FRONT_RIGHT_PATH),
		_create_wheel_spec(&"rear_left", REAR_LEFT_HUB, false, REAR_LEFT_PATH),
		_create_wheel_spec(&"rear_right", REAR_RIGHT_HUB, false, REAR_RIGHT_PATH),
	]


func _create_wheel_spec(
	wheel_id: StringName,
	pivot_position: Vector3,
	steers: bool,
	wheel_path: String
) -> Dictionary:
	return {
		"wheel_id": wheel_id,
		"pivot_parent_path": NodePath(PROCESSED_MODEL_ROOT),
		"pivot_position": pivot_position,
		"steers": steers,
		"steering_direction": 1.0,
		"spin_direction": 1.0,
		"spin_node_paths": [NodePath(wheel_path)],
		"steering_only_node_paths": [],
	}
