extends CarVisualController
class_name MustangShelbyGT5001967VisualController


const IMPORTED_ROOT_PATH: String = "ModelAlignment/DetailedModel/Sketchfab_model/FINAL_MODEL_GT50067_fbx/RootNode"

const FRONT_LEFT_TYRE: String = IMPORTED_ROOT_PATH + "/cobra_gt500_LOD_A_TYRE_mm_tyre"
const FRONT_LEFT_WHEEL: String = IMPORTED_ROOT_PATH + "/cobra_gt500_LOD_A_WHEEL_mm"
const FRONT_LEFT_ROTOR: String = IMPORTED_ROOT_PATH + "/cobra_gt500_LOD_A_ROTOR_mm_rotor"
const FRONT_LEFT_CALIPER: String = IMPORTED_ROOT_PATH + "/cobra_gt500_LOD_A_BRAKE_CALIPER_FRONT_LEFT_mm_misc"

const FRONT_RIGHT_TYRE: String = IMPORTED_ROOT_PATH + "/LOD_A_TYRE_mm_tyre"
const FRONT_RIGHT_WHEEL: String = IMPORTED_ROOT_PATH + "/LOD_A_WHEEL_mm"
const FRONT_RIGHT_ROTOR: String = IMPORTED_ROOT_PATH + "/LOD_A_ROTOR_mm_rotor"
const FRONT_RIGHT_CALIPER: String = IMPORTED_ROOT_PATH + "/cobra_gt500_LOD_A_BRAKE_CALIPER_FRONT_RIGHT_mm_misc"

const REAR_LEFT_TYRE: String = IMPORTED_ROOT_PATH + "/LOD_A_TYRE_mm_tyre1"
const REAR_LEFT_WHEEL: String = IMPORTED_ROOT_PATH + "/LOD_A_WHEEL_mm1"
const REAR_LEFT_ROTOR: String = IMPORTED_ROOT_PATH + "/LOD_A_ROTOR_mm_rotor1"

const REAR_RIGHT_TYRE: String = IMPORTED_ROOT_PATH + "/LOD_A_TYRE_mm_tyre2"
const REAR_RIGHT_WHEEL: String = IMPORTED_ROOT_PATH + "/LOD_A_WHEEL_mm2"
const REAR_RIGHT_ROTOR: String = IMPORTED_ROOT_PATH + "/LOD_A_ROTOR_mm_rotor2"


func _get_explicit_detailed_wheel_specs() -> Array[Dictionary]:
	return [
		_create_wheel_spec(
			&"front_left",
			Vector3(0.7516, 0.32865, 1.3863),
			true,
			[FRONT_LEFT_TYRE, FRONT_LEFT_WHEEL, FRONT_LEFT_ROTOR],
			[FRONT_LEFT_CALIPER]
		),
		_create_wheel_spec(
			&"front_right",
			Vector3(-0.7517, 0.32865, 1.3863),
			true,
			[FRONT_RIGHT_TYRE, FRONT_RIGHT_WHEEL, FRONT_RIGHT_ROTOR],
			[FRONT_RIGHT_CALIPER]
		),
		_create_wheel_spec(
			&"rear_left",
			Vector3(0.7516, 0.32865, -1.3574),
			false,
			[REAR_LEFT_TYRE, REAR_LEFT_WHEEL, REAR_LEFT_ROTOR],
			[]
		),
		_create_wheel_spec(
			&"rear_right",
			Vector3(-0.7517, 0.32865, -1.3574),
			false,
			[REAR_RIGHT_TYRE, REAR_RIGHT_WHEEL, REAR_RIGHT_ROTOR],
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
