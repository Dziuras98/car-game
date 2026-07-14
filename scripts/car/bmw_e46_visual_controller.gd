extends CarVisualController
class_name BmwE46VisualController

func _get_explicit_detailed_wheel_specs() -> Array[Dictionary]:
	return [
		{
			"wheel_id": &"front_left",
			"pivot_parent_path": NodePath("."),
			"pivot_position": Vector3(-0.75, 0.32, -1.36),
			"steers": true,
			"steering_direction": -1.0,
			"spin_direction": 1.0,
			"spin_node_paths": [NodePath("DetailedWheelProxyFrontLeft")],
		},
		{
			"wheel_id": &"front_right",
			"pivot_parent_path": NodePath("."),
			"pivot_position": Vector3(0.75, 0.32, -1.36),
			"steers": true,
			"steering_direction": -1.0,
			"spin_direction": 1.0,
			"spin_node_paths": [NodePath("DetailedWheelProxyFrontRight")],
		},
		{
			"wheel_id": &"rear_left",
			"pivot_parent_path": NodePath("."),
			"pivot_position": Vector3(-0.75, 0.32, 1.36),
			"steers": false,
			"spin_direction": 1.0,
			"spin_node_paths": [NodePath("DetailedWheelProxyRearLeft")],
		},
		{
			"wheel_id": &"rear_right",
			"pivot_parent_path": NodePath("."),
			"pivot_position": Vector3(0.75, 0.32, 1.36),
			"steers": false,
			"spin_direction": 1.0,
			"spin_node_paths": [NodePath("DetailedWheelProxyRearRight")],
		},
	]
