extends Node3D
class_name HighSpeedRingVisualLoader

signal visual_parts_loaded(loaded_count: int, missing_paths: PackedStringArray)

const PART_COUNT: int = 17
const PART_DIRECTORY: String = "res://assets/tracks/high_speed_ring"
const VISUAL_VERTICAL_OFFSET: float = 0.03

var _loaded_parts: Array[Node3D] = []


static func _get_model_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for index: int in range(1, PART_COUNT + 1):
		paths.append("%s/part_%03d.glb" % [PART_DIRECTORY, index])
	return paths


static func _get_source_to_project_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0.0, VISUAL_VERTICAL_OFFSET, 0.0))


func _ready() -> void:
	transform = _get_source_to_project_transform()
	_load_available_parts()


func get_loaded_part_count() -> int:
	var count: int = 0
	for part: Node3D in _loaded_parts:
		if is_instance_valid(part):
			count += 1
	return count


func _load_available_parts() -> void:
	var missing_paths := PackedStringArray()
	for model_path: String in _get_model_paths():
		if not ResourceLoader.exists(model_path, "PackedScene"):
			missing_paths.append(model_path)
			continue
		var packed_scene := ResourceLoader.load(model_path, "PackedScene") as PackedScene
		if packed_scene == null or not packed_scene.can_instantiate():
			missing_paths.append(model_path)
			continue
		var instance := packed_scene.instantiate() as Node3D
		if instance == null:
			missing_paths.append(model_path)
			continue
		instance.name = model_path.get_file().get_basename().to_pascal_case()
		add_child(instance)
		_loaded_parts.append(instance)
	visual_parts_loaded.emit(get_loaded_part_count(), missing_paths)
