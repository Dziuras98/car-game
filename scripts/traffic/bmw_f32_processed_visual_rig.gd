extends Node3D

const BODY_LABEL := "Body"
const FRONT_LEFT_LABEL := "FrontLeftWheel"
const FRONT_RIGHT_LABEL := "FrontRightWheel"
const REAR_LEFT_LABEL := "RearLeftWheel"
const REAR_RIGHT_LABEL := "RearRightWheel"

@export var processed_model_path: NodePath = ^"ProcessedModel"
@export var body_target_path: NodePath = ^"Body"
@export var front_left_target_path: NodePath = ^"WheelFrontLeft"
@export var front_right_target_path: NodePath = ^"WheelFrontRight"
@export var rear_left_target_path: NodePath = ^"WheelRearLeft"
@export var rear_right_target_path: NodePath = ^"WheelRearRight"

var _configured: bool = false


func _ready() -> void:
	_configure_processed_visual()


func is_configured() -> bool:
	return _configured


func _configure_processed_visual() -> void:
	var processed_model := get_node_or_null(processed_model_path) as Node3D
	if processed_model == null:
		push_error("BMW F32 processed rig requires ProcessedModel.")
		return
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(processed_model, meshes)
	if meshes.size() != 5:
		push_error("BMW F32 processed rig expected exactly five mesh instances.")
		return

	var body := _find_exact_mesh(meshes, BODY_LABEL)
	var front_left := _find_exact_mesh(meshes, FRONT_LEFT_LABEL)
	var front_right := _find_exact_mesh(meshes, FRONT_RIGHT_LABEL)
	var rear_left := _find_exact_mesh(meshes, REAR_LEFT_LABEL)
	var rear_right := _find_exact_mesh(meshes, REAR_RIGHT_LABEL)
	if body == null or front_left == null or front_right == null or rear_left == null or rear_right == null:
		push_error("BMW F32 processed rig could not resolve the five exact generated mesh labels.")
		return

	if not _attach_body(body):
		return
	if not _attach_wheel(front_left, front_left_target_path):
		return
	if not _attach_wheel(front_right, front_right_target_path):
		return
	if not _attach_wheel(rear_left, rear_left_target_path):
		return
	if not _attach_wheel(rear_right, rear_right_target_path):
		return
	_configured = true


func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		_collect_meshes(child, output)


func _find_exact_mesh(meshes: Array[MeshInstance3D], label: String) -> MeshInstance3D:
	var matches: Array[MeshInstance3D] = []
	for mesh_instance: MeshInstance3D in meshes:
		var resource_name := "" if mesh_instance.mesh == null else String(mesh_instance.mesh.resource_name)
		if (
			String(mesh_instance.name) == label
			or resource_name == label
			or resource_name == "%sMesh" % label
		):
			matches.append(mesh_instance)
	if matches.size() != 1:
		return null
	return matches[0]


func _attach_body(body_mesh: MeshInstance3D) -> bool:
	var target := get_node_or_null(body_target_path) as Node3D
	if target == null:
		push_error("BMW F32 processed rig is missing the Body target.")
		return false
	var root_relative := global_transform.affine_inverse() * body_mesh.global_transform
	body_mesh.reparent(target, true)
	target.transform = Transform3D.IDENTITY
	body_mesh.transform = root_relative
	return true


func _attach_wheel(wheel_mesh: MeshInstance3D, target_path: NodePath) -> bool:
	var target := get_node_or_null(target_path) as Node3D
	if target == null:
		push_error("BMW F32 processed rig is missing wheel target: %s" % target_path)
		return false
	var root_relative := global_transform.affine_inverse() * wheel_mesh.global_transform
	wheel_mesh.reparent(target, true)
	target.transform = root_relative
	wheel_mesh.transform = Transform3D.IDENTITY
	return true
