extends Node3D
class_name ShortDesertVisualLoader

signal visual_parts_loaded(loaded_count: int, missing_paths: PackedStringArray)

var _loaded_parts: Array[Node3D] = []


static func _get_model_paths() -> PackedStringArray:
	return PackedStringArray([
		"res://assets/tracks/short_desert_track/models/track_surface.glb",
		"res://assets/tracks/short_desert_track/models/fences.glb",
		"res://assets/tracks/short_desert_track/models/barriers.glb",
		"res://assets/tracks/short_desert_track/models/buildings.glb",
		"res://assets/tracks/short_desert_track/models/vehicles.glb",
		"res://assets/tracks/short_desert_track/models/vegetation.glb",
	])


# The source model uses a small presentation scale. This transform applies the
# measured 5x correction, rotates source +X into project -Z and places the
# selected start-line point at the project origin. The slight vertical offset
# lets the imported road render above the procedural collision surface.
static func _get_source_to_project_transform() -> Transform3D:
	return Transform3D(
		Vector3(0.0, 0.0, -5.0),
		Vector3(0.0, 5.0, 0.0),
		Vector3(5.0, 0.0, 0.0),
		Vector3(0.39379445, 0.03, 15.45714075)
	)


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
	var missing_paths: PackedStringArray = PackedStringArray()
	for model_path: String in _get_model_paths():
		if not ResourceLoader.exists(model_path, "PackedScene"):
			missing_paths.append(model_path)
			continue
		var packed_scene: PackedScene = ResourceLoader.load(model_path, "PackedScene") as PackedScene
		if packed_scene == null or not packed_scene.can_instantiate():
			missing_paths.append(model_path)
			continue
		var instance: Node3D = packed_scene.instantiate() as Node3D
		if instance == null:
			missing_paths.append(model_path)
			continue
		instance.name = model_path.get_file().get_basename().to_pascal_case()
		add_child(instance)
		_loaded_parts.append(instance)
	visual_parts_loaded.emit(get_loaded_part_count(), missing_paths)
