extends GeneratedTrack
class_name DesertGeneratedTrack

const SAND_GRIP: float = 0.62
const COMPACTED_SAND_GRIP: float = 0.72
const SAND_COLOR: Color = Color(0.58, 0.39, 0.20, 1.0)
const COMPACTED_SAND_COLOR: Color = Color(0.43, 0.29, 0.16, 1.0)

var _sand_material: StandardMaterial3D
var _compacted_sand_material: StandardMaterial3D


func _ready() -> void:
	geometry_rebuilt.connect(_on_geometry_rebuilt)
	super._ready()
	_apply_desert_theme()


func _on_geometry_rebuilt(_revision: int) -> void:
	call_deferred("_apply_desert_theme")


func _apply_desert_theme() -> void:
	var sand_body: TrackSurfaceBody = find_child("Grass", true, false) as TrackSurfaceBody
	if sand_body != null:
		sand_body.grip_multiplier = SAND_GRIP
		sand_body.set_meta("surface_key", "SAND")
		_apply_material(sand_body, _get_sand_material())

	var compacted_sand_body: TrackSurfaceBody = find_child("RoadsideTerrain", true, false) as TrackSurfaceBody
	if compacted_sand_body != null:
		compacted_sand_body.grip_multiplier = COMPACTED_SAND_GRIP
		compacted_sand_body.set_meta("surface_key", "SAND")
		_apply_material(compacted_sand_body, _get_compacted_sand_material())


func _apply_material(body: TrackSurfaceBody, material: Material) -> void:
	var mesh_instance: MeshInstance3D = body.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_instance != null:
		mesh_instance.material_override = material


func _get_sand_material() -> StandardMaterial3D:
	if _sand_material == null:
		_sand_material = StandardMaterial3D.new()
		_sand_material.albedo_color = SAND_COLOR
		_sand_material.roughness = 1.0
	return _sand_material


func _get_compacted_sand_material() -> StandardMaterial3D:
	if _compacted_sand_material == null:
		_compacted_sand_material = StandardMaterial3D.new()
		_compacted_sand_material.albedo_color = COMPACTED_SAND_COLOR
		_compacted_sand_material.roughness = 0.96
	return _compacted_sand_material
