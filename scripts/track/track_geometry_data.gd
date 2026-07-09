extends RefCounted
class_name TrackGeometryData

var center_points: PackedVector3Array = PackedVector3Array()
var left_edge_points: PackedVector3Array = PackedVector3Array()
var right_edge_points: PackedVector3Array = PackedVector3Array()
var left_shoulder_outer_points: PackedVector3Array = PackedVector3Array()
var right_shoulder_outer_points: PackedVector3Array = PackedVector3Array()
var racing_line_points: PackedVector3Array = PackedVector3Array()
var forward_vectors: PackedVector3Array = PackedVector3Array()
var right_vectors: PackedVector3Array = PackedVector3Array()
var half_widths: PackedFloat32Array = PackedFloat32Array()
var center: Vector3 = Vector3.ZERO


func get_racing_line_points_array() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for point: Vector3 in racing_line_points:
		points.append(point)
	return points


func get_center_points_array() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for point: Vector3 in center_points:
		points.append(point)
	return points
