extends RefCounted
class_name OpponentPaintRandomizer

var _rng: RandomNumberGenerator


func configure(rng: RandomNumberGenerator) -> void:
	_rng = rng


func randomize_car_paint(root: Node) -> void:
	if root == null or _rng == null:
		return

	var paint_color: Color = Color.from_hsv(_rng.randf(), 0.72, 0.82, 1.0)
	_apply_paint_to_children(root, paint_color)


func _apply_paint_to_children(node: Node, paint_color: Color) -> void:
	var mesh_instance: MeshInstance3D = node as MeshInstance3D
	if mesh_instance != null and node.name.to_lower().contains("paint"):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = paint_color
		material.roughness = 0.42
		mesh_instance.material_override = material

	for child: Node in node.get_children():
		_apply_paint_to_children(child, paint_color)
