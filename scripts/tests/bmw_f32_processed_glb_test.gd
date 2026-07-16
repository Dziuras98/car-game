extends SceneTree

const PROCESSED_PATH := "res://assets/third_party/sketchfab/traffic_rider_npc_vehicles/bmw_4_series_f32/processed/bmw_4_series_f32_processed.glb"
const REPORT_PATH := "res://build/test-logs/traffic-rider-bmw-f32-processed-inspection.json"
const EXPECTED_SHA256 := "bd0dc99b51e9756b800aeece83e2cea794b69aa182b583487fccf50e53237369"
const EXPECTED_TOTAL_TRIANGLES := 1780

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_expect(FileAccess.get_sha256(PROCESSED_PATH) == EXPECTED_SHA256, "processed BMW F32 GLB hash is deterministic")
	var packed := ResourceLoader.load(PROCESSED_PATH) as PackedScene
	_expect(packed != null, "processed BMW F32 GLB imports as PackedScene")
	if packed == null:
		_finish()
		return
	var instance: Node = packed.instantiate()
	_expect(instance != null, "processed BMW F32 scene instantiates")
	if instance == null:
		_finish()
		return

	var records: Array[Dictionary] = []
	var hierarchy: Array[Dictionary] = []
	_collect(instance, Transform3D.IDENTITY, "", records, hierarchy)
	_expect(records.size() == 5, "processed BMW F32 contains body plus four wheel meshes")

	var expected: Dictionary = {
		"Body": 1132,
		"FrontLeftWheel": 162,
		"FrontRightWheel": 162,
		"RearLeftWheel": 162,
		"RearRightWheel": 162,
	}
	var resolved: Dictionary = {}
	var total_triangles := 0
	for label: String in expected:
		var record := _find_exact_record(records, label)
		_expect(not record.is_empty(), "processed BMW F32 resolves exact node %s" % label)
		if record.is_empty():
			continue
		resolved[label] = record
		var triangles := _triangle_count((record["instance"] as MeshInstance3D).mesh)
		total_triangles += triangles
		_expect(triangles == int(expected[label]), "%s preserves %d triangles" % [label, int(expected[label])])
		var mesh: Mesh = (record["instance"] as MeshInstance3D).mesh
		_expect(mesh.get_surface_count() == 1, "%s preserves one source material surface" % label)
		_expect(mesh.surface_get_material(0) != null, "%s preserves its material" % label)

	_expect(total_triangles == EXPECTED_TOTAL_TRIANGLES, "processed BMW F32 preserves all 1780 source triangles")
	if resolved.size() == expected.size():
		_validate_geometry(resolved)

	var report := {
		"processed_path": PROCESSED_PATH,
		"sha256": FileAccess.get_sha256(PROCESSED_PATH),
		"hierarchy": hierarchy,
		"records": _serialize_records(records),
	}
	_write_report(report)
	instance.free()
	_finish()


func _collect(
	node: Node,
	parent_transform: Transform3D,
	parent_path: String,
	records: Array[Dictionary],
	hierarchy: Array[Dictionary]
) -> void:
	var node_path := String(node.name) if parent_path.is_empty() else "%s/%s" % [parent_path, node.name]
	var local_transform := Transform3D.IDENTITY
	if node is Node3D:
		local_transform = (node as Node3D).transform
	var accumulated := parent_transform * local_transform
	hierarchy.append({
		"name": String(node.name),
		"type": node.get_class(),
		"path": node_path,
	})
	if node is MeshInstance3D:
		records.append({
			"instance": node as MeshInstance3D,
			"path": node_path,
			"transform": accumulated,
		})
	for child: Node in node.get_children():
		_collect(child, accumulated, node_path, records, hierarchy)


func _find_exact_record(records: Array[Dictionary], expected_name: String) -> Dictionary:
	for record: Dictionary in records:
		var instance: MeshInstance3D = record["instance"]
		var mesh_name := "" if instance.mesh == null else String(instance.mesh.resource_name)
		if String(instance.name) == expected_name or mesh_name == expected_name or mesh_name == "%sMesh" % expected_name:
			return record
	return {}


func _validate_geometry(records: Dictionary) -> void:
	var front_left := _record_center(records["FrontLeftWheel"])
	var front_right := _record_center(records["FrontRightWheel"])
	var rear_left := _record_center(records["RearLeftWheel"])
	var rear_right := _record_center(records["RearRightWheel"])
	_expect(front_left.x < 0.0 and rear_left.x < 0.0, "processed left wheels use project negative X")
	_expect(front_right.x > 0.0 and rear_right.x > 0.0, "processed right wheels use project positive X")
	_expect(front_left.z < 0.0 and front_right.z < 0.0, "processed front axle uses local -Z")
	_expect(rear_left.z > 0.0 and rear_right.z > 0.0, "processed rear axle lies behind the origin")
	_expect(absf(absf(front_left.z - rear_left.z) - 2.81) < 0.001, "processed wheelbase is 2.810 m")
	for label: String in ["FrontLeftWheel", "FrontRightWheel", "RearLeftWheel", "RearRightWheel"]:
		var record: Dictionary = records[label]
		var wheel_instance: MeshInstance3D = record["instance"]
		var radius := maxf(wheel_instance.get_aabb().size.y, wheel_instance.get_aabb().size.z) * 0.5
		_expect(radius > 0.32 and radius < 0.34, "%s rolling radius is near 0.328 m" % label)
	var body_record: Dictionary = records["Body"]
	var body_instance: MeshInstance3D = body_record["instance"]
	var body_minimum_y := _transformed_aabb(body_instance.get_aabb(), body_record["transform"]).position.y
	_expect(body_minimum_y > 0.13 and body_minimum_y < 0.16, "body underside remains above the grounded wheel plane")


func _record_center(record: Dictionary) -> Vector3:
	var instance: MeshInstance3D = record["instance"]
	return (record["transform"] as Transform3D) * instance.get_aabb().get_center()


func _triangle_count(mesh: Mesh) -> int:
	var result := 0
	if mesh == null:
		return result
	for surface_index: int in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface_index)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		result += int(indices.size() / 3) if not indices.is_empty() else int(vertices.size() / 3)
	return result


func _transformed_aabb(value: AABB, transform: Transform3D) -> AABB:
	var result := AABB(transform * value.get_endpoint(0), Vector3.ZERO)
	for endpoint_index: int in range(1, 8):
		result = result.expand(transform * value.get_endpoint(endpoint_index))
	return result


func _serialize_records(records: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record: Dictionary in records:
		var instance: MeshInstance3D = record["instance"]
		result.append({
			"name": String(instance.name),
			"mesh_resource_name": "" if instance.mesh == null else String(instance.mesh.resource_name),
			"path": record["path"],
			"triangle_count": _triangle_count(instance.mesh),
			"center": _vector_to_array(_record_center(record)),
		})
	return result


func _write_report(report: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_PATH.get_base_dir()))
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	_expect(file != null, "processed inspection report can be written")
	if file != null:
		file.store_string(JSON.stringify(report, "\t", false))
		file.close()


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BMW_F32_PROCESSED_GLB_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[BMW_F32_PROCESSED_GLB_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BMW_F32_PROCESSED_GLB_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BMW_F32_PROCESSED_GLB_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
