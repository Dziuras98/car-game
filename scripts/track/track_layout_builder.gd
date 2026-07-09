extends RefCounted
class_name TrackLayoutBuilder


func build(config: Dictionary) -> TrackGeometryData:
	var geometry: TrackGeometryData = TrackGeometryData.new()
	var points: PackedVector3Array = _get_track_points()
	var point_count: int = points.size()
	var track_width: float = float(config.get("track_width", 14.0))
	var width_variation: float = float(config.get("width_variation", 0.28))
	var shoulder_width: float = float(config.get("shoulder_width", 10.0))

	geometry.center_points = points
	geometry.racing_line_points = points
	geometry.center = _get_points_center(points)

	for index in point_count:
		var previous: Vector3 = points[(index - 1 + point_count) % point_count]
		var current: Vector3 = points[index]
		var next: Vector3 = points[(index + 1) % point_count]
		var tangent: Vector3 = (next - previous).normalized()
		var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
		var half_width: float = get_half_width(index, point_count, track_width, width_variation)

		geometry.forward_vectors.append(tangent)
		geometry.right_vectors.append(side)
		geometry.half_widths.append(half_width)
		geometry.left_edge_points.append(current - side * half_width)
		geometry.right_edge_points.append(current + side * half_width)
		geometry.left_shoulder_outer_points.append(current - side * (half_width + shoulder_width))
		geometry.right_shoulder_outer_points.append(current + side * (half_width + shoulder_width))

	return geometry


func get_half_width(index: int, point_count: int, track_width: float, width_variation: float) -> float:
	var progress: float = float(index) / float(point_count)
	var turn_blend: float = maxf(
		clampf(1.0 - absf(progress - 0.29) / 0.16, 0.0, 1.0),
		clampf(1.0 - absf(progress - 0.79) / 0.16, 0.0, 1.0)
	)
	var width_scale: float = 1.0 + turn_blend * width_variation
	return track_width * clampf(width_scale, 0.7, 1.45) * 0.5


func _get_track_points() -> PackedVector3Array:
	var control_points: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(0.0, 0.0, -90.0),
		Vector3(0.0, 0.0, -170.0),
		Vector3(18.0, 0.4, -230.0),
		Vector3(60.0, 1.2, -270.0),
		Vector3(105.0, 1.8, -282.0),
		Vector3(150.0, 1.2, -270.0),
		Vector3(192.0, 0.4, -230.0),
		Vector3(210.0, 0.0, -170.0),
		Vector3(210.0, 0.0, -90.0),
		Vector3(210.0, 0.0, 0.0),
		Vector3(210.0, 0.0, 90.0),
		Vector3(192.0, 0.4, 150.0),
		Vector3(150.0, 1.2, 190.0),
		Vector3(105.0, 1.8, 202.0),
		Vector3(60.0, 1.2, 190.0),
		Vector3(18.0, 0.4, 150.0),
		Vector3(0.0, 0.0, 90.0),
	]

	var sampled_points: PackedVector3Array = PackedVector3Array()
	for index in control_points.size():
		var p0: Vector3 = control_points[(index - 1 + control_points.size()) % control_points.size()]
		var p1: Vector3 = control_points[index]
		var p2: Vector3 = control_points[(index + 1) % control_points.size()]
		var p3: Vector3 = control_points[(index + 2) % control_points.size()]

		for step in 6:
			var t: float = float(step) / 6.0
			sampled_points.append(_catmull_rom(p0, p1, p2, p3, t))

	return sampled_points


func _get_points_center(points: PackedVector3Array) -> Vector3:
	var center: Vector3 = Vector3.ZERO
	for point: Vector3 in points:
		center += point
	return center / float(points.size())


func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)
