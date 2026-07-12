extends CarVisualController
class_name Standard370ZVisualController


const IMPORTED_ROOT_PATH: String = "SketchfabModel/Sketchfab_model/FINAL_MODEL_fbx/RootNode"

const FRONT_LEFT_BRAKE: String = IMPORTED_ROOT_PATH + "/model_SM_Brake_FL_0000_001_SM_Brake_FL_0000_MAT_Tire_Brake"
const FRONT_RIGHT_BRAKE: String = IMPORTED_ROOT_PATH + "/model_SM_Brake_FR_0000_001_SM_Brake_FR_0000_MAT_Tire_Brake_001"
const FRONT_LEFT_DISK: String = IMPORTED_ROOT_PATH + "/model_SM_Disk_L_0000_001_SM_Disk_L_0000_MAT_Tire_Disk"
const FRONT_RIGHT_DISK: String = IMPORTED_ROOT_PATH + "/model_SM_Disk_R_0000_001_SM_Disk_R_0000_MAT_Tire_Disk_001"
const FRONT_LEFT_HUB: String = IMPORTED_ROOT_PATH + "/model_SM_Hub_L_0000_001_SM_Hub_L_0000_MAT_Tire_Hub"
const FRONT_RIGHT_HUB: String = IMPORTED_ROOT_PATH + "/model_SM_Hub_R_0000_001_SM_Hub_R_0000_MAT_Tire_Hub_001"

const REAR_LEFT_BRAKE: String = IMPORTED_ROOT_PATH + "/model_SM_Brake_RL_0000_001_SM_Brake_RL_0000_MAT_Tire_Brake_002"
const REAR_RIGHT_BRAKE: String = IMPORTED_ROOT_PATH + "/model_SM_Brake_RR_0000_001_SM_Brake_RR_0000_MAT_Tire_Brake_003"
const REAR_LEFT_DISK: String = IMPORTED_ROOT_PATH + "/SM_Disk_L_0000_001_SM_Disk_L_0000_MAT_Tire_Disk"
const REAR_RIGHT_DISK: String = IMPORTED_ROOT_PATH + "/SM_Disk_R_0000_001_SM_Disk_R_0000_MAT_Tire_Disk_001"
const REAR_LEFT_HUB: String = IMPORTED_ROOT_PATH + "/SM_Hub_L_0000_001_SM_Hub_L_0000_MAT_Tire_Hub"
const REAR_RIGHT_HUB: String = IMPORTED_ROOT_PATH + "/SM_Hub_R_0000_001_SM_Hub_R_0000_MAT_Tire_Hub_001"

const FRONT_TYRE_GROUP: String = IMPORTED_ROOT_PATH + "/W_LOD_A_TYRE_mm_tyre"
const FRONT_LEFT_TYRE: String = FRONT_TYRE_GROUP + "/polySurface1"
const FRONT_RIGHT_TYRE: String = FRONT_TYRE_GROUP + "/polySurface2"
const REAR_RIGHT_TYRE: String = FRONT_TYRE_GROUP + "/polySurface3"
const REAR_LEFT_TYRE: String = IMPORTED_ROOT_PATH + "/LOD_A_TYRE_mm_tyre"


func _get_explicit_detailed_wheel_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary] = [
		_create_wheel_spec(
			&"front_left",
			Vector3(0.70674, 0.208243, 1.26317),
			true,
			[FRONT_LEFT_TYRE, FRONT_LEFT_HUB, FRONT_LEFT_DISK],
			[FRONT_LEFT_BRAKE]
		),
		_create_wheel_spec(
			&"front_right",
			Vector3(-0.707, 0.208243, 1.26317),
			true,
			[FRONT_RIGHT_TYRE, FRONT_RIGHT_HUB, FRONT_RIGHT_DISK],
			[FRONT_RIGHT_BRAKE]
		),
		_create_wheel_spec(
			&"rear_left",
			Vector3(0.70674, 0.208243, -1.287901),
			false,
			[REAR_LEFT_TYRE, REAR_LEFT_HUB, REAR_LEFT_DISK],
			[]
		),
		_create_wheel_spec(
			&"rear_right",
			Vector3(-0.707, 0.208243, -1.287598),
			false,
			[REAR_RIGHT_TYRE, REAR_RIGHT_HUB, REAR_RIGHT_DISK],
			[]
		),
	]
	return specs


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
