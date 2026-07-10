extends RefCounted
class_name TrackMaterialFactory

var _materials: Dictionary = {}
var _audience_materials: Array[StandardMaterial3D] = []


func create_asphalt_material() -> Material:
	return _get_or_create_material(&"asphalt", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.055, 0.06, 0.065, 1.0)
		material.roughness = 0.92
		return material
	)


func create_grass_material() -> Material:
	return _get_or_create_material(&"grass", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.11, 0.36, 0.16, 1.0)
		material.roughness = 0.9
		return material
	)


func create_shoulder_material() -> Material:
	return _get_or_create_material(&"shoulder", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.12, 0.33, 0.13, 1.0)
		material.roughness = 0.95
		return material
	)


func create_barrier_material() -> Material:
	return _get_or_create_material(&"barrier", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.64, 0.68, 0.7, 1.0)
		material.metallic = 0.2
		material.roughness = 0.55
		return material
	)


func create_marker_material() -> Material:
	return _get_or_create_material(&"marker", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.9, 0.82, 1.0)
		material.roughness = 0.7
		return material
	)


func create_finish_line_material() -> Material:
	return _get_or_create_material(&"finish_line", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.96, 0.96, 0.92, 1.0)
		material.roughness = 0.62
		return material
	)


func create_finish_marker_material() -> Material:
	return _get_or_create_material(&"finish_marker", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.08, 0.06, 1.0)
		material.emission_enabled = true
		material.emission = Color(0.7, 0.02, 0.01, 1.0)
		material.emission_energy_multiplier = 0.35
		return material
	)


func create_stadium_concrete_material() -> Material:
	return _get_or_create_material(&"stadium_concrete", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.42, 0.43, 0.42, 1.0)
		material.roughness = 0.78
		return material
	)


func create_stadium_seat_material() -> Material:
	return _get_or_create_material(&"stadium_seat", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.76, 0.08, 0.06, 1.0)
		material.roughness = 0.55
		return material
	)


func create_stadium_roof_material() -> Material:
	return _get_or_create_material(&"stadium_roof", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.12, 0.12, 0.13, 1.0)
		material.roughness = 0.5
		return material
	)


func create_stadium_back_wall_material() -> Material:
	return _get_or_create_material(&"stadium_back_wall", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.24, 0.25, 0.26, 1.0)
		material.roughness = 0.82
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		return material
	)


func create_stadium_wall_cap_material() -> Material:
	return _get_or_create_material(&"stadium_wall_cap", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.16, 0.17, 0.18, 1.0)
		material.roughness = 0.7
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		return material
	)


func create_wall_arrow_material() -> Material:
	return _get_or_create_material(&"wall_arrow", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.88, 0.12, 1.0)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.68, 0.08, 1.0)
		material.emission_energy_multiplier = 0.35
		material.roughness = 0.48
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		return material
	)


func create_audience_materials() -> Array[StandardMaterial3D]:
	if _audience_materials.is_empty():
		for color: Color in [
			Color(0.1, 0.18, 0.9, 1.0),
			Color(0.95, 0.82, 0.08, 1.0),
			Color(0.92, 0.16, 0.12, 1.0),
			Color(0.92, 0.92, 0.9, 1.0),
			Color(0.08, 0.55, 0.18, 1.0),
		]:
			var material: StandardMaterial3D = StandardMaterial3D.new()
			material.albedo_color = color
			material.roughness = 0.65
			_audience_materials.append(material)
	return _audience_materials.duplicate()


func create_light_pole_material() -> Material:
	return _get_or_create_material(&"light_pole", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.18, 0.19, 0.2, 1.0)
		material.metallic = 0.35
		material.roughness = 0.45
		return material
	)


func create_floodlight_material() -> Material:
	return _get_or_create_material(&"floodlight", func() -> StandardMaterial3D:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.92, 0.66, 1.0)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.86, 0.45, 1.0)
		material.emission_energy_multiplier = 0.9
		return material
	)


func get_cached_material_count() -> int:
	return _materials.size() + _audience_materials.size()


func _get_or_create_material(key: StringName, factory: Callable) -> StandardMaterial3D:
	var cached: StandardMaterial3D = _materials.get(key) as StandardMaterial3D
	if cached != null:
		return cached
	var created: StandardMaterial3D = factory.call() as StandardMaterial3D
	_materials[key] = created
	return created
