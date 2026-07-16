extends Resource
class_name TrafficVehicleVisualDefinition

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

@export_group("Godot integration")
@export var visual_scene: PackedScene
@export var processed_visual_ready: bool = false
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
	if source_path.strip_edges().is_empty():
		errors.append("source_path must not be empty")
	elif not FileAccess.file_exists(source_path):
		errors.append("source_path must reference a committed file: %s" % source_path)
	if source_sha256.length() != 64:
		errors.append("source_sha256 must contain 64 hexadecimal characters")
	elif not source_sha256.is_valid_hex_number(false):
		errors.append("source_sha256 must be hexadecimal")
	if source_scene == null:
		errors.append("source_scene must not be null")
	if visual_scene == null:
		errors.append("visual_scene must not be null")
	for value: float in [length_m, width_m, height_m, wheelbase_m, front_track_m, rear_track_m, source_wheelbase_units, visual_scale]:
		if value <= 0.0:
			errors.append("reference geometry values must be positive")
			break
	if source_wheelbase_units > 0.0 and wheelbase_m > 0.0:
		var expected_scale := wheelbase_m / source_wheelbase_units
		if not is_equal_approx(visual_scale, expected_scale):
			errors.append("visual_scale must equal wheelbase_m / source_wheelbase_units")
	if processed_visual_ready:
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
				break
	return errors


func is_valid() -> bool:
	return validate().is_empty()
