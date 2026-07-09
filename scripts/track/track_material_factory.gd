extends RefCounted
class_name TrackMaterialFactory


func create_asphalt_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.055, 0.06, 0.065, 1.0)
	material.roughness = 0.92
	return material


func create_grass_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.11, 0.36, 0.16, 1.0)
	material.roughness = 0.9
	return material


func create_shoulder_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.33, 0.13, 1.0)
	material.roughness = 0.95
	return material


func create_barrier_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.64, 0.68, 0.7, 1.0)
	material.metallic = 0.2
	material.roughness = 0.55
	return material


func create_marker_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 0.82, 1.0)
	material.roughness = 0.7
	return material


func create_finish_line_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.96, 0.96, 0.92, 1.0)
	material.roughness = 0.62
	return material


func create_finish_marker_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.08, 0.06, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.7, 0.02, 0.01, 1.0)
	material.emission_energy_multiplier = 0.35
	return material


func create_stadium_concrete_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.42, 0.43, 0.42, 1.0)
	material.roughness = 0.78
	return material


func create_stadium_seat_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.76, 0.08, 0.06, 1.0)
	material.roughness = 0.55
	return material


func create_stadium_roof_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.12, 0.13, 1.0)
	material.roughness = 0.5
	return material


func create_stadium_back_wall_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.24, 0.25, 0.26, 1.0)
	material.roughness = 0.82
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func create_stadium_wall_cap_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.16, 0.17, 0.18, 1.0)
	material.roughness = 0.7
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func create_wall_arrow_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.88, 0.12, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.68, 0.08, 1.0)
	material.emission_energy_multiplier = 0.35
	material.roughness = 0.48
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func create_audience_materials() -> Array[StandardMaterial3D]:
	var materials: Array[StandardMaterial3D] = []
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
		materials.append(material)
	return materials


func create_light_pole_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.19, 0.2, 1.0)
	material.metallic = 0.35
	material.roughness = 0.45
	return material


func create_floodlight_material() -> Material:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.92, 0.66, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.86, 0.45, 1.0)
	material.emission_energy_multiplier = 0.9
	return material
