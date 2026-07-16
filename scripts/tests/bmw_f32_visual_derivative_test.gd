extends SceneTree

const VISUAL_SCENE := preload("res://scenes/traffic/vehicles/bmw_4_series_f32_visuals.tscn")
const WHEEL_PATHS: PackedStringArray = PackedStringArray([
	"WheelFrontLeft",
	"WheelFrontRight",
	"WheelRearLeft",
	"WheelRearRight",
])

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var visual := VISUAL_SCENE.instantiate() as Node3D
	_expect(visual != null, "BMW F32 processed visual scene instantiates")
	if visual == null:
		_finish()
		return
	root.add_child(visual)
	_expect(bool(visual.call("is_configured")), "BMW F32 static processed rig configures")

	var body := visual.get_node_or_null(^"Body") as Node3D
	_expect(body != null, "BMW F32 has explicit Body target")
	if body != null:
		var body_meshes: Array[MeshInstance3D] = []
		_collect_meshes(body, body_meshes)
		_expect(body_meshes.size() == 1, "Body target contains exactly one processed mesh")
		if body_meshes.size() == 1:
			_expect(_mesh_triangle_count(body_meshes[0].mesh) == 1132, "body preserves 1132 source triangles")

	var wheel_nodes: Dictionary = {}
	var total_wheel_triangles := 0
	for wheel_path: String in WHEEL_PATHS:
		var wheel := visual.get_node_or_null(NodePath(wheel_path)) as Node3D
		_expect(wheel != null, "%s pivot exists" % wheel_path)
		if wheel == null:
			continue
		wheel_nodes[wheel_path] = wheel
		var meshes: Array[MeshInstance3D] = []
		_collect_meshes(wheel, meshes)
		_expect(meshes.size() == 1, "%s contains exactly one processed wheel mesh" % wheel_path)
		if meshes.size() != 1:
			continue
		var geometry := meshes[0]
		var triangle_count := _mesh_triangle_count(geometry.mesh)
		_expect(triangle_count == 162, "%s preserves 162 source triangles" % wheel_path)
		total_wheel_triangles += triangle_count
		_expect(geometry.mesh.get_surface_count() == 1, "%s preserves one source surface" % wheel_path)
		_expect(geometry.mesh.surface_get_material(0) != null, "%s preserves its source material" % wheel_path)
		var radius := maxf(geometry.get_aabb().size.y, geometry.get_aabb().size.z) * 0.5
		_expect(radius > 0.32 and radius < 0.34, "%s has measured rolling radius near 0.328 m" % wheel_path)

	_expect(total_wheel_triangles == 648, "four wheel pivots preserve all 648 wheel triangles")
	_test_positions(wheel_nodes)
	var processed_model := visual.get_node_or_null(^"ProcessedModel")
	var remaining_meshes: Array[MeshInstance3D] = []
	if processed_model != null:
		_collect_meshes(processed_model, remaining_meshes)
	_expect(remaining_meshes.is_empty(), "processed import container has no unbound render meshes")
	visual.free()
	_finish()


func _test_positions(wheels: Dictionary) -> void:
	if wheels.size() != 4:
		return
	var front_left: Node3D = wheels["WheelFrontLeft"]
	var front_right: Node3D = wheels["WheelFrontRight"]
	var rear_left: Node3D = wheels["WheelRearLeft"]
	var rear_right: Node3D = wheels["WheelRearRight"]
	_expect(front_left.position.x < 0.0, "front-left pivot uses project negative X")
	_expect(rear_left.position.x < 0.0, "rear-left pivot uses project negative X")
	_expect(front_right.position.x > 0.0, "front-right pivot uses project positive X")
	_expect(rear_right.position.x > 0.0, "rear-right pivot uses project positive X")
	_expect(front_left.position.z < 0.0 and front_right.position.z < 0.0, "front axle uses project local -Z")
	_expect(rear_left.position.z > 0.0 and rear_right.position.z > 0.0, "rear axle lies behind the centred origin")
	_expect(absf(front_left.position.z - front_right.position.z) < 0.0001, "front pivots share one axle")
	_expect(absf(rear_left.position.z - rear_right.position.z) < 0.0001, "rear pivots share one axle")
	_expect(absf(absf(front_left.position.z - rear_left.position.z) - 2.81) < 0.001, "processed wheelbase is 2.810 m")
	for wheel: Node3D in [front_left, front_right, rear_left, rear_right]:
		_expect(wheel.position.y > 0.32 and wheel.position.y < 0.34, "%s pivot height matches tyre radius" % wheel.name)


func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		_collect_meshes(child, output)


func _mesh_triangle_count(mesh: Mesh) -> int:
	var result := 0
	if mesh == null:
		return result
	for surface_index: int in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface_index)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		result += int(indices.size() / 3) if not indices.is_empty() else int(vertices.size() / 3)
	return result


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BMW_F32_VISUAL_DERIVATIVE_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[BMW_F32_VISUAL_DERIVATIVE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BMW_F32_VISUAL_DERIVATIVE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BMW_F32_VISUAL_DERIVATIVE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
