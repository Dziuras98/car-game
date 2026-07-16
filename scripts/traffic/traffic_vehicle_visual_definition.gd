extends Resource
class_name TrafficVehicleVisualDefinition

const SUPPORTED_SOURCE_FRONT_AXES: PackedStringArray = PackedStringArray([
	"+Z",
	"-Z",
	"+X",
	"-X",
])

@export_group("Identity")
@export var vehicle_id: StringName = &""
@export var display_name: String = ""

@export_group("Source")
@export_file("*.glb") var source_path: String = ""
@export var source_sha256: String = ""
@export var source_scene: PackedScene
@export var source_front_axis: String = "+Z"

@export_group("Reference geometry")
@export var length_m: float = 0.0
@export var width_m: float = 0.0
@export var height_m: float = 0.0
@export var wheelbase_m: float = 0.0
@export var front_track_m: float = 0.0
@export var rear_track_m: float = 0.0
@export var ground_clearance_m: float = 0.0
@export var source_wheelbase_units: float = 0.0
@export var visual_scale: float = 0.0

@export_group("Processed derivative")
@export_file("*.glb") var processed_path: String = ""
@export var processed_sha256: String = ""
@export var processed_visual_ready: bool = false

@export_group("Godot integration")
@export var visual_scene: PackedScene
@export var body_path: NodePath
@export var front_left_wheel_path: NodePath
@export var front_right_wheel_path: NodePath
@export var rear_left_wheel_path: NodePath
@export var rear_right_wheel_path: NodePath


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if vehicle_id == &"":
		errors.append("vehicle_id must not be empty")
	if display_name.strip_edges().is_empty():
		errors.append("display_name must not be empty")
	_validate_source(errors)
	_validate_reference_geometry(errors)
	if visual_scene == null:
		errors.append("visual_scene must not be null")
	elif processed_visual_ready:
		_validate_processed_asset(errors)
		_validate_processed_visual_paths(errors)
	return errors


func is_valid() -> bool:
	return validate().is_empty()


func _validate_source(errors: PackedStringArray) -> void:
	_validate_file_hash(source_path, source_sha256, "source", errors)
	if source_scene == null:
		errors.append("source_scene must not be null")
	if not SUPPORTED_SOURCE_FRONT_AXES.has(source_front_axis):
		errors.append("source_front_axis must be one of: %s" % ", ".join(SUPPORTED_SOURCE_FRONT_AXES))


func _validate_processed_asset(errors: PackedStringArray) -> void:
	_validate_file_hash(processed_path, processed_sha256, "processed", errors)
	if not processed_path.strip_edges().is_empty() and not ResourceLoader.exists(processed_path, "PackedScene"):
		errors.append("processed_path must import as PackedScene: %s" % processed_path)


func _validate_file_hash(
	path: String,
	expected_sha256: String,
	label: String,
	errors: PackedStringArray
) -> void:
	if path.strip_edges().is_empty():
		errors.append("%s_path must not be empty" % label)
	elif not FileAccess.file_exists(path):
		errors.append("%s_path must reference a committed file: %s" % [label, path])
	else:
		var actual_sha256: String = FileAccess.get_sha256(path)
		if actual_sha256.is_empty():
			errors.append("%s_path SHA-256 could not be calculated: %s" % [label, path])
		elif expected_sha256.to_lower() != actual_sha256.to_lower():
			errors.append("%s_sha256 does not match the committed %s bytes" % [label, label])
	if expected_sha256.length() != 64:
		errors.append("%s_sha256 must contain 64 hexadecimal characters" % label)
	elif not expected_sha256.is_valid_hex_number(false):
		errors.append("%s_sha256 must be hexadecimal" % label)


func _validate_reference_geometry(errors: PackedStringArray) -> void:
	var positive_values: Array[float] = [
		length_m,
		width_m,
		height_m,
		wheelbase_m,
		front_track_m,
		rear_track_m,
		source_wheelbase_units,
		visual_scale,
	]
	for value: float in positive_values:
		if value <= 0.0:
			errors.append("reference geometry values must be positive")
			break
	if ground_clearance_m < 0.0:
		errors.append("ground_clearance_m must not be negative")
	if source_wheelbase_units > 0.0 and wheelbase_m > 0.0:
		var expected_scale := wheelbase_m / source_wheelbase_units
		if not is_equal_approx(visual_scale, expected_scale):
			errors.append("visual_scale must equal wheelbase_m / source_wheelbase_units")


func _validate_processed_visual_paths(errors: PackedStringArray) -> void:
	var required_paths: Array[NodePath] = [
		body_path,
		front_left_wheel_path,
		front_right_wheel_path,
		rear_left_wheel_path,
		rear_right_wheel_path,
	]
	for path: NodePath in required_paths:
		if path.is_empty():
			errors.append("processed visuals require explicit body and four wheel paths")
			return
	if not visual_scene.can_instantiate():
		errors.append("processed visual_scene must be instantiable")
		return
	var visual_root: Node = visual_scene.instantiate()
	if visual_root == null:
		errors.append("processed visual_scene could not be instantiated")
		return
	var resolved_nodes: Array[Node] = []
	for path: NodePath in required_paths:
		var resolved_node: Node = visual_root.get_node_or_null(path)
		if not resolved_node is Node3D:
			errors.append("processed visual path must resolve to Node3D: %s" % path)
			continue
		if resolved_nodes.has(resolved_node):
			errors.append("processed visual body and wheel paths must resolve to distinct nodes")
			continue
		resolved_nodes.append(resolved_node)
	visual_root.free()
