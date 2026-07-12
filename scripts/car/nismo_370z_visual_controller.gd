extends CarVisualController
class_name Nismo370ZVisualController


const IMPORTED_ROOT_PATH: String = "SketchfabModel/Sketchfab_model/FINAL_MODEL_N_fbx/RootNode"

const FRONT_LEFT_BRAKE: String = IMPORTED_ROOT_PATH + "/z_nismo_LOD_A_BRAKE_CALIPER_FRONT_LEFT_mm_misc"
const FRONT_RIGHT_BRAKE: String = IMPORTED_ROOT_PATH + "/z_nismo_LOD_A_BRAKE_CALIPER_FRONT_RIGHT_mm_misc"
const REAR_LEFT_BRAKE: String = IMPORTED_ROOT_PATH + "/z_nismo_LOD_A_BRAKE_CALIPER_REAR_LEFT_mm_misc"
const REAR_RIGHT_BRAKE: String = IMPORTED_ROOT_PATH + "/z_nismo_LOD_A_BRAKE_CALIPER_REAR_RIGHT_mm_misc"

const FRONT_LEFT_TYRE: String = IMPORTED_ROOT_PATH + "/z_nismo_LOD_A_TYRE_mm_tyre"
const FRONT_LEFT_WHEEL: String = IMPORTED_ROOT_PATH + "/z_nismo_LOD_A_WHEEL_mm_wheel"
const FRONT_RIGHT_TYRE: String = IMPORTED_ROOT_PATH + "/LOD_A_TYRE_mm_tyre"
const FRONT_RIGHT_WHEEL: String = IMPORTED_ROOT_PATH + "/LOD_A_WHEEL_mm_wheel"
const REAR_LEFT_TYRE: String = IMPORTED_ROOT_PATH + "/LOD_A_TYRE_mm_tyre1"
const REAR_LEFT_WHEEL: String = IMPORTED_ROOT_PATH + "/LOD_A_WHEEL_mm_wheel1"
const REAR_RIGHT_TYRE: String = IMPORTED_ROOT_PATH + "/LOD_A_TYRE_mm_tyre2"
const REAR_RIGHT_WHEEL: String = IMPORTED_ROOT_PATH + "/LOD_A_WHEEL_mm_wheel2"


func _get_explicit_detailed_wheel_specs() -> Array[Dictionary]:
	return [
		_create_wheel_spec(
			&"front_left",
			Vector3(0.916548, 0.330554, 1.272044),
			true,
			[FRONT_LEFT_TYRE, FRONT_LEFT_WHEEL],
			[FRONT_LEFT_BRAKE]
		),
		_create_wheel_spec(
			&"front_right",
			Vector3(-0.917, 0.330554, 1.272044),
			true,
			[FRONT_RIGHT_TYRE, FRONT_RIGHT_WHEEL],
			[FRONT_RIGHT_BRAKE]
		),
		_create_wheel_spec(
			&"rear_left",
			Vector3(0.916548, 0.330554, -1.281999),
			false,
			[REAR_LEFT_TYRE, REAR_LEFT_WHEEL],
			[]
		),
		_create_wheel_spec(
			&"rear_right",
			Vector3(-0.917, 0.330554, -1.281999),
			false,
			[REAR_RIGHT_TYRE, REAR_RIGHT_WHEEL],
			[]
		),
	]


func _create_wheel_spec(
	wheel_id: StringName,
	pivot_position: Vector3,
	steers: bool,
	spin_path_strings: Array[String],
	steering_path_strings: Array[String]
) -> Dictionary:
	var spin_paths: Array[NodePath] = []
	for path_string: String in spin_path_strings:
		spin_paths.append(NodePath(path_string))
	var steering_paths: Array[NodePath] = []
	for path_string: String in steering_path_strings:
		steering_paths.append(NodePath(path_string))
	return {
		"wheel_id": wheel_id,
		"pivot_parent_path": NodePath(IMPORTED_ROOT_PATH),
		"pivot_position": pivot_position,
		"steers": steers,
		"steering_direction": -1.0,
		"spin_direction": 1.0,
		"spin_node_paths": spin_paths,
		"steering_only_node_paths": steering_paths,
	}
